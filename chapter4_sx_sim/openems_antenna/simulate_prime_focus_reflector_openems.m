function result = simulate_prime_focus_reflector_openems(cfg)
%SIMULATE_PRIME_FOCUS_REFLECTOR_OPENEMS Full-wave openEMS reflector model.
%
% This function builds and solves a PEC prime-focus parabolic reflector
% illuminated by a circular-waveguide TE11 feed. The geometry and workflow
% are adapted from the open-source reflector tutorial by Paul Klasmann and
% the standard openEMS MATLAB/Octave tutorial style.
%
% This is intentionally a reference electromagnetic model, not an original
% optimized feed design. It is suitable for demonstrating real full-wave
% FDTD modelling of a reflector antenna when antenna design is not the core
% contribution of the project.
%
% Required external software:
%   - openEMS with the MATLAB/Octave interface on the MATLAB path
%   - CSXCAD (installed with openEMS)
%
% Required cfg fields:
%   name, slug, fStartHz, f0Hz, fStopHz
%   dishDiameterMm, focalLengthMm
%   waveguideRadiusMm, waveguideLengthMm, metalThicknessMm
%   cellsPerLambda, airMarginMm, profileStepMm, numThreads
%   runSimulation, showGeometry, calculate3D
%
% Output files are written under openems_antenna/results/<slug>/.

validateattributes(cfg.fStartHz, {'numeric'}, {'scalar','positive','finite'});
validateattributes(cfg.f0Hz, {'numeric'}, {'scalar','positive','finite'});
validateattributes(cfg.fStopHz, {'numeric'}, {'scalar','positive','finite'});
assert(cfg.fStartHz < cfg.f0Hz && cfg.f0Hz < cfg.fStopHz, ...
    'Frequency order must be fStartHz < f0Hz < fStopHz.');

% openEMS constants: c0, eps0, mue0, eta0.
physical_constants;
unit = 1e-3; % geometry is specified in millimetres

scriptDir = fileparts(mfilename('fullpath'));
simPath = fullfile(scriptDir, 'tmp', cfg.slug);
outDir = fullfile(scriptDir, 'results', cfg.slug);
if ~exist(outDir, 'dir'), mkdir(outDir); end
if exist(simPath, 'dir'), rmdir(simPath, 's'); end
mkdir(simPath);

% -------------------------------------------------------------------------
% Geometry and waveguide checks
% -------------------------------------------------------------------------
R = cfg.dishDiameterMm / 2;
FL = cfg.focalLengthMm;
A = pi * (R * unit)^2;
depth = cfg.dishDiameterMm^2 / (16 * FL);

wgRadiusM = cfg.waveguideRadiusMm * unit;
fcTE11 = 1.8412 * c0 / (2*pi*wgRadiusM);
fcTM01 = 2.4048 * c0 / (2*pi*wgRadiusM);

fprintf('\n============================================================\n');
fprintf('%s\n', cfg.name);
fprintf('openEMS full-wave FDTD prime-focus reflector model\n');
fprintf('Centre frequency       : %.4f GHz\n', cfg.f0Hz/1e9);
fprintf('Dish diameter          : %.1f mm\n', cfg.dishDiameterMm);
fprintf('Focal length           : %.1f mm (f/D = %.3f)\n', FL, FL/cfg.dishDiameterMm);
fprintf('Waveguide radius       : %.2f mm\n', cfg.waveguideRadiusMm);
fprintf('TE11 cutoff            : %.4f GHz\n', fcTE11/1e9);
fprintf('Next TM01 cutoff       : %.4f GHz\n', fcTM01/1e9);
fprintf('============================================================\n');

if cfg.fStartHz <= fcTE11
    error('openems:WaveguideBelowCutoff', ...
        'The requested band begins below the TE11 cutoff frequency.');
end
if cfg.fStopHz >= fcTM01
    warning('openems:HigherModePossible', ...
        ['The simulated band reaches the TM01 cutoff. Reduce the waveguide ' ...
         'radius or narrow the frequency range for cleaner single-mode operation.']);
end

% Parabola profile: z = r^2/(4F) - F, so the focus is at z = 0.
x = 0:cfg.profileStepMm:R;
if x(end) < R, x(end+1) = R; end %#ok<AGROW>
z = x.^2/(4*FL) - FL;
curve = [x; z];

% Close the rotational polygon to create a finite-thickness PEC reflector.
extraPoints = [R, 0, 0; ...
              -FL-cfg.metalThicknessMm, -FL-cfg.metalThicknessMm, 0];
coords = [curve, extraPoints];

fig = figure('Visible','off');
plot(x, z, 'LineWidth', 1.5); axis equal; grid on;
xlabel('Radius (mm)'); ylabel('z (mm)');
title([cfg.name ' - parabolic profile']);
saveas(fig, fullfile(outDir, 'reflector_profile.png'));
close(fig);

% -------------------------------------------------------------------------
% FDTD setup
% -------------------------------------------------------------------------
FDTD = InitFDTD('NrTS', 12000, 'EndCriteria', 1e-4);
FDTD = SetGaussExcite(FDTD, ...
    0.5*(cfg.fStartHz + cfg.fStopHz), ...
    0.5*(cfg.fStopHz - cfg.fStartHz));
FDTD = SetBoundaryCond(FDTD, ...
    {'PML_8','PML_8','PML_8','PML_8','PML_8','PML_8'});

maxRes = c0 / cfg.fStopHz / unit / cfg.cellsPerLambda;

simBoxXY = cfg.dishDiameterMm + 2*cfg.airMarginMm;
zMin = -FL - cfg.airMarginMm;
zMax = cfg.waveguideLengthMm + cfg.airMarginMm;

mesh.x = [-simBoxXY/2, -cfg.waveguideRadiusMm, 0, ...
           cfg.waveguideRadiusMm, simBoxXY/2];
mesh.x = SmoothMeshLines(mesh.x, maxRes, 1.4);
mesh.y = mesh.x;
mesh.z = [zMin, -FL-cfg.metalThicknessMm, -FL, -FL+depth, ...
          0, cfg.waveguideLengthMm-5, cfg.waveguideLengthMm, ...
          cfg.waveguideLengthMm+1, zMax];
mesh.z = SmoothMeshLines(mesh.z, maxRes, 1.4);

CSX = InitCSX();
CSX = DefineRectGrid(CSX, unit, mesh);

% -------------------------------------------------------------------------
% PEC parabolic reflector using a rotational polygon
% -------------------------------------------------------------------------
CSX = AddMetal(CSX, 'Parabola');
CSX = AddRotPoly(CSX, 'Parabola', 10, 'x', coords, 'z');

% -------------------------------------------------------------------------
% Circular-waveguide TE11 feed, following the reference reflector model.
% The open aperture is at z=0, which is the reflector focal point.
% -------------------------------------------------------------------------
CSX = AddMetal(CSX, 'Circular_Waveguide');
p = zeros(2,4);
p(:,1) = [cfg.waveguideRadiusMm; 0];
p(:,2) = [cfg.waveguideRadiusMm + cfg.metalThicknessMm; 0];
p(:,3) = [cfg.waveguideRadiusMm + cfg.metalThicknessMm; cfg.waveguideLengthMm];
p(:,4) = [cfg.waveguideRadiusMm; cfg.waveguideLengthMm];
CSX = AddRotPoly(CSX, 'Circular_Waveguide', 10, 'x', p, 'z');

CSX = AddMetal(CSX, 'Feed_Back_Cap');
CSX = AddCylinder(CSX, 'Feed_Back_Cap', 10, ...
    [0 0 cfg.waveguideLengthMm], ...
    [0 0 cfg.waveguideLengthMm+1], ...
    cfg.waveguideRadiusMm + cfg.metalThicknessMm);

% TE11 circular waveguide excitation.
portStart = [-cfg.waveguideRadiusMm, -cfg.waveguideRadiusMm, cfg.waveguideLengthMm];
portStop  = [ cfg.waveguideRadiusMm,  cfg.waveguideRadiusMm, cfg.waveguideLengthMm-5];
[CSX, port] = AddCircWaveGuidePort(CSX, 0, 1, ...
    portStart, portStop, cfg.waveguideRadiusMm*unit, 'TE11', 0, 1);

% Near-field to far-field recording box. Keep it away from the PML cells.
guard = 10;
if numel(mesh.x) <= 2*guard || numel(mesh.z) <= 2*guard
    error('openems:MeshTooSmall', ...
        'Mesh does not contain enough cells to place an NF2FF box safely.');
end
nfStart = [mesh.x(guard), mesh.y(guard), mesh.z(guard)];
nfStop  = [mesh.x(end-guard), mesh.y(end-guard), mesh.z(end-guard)];
[CSX, nf2ff] = CreateNF2FFBox(CSX, 'nf2ff', nfStart, nfStop, ...
    'Directions', [1 1 1 1 1 1], 'OptResolution', maxRes*2);

simXml = [cfg.slug '.xml'];
WriteOpenEMS(fullfile(simPath, simXml), FDTD, CSX);

if cfg.showGeometry
    CSXGeomPlot(fullfile(simPath, simXml));
end

if cfg.runSimulation
    RunOpenEMS(simPath, simXml, sprintf('--numThreads=%d', cfg.numThreads));
else
    fprintf('Geometry written but FDTD run skipped because cfg.runSimulation=false.\n');
    result = struct('name',cfg.name,'simulationPath',simPath,'outputPath',outDir, ...
        'ranSimulation',false);
    return;
end

% -------------------------------------------------------------------------
% S11 and impedance post-processing
% -------------------------------------------------------------------------
freq = linspace(cfg.fStartHz, cfg.fStopHz, 201);
port = calcPort(port, simPath, freq);
Zin = port.uf.tot ./ port.if.tot;
s11 = port.uf.ref ./ port.uf.inc;
s11Db = 20*log10(abs(s11));

fig = figure('Visible','off');
plot(freq/1e9, s11Db, 'LineWidth', 1.5); grid on;
xlabel('Frequency (GHz)'); ylabel('|S_{11}| (dB)');
title([cfg.name ' - reflection coefficient']);
ylim([-50 0]);
saveas(fig, fullfile(outDir, 's11.png'));
close(fig);

fig = figure('Visible','off');
plot(freq/1e9, real(Zin), 'LineWidth', 1.5); hold on;
plot(freq/1e9, imag(Zin), '--', 'LineWidth', 1.5); grid on;
xlabel('Frequency (GHz)'); ylabel('Input impedance (ohm)');
legend('Real','Imaginary','Location','best');
title([cfg.name ' - feed input impedance']);
saveas(fig, fullfile(outDir, 'input_impedance.png'));
close(fig);

T = table(freq(:), s11Db(:), real(Zin(:)), imag(Zin(:)), ...
    'VariableNames', {'Frequency_Hz','S11_dB','Zin_Real_Ohm','Zin_Imag_Ohm'});
writetable(T, fullfile(outDir, 'port_results.csv'));

% -------------------------------------------------------------------------
% Far-field post-processing at the design frequency
% -------------------------------------------------------------------------
thetaDeg = (0:0.5:359) - 180;
phiDeg = [0 90];
fprintf('Calculating far field at %.4f GHz...\n', cfg.f0Hz/1e9);
nf2ff = CalcNF2FF(nf2ff, simPath, cfg.f0Hz, ...
    thetaDeg*pi/180, phiDeg*pi/180);

DmaxLinear = nf2ff.Dmax(1);
DmaxDb = 10*log10(DmaxLinear);
idealApertureDirectivity = 4*pi*A/(c0/cfg.f0Hz)^2;
apertureEfficiency = DmaxLinear/idealApertureDirectivity;

fig = figure('Visible','off');
plotFFdB(nf2ff, 'xaxis','theta', 'param',[1 2]);
grid on;
title(sprintf('%s - far-field directivity at %.4f GHz', cfg.name, cfg.f0Hz/1e9));
saveas(fig, fullfile(outDir, 'farfield_cuts.png'));
close(fig);

if cfg.calculate3D
    phi3D = -180:5:180;
    theta3D = 0:2:180;
    nf2ff3D = CalcNF2FF(nf2ff, simPath, cfg.f0Hz, ...
        theta3D*pi/180, phi3D*pi/180, ...
        'Verbose', 2, 'Outfile', 'nf2ff_3D.h5');
    fig = figure('Visible','off');
    plotFF3D(nf2ff3D, 'logscale', -40);
    saveas(fig, fullfile(outDir, 'farfield_3d.png'));
    close(fig);
end

[~, idx0] = min(abs(freq-cfg.f0Hz));

summaryPath = fullfile(outDir, 'summary.txt');
fid = fopen(summaryPath, 'w');
if fid == -1, error('Could not create summary file: %s', summaryPath); end
cleaner = onCleanup(@() fclose(fid));
fprintf(fid, 'Model: %s\n', cfg.name);
fprintf(fid, 'Solver: openEMS FDTD\n');
fprintf(fid, 'Centre frequency: %.9g Hz\n', cfg.f0Hz);
fprintf(fid, 'Dish diameter: %.6f m\n', cfg.dishDiameterMm/1000);
fprintf(fid, 'Focal length: %.6f m\n', cfg.focalLengthMm/1000);
fprintf(fid, 'f/D: %.6f\n', cfg.focalLengthMm/cfg.dishDiameterMm);
fprintf(fid, 'Waveguide radius: %.6f m\n', cfg.waveguideRadiusMm/1000);
fprintf(fid, 'TE11 cutoff: %.9g Hz\n', fcTE11);
fprintf(fid, 'TM01 cutoff: %.9g Hz\n', fcTM01);
fprintf(fid, 'S11 at design frequency: %.4f dB\n', s11Db(idx0));
fprintf(fid, 'Maximum directivity: %.4f dBi\n', DmaxDb);
fprintf(fid, 'Calculated aperture efficiency: %.4f %%\n', 100*apertureEfficiency);
fprintf(fid, 'Reference-model note: feed and reflector are not claimed as an original optimized antenna design.\n');
clear cleaner;

result = struct();
result.name = cfg.name;
result.frequencyHz = freq;
result.s11Db = s11Db;
result.ZinOhm = Zin;
result.designFrequencyHz = cfg.f0Hz;
result.directivityDbi = DmaxDb;
result.apertureEfficiency = apertureEfficiency;
result.te11CutoffHz = fcTE11;
result.tm01CutoffHz = fcTM01;
result.simulationPath = simPath;
result.outputPath = outDir;
result.ranSimulation = true;

fprintf('Simulation complete: %s\n', cfg.name);
fprintf('Maximum directivity: %.2f dBi\n', DmaxDb);
fprintf('Aperture efficiency: %.1f %%\n', 100*apertureEfficiency);
fprintf('Results: %s\n', outDir);
end
