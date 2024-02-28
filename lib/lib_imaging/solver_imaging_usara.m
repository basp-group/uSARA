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
waveletNoiseFloor = param_algo.waveletNoiseFloor;
% calculate dirty image
DirtyIm = BWOp(DATA);

% prepare SARA sparsity op
[Psi, Psit] = op_p_sp_wlt_basis(param_algo.dict.basis, param_algo.dict.nlevel, param_imaging.imDims(1), param_imaging.imDims(2));
hpc_cluster = util_set_parpool(min(numel(param_algo.dict.basis), feature('numcores')), 'local');

% uSARA specific
% param_prox: lambda, verbose, ObjTolProx, MaxItrProx
param_prox = param_algo.param_prox;
algo_print_name = '  uSARA  ';

%% ALGORITHM
fprintf('\n*************************************************\n')
fprintf('********* STARTING ALGORITHM: %s *********', algo_print_name)
fprintf('\n*************************************************\n')

iter = 1;
tStart_total = tic;
for iter_outer = 1 : param_algo.imMaxOuterItr
    tStart_outer = tic;
    for iter_inner = 1 : param_algo.imMaxInnerItr
        tStart_iter = tic;
        MODEL_prev = MODEL;

        % gradient step
        tStart_grad =tic;
        Xhat = MODEL - param_algo.gamma * (BWOp(FWOp(MODEL)) - DirtyIm);
        t_grad = toc(tStart_grad);

        % denoising step
        tStart_den =tic;
        [MODEL, DualL1] = denoiser_prox_usara(MODEL, DualL1, Xhat, Psi, Psit, weights, param_prox);
        t_den = toc(tStart_den);

        t_iter = toc(tStart_iter);

        % print info
        im_relval = sqrt(sum((MODEL - MODEL_prev).^2, 'all') ./ (sum(MODEL.^2, 'all')+1e-10));
        fprintf("\nIter cumul %d, outer %d, inner %d: relative variation %g, gradient step %f sec, denoising step %f sec, current iteration %f sec.\n", ...
            iter, iter_outer, iter_inner, im_relval, t_grad, t_den, t_iter);

        % check inner creteria
        if im_relval < param_algo.imVarInnerTol && iter_inner >= param_algo.imMinInnerItr
            break;
        end

        % save intermediate results
        if param_imaging.itrSave > 0 && mod(iter, param_imaging.itrSave) == 0
            fitswrite(single(MODEL), fullfile(param_imaging.resultPath, ...
                ['tempModel_iter_', num2str(iter), '.fits']))
            RESIDUAL = DirtyIm - BWOp(FWOp(MODEL));
            fitswrite(single(RESIDUAL), fullfile(param_imaging.resultPath, ...
                ['tempResidual_iter_', num2str(iter), '.fits']))
        end

        % update iteration counter
        iter = iter + 1;
    end
    t_outer = toc(tStart_outer);
    fprintf('\n\n********************* Major cycle %d finished *********************\n', iter_outer);
    fprintf('\nInfo: Major cycle %d took %g sec.', iter_outer, t_outer)

    % save intermediate results
    RESIDUAL = DirtyIm - BWOp(FWOp(MODEL));
    residual_std = std(RESIDUAL, 0, 'all');
    if param_imaging.itrSave > 0
        fitswrite(single(MODEL), fullfile(param_imaging.resultPath, ...
            ['tempModel_major_iter_', num2str(iter), '.fits']))
        fitswrite(single(RESIDUAL), fullfile(param_imaging.resultPath, ...
            ['tempResidual_major_iter_', num2str(iter), '.fits']))
    end
    fprintf('\nINFO: The std of the residual dirty image %g', residual_std)

    % check outer creteria
    im_relval = sqrt(sum((MODEL - MODEL_prevRe).^2, 'all') ./ (sum(MODEL.^2, 'all')+1e-10));
    fprintf('\nInfo: Image relative variation of the major cycle %g', im_relval)
    if im_relval < param_algo.imVarOuterTol || ~param_algo.reweighting
        break;
    end

    % re-weighting
    if iter_outer <=  param_algo.imMaxOuterItr - 1
        fprintf('\n\n********************* Reweighting, start major cycle %d *********************\n', iter_outer + 1);
    end

    parfor basis = 1 : numel(Psit)
        weights{basis} = waveletNoiseFloor ./ (waveletNoiseFloor + abs(Psit{basis}(MODEL)));
    end

    % update
    MODEL_prevRe = MODEL;
end
t_total = toc(tStart_total);

fprintf("\n\nImaging finished in %f sec, cumulative number of iterations %d\n\n", t_total, iter);
fprintf('\n**************************************\n')
fprintf('********** END OF ALGORITHM **********')
fprintf('\n**************************************\n')

%% Final variables
RESULTS.MODEL = MODEL; %reconstructed image
RESULTS.RESIDUAL = DirtyIm - BWOp(FWOp(MODEL)); %reconstructed image

end
