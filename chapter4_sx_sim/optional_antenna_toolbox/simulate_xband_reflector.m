function resultType = simulate_xband_reflector(cfg, figuresDir)
%SIMULATE_XBAND_REFLECTOR Export X-band antenna figures with fallback.
resultType = simulate_reflector_common(cfg.x, figuresDir, 'xband', 'horn', cfg.output);
end
