function hpc_cluster = util_set_parpool(ncores_data, parcluster_name)
    % function to launch parpool before the solver.
    %
    % Parameters
    % ----------
    % ncores_data : [int]
    %     number of data workers
    % parcluster_name : [string]
    %     name of the parcluster profile to use, default "local"
    %
    % Returns
    % -------
    % hpc_cluster
    %     [description]

    numworkers = ncores_data;

%     hpc_cluster = parcluster(parcluster_name); 
    hpc_cluster = parcluster('local'); 
    hpc_cluster.NumWorkers = numworkers;
    hpc_cluster.NumThreads = 1;
  
    % create temp. dir. if slurm parcluster profile is used
    if ~strcmp(parcluster_name,'local')
        hpc_cluster.JobStorageLocation = getenv('MATLAB_PREFDIR');
    end
   
    disp('Directing parpool logs to :');
    disp(hpc_cluster.JobStorageLocation);
    % % start the matlabpool with the requested workers
    parpool(hpc_cluster, numworkers);
    
    % wavelet 
    dwtmode('zpd', 'nodisp');
    spmd
        dwtmode('zpd', 'nodisp');
    end

end
