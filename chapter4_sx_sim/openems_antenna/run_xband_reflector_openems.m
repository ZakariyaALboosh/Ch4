%% RUN_XBAND_REFLECTOR_OPENEMS
% Real full-wave X-band reflector simulation using openEMS.
%
% Architecture:
%   8.2 GHz prime-focus parabolic reflector
%   circular waveguide TE11 feed at the focal point
%
% The dimensions are intentionally conventional and computationally
% manageable. This is a reference EM verification model, not an original
% optimized feed design or a manufacturing release.

clear; clc;
thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

cfg = struct();
cfg.name = 'X-band 8.2 GHz prime-focus reflector';
cfg.slug = 'xband_8p2GHz_reflector';

cfg.fStartHz = 7.80e9;
cfg.f0Hz     = 8.20e9;
cfg.fStopHz  = 8.60e9;

% Reference reflector dimensions.
cfg.dishDiameterMm = 450;
cfg.focalLengthMm  = 202.5; % f/D = 0.45

% Circular waveguide dimensions chosen so TE11 propagates over the band
% while the next TM01 mode remains above the simulated band.
cfg.waveguideRadiusMm = 12;
cfg.waveguideLengthMm = 70;
cfg.metalThicknessMm  = 1;

% X-band is electrically larger, so use a slightly coarser but still
% reasonable baseline mesh. Increase cellsPerLambda for a convergence run.
cfg.cellsPerLambda = 12;
cfg.airMarginMm = 50;
cfg.profileStepMm = 0.5;
cfg.numThreads = 4;

cfg.runSimulation = true;
cfg.showGeometry = false;
cfg.calculate3D = false; % set true only after the 2D far-field run succeeds

result = simulate_prime_focus_reflector_openems(cfg); %#ok<NASGU>
