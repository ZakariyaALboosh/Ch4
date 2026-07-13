function gainDbi = compute_dish_gain(fcHz, diameterM, efficiency)
validateattributes(fcHz, {'numeric'}, {'positive','finite'});
validateattributes(diameterM, {'numeric'}, {'positive','finite'});
validateattributes(efficiency, {'numeric'}, {'positive','finite','<=',1});
c = 299792458; lambda = c ./ fcHz;
gainLinear = efficiency .* (pi .* diameterM ./ lambda).^2;
gainDbi = 10 .* log10(gainLinear);
end
