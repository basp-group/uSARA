clear 
clc

delete(gcp('nocreate'))

path = fileparts(mfilename('fullpath'));
cd(path)
cd ..

config = ['.', filesep, 'config', filesep, 'usara_sim.json'];
dataFile = ['.', filesep, 'examples', filesep, 'simulated_measurements', filesep, 'dt8', filesep, '3c353_lrs_1.0_seed_0.mat'];
resultPath = ['.', filesep, 'results', filesep, '3c353_dt8_seed0', filesep, 'uSARA']; 
algorithm = 'usara';
RunID = 0;

run_imager(config, 'dataFile', dataFile, 'resultPath', resultPath, 'runID', 0)