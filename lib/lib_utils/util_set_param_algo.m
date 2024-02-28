function param_algo = util_set_param_algo(param_general, heuristic, peak_est, numMeas)

    % algorithm
    param_algo.algorithm = param_general.algorithm;
    
    % max number of inner iterations
    if ~isfield(param_general,'imMaxInnerItr') || ~isscalar(param_general.imMaxInnerItr)
        param_algo.imMaxInnerItr = 2000;
    else
        param_algo.imMaxInnerItr = param_general.imMaxInnerItr;
    end
    % max number of outter iterations
    if ~isfield(param_general,'imMaxOuterItr') || ~isscalar(param_general.imMaxOuterItr)
        param_algo.imMaxOuterItr = 10;
    else
        param_algo.imMaxOuterItr = param_general.imMaxOuterItr;
    end
    % min number of inner iterations
    if ~isfield(param_general,'imMinInnerItr') || ~isscalar(param_general.imMinInnerItr)
        param_algo.imMinInnerItr = 10;
    else
        param_algo.imMinInnerItr = param_general.imMinInnerItr;
    end
    % image variation tolerance inner loop
    if ~isfield(param_general,'imVarInnerTol') || ~isscalar(param_general.imVarInnerTol) || param_general.imVarInnerTol<=0
        param_algo.imVarInnerTol = 1e-4;
    else
        param_algo.imVarInnerTol = param_general.imVarInnerTol;
    end
    % image variation tolerance outer loop
    if ~isfield(param_general,'imVarOuterTol') || ~isscalar(param_general.imVarOuterTol) || param_general.imVarOuterTol<=0
        param_algo.imVarOuterTol = 1e-4;
    else
        param_algo.imVarOuterTol = param_general.imVarOuterTol;
    end
    % heuristic noise scale
    if ~isfield(param_general,'heuNoiseScale') || ~isscalar(param_general.heuNoiseScale) || param_general.heuNoiseScale<=0
        param_algo.heuNoiseScale = 1.0;
    else
        param_algo.heuNoiseScale = param_general.heuNoiseScale;
    end
    % heuristic noise level
    param_algo.heuristic = heuristic;
    if param_algo.heuNoiseScale ~= 1.0
        param_algo.heuristic = param_algo.heuristic * param_algo.heuNoiseScale;
        fprintf('\nINFO: heuristic noise level after scaling: %g', param_algo.heuristic);
    end

    % dictionary
    dict.nlevel = 4;
    dict.basis = {'db1', 'db2', 'db3', 'db4', 'db5', 'db6', 'db7', 'db8', 'self'};
    dict.filter_length = [2, 4, 6, 8, 10, 12, 14, 16, 0];
    param_algo.dict = dict;

    % step size
    param_algo.gamma = 1.98 / param_general.measOpNorm;
    fprintf('\nINFO: step size (gamma): %g.', param_algo.gamma)
    
    % heuristic parameters
    param_algo.lambda = param_algo.heuristic / 3.0 / param_algo.gamma; % 9 wavelet bases
    param_algo.waveletNoiseFloor = heuristic / 3.0; % decouple from noise scaling factor
    fprintf('\nINFO: regularisation param (lambda): %g.', param_algo.lambda)

    % dual-FB parameters
    param_prox.ObjTolProx = 1e-4;
    param_prox.MaxItrProx = 200;
    param_prox.gamma_lambda = param_algo.heuristic / 3.0;
    fprintf('\nINFO: soft-thresholding param (gamma x lambda): %g.', param_prox.gamma_lambda)
    param_algo.param_prox = param_prox;

    % reweighting
    if ~isfield(param_general,'reweighting')
        param_algo.reweighting = true;
    else
        param_algo.reweighting = param_general.reweighting;
    end
end