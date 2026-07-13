function lossDb = compute_pointing_loss(errorDeg, hpbwDeg)
validateattributes(errorDeg, {'numeric'}, {'nonnegative','finite'});
validateattributes(hpbwDeg, {'numeric'}, {'positive','finite'});
lossDb = 12 .* (errorDeg ./ hpbwDeg).^2;
end
