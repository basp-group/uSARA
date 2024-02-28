function [MODEL, DualL1] = denoiser_prox_usara(MODEL, DualL1, Y, Psi, Psit, weights, param)
% PROJ_L1 - Proximal operator with L1 norm
% sol = solver_prox_L1_full_image(x, lambda, param) solves:
%   min_{z} 0.5*||x - z||_2^2 + lambda * ||Psit (xA + z)||_1
% References:
% [1] M.J. Fadili and J-L. Starck, "Monotone operator splitting for
% optimization problems in sparse recovery" , IEEE ICIP, Cairo,
% Egypt, 2009.
% [2] Amir Beck and Marc Teboulle, "A Fast Iterative Shrinkage-Thresholding
% Algorithm for Linear Inverse Problems",  SIAM Journal on Imaging Sciences
% 2 (2009), no. 1, 183--202.

%% Optional input arguments -- >  to be updated
if ~isfield(param, 'verbose'), param.verbose = true; end
if ~isfield(param, 'ObjTolProx'), param.ObjTolProx = 1e-4; end
if ~isfield(param, 'MaxItrProx'), param.MaxItrProx = 200; end

%%  Initializations
gamma_lambda = param.gamma_lambda;

% dual variable
if isempty(DualL1)
    DualL1 = cell(numel(Psit), 1);
    for basis = 1 : numel(Psi)
        DualL1{basis} = Psit{basis}(MODEL);
    end
end

% algo params
itr = 1;
objective = -1;

% stopping crit.
ObjTolProx = param.ObjTolProx;
MaxItrProx = param.MaxItrProx;

% Useful functions
Id_proxL1 = @(z, T) z - (sign(z) .* max(abs(z)-T, 0));

%% dual-FB
while 1

    % update primal
    PsiDual = 0;
    parfor basis = 1 : numel(Psi)
        PsiDual = PsiDual + Psi{basis}(DualL1{basis});
    end
    MODEL = max(Y - PsiDual , 0); % FW
    nrmL2 = 0.5 * sum((MODEL - Y).^2, 'all');

    % update dual
    nrmL1 = 0;
    nrmL1_raw = 0;
    parfor basis = 1 : numel(Psit)
        PsitIm = Psit{basis}(MODEL); % apply \Psi^\dagger
        DualL1{basis} = Id_proxL1(DualL1{basis}+PsitIm, gamma_lambda*weights{basis});
        nrmL1 = nrmL1 + sum(abs(weights{basis}.*PsitIm), 'all');
        nrmL1_raw = nrmL1_raw + sum(abs(PsitIm), 'all');
    end

    %% Stopping criterion
    prev_objective = objective(itr);
    itr = itr + 1;
    objective(itr) = nrmL2 + gamma_lambda * nrmL1;
    relative_objective = abs(objective(itr)-prev_objective) / objective(itr);

    fprintf('\n\tProx Iter %i, prox_fval = %e, rel_fval = %e, l1norm = %e, l1norm_w = %e', itr-1, objective(end), relative_objective, nrmL1_raw, nrmL1);
    if (relative_objective < ObjTolProx) || itr >= MaxItrProx
        break;
    end

end

