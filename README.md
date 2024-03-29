# uSARA: Unconstrained "Sparsity Averaging Reweighted Analysis" algorithm for computational imaging
![language](https://img.shields.io/badge/language-MATLAB-orange.svg)
[![license](https://img.shields.io/badge/license-GPL--3.0-brightgreen.svg)](LICENSE)

- [uSARA: Unconstrained "Sparsity Averaging Reweighted Analysis" algorithm for computational imaging](#usara-unconstrained-sparsity-averaging-reweighted-analysis-algorithm-for-computational-imaging)
  - [Description](#description)
  - [Dependencies](#dependencies)
  - [Installation](#installation)
    - [Cloning the project](#cloning-the-project)
    - [Updating submodules (optional)](#updating-submodules-optional)
  - [Input Files](#input-files)
    - [Measurement file](#measurement-file)
    - [Configuration file](#configuration-parameter-file)
  - [Usage and Example](#usage-and-example)

## Description

``uSARA`` is the unconstrained counterpart of the ``SARA`` algorithm. It is underpinned by the forward-backward algorithmic structure for solving inverse imaging problem. This repository provides a straightforward MATLAB implementation of ``uSARA`` to solve small scale monochromatic astronomical imaging problem. The details of the algorithm are discussed in the following papers.

>[1] Terris, M., Dabbech, A., Tang, C., & Wiaux, Y., [Image reconstruction algorithms in radio interferometry: From handcrafted to learned regularization denoisers](https://doi.org/10.1093/mnras/stac2672). *MNRAS, 518*(1), 604-622.
>
>[2] Repetti, A., & Wiaux, Y., [A forward-backward algorithm for reweighted procedures: Application to radio-astronomical imaging](https://doi.org/10.1109/ICASSP40776.2020.9053284). *IEEE ICASSP 2020*, 1434-1438, 2020.

## Dependencies 

This repository relies on two auxiliary submodules :

1. [`RI-measurement-operator`](https://github.com/basp-group/RI-measurement-operator) for the formation of the radio-interferometric measurement operator [3,4,5];
2. [`SARA-dictionary`](https://github.com/basp-group-private/SARA-dictionary/tree/master) for the faceted implementation of the sparsity dictionary [6].

These modules contain codes associated with the following publications

>[3] Fessler, J. A., & Sutton, B. P., Nonuniform fast Fourier transforms using min-max interpolation. *IEEE TSP*, 51(2), 560-574, 2003.
>
>[4] Onose, A., Dabbech, A., & Wiaux, Y., [An accelerated splitting algorithm for radio-interferometric imaging: when natural and uniform weighting meet](http://dx.doi.org/10.1093/mnras/stx755). *MNRAS*, 469(1), 938-949, 2017.
>
>[5] Dabbech, A., Wolz, L., Pratley, L., McEwen, J. D., & Wiaux, Y., [The w-effect in interferometric imaging: from a fast sparse measurement operator to superresolution](http://dx.doi.org/10.1093/mnras/stx1775). *MNRAS*, 471(4), 4300-4313, 2017.
> 
>[6] Průša, Z. D. E. N. Ě. K., Segmentwise discrete wavelet transform, Ph. D. thesis, Brno University of Technology, Brno, 2012.

## Installation


### Cloning the project
To clone the project with the required submodules, you may consider one of the following set of instructions.

- Cloning the project using `https`: you should run the following command
```bash
git clone --recurse-submodules https://github.com/basp-group/uSARA.git
```
- Cloning the project using SSH key for GitHub: you should run the following command first
```bash
git clone git@github.com:basp-group/AIRI.git
```

Next, please edit the `.gitmodules` file, replacing the `https` addresses with the `git@github.com` counterpart as follows: 

```bash
[submodule "lib/RI-measurement-operator"]
	path = lib/RI-measurement-operator
	url = git@github.com/basp-group/RI-measurement-operator.git
[submodule "lib/RI-measurement-operator"]
	path = lib/RI-measurement-operator
	url = git@github.com/basp-group/RI-measurement-operator.git
```
Finally, please follow the instructions in the next session [Updating submodules (optional)](#updating-submodules-optional) to clone the submodules into the repository's path.

The full path to the uSARA repository is referred to as `$uSARA` in the rest of the documentation.

### Updating submodules (optional)
- To update the submodules from your local repository `$uSARA`, run the following commands: 
```bash
git pull
git submodule sync --recursive # update submodule address, in case the url has changed
git submodule update --init --recursive # update the content of the submodules
git submodule update --remote --merge # fetch and merge latest state of the submodule
```

## Input Files
### Measurement file
The current code takes as input data a measurement file in ``.mat`` format, and containing the following fields:

 ``` MATLAB 
   "y"               %% vector; data (Stokes I)
   "u"               %% vector; u coordinate (in units of the wavelength)
   "v"               %% vector; v coordinate (in units of the wavelength)
   "w"               %% vector; w coordinate (in units of the wavelength)
   "nW"              %% vector; inverse of the noise standard deviation 
   "nWimag"          %% vector; square root of the imaging weights if available (Briggs or uniform), empty otherwise
   "frequency"       %% scalar; channel frequency
   "maxProjBaseline" %% scalar; maximum projected baseline (in units of the wavelength; formally  max(sqrt(u.^2+v.^2)))
   ```

An example measurement file ``3c353_meas_dt_1_seed_0.mat`` is provided in the folder ``$uSARA$/data``. The full synthetic test set used in [1] can be found in this (temporary) [Dropbox link](https://www.dropbox.com/scl/fo/et0o4jl0d9twskrshdd7j/h?rlkey=gyl3fj3y7ca1tmoa1gav71kgg&dl=0).

To extract the measurement file from Measurement Set Tables (MS), you can use the utility Python script `$uSARA/pyxisMs2mat/pyxis_ms2mat.py`. Instructions are provided in the [Readme File](https://github.com/basp-group/uSARA/blob/main/pyxisMs2mat/README.md).

Note that the measurement file is of the same format as the input expected in the library [Faceted-HyperSARA](https://github.com/basp-group/Faceted-HyperSARA) for wideband imaging. 
### Configuration (parameter) file
The configuration file is a ``.json`` format file comprising all parameters to run the code.
An example `usara_sim.json` is provided in `$uSARA/config/`. A detailed description about the fields in the configuration file is provided [here](https://github.com/basp-group/uSARA/blob/main/config/README.md).

## Usage and Example
The algorithm can be launched through function `run_imager()`. The mandatory input argument of this function is the path of configuration file discussed in the above section. 

```MATLAB
pth_config = ['.', filesep, 'config', filesep, 'usara_sim.json'];
run_imager(pth_config)
```

It also accepts 10 optional name-argument pairs which will overwrite corresponding fields in the configuration file.

```MATLAB
run_imager(pth_config, ... %% path of the configuration file
    'srcName', srcName, ... %% name of the target src used for output filenames
    'dataFile', dataFile, ... %% path of the measurement file
    'resultPath', resultPath, ... %% path where the result folder will be created
    'imDimx', imDimx, ... %% horizontal number of pixels in the final reconstructed image
    'imDimy', imDimy, ... %% vertical number of pixels in the final reconstructed image
    'imPixelSize', imPixelSize, ... %% pixel size of the reconstructed image in the unit of arcsec 
    'superresolution', superresolution, ... %% used if pixel size not provided
    'groundtruth', groundtruth, ... %% path of the groundtruth image when available
    'runID', runID ... %% identification number of the imaging run used for output filenames 
  )
```

An example script is provided in the folder `$uSARA/example`. This script will reconstruct the groundtruth image `$uSARA/data/3c353_gdth.fits` from the measurement file `$uSARA/data/3c353_meas_dt_1_seed_0.mat`.  To launch this test, please change your current directory to ``$uSARA/example`` and launch the MATLAB scripts inside the folder. The results will be saved in the folder `$uSARA/results/`.
