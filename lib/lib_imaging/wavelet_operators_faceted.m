function [PsiFun, PsitFun, param_facet] = wavelet_operators_faceted(wvltBases,wvltlevel,ImDims,nFacetsPerDim)
% default daubechies dict
dbWvltBasis={'db1', 'db2', 'db3', 'db4', 'db5', 'db6', 'db7', 'db8'}; 
% facet definition
nFacets = nFacetsPerDim(2) * nFacetsPerDim(1);
rg_y = split_range(nFacetsPerDim(1), ImDims(1));
rg_x = split_range(nFacetsPerDim(2), ImDims(2));
ndbWvltBasis = 0; 
for iBasis =1:numel(wvltBases)
    ndbWvltBasis = ndbWvltBasis +ismember(wvltBases{iBasis} , dbWvltBasis);
end
segDims = zeros(nFacets, 4);
for qx = 1:nFacetsPerDim(2)
    for qy = 1:nFacetsPerDim(1)
        iFacet = (qx - 1) * nFacetsPerDim(1) + qy;
        segDims(iFacet, :) = [rg_y(qy, 1) - 1, rg_x(qx, 1) - 1, rg_y(qy, 2) - rg_y(qy, 1) + 1, rg_x(qx, 2) - rg_x(qx, 1) + 1];
    end
end
I = segDims(:, 1:2);
dims = segDims(:, 3:4);

% length of the wavelet filters (0 taken as a convention for the Dirac basis)
L = [2 * (1:ndbWvltBasis), 0].'; % filter length
[I_overlap_ref, dims_overlap_ref, I_overlap, dims_overlap, ...
    status, offset, pre_offset, post_offset, Ncoefs, pre_offset_dict, ...
    post_offset_dict] = sdwt2_setup(ImDims, I, dims, wvltlevel, wvltBases, L);

PsitFun = cell(nFacets, 1);
PsiFun = cell(nFacets, 1);
% facetSize = dims_overlap_ref + pre_offset + post_offset; % full facet-size, including 0-padding (pre_offset / post_offset 0s added)
for iFacet = 1:nFacets
    slicePos(iFacet).y(1, 1) = I_overlap_ref(iFacet, 1) + 1;
    slicePos(iFacet).y(1, 2) = I_overlap_ref(iFacet, 1) + dims_overlap_ref(iFacet, 1);
    slicePos(iFacet).x(1, 1) = I_overlap_ref(iFacet, 2) + 1;
    slicePos(iFacet).x(1, 2) = I_overlap_ref(iFacet, 2) + dims_overlap_ref(iFacet, 2);

    PsitFun{iFacet} = @(facet) sdwt2_sara_faceting(facet, I(iFacet, :),  offset, status(iFacet, :), wvltlevel, wvltBases, Ncoefs{iFacet});  
    PsiFun{iFacet} = @(wvltCoeffs) isdwt2_sara_faceting(wvltCoeffs, I(iFacet, :), dims(iFacet, :), I_overlap{iFacet}, dims_overlap{iFacet}, Ncoefs{iFacet}, wvltlevel, wvltBases, pre_offset_dict{iFacet}, post_offset_dict{iFacet});
end
%
param_facet.slicePos = slicePos;
param_facet.nFacets = nFacets;
end
