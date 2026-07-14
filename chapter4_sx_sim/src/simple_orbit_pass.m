function pass = simple_orbit_pass(cfg)

warningText = "";

try
    % More reliable than exist(...,'file') for MATLAB class constructors.
    if isempty(which('satelliteScenario'))
        error('satelliteScenario constructor was not found on the MATLAB path.');
    end

    startTime = cfg.orbit.startTimeUTC;
    stopTime = startTime + hours(cfg.orbit.durationHours);

    sc = satelliteScenario( ...
        startTime, ...
        stopTime, ...
        cfg.orbit.sampleTimeSec);

    Re = 6378137;
    semiMajorAxisM = Re + cfg.orbit.altitudeM;

    sat = satellite( ...
        sc, ...
        semiMajorAxisM, ...
        0, ...
        cfg.orbit.inclinationDeg, ...
        cfg.orbit.raanDeg, ...
        cfg.orbit.argumentOfPerigeeDeg, ...
        cfg.orbit.trueAnomalyDeg, ...
        'OrbitPropagator', 'two-body-keplerian');

    gs = groundStation( ...
        sc, ...
        cfg.gs.latDeg, ...
        cfg.gs.lonDeg, ...
        'Altitude', cfg.gs.altM, ...
        'MinElevationAngle', cfg.gs.minElevationDeg);

    % Request the complete scenario history directly.
    [az, el, rng, t] = aer(gs, sat);

    az = az(:);
    el = el(:);
    rng = rng(:);
    t = t(:);

    mask = el >= cfg.gs.minElevationDeg & isfinite(rng);

    if ~any(mask)
        error('No visible pass was found during the configured scenario period.');
    end

    % Find every continuous visible section.
    transitions = diff([false; mask; false]);
    starts = find(transitions == 1);
    stops = find(transitions == -1) - 1;

    % Select the pass having the highest maximum elevation.
    maximumElevations = arrayfun( ...
        @(firstIndex,lastIndex) max(el(firstIndex:lastIndex)), ...
        starts, ...
        stops);

    [~, selectedPass] = max(maximumElevations);
    idx = starts(selectedPass):stops(selectedPass);

    tSec = seconds(t(idx) - t(idx(1)));

    pass = finishPass( ...
        tSec, ...
        t(idx), ...
        az(idx), ...
        el(idx), ...
        rng(idx), ...
        cfg, ...
        "satelliteScenario", ...
        warningText);

    return

catch ME
    fprintf(2, '\nSatellite scenario branch failed:\n%s\n\n', ...
        getReport(ME, 'extended', 'hyperlinks', 'off'));

    warningText = ...
        "WARNING: satelliteScenario unavailable or unusable. " + ...
        "Using synthetic representative LEO pass. " + ...
        "Do not present this result as precise orbital propagation.";

    fprintf('%s\n', warningText);
end
dt = cfg.orbit.sampleTimeSec; tSec = (0:dt:cfg.orbit.syntheticDurationSec)'; u = tSec./cfg.orbit.syntheticDurationSec;
el = cfg.gs.minElevationDeg + (cfg.orbit.syntheticMaxElevationDeg-cfg.gs.minElevationDeg).*sin(pi*u).^0.9;
rngKm = cfg.orbit.syntheticMinRangeKm + (cfg.orbit.syntheticMaxRangeKm-cfg.orbit.syntheticMinRangeKm).*(abs(2*u-1)).^1.25;
az = cfg.orbit.syntheticAzStartDeg + (cfg.orbit.syntheticAzEndDeg-cfg.orbit.syntheticAzStartDeg).*(3*u.^2 - 2*u.^3);
time = cfg.orbit.startTimeUTC + seconds(tSec);
pass = finishPass(tSec, time, az, el, rngKm*1000, cfg, "synthetic representative pass", warningText);
end
function pass = finishPass(tSec, time, azDeg, elDeg, rangeM, cfg, source, warningText)
tSec = tSec(:); azDeg=azDeg(:); elDeg=elDeg(:); rangeM=rangeM(:); dt = median(diff(tSec));
pass.tSec=tSec; pass.time=time(:); pass.azDeg=mod(azDeg,360); pass.elDeg=elDeg; pass.rangeM=rangeM; pass.rangeKm=rangeM/1000;
pass.radialVelocityMps = gradient(rangeM, dt); pass.azRateDegPerSec = gradient(unwrap(deg2rad(pass.azDeg)), dt)*180/pi; pass.elRateDegPerSec = gradient(elDeg, dt);
pass.accessMask = elDeg >= cfg.gs.minElevationDeg; pass.source = source; pass.warningText = warningText;
end
