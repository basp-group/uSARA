function run_imager(json_filename, NameValueArgs)
% Read configuration parameters defined in an input ``.json`` file & Run imager
% Parameters
% ----------
% json_filename : string
%     Name of the .json configuration file.
% NameValueArgs : 
% Returns
% -------
% None
%

arguments
    json_filename (1,:) {mustBeFile}
    NameValueArgs.srcName (1,:) {mustBeText}
    NameValueArgs.dataFile (1,:) {mustBeFile}
    NameValueArgs.resultPath (1,:) {mustBeText}
    NameValueArgs.algorithm (1,:) {mustBeMember(NameValueArgs.algorithm,{'usara'})}
    NameValueArgs.imPixelSize (1,1) {mustBePositive}
    NameValueArgs.runID (1,1) {mustBeNonnegative, mustBeInteger}=0
end

%% Parsing json file
clc
fid = fopen(json_filename);
raw = fread(fid, inf);
str = char(raw');
fclose(fid);
config = jsondecode(str);

% main input
main = cell2struct(struct2cell(config{1, 1}.main), fieldnames(config{1, 1}.main));
% overwrite fields in main if available
if isfield(NameValueArgs, 'srcName')
    main.srcName = NameValueArgs.srcName;
end
if isfield(NameValueArgs, 'dataFile')
    main.dataFile = NameValueArgs.dataFile;
end
if isfield(NameValueArgs, 'resultPath')
    main.resultPath = NameValueArgs.resultPath;
end
if isfield(NameValueArgs, 'imPixelSize')
    main.imPixelSize = NameValueArgs.imPixelSize;
end
if isfield(NameValueArgs, 'runID')
    main.runID = NameValueArgs.runID;
end
disp(main)

% flag
param_flag = cell2struct(struct2cell(config{2, 1}.flag), fieldnames(config{2, 1}.flag));
disp(param_flag)

% solver
switch main.algorithm
    case 'usara'
        param_solver = cell2struct(struct2cell(config{3, 1}.usara), fieldnames(config{3, 1}.usara));
        param_solver_default = cell2struct(struct2cell(config{3, 1}.usara_default), fieldnames(config{3, 1}.usara_default));
        param_solver = cell2struct([struct2cell(param_solver); struct2cell(param_solver_default)], ...
            [fieldnames(param_solver); fieldnames(param_solver_default)]);
    otherwise
        error("Algorithm %s not found\n", main.algorithm)
end
param_solver.algorithm = main.algorithm;
disp(param_solver)

% full param list
param_general = cell2struct([struct2cell(param_flag); struct2cell(param_solver)], ...
    [fieldnames(param_flag); fieldnames(param_solver)]);
param_general.resultPath = main.resultPath;
param_general.srcName = main.srcName;

% set fields to default value if missing
% set main path for the program
if isfield(main, 'dirProject') && ~isempty(main.dirProject)
    param_general.dirProject = main.dirProject;
else
    param_general.dirProject = [pwd, filesep];
end
% general flag
if ~isfield(param_general, 'flag_imaging')
    param_general.flag_imaging = true;
end
if ~isfield(param_general, 'flag_data_weighting')
    param_general.flag_data_weighting = true;
end
if ~isfield(param_general, 'verbose')
    param_general.verbose = true;
end
% super-resolution factor
if isfield(main, 'superresolution') && ~isempty(main.superresolution)
    param_general.superresolution = main.superresolution; % the ratio between the given max projection base line and the desired one 
else
    param_general.superresolution = 1.0;
end
% compute resources
if isfield(main,'ncpus') && ~isempty(main.ncpus)
    navail=maxNumCompThreads;
    nrequested = maxNumCompThreads(main.ncpus);
    fprintf("\nINFO: Available CPUs: %d. Requested CPUs: %d\n",navail , maxNumCompThreads)
else
    fprintf("\nINFO: Available CPUs: %d.\n", maxNumCompThreads)
end

disp(param_general)

fprintf("\n________________________________________________________________\n")

%% main function
imager(main.dataFile, main.imPixelSize, main.imDimx, main.imDimy, param_general, main.runID);

end