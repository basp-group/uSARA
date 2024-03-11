function [FINAL_MODEL, FINAL_RESIDUAL] = usara(dirty, measop, adjoint_measop, param_imaging, param_algo)
%% ************************************************************************
% *************************************************************************
% Imaging: unconstraint minimisation
% *************************************************************************

%% Initialization
% general param
ImDims = size(dirty);

%% SARA sparsity op
wvltlevel = 4;
wvltBases = {'db1', 'db2', 'db3', 'db4', 'db5', 'db6', 'db7', 'db8', 'self'};
switch param_algo.waveletDistribution
    case 'basis'
        [Psi, Psit] = wavelet_operators(wvltBases, wvltlevel, ImDims);
        param_wvlt.nBases = numel(wvltBases);
        % parpool
        myparpool = util_set_parpool(min(param_wvlt.nBases, feature('numcores')), 'local');
    case 'facet'
        [Psi,Psit,param_wvlt] = wavelet_operators_faceted(wvltBases, wvltlevel, ImDims, param_algo.nFacetsPerDim);
        % parpool
        myparpool = util_set_parpool(param_wvlt.nFacets, 'local');
end

% just for info: Forward-backward param. struct:  `param_algo.param_prox`:
% `SoftThres` (compulsory), `ObjTolProx`, `MaxItrProx`, `verbose`

%% ALGORITHM
fprintf('\n*************************************************\n')
fprintf('********* STARTING ALGORITHM: uSARA *********')
fprintf('\n*************************************************\n')
% init
MODEL = zeros(ImDims);
MODEL_prevRe = MODEL;
weights = init_weights(param_algo.waveletDistribution,param_wvlt);
itr = 1;
t_total = tic;

% reweighting algorithm
for itr_outer = 1 : param_algo.imMaxOuterItr
    t_outer = tic;

    % forward-backward algorithm
    DualL1 = []; % init.
    for itr_inner = 1 : param_algo.imMaxInnerItr
        t_iter = tic;
        MODEL_prev = MODEL;

        % (forward) gradient step
        t_grad = tic;
        Xhat = MODEL - param_algo.gamma * (adjoint_measop(measop(MODEL)) - dirty);
        t_grad = toc(t_grad);

        % (backward) proximal step
        t_den = tic;
        switch param_algo.waveletDistribution
            case 'basis'
                [MODEL, DualL1] = denoiser_prox_weighted_l1(MODEL, DualL1, Xhat, Psi, Psit, weights, param_algo.param_prox);
            case 'facet'
                [MODEL, DualL1] = denoiser_prox_weighted_l1_faceted(MODEL, DualL1, Xhat, Psi, Psit, weights,...
                    param_algo.param_prox, param_wvlt);
        end
        t_den = toc(t_den);

        %total iteration time
        t_iter = toc(t_iter);

        % print info
        im_relval = sqrt(sum((MODEL - MODEL_prev).^2, 'all') ./ (sum(MODEL.^2, 'all') + 1e-10));
        fprintf("\nCumulative itr: %d,  re-weighting itr: %d,  forward-backward itr: %d: relative variation %g\ntimings: gradient step %f sec, denoising step %f sec, iteration %f sec.\n", ...
            itr, itr_outer, itr_inner, im_relval, t_grad, t_den, t_iter);

        % check inner loop creteria
        if im_relval < param_algo.imVarInnerTol && itr_inner >= param_algo.imMinInnerItr
            break;
        end

        % save intermediate results
        if param_imaging.itrSave > 0 && mod(itr, param_imaging.itrSave) == 0
            fitswrite(single(MODEL), fullfile(param_imaging.resultPath, ...
                ['tmpModel_itr_', num2str(itr), '.fits']))
            RESIDUAL = dirty - adjoint_measop(measop(MODEL));
            fitswrite(single(RESIDUAL), fullfile(param_imaging.resultPath, ...
                ['tmpResidual_itr_', num2str(itr), '.fits']))
        end

        % update iteration counter
        itr = itr + 1;
    end
    t_outer = toc(t_outer);

    fprintf('\n\n************************** Major cycle %d finished **************************\n', itr_outer);
    fprintf('\nINFO: Re-weighting iteration %d completed in %g sec.', itr_outer, t_outer)

    % save intermediate results
    RESIDUAL = dirty - adjoint_measop(measop(MODEL));
    if param_imaging.itrSave > 0
        fitswrite(single(MODEL), fullfile(param_imaging.resultPath, ...
            ['tmpModel_major_iter_', num2str(itr_outer), '.fits']))
        fitswrite(single(RESIDUAL), fullfile(param_imaging.resultPath, ...
            ['tmpResidual_major_iter_', num2str(itr_outer), '.fits']))
    end
    fprintf('\nINFO: The std of the residual dirty image %g', std(RESIDUAL, 0, 'all'))

    % check outer loop creteria
    im_relval = sqrt(sum((MODEL - MODEL_prevRe).^2, 'all') ./ (sum(MODEL.^2, 'all')+1e-10));
    fprintf('\nINFO: Image relative variation of the major cycle %g', im_relval)
    if im_relval < param_algo.imVarOuterTol || ~param_algo.reweighting
        break;
    end

    % re-weighting
    if itr_outer <=  param_algo.imMaxOuterItr - 1
        fprintf('\n\n********************* Reweighting, start major cycle %d *********************\n', itr_outer + 1);
    end
    
    weights = update_weights(MODEL, Psit, param_algo.waveletDistribution, param_algo.waveletNoiseFloor, param_wvlt);

    % update
    MODEL_prevRe = MODEL;
end
t_total = toc(t_total);

fprintf("\n\nImaging finished in %f sec, cumulative number of iterations %d\n\n", t_total, itr);
fprintf('\n**************************************\n')
fprintf('********** END OF ALGORITHM **********')
fprintf('\n**************************************\n')

%% Final variables
FINAL_MODEL = MODEL ;
FINAL_RESIDUAL = dirty - adjoint_measop(measop(MODEL)); 

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function weights = update_weights(MODEL, Psit, waveletDistribution, waveletNoiseFloor, param_wvlt)
switch waveletDistribution
    case 'basis'
        weights = cell(param_wvlt.nBases,1);
        parfor iBasis = 1 : param_wvlt.nBases
            weights{iBasis} = waveletNoiseFloor ./ ...
                (waveletNoiseFloor + abs(Psit{iBasis}(MODEL)));
        end
    case 'facet'
        weights = Composite();
        for iFacet = 1:param_wvlt.nFacets
            sp_y = param_wvlt.slicePos(iFacet).y;
            sp_x = param_wvlt.slicePos(iFacet).x;
            MODELFacet = MODEL(sp_y(1,1):sp_y(1,2),sp_x(1,1):sp_x(1,2));
            weights{iFacet} = waveletNoiseFloor ./ ...
                (waveletNoiseFloor + abs(Psit{iFacet}(MODELFacet)));
        end
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function weights = init_weights(waveletDistribution,param_wvlt)
switch waveletDistribution
    case 'basis'
        weights = cell(param_wvlt.nBases,1);
        parfor iBasis = 1 : param_wvlt.nBases
            weights{iBasis} = 1;
        end
    case 'facet'
        weights = Composite();
        for iFacet = 1:param_wvlt.nFacets
             weights{iFacet} = 1;
        end
end
end
