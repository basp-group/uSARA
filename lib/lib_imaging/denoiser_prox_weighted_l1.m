function [MODEL, DualL1] = denoiser_prox_weighted_l1(MODEL, DualL1, Y, Psi, Psit, weights, param)
% PROJ_L1 - Proximal operator with L1 norm
% Parameters
% ----------
% MODEL : 2D matrix
%     model estimate - primal variable
% DualL1 : vector
%     dual variable (in the wavelet domain)
% Y : 2D matrix
%     point at which the prox. is computed
% Psi: cell of function handle
%     direct operator: wavelet tranform  (9 bases, including identity) 
% Psit: cell of function handle
%     adjoint operator: inverse wavelet transform 
% weights: vector
%     weights involved in the re-weighting algorithm
% param: struct
% Returns
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

% Useful function
Id_proxL1 = @(z, T) z - (sign(z) .* max(abs(z) - T, 0));

% init dual variable
nBases = numel(Psit);
if isempty(DualL1)
    DualL1 = cell(nBases, 1);
    for iBasis = 1 : nBases
        DualL1{iBasis} = Psit{iBasis}(MODEL);
    end
end

% init algo 
itr = 1;
objective = -1;

%% dual-FB
while 1

    %% update primal
    PsiDualL1 = 0;
    parfor iBasis = 1 : nBases
        PsiDualL1 = PsiDualL1 + Psi{iBasis}(DualL1{iBasis});
    end
    MODEL = max(Y - PsiDualL1 , 0); % positivity
    nrmL2 = 0.5 * sum((MODEL - Y).^2, 'all'); 

    %% update dual
    nrmL1 = zeros(nBases, 1);
    parfor iBasis = 1 : nBases
        PsitModel = Psit{iBasis}(MODEL); % apply \Psi^\dagger
        DualL1{iBasis} = Id_proxL1(DualL1{iBasis} + PsitModel, SoftThres*weights{iBasis});
        nrmL1(iBasis) = sum(abs(weights{iBasis}.*PsitModel), 'all');
    end
    nrmL1 = sum(nrmL1);

    %% Stopping criterion
    prev_objective = objective(itr);
    itr = itr + 1;
    objective(itr) = nrmL2 + SoftThres * nrmL1;
    relative_objective = abs(objective(itr)-prev_objective) / objective(itr);
    if param.verbose
        fprintf('\n\tProx Iter %i, prox_fval = %e, rel_fval = %e,  l1norm_w = %e', itr-1, objective(end), relative_objective, nrmL1);
    end
    if (relative_objective < ObjTolProx) || itr >= MaxItrProx
        fprintf('\n\tProx converged: Iter %i, rel_fval = %e', itr-1, relative_objective);

        break;
    end

end

