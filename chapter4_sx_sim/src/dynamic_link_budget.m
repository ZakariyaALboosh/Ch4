function link = dynamic_link_budget(bandConfig, pass, environmentCase, receiverTeK)
environmentCase = lower(string(environmentCase));
if ~(environmentCase=="nominal" || environmentCase=="adverse"), error('Environment must be nominal or adverse.'); end
validateattributes(receiverTeK, {'numeric'}, {'scalar','nonnegative','finite'});
c=299792458; k=1.380649e-23; rangeM = pass.rangeM(:); lambda = c/bandConfig.fcHz;
fsplDb = 20*log10(4*pi*rangeM/lambda);
rxAntennaGainDbi = compute_dish_gain(bandConfig.fcHz, bandConfig.selectedDishDiameterM, bandConfig.dishEfficiency);
eirpDbm = bandConfig.txPowerDbm + bandConfig.txAntennaGainDbi - bandConfig.txLossDb;
if environmentCase=="nominal", envLoss=bandConfig.environmentLossNominalDb; antT=bandConfig.antennaTempNominalK; else, envLoss=bandConfig.environmentLossAdverseDb; antT=bandConfig.antennaTempAdverseK; end
% Reference plane: receiver cascade losses are included in receiverTeK, so
% pre-LNA/post-LNA losses are not subtracted again from carrier power here.
rxPowerDbm = eirpDbm - fsplDb - envLoss - bandConfig.polarizationLossDb - bandConfig.pointingLossDb + rxAntennaGainDbi;
systemTemperatureK = antT + receiverTeK; noisePowerDbm = 10*log10(k*systemTemperatureK*bandConfig.bandwidthHz) + 30;
snrDb = rxPowerDbm - noisePowerDbm; ebnoDb = snrDb + 10*log10(bandConfig.bandwidthHz/bandConfig.netDataRateBps);
rawMarginDb = ebnoDb - bandConfig.requiredEbNoDb - bandConfig.implementationLossDb; marginDb = rawMarginDb - bandConfig.requiredMarginDb;
usableMask = marginDb >= 0; dtVector = diff(pass.tSec(:)); inc = double(usableMask(1:end-1)).*dtVector.*bandConfig.netDataRateBps; cumulativeDataBits=[0; cumsum(inc)];
link.time=pass.time; link.tSec=pass.tSec(:); link.rangeKm=pass.rangeKm(:); link.fsplDb=fsplDb; link.rxAntennaGainDbi=rxAntennaGainDbi; link.eirpDbm=eirpDbm;
link.rxPowerDbm=rxPowerDbm; link.systemTemperatureK=systemTemperatureK; link.noisePowerDbm=noisePowerDbm; link.snrDb=snrDb; link.ebnoDb=ebnoDb;
link.rawMarginDb=rawMarginDb; link.marginDb=marginDb; link.usableMask=usableMask; link.cumulativeDataBits=cumulativeDataBits; link.cumulativeDataMB=cumulativeDataBits/8/1e6; link.environmentCase=environmentCase;
end
