function imager(pathData, imPixelSize, imDimx, imDimy, param_general, runID)
    
    fprintf('\nINFO: measurement file %s', pathData);
    fprintf('\nINFO: Image size %d x %d', imDimx, imDimy)

    %% setting paths
    dirProject = param_general.dirProject;
    fprintf('\nINFO: Main project dir. is %s', dirProject);
    
    % src & lib codes
    addpath([dirProject, filesep, 'lib', filesep, 'lib_imaging', filesep]);
    addpath([dirProject, filesep, 'lib', filesep, 'lib_utils', filesep]);
    addpath([dirProject, filesep, 'lib', filesep, 'RI-measurement-operator', filesep, 'nufft']);
    addpath([dirProject, filesep, 'lib', filesep, 'RI-measurement-operator', filesep, 'irt', filesep, 'utilities']);
    addpath([dirProject, filesep, 'lib', filesep, 'RI-measurement-operator', filesep, 'lib', filesep, 'utils']);
    addpath([dirProject, filesep, 'lib', filesep, 'RI-measurement-operator', filesep, 'lib', filesep, 'operators']);
    addpath([dirProject, filesep, 'lib', filesep, 'RI-measurement-operator', filesep, 'lib', filesep, 'ddes_utils']);
    addpath([dirProject, filesep, 'lib', filesep, 'SARA-dictionary', filesep, 'src']);
    
    %% Measurements & operators
    % Measurements
    [DATA, param_general.flag_data_weighting] = util_read_data_file(pathData, param_general.flag_data_weighting);

    % Set pixel size
    if isempty(imPixelSize)
        maxProjBaseline = double( load(pathData, 'maxProjBaseline').maxProjBaseline );
        spatialBandwidth = 2 * maxProjBaseline;
        imPixelSize = (180 / pi) * 3600 / (param_general.superresolution * spatialBandwidth);
        fprintf('\nINFO: default pixelsize: %g arcsec, that is %.2f x nominal resolution',...
            imPixelSize, param_general.superresolution);
    else
        fprintf('\nINFO: user specified pixelsize: %g arcsec,', imPixelSize)
    end
    
    % Set parameters releated to operators
    [param_nufft, param_wproj] = util_set_param_operator(param_general, imDimx, imDimy, imPixelSize);

    % Generate operators
    [A, At, G, W, nWimag] = util_gen_meas_op_comp_single(pathData, imDimx, imDimy, ...
        param_general.flag_data_weighting, param_nufft, param_wproj);

    [measop, adjoint_measop] = util_syn_meas_op_single(A, At, G, W, []);

    % compute operator norm
    fprintf('\nComputing spectral norm of the measurement operator..')
    [param_general.measOpNorm,~] = op_norm(measop, adjoint_measop, [imDimy,imDimx], 1e-6, 500, 0);
    fprintf('\nINFO: measurement op norm %f', param_general.measOpNorm);
    
    % Compute PSF & dirty image
    dirac = sparse(floor(imDimy./2) + 1, floor(imDimx./2) + 1, 1, imDimy, imDimx);
    PSF = adjoint_measop(measop(full(dirac)));
    PSFPeak = max(PSF,[],'all');  clear dirac;
    fprintf('\nINFO: normalisation factor in RI: PSF peak value (normalisation factor in RI): %g',PSFPeak);

    %% Compute back-projected data 
    dirty = adjoint_measop(DATA);
  
    %% Heuristic noise level, used to set the regularisation params
    heuristic = 1 / sqrt(2 * param_general.measOpNorm);
    fprintf('\nINFO: heuristic noise level: %g', heuristic);

    if param_general.flag_data_weighting
        % Calculate the correction factor of the heuristic noise level when
        % data weighting vector is used
        [FWOp_prime, BWOp_prime] = util_syn_meas_op_single(A, At, G, W, nWimag.^2);
        measOpNorm_prime = op_norm(FWOp_prime,BWOp_prime,[imDimy,imDimx],1e-6,500,0);
        heuristic_correction = sqrt(measOpNorm_prime/param_general.measOpNorm);
        clear FWOp_prime BWOp_prime nWimag;

        heuristic = heuristic .* heuristic_correction;
        fprintf('\nINFO: heuristic noise level after correction: %g', heuristic);
    end

    %% Set parameters for imaging and algorithms
    param_algo = util_set_param_algo(param_general, heuristic);
    param_imaging = util_set_param_imaging(param_general, param_algo, [imDimy,imDimx], pathData, runID);
    
    % save dirty image and PSF
    fitswrite(single(PSF), fullfile(param_imaging.resultPath, 'PSF.fits')); clear PSF;
    fitswrite(single(dirty./PSFPeak), fullfile(param_imaging.resultPath, 'dirty.fits')); 
    
    
    %% INFO
    fprintf("\n________________________________________________________________\n")
    disp('param_algo:')
    disp(param_algo)
    disp('param_imaging:')
    disp(param_imaging)
    fprintf("________________________________________________________________\n")

    if ~param_imaging.flag_imaging
        fprintf('\nTHE END\n')
        return
    end
    
    %% uSARA Imaging
    [MODEL,RESIDUAL] = usara(dirty, measop, adjoint_measop, param_imaging, param_algo);

    %% Save final results
    fitswrite(MODEL, fullfile(param_imaging.resultPath, 'usara_model_image.fits')) % model estimate
    fitswrite(RESIDUAL, fullfile(param_imaging.resultPath, 'usara_residual_dirty_image.fits')) % back-projected residual data
    fitswrite(RESIDUAL ./ PSFPeak, fullfile(param_imaging.resultPath, 'usara_normalised_residual_dirty_image.fits')) % normalised back-projected residual data
    
    %% Final metrics
    fprintf('\nINFO: The standard deviation of the final residual dirty image %g', std(RESIDUAL, 0, 'all'))
    if isfield(param_imaging,'groundtruth') && ~isempty(param_imaging.groundtruth) && isfile(param_imaging.groundtruth)
        gdth_img = fitsread(param_imaging.groundtruth);
        snr = 20*log10( norm(gdth_img(:)) / norm(MODEL(:) - gdth_img(:)) );
        fprintf('\nINFO: The signal-to-noise ratio of the final reconstructed image %f dB', snr)
    end

    fprintf('\nTHE END\n')
    end
