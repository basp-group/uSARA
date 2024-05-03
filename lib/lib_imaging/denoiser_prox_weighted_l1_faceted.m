function [MODEL, DualL1] = denoiser_prox_weighted_l1_faceted(MODEL, DualL1, Y, Psi, Psit, weightsCmpst, param, param_facet)
% PROJ_L1 - Proximal operator with L1 norm
% featuring a faceted wavelet transform
% Parameters
% ----------
% MODEL : 2D matrix
%     model estimate - primal variable
% DualL1 : vector (composite)
%     dual variable (in the wavelet domain)
% Y : 2D matrix
%     point at which the prox. is computed
% Psi: cell of function handle
%     direct operator: faceted wavelet tranform  (9 bases, including identity)
% Psit: cell of function handle
%     adjoint operator: faceted inverse wavelet transform
% weights: vector (composite)
%     weights involved in the re-weighting algorithm
% param: struct

%% Optional input arguments -- >  to be updated
if ~isfield(param, 'verbose'), param.verbose = true; end
if ~isfield(param, 'ObjTolProx'), param.ObjTolProx = 1e-4; end
if ~isfield(param, 'MaxItrProx'), param.MaxItrProx = 200; end

%%  Initializations
% soft thresholding param
SoftThres = param.SoftThres;

% stopping crit.
ObjTolProx = param.ObjTolProx;
MaxItrProx = param.MaxItrProx;

% Useful functions
Id_proxL1 = @(z, T) z - (sign(z) .* max(abs(z)-T, 0));

% faceting params
nFacets = param_facet.nFacets;
sp = param_facet.slicePos;

% init composite vars
spmd (nFacets)
    if spmdIndex == 1
        YCmpst = Y;
        ModelCmpst = MODEL;
    end
end

% init dual variable
if isempty(DualL1)
    spmd (nFacets)
        if spmdIndex == 1
            % split image to slices and send them to workers
            for iFacet = 2:nFacets
                ModelSlice2Send = ModelCmpst(sp(iFacet).y(1, 1):sp(iFacet).y(1, 2), sp(iFacet).x(1, 1):sp(iFacet).x(1, 2));
                spmdSend(ModelSlice2Send, iFacet, iFacet);
            end
            facetCmpst = ModelCmpst(sp(1).y(1, 1):sp(1).y(1, 2), sp(1).x(1, 1):sp(1).x(1, 2));
        else
            %recieve slices
            facetCmpst = spmdReceive(1, spmdIndex);
        end
        DualL1 = Psit{spmdIndex}(facetCmpst);
    end
end

% init algo
itr = 1;
objective = -1;

%% dual-FB
while 1
    spmd (nFacets)
        % send slices to main worker (1)
        if spmdIndex > 1
            PsiDualL1 = [];
            spmdSend(Psi{spmdIndex}(DualL1), 1, spmdIndex);
            facetCmpst = spmdReceive(1);

        elseif spmdIndex == 1
            PsiDualL1 = zeros(size(ModelCmpst));
            PsiDualL1(sp(1).y(1, 1):sp(1).y(1, 2), sp(1).x(1, 1):sp(1).x(1, 2)) = Psi{1}(DualL1);
            for iFacet = 2:nFacets
                PsiDualL1(sp(iFacet).y(1, 1):sp(iFacet).y(1, 2), sp(iFacet).x(1, 1):sp(iFacet).x(1, 2)) = spmdReceive(iFacet, iFacet) + ...
                    PsiDualL1(sp(iFacet).y(1, 1):sp(iFacet).y(1, 2), sp(iFacet).x(1, 1):sp(iFacet).x(1, 2));
            end

            % update primal
            ModelCmpst = max(YCmpst-PsiDualL1, 0); % % positivity
            nrmL2 = 0.5 * sum((ModelCmpst - YCmpst).^2, 'all'); %  objective fun
            % split image to slices and send them to workers
            for iFacet = 2:nFacets
                ModelSlice2Send = ModelCmpst(sp(iFacet).y(1, 1):sp(iFacet).y(1, 2), sp(iFacet).x(1, 1):sp(iFacet).x(1, 2));
                spmdSend(ModelSlice2Send, iFacet);
            end
            facetCmpst = ModelCmpst(sp(1).y(1, 1):sp(1).y(1, 2), sp(1).x(1, 1):sp(1).x(1, 2));
        end
        % update dual
        PsitFacetCmpst = Psit{spmdIndex}(facetCmpst);
        DualL1 = Id_proxL1(DualL1+PsitFacetCmpst, SoftThres*weightsCmpst);
        nrmL1 = SoftThres * sum(abs(weightsCmpst.*PsitFacetCmpst), 'all'); % objective
        nrmL1 = spmdPlus(nrmL1, 1);
    end

    %% Stopping criterion
    prev_objective = objective(itr);
    itr = itr + 1;
    objective(itr) = nrmL2{1} + nrmL1{1};
    relative_objective = abs(objective(itr)-prev_objective) / objective(itr);
    if param.verbose
        fprintf('\n\tProx Iter %i, prox_fval = %e, rel_fval = %e,  l1norm_w = %e', itr-1, objective(end), relative_objective, nrmL1{1});
    end
    if (relative_objective < ObjTolProx) || itr >= MaxItrProx
        fprintf('\n\tProx converged: Iter %i, rel_fval = %e', itr-1, relative_objective);
        break;
    end
end, clear ModelSlice2Send facetCmpst PsiDualL1 PsitFacetCmpst;

% gather model estimate
MODEL = ModelCmpst{1};

end