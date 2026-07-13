function hpbwDeg = compute_beamwidth(fcHz, diameterM)
validateattributes(fcHz, {'numeric'}, {'positive','finite'});
validateattributes(diameterM, {'numeric'}, {'positive','finite'});
c = 299792458; lambda = c ./ fcHz;
hpbwDeg = 70 .* lambda ./ diameterM;
end
