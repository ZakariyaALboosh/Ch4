function cfg = config_chapter4()
%CONFIG_CHAPTER4 Editable assumptions for Chapter 4 S/X-band studies.
% All transmitter, antenna-temperature, receiver, and loss values are
% preliminary design assumptions for thesis analysis, not measured values.

cfg.output.savePng = true;
cfg.output.savePdf = true;
cfg.output.figureVisible = "off";
cfg.output.runOptionalAntenna = false;

% Editable preliminary site values: coordinates and altitude should be
% updated if a final survey of the Zawiya station site is available.
cfg.gs.name = "Zawiya Ground Station";
cfg.gs.latDeg = 32.75;
cfg.gs.lonDeg = 12.72;
cfg.gs.altM = 20;
cfg.gs.minElevationDeg = 15;

cfg.orbit.altitudeM = 500e3;
cfg.orbit.inclinationDeg = 51.6;
cfg.orbit.raanDeg = 0;
cfg.orbit.argumentOfPerigeeDeg = 0;
cfg.orbit.trueAnomalyDeg = 0;
cfg.orbit.startTimeUTC = datetime(2026,7,13,0,0,0,"TimeZone","UTC");
cfg.orbit.durationHours = 24;
cfg.orbit.sampleTimeSec = 5;
cfg.orbit.rotatorLimitDegPerSec = 6;
% Synthetic fallback assumptions for a representative LEO pass only.
cfg.orbit.syntheticDurationSec = 780;
cfg.orbit.syntheticMaxElevationDeg = 70;
cfg.orbit.syntheticMinRangeKm = 500;
cfg.orbit.syntheticMaxRangeKm = 1800;
cfg.orbit.syntheticAzStartDeg = 40;
cfg.orbit.syntheticAzEndDeg = 220;

cfg.general.referenceTemperatureK = 290;
cfg.general.passesPerDay = 4;
cfg.general.exampleImageSizeMB = 6;

cfg.s.name = "S-band"; cfg.s.fcHz = 2.25e9;
cfg.s.netDataRateBps = 1e6; cfg.s.requiredEbNoDb = 1; cfg.s.implementationLossDb = 1; cfg.s.requiredMarginDb = 3;
cfg.s.rxDishDiametersM = [0.6 0.9 1.2 1.5]; cfg.s.selectedDishDiameterM = 1.2; cfg.s.dishEfficiency = 0.45;
cfg.s.txPowerDbm = 33; cfg.s.txAntennaGainDbi = 13; cfg.s.txLossDb = 1.5;
cfg.s.rxLossBeforeLnaDb = 0.5; cfg.s.rxLossAfterLnaDb = 2.0;
cfg.s.environmentLossNominalDb = 1.0; cfg.s.environmentLossAdverseDb = 3.0; cfg.s.polarizationLossDb = 0.5; cfg.s.pointingLossDb = 0.5;
cfg.s.bandwidthHz = 1.2e6; cfg.s.antennaTempNominalK = 80; cfg.s.antennaTempAdverseK = 150;
cfg.s.receiver.activeDeviceName = "S-band LNA"; cfg.s.receiver.activeGainDb = 30; cfg.s.receiver.activeNfDb = 0.8; cfg.s.receiver.postLnaLossDb = 2.0; cfg.s.receiver.studyPreLnaLossDb = [0 1 3];

cfg.x.name = "X-band"; cfg.x.fcHz = 8.2e9;
cfg.x.netDataRateBps = 5e6; cfg.x.requiredEbNoDb = 1; cfg.x.implementationLossDb = 1; cfg.x.requiredMarginDb = 3;
cfg.x.rxDishDiametersM = [0.6 0.9 1.2 1.5]; cfg.x.selectedDishDiameterM = 1.2; cfg.x.dishEfficiency = 0.55;
cfg.x.txPowerDbm = 33; cfg.x.txAntennaGainDbi = 16; cfg.x.txLossDb = 1.5;
cfg.x.rxLossBeforeLnaDb = 0.3; cfg.x.rxLossAfterLnaDb = 1.0;
cfg.x.environmentLossNominalDb = 2.0; cfg.x.environmentLossAdverseDb = 8.0; cfg.x.polarizationLossDb = 0.5; cfg.x.pointingLossDb = 0.5;
cfg.x.bandwidthHz = 6e6; cfg.x.antennaTempNominalK = 80; cfg.x.antennaTempAdverseK = 150;
cfg.x.receiver.activeDeviceName = "X-band LNB/LNA"; cfg.x.receiver.activeGainDb = 40; cfg.x.receiver.activeNfDb = 1.2; cfg.x.receiver.postLnaLossDb = 1.0; cfg.x.receiver.studyPreLnaLossDb = [0 0.5 2];
end
