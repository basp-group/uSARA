# Configuration (parameter) file

The algorithms implemented in this repository are launched through the function ``run_imager()``. This function accepts a ``.json`` file where all the parameters required the algorithm are defined. A sample configuration file ``usara_sim.json`` is given in the folder ``$uSARA/config``. In this document, we'll provide explanations for all the fields in this file.

The configuration file is composed by three parts, i.e. Main, General and Denoiser. 

1. Main
    - ``srcName``(optional): Experiment/target source name tag, used in the output filenames. If empty, the script will take the filename given in the ``dataFile`.
    - ``dataFile``: Path to the measurement (data) file. The file must be in ``.mat`` format containing fields discussed [here](https://github.com/basp-group/uSARA?tab=readme-ov-file#measurement-file).
    - ``resultPath``(optional): Path to the output files. The script will create a folder in ``$resultPath`` with name ``${srcname}_${algorithm}_ID_${runID}_heuScale_${heuNoiseScale}_maxItr_${imMaxItr}``. Default: ``$uSARA/results``
    - ``imDimx``: Horizontal dimension of the estimated image.
    - ``imDimy``: Vertical dimension of the estimated image.
    - ``imPixelSize``(optional): Pixel size of the estimated image in the unit of arcsec. If empty, its value is inferred from ``superresolution`` such that ``imPixelSize = (180 / pi) * 3600 / (superresolution * 2 * maxProjBaseline)``.
    - ``superresolution``(optional): Ratio between the spatial bandwidth of the image estimate and the spatial bandwidth of the observations (recommended to be in [1.5, 2.5]). Default: ``1.0``.
    - ``groundtruth``(optional): Path of the groundtruth image. The file must be in ``.fits `` format, and is used to compute reconstruction metrics. 
    - ``runID``(optional): Identification number of the current task. The default value is ``0``.

    The values of the entries in Main will be overwritten if corresponding name-value arguments are fed into the function ``run_imager()``.

2. General
    - ``flag``
        - ``flag_imaging``(optional): Enable imaging. If ``false``, the back-projected data (dirty image) and corresponding PSF are generated. Default: ``true``.
        - ``flag_data_weighting``(optional): Use the data-weighting scheme, with the weights ``nWimag`` given in the measurement file. Default: ``true``.

    - ``other``
        - ``dirProject``(optional): Path to project repository. Default: MATLAB's current running path.
        - ``ncpus``(optional): Number of CPUs used for imaging task. If empty, the script will make use of the available CPUs.

3. Denoiser
    - ``usara`` and ``usara_default``
        
        If the imaging ``algorithm``is specified as ``usara``, then the fields in the section will be loaded.
        - ``heuRegParamScale``(optional): Adjusting factor applied to the regularisation parameter calculated based on the heuristic noise levels. Default: ``1.0``.
        - ``reweighting``: Enable reweighting algorithm.  Default: ``true``.
        - ``imMinInnerItr``(optional): Minimum number of iterations in the forward-backward algorithm (inner loop). Default: ``10``.
        - ``imMaxInnerItr``(optional): Maximum number of iterations in the forward-backward algorithm (inner loop). Default: ``2000``.
        - ``imVarInnerTol``(optional): Tolerance on the relative variation of the estimation in the forward-backward algorithm (inner loop) to indicate convergence. Default: ``1e-4``.
        - ``imMaxOuterItr``(optional): Maximum number of iterations in the reweighting algorithm (outer loop).  Default: ``10``.
        - ``imVarOuterTol``(optional): Tolerance on the relative variation of the estimation in the reweighting algorithm (outer loop) to indicate convergence. Default: ``1e-4``.
        - ``itrSave``(optional): Interval of iterations for saving intermediate results. Default: ``500``.
        - ``waveletDistribution``(optional): The way to distribute wavelet coefficients. It has to be chosen from ``"basis"`` and ``"facet"``. Default: ``"facet"``.
        - ``nFacetsPerDim``(optional): Number of wavelet facets on each image dimension. Default: ``[2,2]``.
        - ``facetDimLowerBound``(optional): The smallest size of wavelet facets on each image dimension. Default: ``256``.


    

    
