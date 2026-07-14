function T = chapter4_figure_manifest(pass, antennaStatus)
%CHAPTER4_FIGURE_MANIFEST Metadata for generated Chapter 4 figures.
if nargin < 1 || isempty(pass), orbitType = "satelliteScenario"; else, orbitType = string(pass.source); end
if nargin < 2 || isempty(antennaStatus)
    antennaStatus.s = "analytical approximation"; antennaStatus.x = "analytical approximation";
end
files = chapter4_required_figures();
desc = [
"3-D orbit/scenario view with ground station and selected pass"
"Satellite ground track with station and selected pass"
"Access visibility over the analysis interval"
"Selected-pass elevation angle versus time"
"Selected-pass azimuth angle versus time"
"Selected-pass slant range versus time"
"Selected-pass azimuth tracking rate versus time"
"Selected-pass elevation tracking rate versus time"
"S-band reflector geometry"
"S-band normalized 3-D antenna pattern"
"S-band principal-plane antenna pattern cut"
"S-band received power versus time"
"S-band nominal and adverse link margin versus time"
"S-band cumulative received data versus time"
"X-band reflector geometry"
"X-band normalized 3-D antenna pattern"
"X-band principal-plane antenna pattern cut"
"X-band pointing loss versus angular error"
"X-band Doppler shift versus time"
"X-band received power versus time"
"X-band nominal and adverse link margin versus time"
"X-band cumulative received data versus time"];
func = [
"plotOrbitFigures"
"plotOrbitFigures"
"plotOrbitFigures"
"plotPass"
"plotPass"
"plotPass"
"plotPass"
"plotPass"
"simulate_sband_reflector or analytical fallback"
"simulate_sband_reflector or analytical fallback"
"simulate_sband_reflector or analytical fallback"
"plotLinks"
"plotLinks"
"plotLinks"
"simulate_xband_reflector or analytical fallback"
"simulate_xband_reflector or analytical fallback"
"simulate_xband_reflector or analytical fallback"
"plotLinks"
"plotLinks"
"plotLinks"
"plotLinks"
"plotLinks"];
data = [repmat(orbitType,8,1); repmat("calculated S-band antenna parameters",3,1); repmat("dynamic S-band link budget",3,1); repmat("calculated X-band antenna parameters",3,1); "calculated X-band pointing table"; "selected-pass radial velocity"; repmat("dynamic X-band link budget",3,1)];
type = [repmat(orbitType,8,1); repmat(string(antennaStatus.s),3,1); repmat("analytical link-budget result",3,1); repmat(string(antennaStatus.x),3,1); "analytical link-budget result"; "analytical Doppler result"; repmat("analytical link-budget result",3,1)];
T = table(string(files), desc, func, data, type, 'VariableNames', {'FigureFilename','FigureDescription','GeneratingFunction','DataSource','ResultType'});
end
