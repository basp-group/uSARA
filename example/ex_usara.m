clear 
clc

delete(gcp('nocreate'))

path = fileparts(mfilename('fullpath'));
cd(path)
cd ..

config = ['.', filesep, 'config', filesep, 'usara_sim.json'];
dataFile = ['.', filesep, 'data', filesep, '3c353_meas_dt_1_seed_0.mat'];
groundtruth = ['.', filesep, 'data', filesep, '3c353_gdth.fits'];
resultPath = ['.', filesep, 'results']; 
algorithm = 'usara';
RunID = 0;

run_imager(config, 'dataFile', dataFile, 'resultPath', resultPath, 'groundtruth', groundtruth, 'runID', 0)