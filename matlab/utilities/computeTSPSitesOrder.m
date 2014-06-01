% get the start position
loadRobotParameters;

% Load SitesPosition (using the old Sites.m file that will be written
% as result of this function execution)
Sites;

% GA TSP Algorithm
pop_size = 300;
mutation_rate = 300;
crossing_rate = 300;
iter_number = 300;
speed_straight = 1;
SitesPositions = ga_tsp(SitesPositions, pop_size, mutation_rate, crossing_rate, iter_number, speed_straight, startPos);

% Save data
% Get current date
[year,month,day,hour,minute,second] = datevec(now);
filename = which('Sites.m');

% Make a copy of the previous target definition file
oldfileName = sprintf('%s_%4d_%02d_%02d_%02dH%02dM%06.3fs.bak',...
    filename ,year,month,day,hour,minute,second );
movefile(filename,oldfileName,'f');

% Open new file for writing
fid = fopen(filename,'wt');
try %#ok<TRYNC>
    
    % Set file header (to write that file is autogenerated and print the
    % date)
    fprintf(fid,'%% File Autogenerate by function %s\n',mfilename);
    fprintf(fid,'%% Date %s\n',datestr(now,'dddd dd mmmm yyyy HH:MM:SS'));
    
    % Write vector SitesPositions with new values
    fprintf(fid,'SitesPositions = single([...\n');
    fprintf(fid,'\t%4.0f,%4.0f;...\n',SitesPositions');
    fprintf(fid,'\t]);');
end

% Close file
fclose(fid);