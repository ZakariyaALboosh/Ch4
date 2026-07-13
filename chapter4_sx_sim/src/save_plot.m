function save_plot(figHandle, filenameBase, outputConfig)
filenameBase = string(filenameBase);
if contains(filenameBase,'.'), error('save_plot:ExtensionNotAllowed','filenameBase must not contain an extension.'); end
set(figHandle,'Color','w'); axs = findall(figHandle,'Type','axes');
for k=1:numel(axs), grid(axs(k),'on'); set(axs(k),'FontSize',11); end
parentDir = fileparts(filenameBase); if ~isempty(parentDir) && ~exist(parentDir,'dir'), mkdir(parentDir); end
if outputConfig.savePng
    out = filenameBase + ".png";
    if exist('exportgraphics','file'), exportgraphics(figHandle,out,'Resolution',200,'BackgroundColor','white'); else, print(figHandle,out,'-dpng','-r200'); end
end
if outputConfig.savePdf
    out = filenameBase + ".pdf";
    if exist('exportgraphics','file'), exportgraphics(figHandle,out,'ContentType','vector','BackgroundColor','white'); else, print(figHandle,out,'-dpdf','-bestfit'); end
end
close(figHandle);
end
