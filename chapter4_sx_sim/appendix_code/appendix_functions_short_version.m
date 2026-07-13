function out = appendix_functions_short_version(action, varargin)
% Compact helper collection for thesis appendix examples. The complete
% implementation is contained in the main chapter4_sx_sim project files.
switch lower(action)
    case 'friis'
        gainDb = varargin{1}; nfDb = varargin{2}; T0 = varargin{3};
        G = 10.^(gainDb(:)/10); F = 10.^(nfDb(:)/10); Ftot = F(1); cg = G(1);
        for k=2:numel(F), Ftot = Ftot + (F(k)-1)/cg; cg = cg*G(k); end
        out.noiseFigureDb = 10*log10(Ftot); out.noiseTemperatureK = T0*(Ftot-1); out.gainDb = 10*log10(prod(G));
    case 'dishgain'
        c=299792458; fc=varargin{1}; D=varargin{2}; eta=varargin{3}; out = 10*log10(eta*(pi*D/(c/fc))^2);
    case 'beamwidth'
        c=299792458; fc=varargin{1}; D=varargin{2}; out = 70*(c/fc)/D;
    case 'doppler'
        c=299792458; radialVelocityMps=varargin{1}; fc=varargin{2}; out = -(radialVelocityMps/c)*fc;
    otherwise
        error('Unknown appendix action.');
end
end
