% Minimal GRBBeta TLE orbit smoke test for simple_orbit_pass.
addpath(fullfile(fileparts(mfilename('fullpath')), 'src'));

cfg.orbit.startTimeUTC = datetime(2026, 7, 14, 0, 0, 0, 'TimeZone', 'UTC');
cfg.orbit.durationHours = 24;
cfg.orbit.sampleTimeSec = 1;
cfg.orbit.tleName = 'GRBBETA';
cfg.orbit.tleLine1 = '1 60237U 24128C   26195.16407140  .00001802  00000-0  13324-3 0  9998';
cfg.orbit.tleLine2 = '2 60237  61.9897 121.6054 0037194 140.4046 219.9774 15.06804555110338';

cfg.orbit.altitudeM = 500e3;
cfg.orbit.syntheticDurationSec = 780;
cfg.orbit.syntheticMaxElevationDeg = 70;
cfg.orbit.syntheticMinRangeKm = 500;
cfg.orbit.syntheticMaxRangeKm = 1800;
cfg.orbit.syntheticAzStartDeg = 40;
cfg.orbit.syntheticAzEndDeg = 220;

cfg.gs.latDeg = 32.75;
cfg.gs.lonDeg = 12.73;
cfg.gs.altM = 20;
cfg.gs.minElevationDeg = 10;

pass = simple_orbit_pass(cfg);

disp(pass.source)
disp(pass.maxElevationDeg)
disp(pass.aosTime)
disp(pass.losTime)
