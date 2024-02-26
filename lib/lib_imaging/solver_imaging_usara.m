function RESULTS = solver_imaging_usara(DATA, FWOp, BWOp, param_imaging, param_algo)
%% ************************************************************************
% *************************************************************************
% Imaging: forward-backward algorithm
% *************************************************************************

%% Initialization
MODEL = zeros(param_imaging.imDims);
MODEL_prevRe = MODEL;
DualL1 = [];
iter_inner = 1;
iter_outer = 1;
weights = cell(numel((param_algo.dict.basis)) , 1);
for i = 1 : numel(weights)
    weights{i} = 1.0;
end
noise_floor = param_algo.heuristic;
objective_prev = -1;
% calculate dirty image
DirtyIm = BWOp(DATA);

% prepare SARA sparsity op
[Psi, Psit] = op_p_sp_wlt_basis(param_algo.dict.basis, param_algo.dict.nlevel, param_imaging.imDims(1), param_imaging.imDims(2));
hpc_cluster = util_set_parpool(min(numel(param_algo.dict.basis), feature('numcores')), 'local');

% uSARA specific
% param_prox: lambda, verbose, ObjTolProx, MaxItrProx
param_prox = param_algo.param_prox;
algo_print_name = '  USARA  ';

%% ALGORITHM
fprintf('\n*************************************************\n')
fprintf('********* STARTING ALGORITHM: %s *********', algo_print_name)
fprintf('\n*************************************************\n')

tStart_total = tic;
while 1
    tStart_iter = tic;
    MODEL_prev = MODEL;

    % gradient step
    tStart_grad =tic;
    Xhat = MODEL - param_algo.gamma * (BWOp(FWOp(MODEL)) - DirtyIm);
    t_grad = toc(tStart_grad);

    % denoising step
    tStart_den =tic;
    [MODEL, DualL1, objective_prev] = denoiser_prox_usara(MODEL, DualL1, Xhat, Psi, Psit, weights, objective_prev, param_prox);
    t_den = toc(tStart_den);

    t_iter = toc(tStart_iter);

    % print info
    im_relval = sqrt(sum((MODEL - MODEL_prev).^2, 'all') ./ (sum(MODEL.^2, 'all')+1e-10));
    fprintf("\nIter total %d, outer %d, inner %d: relative variation %g, gradient step %f sec, denoising step %f sec, current iteration %f sec.\n", ...
        iter, iter_outer, iter_inner, im_relval, t_grad, t_den, t_iter);

    % stopping creteria
    % check inner creteria
    if (im_relval < param_algo.imVarInnerTol && iter_inner >= param_algo.imMinInnerItr) || iter_inner > param_algo.imMaxInnerItr
        % check outer creteria
        im_relval = sqrt(sum((MODEL - MODEL_prevRe).^2, 'all') ./ (sum(MODEL.^2, 'all')+1e-10));
        if im_relval < param_algo.imVarOuterTol || iter_outer > param_algo.imMaxOuterItr || ~param_algo.reweighting
            fprintf('\n\nRelative variation outer %g\n\n', im_relval);
            break;
        end

        % re-weighting
        fprintf('\n\n******* Reweighting, relative variation outer %g *******\n\n', im_relval);
        parfor basis = 1 : numel(Psit)
            weights{basis} = noise_floor ./ (noise_floor + abs(Psit{basis}(MODEL)));
        end

        % update
        MODEL_prevRe = MODEL;
        iter_outer = iter_outer + 1;
        iter_inner = 1;
    else
        iter_inner = iter_inner + 1;
    end

    % save intermediate results
    if param_imaging.itrSave > 0 && mod(iter, param_imaging.itrSave) == 0
        fitswrite(MODEL, fullfile(param_imaging.resultPath, ...
            ['tempModel_iter_', num2str(iter), '.fits']))
        RESIDUAL = DirtyIm - BWOp(FWOp(MODEL));
        fitswrite(RESIDUAL, fullfile(param_imaging.resultPath, ...
            ['tempResidual_iter_', num2str(iter), '.fits']))
    end
    
    iter = iter + 1;
end
t_total = toc(tStart_total);

fprintf("\n\nImaging finished in %f sec, total number of iterations %d\n\n", t_total, iter);
fprintf('\n**************************************\n')
fprintf('********** END OF ALGORITHM **********')
fprintf('\n**************************************\n')

%% Final variables
RESULTS.MODEL = MODEL; %reconstructed image
RESULTS.RESIDUAL = DirtyIm - BWOp(FWOp(MODEL)); %reconstructed image

end
