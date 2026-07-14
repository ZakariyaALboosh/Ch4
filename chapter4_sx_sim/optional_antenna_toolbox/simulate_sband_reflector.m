function resultType = simulate_sband_reflector(cfg, figuresDir)
%SIMULATE_SBAND_REFLECTOR Export S-band antenna figures with fallback.
resultType = simulate_reflector_common(cfg.s, figuresDir, 'sband', 'helix', cfg.output);
end
