function param_imaging = util_set_param_imaging(param_general, param_algo, imDims, pathData, runID)

    % path for saving results
    % set result path
    if ~isfield(param_general, 'resultPath') || isempty(param_general.resultPath)
        resultPath = fullfile(param_general.dirProject, 'results');
    else
        resultPath = param_general.resultPath;
    end
    if ~exist(resultPath, 'dir') 
        mkdir(resultPath)
    end
    % src name
    if isfield(param_general, 'srcName') && ~isempty(param_general.srcName)
        srcname = param_general.srcName;
    else
        [~, srcname, ~] = fileparts(pathData);
    end
    % set subfolder name
    subFolerName = [srcname, '_uSARA_ID_',num2str(runID), ...
                '_heuRegScale_', num2str(param_algo.heuRegParamScale)];
    % set full path
    param_imaging.resultPath = fullfile(resultPath, subFolerName);
    if ~exist(param_imaging.resultPath, 'dir') 
        mkdir(param_imaging.resultPath)
    end

    fprintf('\nINFO: results will be saved in ''%s''', param_imaging.resultPath);
    
    % interval for saveing intermediate results
    if ~isfield(param_general,'itrSave') || ~isscalar(param_general.itrSave)
        param_imaging.itrSave = 500;
    else
        param_imaging.itrSave = floor(param_general.itrSave);
    end
    
    % set image dimension
    param_imaging.imDims = imDims;

    % imaging & verbose flag
    param_imaging.flag_imaging = param_general.flag_imaging;
    param_imaging.verbose = param_general.verbose;

    % groundtruth image
    param_imaging.groundtruth = param_general.groundtruth;

    % run ID
    param_imaging.runID = runID;

end