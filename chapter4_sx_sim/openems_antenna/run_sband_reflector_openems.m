%% RUN_SBAND_REFLECTOR_OPENEMS
% Real full-wave S-band reflector simulation using openEMS.
%
% Architecture:
%   2.25 GHz prime-focus parabolic reflector
%   circular waveguide TE11 feed at the focal point
%
% The dimensions are intentionally conventional and computationally
% manageable. This is a reference EM verification model, not an original
% optimized feed design or a manufacturing release.

clear; clc;
thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

cfg = struct();
cfg.name = 'S-band 2.25 GHz prime-focus reflector';
cfg.slug = 'sband_2p25GHz_reflector';

cfg.fStartHz = 2.10e9;
cfg.f0Hz     = 2.25e9;
cfg.fStopHz  = 2.40e9;

% Reference reflector dimensions.
cfg.dishDiameterMm = 600;
cfg.focalLengthMm  = 270;   % f/D = 0.45

% Circular waveguide dimensions chosen so TE11 propagates over the band
% while the next TM01 mode remains above the simulated band.
cfg.waveguideRadiusMm = 45;
cfg.waveguideLengthMm = 120;
cfg.metalThicknessMm  = 2;

% Numerical controls.
cfg.cellsPerLambda = 15;
cfg.airMarginMm = 100;
cfg.profileStepMm = 1.0;
cfg.numThreads = 4;

cfg.runSimulation = true;
cfg.showGeometry = false;
cfg.calculate3D = false; % set true only after the 2D far-field run succeeds

result = simulate_prime_focus_reflector_openems(cfg); %#ok<NASGU>
