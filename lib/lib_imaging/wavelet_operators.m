function [PsiFun, PsitFun] = wavelet_operators(wvltBases, wvltlevel, ImDims)
% Resturns the operator to the sparsity wavelet basis passed as argument
% Each basis is considered to be distributed to a different node.
%
% Parameters
% ----------
% wvltBases : cell[string]
%     Cell of strigs containing the names of the wavelets to be used, eg:
%     {'db1', 'db2', 'self'}.
% wvltlevel : int
%     Decomposition level.
% ImDims : int
%     Image size.
%
% Returns
% -------
% PsiFun : cell{anonymous functions}
%     Function handles for direct operator.
% PsitFun : cell{anonymous function}
%     Function handles for adjoint operator.
%

Ny = ImDims(1);
Nx = ImDims(2);
dwtmode('zpd');

%% sparsity operator definition
% construct a sting to repesent the desired inline function

PsitFun = cell(length(wvltBases), 1);
for i = 1:length(wvltBases)
    f = '@(x) [';
    if strcmp(wvltBases{i}, 'self')
        f = sprintf('%s x(:);', f);
    else
        f = sprintf('%s wavedec2(x, %d, ''%s'')'';', f, wvltlevel, wvltBases{i});
    end
    f = sprintf('%s]/sqrt(%d)', f, length(wvltBases));
    PsitFun{i} = eval(f);
end

% for Psi it is a bit more complicated, we need to do some extra
% precomputations
PsiFun = make_Psi(wvltBases, wvltlevel, Ny, Nx);

end

function Psi = make_Psi(basis, nlevel, Ny, Nx)
Psi = cell(length(basis), 1);

% estimate the structure of the data used to performe the
% reconstruction
S = cell(length(basis), 1);
ncoef = cell(length(basis), 1);

for i = 1:length(basis)
    if ~strcmp(basis{i}, 'self')
        [Cb, Sb] = wavedec2(zeros(Ny, Nx), nlevel, basis{i});
        S{i} = Sb;
        ncoef{i} = length(Cb(:));
    end
end

% construct a sting to repesent the desired inline function

for i = 1:length(basis)
    f = '@(x)(';
    if strcmp(basis{i}, 'self')
        f = sprintf('%s reshape(x(%d:%d), [Ny Nx])', f, 1, Ny*Nx);
    else
        f = sprintf('%s waverec2(x(%d:%d), S{%d}, ''%s'')', f, 1, ncoef{i}, i, basis{i});
    end
    f = sprintf('%s)/sqrt(%d)', f, length(basis));
    Psi{i} = eval(f);
end
end
