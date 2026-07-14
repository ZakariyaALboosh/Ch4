function package_overleaf_figures(pass, antennaStatus)
%PACKAGE_OVERLEAF_FIGURES Copy Chapter 4 figures into an Overleaf-ready folder.
projectDir = fileparts(mfilename('fullpath'));
addpath(fullfile(projectDir,'src'));
figDir = fullfile(projectDir,'results','figures');
outDir = fullfile(projectDir,'results','overleaf_figures');
if exist(outDir,'dir'), delete(fullfile(outDir,'*.png')); delete(fullfile(outDir,'figure_manifest.csv')); else, mkdir(outDir); end
figs = chapter4_required_figures();
for i = 1:numel(figs)
    copyfile(fullfile(figDir,figs{i}), fullfile(outDir,figs{i}));
end
manual = {'designworkflow.png','fig4_11_sband_block_diagram.png','fig4_18_selected_sband_design.png','fig4_19_xband_block_diagram.png','fig4_28_selected_xband_design.png'};
for i = 1:numel(manual)
    hits = [dir(fullfile(projectDir,manual{i})); dir(fullfile(fileparts(projectDir),manual{i}))];
    if ~isempty(hits)
        copyfile(fullfile(hits(1).folder,hits(1).name), fullfile(outDir,manual{i}));
    else
        fprintf('Manual diagram not found, not fabricated: %s\n', manual{i});
    end
end
if nargin < 1, pass = []; end
if nargin < 2, antennaStatus = []; end
manifest = chapter4_figure_manifest(pass, antennaStatus);
writetable(manifest, fullfile(outDir,'figure_manifest.csv'));
fprintf('Packaged %d generated figure(s) in %s\n', numel(figs), outDir);
end
