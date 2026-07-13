function export_table_csv(tableValue, outputPath)
if ~istable(tableValue), error('export_table_csv:InputNotTable','Input must be a MATLAB table.'); end
parentDir = fileparts(outputPath); if ~isempty(parentDir) && ~exist(parentDir,'dir'), mkdir(parentDir); end
try
    writetable(tableValue, outputPath);
catch ME
    error('export_table_csv:WriteFailed','Failed to write CSV %s: %s', outputPath, ME.message);
end
end
