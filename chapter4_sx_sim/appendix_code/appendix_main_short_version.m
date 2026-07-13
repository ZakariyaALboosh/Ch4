%% Appendix short analytical example for Chapter 4
% The complete implementation is contained in the main project files.
fcHz = 2.25e9; dishDiameterM = 1.2; efficiency = 0.45; T0 = 290;
netDataRateBps = 1e6; bandwidthHz = 1.2e6; k = 1.380649e-23; c = 299792458;
rangeM = (1800:-10:500)'*1000; tSec = (0:numel(rangeM)-1)'*5;
rx = appendix_functions_short_version('friis',[-0.5 30 -2.0],[0.5 0.8 2.0],T0);
gainDbi = appendix_functions_short_version('dishgain',fcHz,dishDiameterM,efficiency);
hpbwDeg = appendix_functions_short_version('beamwidth',fcHz,dishDiameterM);
radialVelocityMps = gradient(rangeM,5); dopplerHz = appendix_functions_short_version('doppler',radialVelocityMps,fcHz);
fsplDb = 20*log10(4*pi*rangeM/(c/fcHz)); eirpDbm = 33 + 13 - 1.5;
rxPowerDbm = eirpDbm - fsplDb - 1.0 - 0.5 - 0.5 + gainDbi;
noiseDbm = 10*log10(k*(80 + rx.noiseTemperatureK)*bandwidthHz)+30;
ebnoDb = rxPowerDbm - noiseDbm + 10*log10(bandwidthHz/netDataRateBps);
marginDb = ebnoDb - 1 - 1 - 3; usable = marginDb >= 0;
usableTimeSec = sum(diff(tSec) .* (usable(1:end-1) & usable(2:end)));
dataPerPassMB = usableTimeSec * netDataRateBps / 8 / 1e6;
fprintf('Gain %.2f dBi, HPBW %.2f deg, NF %.2f dB, max Doppler %.0f Hz, data %.2f MB\n', gainDbi, hpbwDeg, rx.noiseFigureDb, max(abs(dopplerHz)), dataPerPassMB);
