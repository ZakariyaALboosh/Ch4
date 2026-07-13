function simulate_xband_reflector(cfg, figuresDir)
try
    if ~license('test','Antenna_Toolbox') || exist('reflector','file') ~= 2
        fprintf('Antenna Toolbox unavailable. Skipping full reflector radiation pattern simulation.\n'); return;
    end
    ant = reflector; ant.Exciter = horn; ant.Radius = cfg.x.selectedDishDiameterM/2;
    saveAntFigures(ant,cfg.x.fcHz,figuresDir,'xband');
catch ME
    fprintf('Antenna Toolbox reflector limitation: %s. Analytical gain/beamwidth remains the core result.\n',ME.message);
end
end
function saveAntFigures(ant,fc,dir,prefix)
fig=figure('Visible','off'); show(ant); exportgraphics(fig,fullfile(dir,[prefix '_reflector_geometry.png'])); close(fig);
fig=figure('Visible','off'); pattern(ant,fc); exportgraphics(fig,fullfile(dir,[prefix '_reflector_pattern_3d.png'])); close(fig);
fig=figure('Visible','off'); patternAzimuth(ant,fc); exportgraphics(fig,fullfile(dir,[prefix '_reflector_az_cut.png'])); close(fig);
fig=figure('Visible','off'); patternElevation(ant,fc); exportgraphics(fig,fullfile(dir,[prefix '_reflector_el_cut.png'])); close(fig);
end
