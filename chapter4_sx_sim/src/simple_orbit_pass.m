function pass = simple_orbit_pass(cfg)
warningText = "";
try
    pass = realTleOrbitPass(cfg, warningText);
    return
catch ME
    printRealOrbitFailure(ME);
    warningText = "WARNING: TLE orbit propagation failed: " + ...
        string(ME.message) + ...
        ". Using synthetic representative LEO pass. This is not precise orbital propagation.";
    fprintf(2, '%s\n', char(warningText));
end

pass = syntheticOrbitPass(cfg, warningText);
end

function pass = realTleOrbitPass(cfg, warningText)
validateTleConfig(cfg);

startTime = cfg.orbit.startTimeUTC;
if isempty(startTime.TimeZone)
    startTime.TimeZone = 'UTC';
end
stopTime = startTime + hours(cfg.orbit.durationHours);

sc = satelliteScenario(startTime, stopTime, cfg.orbit.sampleTimeSec);

tleFile = writeTemporaryTleFile(cfg.orbit.tleName, cfg.orbit.tleLine1, cfg.orbit.tleLine2);
cleanupTle = onCleanup(@() deleteFileIfPresent(tleFile)); %#ok<NASGU>

sat = satellite(sc, tleFile);
gs = groundStation(sc, cfg.gs.latDeg, cfg.gs.lonDeg, ...
    'Altitude', cfg.gs.altM, ...
    'MinElevationAngle', cfg.gs.minElevationDeg);

[az, el, rng, t] = aer(gs, sat);
az = az(:);
el = el(:);
rng = rng(:);
t = t(:);

[pos, vel] = states(sat, 'CoordinateFrame', 'ecef');
pos = normalizeStateHistory(pos, 'position');
vel = normalizeStateHistory(vel, 'velocity');

N = min([numel(t), numel(az), numel(el), numel(rng), size(pos,2), size(vel,2)]);
if N < 1
    error('simple_orbit_pass:EmptyHistory', ...
        'The TLE propagation returned no common AER/state samples.');
end

t = t(1:N);
az = az(1:N);
el = el(1:N);
rng = rng(1:N);
pos = pos(:,1:N);
vel = vel(:,1:N);

lat = zeros(N,1);
lon = zeros(N,1);
alt = zeros(N,1);
for k = 1:N
    [lat(k), lon(k), alt(k)] = ecefToLlaLocal(pos(1,k), pos(2,k), pos(3,k));
end

mask = isfinite(el) & isfinite(rng) & el >= cfg.gs.minElevationDeg;
if ~any(mask)
    error('simple_orbit_pass:NoVisiblePass', ...
        'No visible satellite pass was found during the selected simulation interval.');
end

d = diff([false; mask; false]);
starts = find(d == 1);
stops = find(d == -1) - 1;
maxEl = zeros(numel(starts),1);
for k = 1:numel(starts)
    maxEl(k) = max(el(starts(k):stops(k)));
end
[bestMaxElevation, selectedPassNumber] = max(maxEl);
idx = starts(selectedPassNumber):stops(selectedPassNumber);

source = "TLE / SGP4";
scenario = makeScenario(t, lat, lon, alt, pos', vel', mask, idx, cfg, source, warningText);
tSec = seconds(t(idx) - t(idx(1)));
pass = finishPass(tSec, t(idx), az(idx), el(idx), rng(idx), cfg, source, warningText, scenario);
pass.usingTLE = true;
pass.tleName = cfg.orbit.tleName;
pass.numberOfPassesFound = numel(starts);
pass.selectedPassNumber = selectedPassNumber;
pass.maxElevationDeg = bestMaxElevation;
pass.aosTime = t(idx(1));
pass.losTime = t(idx(end));

fprintf('Orbit source: %s\n', char(source));
fprintf('Satellite: %s\n', char(string(cfg.orbit.tleName)));
fprintf('Scenario start: %s\n', char(startTime));
fprintf('Scenario stop: %s\n', char(stopTime));
fprintf('Samples: %d\n', N);
fprintf('Maximum elevation: %.3f deg\n', bestMaxElevation);
fprintf('Visible passes found: %d\n', numel(starts));
fprintf('Selected pass: %d\n', selectedPassNumber);
fprintf('AOS: %s\n', char(pass.aosTime));
fprintf('LOS: %s\n', char(pass.losTime));
end

function validateTleConfig(cfg)
requiredOrbitFields = {'startTimeUTC','durationHours','sampleTimeSec','tleName','tleLine1','tleLine2'};
for k = 1:numel(requiredOrbitFields)
    if ~isfield(cfg.orbit, requiredOrbitFields{k})
        error('simple_orbit_pass:MissingConfig', ...
            'Missing cfg.orbit.%s for TLE propagation.', requiredOrbitFields{k});
    end
end
requiredGsFields = {'latDeg','lonDeg','altM','minElevationDeg'};
for k = 1:numel(requiredGsFields)
    if ~isfield(cfg.gs, requiredGsFields{k})
        error('simple_orbit_pass:MissingConfig', ...
            'Missing cfg.gs.%s for TLE propagation.', requiredGsFields{k});
    end
end
end

function tleFile = writeTemporaryTleFile(tleName, tleLine1, tleLine2)
tleFile = [tempname, '.tle'];
fid = fopen(tleFile, 'w');
if fid < 0
    error('simple_orbit_pass:TleFileOpenFailed', ...
        'Unable to create temporary TLE file: %s', tleFile);
end
cleanupClose = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s\n', char(string(tleName)));
fprintf(fid, '%s\n', char(string(tleLine1)));
fprintf(fid, '%s\n', char(string(tleLine2)));
end

function deleteFileIfPresent(fileName)
if exist(fileName, 'file') == 2
    delete(fileName);
end
end

function state = normalizeStateHistory(state, stateName)
state = squeeze(state);
if isempty(state)
    error('simple_orbit_pass:InvalidStateDimensions', ...
        'The %s history returned by states is empty.', stateName);
end
if isvector(state)
    if numel(state) == 3
        state = state(:);
    else
        error('simple_orbit_pass:InvalidStateDimensions', ...
            'The %s history vector has %d elements; expected 3 components by N samples.', ...
            stateName, numel(state));
    end
end
if size(state,1) == 3
    return
elseif size(state,2) == 3
    state = state';
else
    error('simple_orbit_pass:InvalidStateDimensions', ...
        'The %s history must be 3-by-N or N-by-3 after squeeze; received %d-by-%d.', ...
        stateName, size(state,1), size(state,2));
end
end

function printRealOrbitFailure(ME)
fprintf(2, '\nREAL ORBIT PROPAGATION FAILED\n');
fprintf(2, 'Identifier: %s\n', ME.identifier);
fprintf(2, 'Message: %s\n', ME.message);
if ~isempty(ME.stack)
    fprintf(2, 'Location: %s line %d\n', ME.stack(1).name, ME.stack(1).line);
end
end

function pass = syntheticOrbitPass(cfg, warningText)
dt = cfg.orbit.sampleTimeSec;
tSec = (0:dt:cfg.orbit.syntheticDurationSec)';
u = tSec./cfg.orbit.syntheticDurationSec;
el = cfg.gs.minElevationDeg + ...
    (cfg.orbit.syntheticMaxElevationDeg-cfg.gs.minElevationDeg).*sin(pi*u).^0.9;
rngKm = cfg.orbit.syntheticMinRangeKm + ...
    (cfg.orbit.syntheticMaxRangeKm-cfg.orbit.syntheticMinRangeKm).*(abs(2*u-1)).^1.25;
az = cfg.orbit.syntheticAzStartDeg + ...
    (cfg.orbit.syntheticAzEndDeg-cfg.orbit.syntheticAzStartDeg).*(3*u.^2 - 2*u.^3);
time = cfg.orbit.startTimeUTC + seconds(tSec);
lat = cfg.gs.latDeg + 8*sin(2*pi*(u-0.15));
lon = wrapTo180Local(cfg.gs.lonDeg + linspace(-45,45,numel(u))');
alt = repmat(cfg.orbit.altitudeM,numel(u),1);
pos = llaToEcefLocal(lat, lon, alt);
vel = [gradient(pos(:,1),dt), gradient(pos(:,2),dt), gradient(pos(:,3),dt)];
scenario = makeScenario(time, lat, lon, alt, pos, vel, true(size(tSec)), ...
    1:numel(tSec), cfg, "synthetic representative pass", warningText);
pass = finishPass(tSec, time, az, el, rngKm*1000, cfg, ...
    "synthetic representative pass", warningText, scenario);
pass.usingTLE = false;
pass.tleName = "";
pass.numberOfPassesFound = 1;
pass.selectedPassNumber = 1;
pass.maxElevationDeg = max(el);
pass.aosTime = time(1);
pass.losTime = time(end);
end

function pass = finishPass(tSec, time, azDeg, elDeg, rangeM, cfg, source, warningText, scenario)
tSec = tSec(:);
azDeg = azDeg(:);
elDeg = elDeg(:);
rangeM = rangeM(:);
pass.tSec = tSec;
pass.time = time(:);
pass.azDeg = mod(azDeg,360);
pass.elDeg = elDeg;
pass.rangeM = rangeM;
pass.rangeKm = rangeM/1000;
if numel(tSec) >= 2
    dt = median(diff(tSec));
    if isfinite(dt) && dt > 0
        pass.radialVelocityMps = gradient(rangeM, dt);
        pass.azRateDegPerSec = gradient(unwrap(deg2rad(pass.azDeg)), dt)*180/pi;
        pass.elRateDegPerSec = gradient(elDeg, dt);
    else
        pass.radialVelocityMps = zeros(size(rangeM));
        pass.azRateDegPerSec = zeros(size(azDeg));
        pass.elRateDegPerSec = zeros(size(elDeg));
    end
else
    pass.radialVelocityMps = zeros(size(rangeM));
    pass.azRateDegPerSec = zeros(size(azDeg));
    pass.elRateDegPerSec = zeros(size(elDeg));
end
pass.accessMask = isfinite(elDeg) & isfinite(rangeM) & elDeg >= cfg.gs.minElevationDeg;
pass.source = source;
pass.warningText = warningText;
pass.scenario = scenario;
end

function scenario = makeScenario(time, lat, lon, alt, pos, vel, mask, idx, cfg, source, warningText)
scenario.time = time(:);
scenario.latDeg = lat(:);
scenario.lonDeg = lon(:);
scenario.altM = alt(:);
scenario.positionEcefM = pos;
scenario.velocityEcefMps = vel;
scenario.accessMask = mask(:);
scenario.selectedIdx = idx(:);
scenario.source = source;
scenario.warningText = warningText;
scenario.gsLatDeg = cfg.gs.latDeg;
scenario.gsLonDeg = cfg.gs.lonDeg;
scenario.gsAltM = cfg.gs.altM;
scenario.minElevationDeg = cfg.gs.minElevationDeg;
end

function [lat,lon,alt] = ecefToLlaLocal(x,y,z)
a=6378137; e2=6.69437999014e-3; lon=atan2d(y,x); p=hypot(x,y); lat=atan2d(z,p*(1-e2));
for n=1:6, N=a/sqrt(1-e2*sind(lat)^2); alt=p/cosd(lat)-N; lat=atan2d(z,p*(1-e2*N/(N+alt))); end
N=a/sqrt(1-e2*sind(lat)^2); alt=p/cosd(lat)-N;
end
function ecef = llaToEcefLocal(lat, lon, alt)
a=6378137; e2=6.69437999014e-3; N=a./sqrt(1-e2*sind(lat).^2);
x=(N+alt).*cosd(lat).*cosd(lon); y=(N+alt).*cosd(lat).*sind(lon); z=(N*(1-e2)+alt).*sind(lat); ecef=[x(:),y(:),z(:)];
end
function lon = wrapTo180Local(lon), lon = mod(lon+180,360)-180; end
