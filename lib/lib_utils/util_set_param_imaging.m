function param_imaging = util_set_param_imaging(param_general,resultPath, srcname, heuRegParamScale)
    % set subfolder name
    subFolerName = [srcname,'-usara_', '_heuRegScale_', num2str(heuRegParamScale)];
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
   
    % imaging & verbose flag
    param_imaging.flag_imaging = param_general.flag_imaging;
    param_imaging.verbose = param_general.verbose;

    % groundtruth image
    if isfield(param_general,'groundtruth')
        param_imaging.groundtruth = param_general.groundtruth;
    end

end