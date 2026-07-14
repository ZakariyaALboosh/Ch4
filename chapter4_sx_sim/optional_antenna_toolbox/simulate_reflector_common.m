function resultType = simulate_reflector_common(band, figuresDir, prefix, feedType, output)
resultType = "analytical approximation";
baseNames = antennaFigureNames(prefix);
try
    if license('test','Antenna_Toolbox') && exist('reflector','file') == 2
        ant = reflector;
        if strcmp(feedType,'helix'), ant.Exciter = helix; else, ant.Exciter = horn; end
        ant.Radius = band.selectedDishDiameterM/2;
        fig=figure('Visible',output.figureVisible); show(ant); title(sprintf('%s reflector geometry (%s feed)', band.name, feedType)); save_plot(fig,fullfile(figuresDir,erase(baseNames{1},'.png')),output);
        fig=figure('Visible',output.figureVisible); pattern(ant,band.fcHz); title(sprintf('%s Antenna Toolbox 3-D pattern', band.name)); save_plot(fig,fullfile(figuresDir,erase(baseNames{2},'.png')),output);
        fig=figure('Visible',output.figureVisible); patternElevation(ant,band.fcHz); title(sprintf('%s Antenna Toolbox elevation cut', band.name)); save_plot(fig,fullfile(figuresDir,erase(baseNames{3},'.png')),output);
        resultType = "Antenna Toolbox"; return
    end
catch ME
    fprintf('%s Antenna Toolbox reflector failed: %s\n', band.name, ME.message);
end
fprintf('%s antenna figures use analytical approximation fallback.\n', band.name);
exportAnalyticalAntenna(band, figuresDir, prefix, feedType, output);
end

function names = antennaFigureNames(prefix)
if strcmp(prefix,'sband')
    names = {'fig4_12_sband_reflector_geometry.png','fig4_13_sband_3d_pattern.png','fig4_14_sband_pattern_cut.png'};
else
    names = {'fig4_20_xband_reflector_geometry.png','fig4_21_xband_3d_pattern.png','fig4_22_xband_pattern_cut.png'};
end
end

function exportAnalyticalAntenna(band, figuresDir, prefix, feedType, output)
names = antennaFigureNames(prefix); D=band.selectedDishDiameterM; hp=compute_beamwidth(band.fcHz,D); g=compute_dish_gain(band.fcHz,D,band.dishEfficiency);
fig=figure('Visible',output.figureVisible); th=linspace(0,2*pi,200); plot((D/2)*cos(th),(D/2)*sin(th),'LineWidth',2); axis equal; grid on; xlabel('x (m)'); ylabel('y (m)'); title(sprintf('%s %.2f m reflector geometry schematic',band.name,D)); text(-D/2, -0.7*D, sprintf('Feed: %s\nGain %.1f dBi, HPBW %.2f deg\nAnalytical approximation -- not a full-wave EM simulation',feedType,g,hp),'FontWeight','bold'); save_plot(fig,fullfile(figuresDir,erase(names{1},'.png')),output);
[u,v]=meshgrid(linspace(-3*hp,3*hp,91)); r=sqrt(u.^2+v.^2); p=-12*(r./hp).^2; p(p<-35)=-35; [x,y,z]=sph2cart(atan2d(v,u)*pi/180,(90-r)*pi/180,10.^((p+35)/35)); fig=figure('Visible',output.figureVisible); surf(x,y,z,p,'EdgeColor','none'); colorbar; axis equal; title(sprintf('%s normalized 3-D beam approximation',band.name)); xlabel('x'); ylabel('y'); zlabel('Normalized radius'); text(0,0,max(z(:))*1.05,'Analytical approximation -- not a full-wave EM simulation','FontWeight','bold'); save_plot(fig,fullfile(figuresDir,erase(names{2},'.png')),output);
ang=linspace(-3*hp,3*hp,401); pat=-12*(ang./hp).^2; pat(pat<-35)=-35; fig=figure('Visible',output.figureVisible); plot(ang,pat,'LineWidth',1.5); yline(-3,'--','-3 dB'); xlabel('Off-boresight angle (deg)'); ylabel('Normalized gain (dB)'); title(sprintf('%s principal-plane analytical pattern cut',band.name)); text(min(ang)+0.05*range(ang),-30,'Analytical approximation -- not a full-wave EM simulation','FontWeight','bold'); save_plot(fig,fullfile(figuresDir,erase(names{3},'.png')),output);
end
