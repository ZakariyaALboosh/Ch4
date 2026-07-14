function validate_chapter4_outputs()
%VALIDATE_CHAPTER4_OUTPUTS Check required MATLAB-generated Chapter 4 figures.
projectDir = fileparts(mfilename('fullpath'));
addpath(fullfile(projectDir,'src'));
figDir = fullfile(projectDir,'results','figures');
figs = chapter4_required_figures();
missing = {};
fprintf('Validating Chapter 4 MATLAB figure outputs in %s\n', figDir);
for i = 1:numel(figs)
    p = fullfile(figDir, figs{i});
    d = dir(p);
    if isempty(d) || d.bytes == 0
        fprintf('FAIL  %s\n', figs{i});
        missing{end+1,1} = figs{i}; %#ok<AGROW>
    else
        fprintf('OK    %s (%d bytes)\n', figs{i}, d.bytes);
    end
end
if ~isempty(missing)
    error('validate_chapter4_outputs:MissingFigures','%d required Chapter 4 figure(s) are missing or empty.', numel(missing));
end
fprintf('Validation passed: all %d required MATLAB-generated Chapter 4 figures exist and are non-empty.\n', numel(figs));
end
