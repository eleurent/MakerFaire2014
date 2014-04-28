% CLOSEPROJECT Clean up MATLAB path from project folders
%
%
%

% Determine the complete path of project folder
root_dir = fileparts(fileparts(mfilename('fullpath')));

% Remove project directories from path
rmpath(fullfile(root_dir,'data'))
rmpath(fullfile(root_dir,'lib'))
rmpath(fullfile(root_dir,'matlab'))
rmpath(fullfile(root_dir,'matlab','trackingApp'))
rmpath(fullfile(root_dir,'matlab','utilities'))
rmpath(fullfile(root_dir,'model'))
rmpath(fullfile(root_dir,'work'))

% Clean up workspace
clear root_dir

