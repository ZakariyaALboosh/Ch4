function result = receiver_cascade(stages, referenceTemperatureK)
validateattributes(referenceTemperatureK, {'numeric'}, {'scalar','positive','finite'});
if istable(stages)
    req = {'name','gainDb','nfDb'}; req2 = {'Name','Gain_dB','Noise_Figure_dB'};
    if all(ismember(req, stages.Properties.VariableNames))
        names = string(stages.name); gainDb = stages.gainDb; nfDb = stages.nfDb;
    elseif all(ismember(req2, stages.Properties.VariableNames))
        names = string(stages.Name); gainDb = stages.Gain_dB; nfDb = stages.Noise_Figure_dB;
    else, error('receiver_cascade:MissingColumns','Table must contain name/gainDb/nfDb columns.'); end
elseif isstruct(stages)
    if ~all(isfield(stages, {'name','gainDb','nfDb'})), error('receiver_cascade:MissingFields','Stages must contain name, gainDb, nfDb.'); end
    names = string({stages.name})'; gainDb = [stages.gainDb]'; nfDb = [stages.nfDb]';
else, error('receiver_cascade:BadInput','Stages must be a struct array or table.'); end
if isempty(gainDb) || any(~isfinite(gainDb)) || any(~isfinite(nfDb)), error('receiver_cascade:BadValues','Gain and noise figure values must be finite.'); end
G = 10.^(gainDb(:)/10); F = 10.^(nfDb(:)/10); nStages = numel(G);
Ftotal = F(1); cumulativeGain = G(1); friisContribution = zeros(nStages,1); friisContribution(1) = F(1);
cumGain = zeros(nStages,1); cumF = zeros(nStages,1); cumGain(1)=G(1); cumF(1)=F(1);
for n = 2:nStages
    friisContribution(n) = (F(n)-1)/cumulativeGain;
    Ftotal = Ftotal + friisContribution(n);
    cumulativeGain = cumulativeGain * G(n);
    cumGain(n) = cumulativeGain; cumF(n) = Ftotal;
end
totalGainDb = 10*log10(prod(G)); totalNoiseFigureDb = 10*log10(Ftotal);
result.totalGainDb = totalGainDb; result.totalNoiseFactor = Ftotal; result.totalNoiseFigureDb = totalNoiseFigureDb;
result.equivalentNoiseTemperatureK = referenceTemperatureK * (Ftotal - 1);
result.stageTable = table(names(:), gainDb(:), nfDb(:), G(:), F(:), friisContribution(:), 10*log10(cumGain(:)), 10*log10(cumF(:)), ...
    'VariableNames', {'Stage','Gain_dB','Noise_Figure_dB','Linear_Gain','Linear_Noise_Factor','Friis_Contribution','Cumulative_Gain_dB','Cumulative_Noise_Figure_dB'});
end
