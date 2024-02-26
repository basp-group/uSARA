function [MODEL, DualL1, objective_prev] = denoiser_prox_usara(MODEL, DualL1, Y, Psi, Psit, weights, objective_prev, param)
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
lambda = param.lambda;

% dual variable
if isempty(DualL1)
    DualL1 = cell(numel(Psit), 1);
    for basis = 1 : numel(Psi)
        DualL1{basis} = Psit{basis}(MODEL);
    end
end

% algo params
itr = 1;
objective = objective_prev;
% step sizes
% nu = 1;
% eps_step = 0.99 * min(1/(nu), 1);
% gamma_step = 1; % because nu==1 ... max(eps_step,2/(nu) -eps_step);
% lambda_step = 1;

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
    parfor basis = 1 : numel(Psit)
        PsitIm = Psit{basis}(MODEL); % apply \Psi^\dagger
        DualL1{basis} = Id_proxL1(DualL1{basis}+PsitIm, lambda*weights{basis});
        nrmL1 = nrmL1 + lambda * sum(abs(weights{basis}.*PsitIm), 'all');
    end

    %% Stopping criterion
    prev_objective = objective(itr);
    itr = itr + 1;
    objective(itr) = nrmL2 + nrmL1;
    relative_objective = abs(objective(itr)-prev_objective) / objective(itr);

    fprintf('\n\tProx Iter %i, prox_fval = %e, rel_fval = %e', itr-1, objective(end), relative_objective);
    if (relative_objective < ObjTolProx) || itr >= MaxItrProx
        objective_prev = objective(itr);
        break;
    end

end
