function pass = simple_orbit_pass(cfg)
warningText = "";
try
    if exist('satelliteScenario','file') ~= 2, error('satelliteScenario unavailable'); end
    startTime = cfg.orbit.startTimeUTC; stopTime = startTime + hours(cfg.orbit.durationHours);
    sc = satelliteScenario(startTime, stopTime, cfg.orbit.sampleTimeSec);
    Re = 6378137; a = Re + cfg.orbit.altitudeM;
    sat = satellite(sc, a, 0, cfg.orbit.inclinationDeg, cfg.orbit.raanDeg, cfg.orbit.argumentOfPerigeeDeg, cfg.orbit.trueAnomalyDeg, 'OrbitPropagator','two-body-keplerian');
    gs = groundStation(sc, cfg.gs.latDeg, cfg.gs.lonDeg, 'Altitude', cfg.gs.altM, 'MinElevationAngle', cfg.gs.minElevationDeg);
    t = (startTime:seconds(cfg.orbit.sampleTimeSec):stopTime)';
    [az,el,rng] = aer(gs, sat, t);
    [pos,vel] = states(sat,t,'CoordinateFrame','ecef');
    lat = zeros(numel(t),1); lon = lat; alt = lat;
    for k = 1:numel(t)
        [lat(k),lon(k),alt(k)] = ecefToLlaLocal(pos(1,k),pos(2,k),pos(3,k));
    end
    az=az(:); el=el(:); rng=rng(:); mask = el >= cfg.gs.minElevationDeg & isfinite(rng);
    if ~any(mask), error('No visible pass'); end
    d = diff([false; mask; false]); starts=find(d==1); stops=find(d==-1)-1; maxEl=arrayfun(@(a,b) max(el(a:b)), starts, stops); [~,i]=max(maxEl); idx=starts(i):stops(i);
    scenario = makeScenario(t, lat, lon, alt, pos', vel', mask, idx, cfg, "satelliteScenario", warningText);
    pass = finishPass(seconds(t(idx)-t(idx(1))), t(idx), az(idx), el(idx), rng(idx), cfg, "satelliteScenario", warningText, scenario); return
catch ME
    warningText = "WARNING: satelliteScenario unavailable or unusable. Using synthetic representative LEO pass. Do not present this result as precise orbital propagation.";
    fprintf('%s (%s)\n', warningText, ME.message);
end
dt = cfg.orbit.sampleTimeSec; tSec = (0:dt:cfg.orbit.syntheticDurationSec)'; u = tSec./cfg.orbit.syntheticDurationSec;
el = cfg.gs.minElevationDeg + (cfg.orbit.syntheticMaxElevationDeg-cfg.gs.minElevationDeg).*sin(pi*u).^0.9;
rngKm = cfg.orbit.syntheticMinRangeKm + (cfg.orbit.syntheticMaxRangeKm-cfg.orbit.syntheticMinRangeKm).*(abs(2*u-1)).^1.25;
az = cfg.orbit.syntheticAzStartDeg + (cfg.orbit.syntheticAzEndDeg-cfg.orbit.syntheticAzStartDeg).*(3*u.^2 - 2*u.^3);
time = cfg.orbit.startTimeUTC + seconds(tSec);
lat = cfg.gs.latDeg + 8*sin(2*pi*(u-0.15)); lon = wrapTo180Local(cfg.gs.lonDeg + linspace(-45,45,numel(u))'); alt = repmat(cfg.orbit.altitudeM,numel(u),1);
pos = llaToEcefLocal(lat, lon, alt); vel = [gradient(pos(:,1),dt), gradient(pos(:,2),dt), gradient(pos(:,3),dt)];
scenario = makeScenario(time, lat, lon, alt, pos, vel, true(size(tSec)), 1:numel(tSec), cfg, "synthetic representative pass", warningText);
pass = finishPass(tSec, time, az, el, rngKm*1000, cfg, "synthetic representative pass", warningText, scenario);
end

function pass = finishPass(tSec, time, azDeg, elDeg, rangeM, cfg, source, warningText, scenario)
tSec = tSec(:); azDeg=azDeg(:); elDeg=elDeg(:); rangeM=rangeM(:); dt = median(diff(tSec));
pass.tSec=tSec; pass.time=time(:); pass.azDeg=mod(azDeg,360); pass.elDeg=elDeg; pass.rangeM=rangeM; pass.rangeKm=rangeM/1000;
pass.radialVelocityMps = gradient(rangeM, dt); pass.azRateDegPerSec = gradient(unwrap(deg2rad(pass.azDeg)), dt)*180/pi; pass.elRateDegPerSec = gradient(elDeg, dt);
pass.accessMask = elDeg >= cfg.gs.minElevationDeg; pass.source = source; pass.warningText = warningText; pass.scenario = scenario;
end

function scenario = makeScenario(time, lat, lon, alt, pos, vel, mask, idx, cfg, source, warningText)
scenario.time = time(:); scenario.latDeg = lat(:); scenario.lonDeg = lon(:); scenario.altM = alt(:); scenario.positionEcefM = pos; scenario.velocityEcefMps = vel;
scenario.accessMask = mask(:); scenario.selectedIdx = idx(:); scenario.source = source; scenario.warningText = warningText;
scenario.gsLatDeg = cfg.gs.latDeg; scenario.gsLonDeg = cfg.gs.lonDeg; scenario.gsAltM = cfg.gs.altM; scenario.minElevationDeg = cfg.gs.minElevationDeg;
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
