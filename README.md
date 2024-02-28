# uSARA: Unconstrained "Sparsity Averaging Reweighted Analysis" algorithm for computational imaging
![language](https://img.shields.io/badge/language-MATLAB-orange.svg)
[![license](https://img.shields.io/badge/license-GPL--3.0-brightgreen.svg)](LICENSE)

- [uSARA: Unconstrained "Sparsity Averaging Reweighted Analysis" algorithm for computational imaging](#usara-unconstrained-sparsity-averaging-reweighted-analysis-algorithm-for-computational-imaging)
  - [Description](#description)
  - [Dependencies](#dependencies)
  - [Installation](#installation)
    - [Cloning the project](#cloning-the-project)
  - [Input Files](#input-files)
    - [Measurement file](#measurement-file)
    - [Configuration file](#configuration-file)
  - [Examples](#examples)

## Description

``uSARA`` is the unconstrained counterpart of the ``SARA`` algorithm. It is underpinned by the forward-backward algorithmic structure for solving inverse imaging problem. This repository provides a straightforward MATLAB implementation of  ``uSARA`` to solve small scale monochromatic astronomical imaging problem. The details of the algorithm are discussed in the following papers.

>[1] Terris, M., Dabbech, A., Tang, C., & Wiaux, Y. (2023). [Image reconstruction algorithms in radio interferometry: From handcrafted to learned regularization denoisers](https://doi.org/10.1093/mnras/stac2672). *MNRAS, 518*(1), 604-622.
>
>[2] Repetti, A., Birdi, J., Dabbech, A., & Wiaux, Y. (2017). [Non-convex optimization for self-calibration of direction-dependent effects in radio interferometric imaging](https://doi.org/10.1093/mnras/stx1267). *Monthly Notices of the Royal Astronomical Society, 470*(4), 3981-4006. (WRONG REF UPDATE: repetti 2020 conf)

## Dependencies 

This repository relies on two auxiliary submodules :

1. [`RI-measurement-operator`](https://github.com/basp-group/RI-measurement-operator) for the formation of the radio-interferometric measurement operator [3,4,5];
2. [`SARA-dictionary`](https://github.com/basp-group-private/SARA-dictionary/tree/master) for the faceted implementation of the sparsity dictionary [6].

These modules contain codes associated with the following publications

>[3] Fessler, J. A., & Sutton, B. P. (2003). Nonuniform fast Fourier transforms using min-max interpolation. *IEEE TSP, 51*(2), 560-574.
>
>[4] Onose, A., Dabbech, A., & Wiaux, Y. (2017). [An accelerated splitting algorithm for radio-interferometric imaging: when natural and uniform weighting meet](http://dx.doi.org/10.1093/mnras/stx755). *MNRAS, 469*(1), 938-949.
>
>[5] Dabbech, A., Wolz, L., Pratley, L., McEwen, J. D., & Wiaux, Y. (2017). [The w-effect in interferometric imaging: from a fast sparse measurement operator to superresolution](http://dx.doi.org/10.1093/mnras/stx1775). *MNRAS, 471*(4), 4300-4313.
> 
>[6] Průša, Z. D. E. N. Ě. K. (2012). Segmentwise discrete wavelet transform (Doctoral dissertation, Ph. D. thesis, Brno University of Technology, Brno).

## Installation


### Cloning the project
To clone the project with the required submodules, you may consider one of the following set of instructions.

- Cloning the project using `https`:  you should run the following command
```bash
git clone --recurse-submodules https://github.com/basp-group/uSARA.git
```
- Cloning the project using SSH key for GitHub: you should first edit the `.gitmodules` file, replacing the `https` addresses with the `git@github.com` counterpart as follows: 

```bash
[submodule "lib/RI-measurement-operator"]
	path = lib/RI-measurement-operator
	url = git@github.com/basp-group/RI-measurement-operator.git
[submodule "lib/RI-measurement-operator"]
	path = lib/RI-measurement-operator
	url = git@github.com/basp-group/RI-measurement-operator.git
```
You can then clone the repository with all the submodules as follows:

```bash
git clone --recurse-submodules git@github.com:basp-group/uSARA.git
```
### Updating submodules (optional)
- To update the submodules from your local `uSARA` repository, run the follwing commands: 
```bash
git pull
git submodule sync --recursive # update submodule address, in case the url has changed
git submodule update --init --recursive # update the content of the submodules
git submodule update --remote --merge # fetch and merge latest state of the submodule
```

## Input Files
### Measurement file
The current code takes as input data a measurement file in ``.mat`` format containing the following fields:

```matlab
"frequency"       % scalar, observation frequency                       
"y"               % vector, measurements/data (Stokes I)
"u"               % vector, u coordinate (in units of the wavelength)
"v"               % vector, v coordinate (in units of the wavelength)
"w"               % vector, w coordinate (in units of the wavelength)                       
"nW"              % vector, inverse of the standard deviation
"nWimag"          % vector, sqrt of the imaging weights if available (Briggs or uniform), empty otherwise
"maxProjBaseline" % scalar, maximum projected baseline (in units of the wavelength; formally  max(sqrt(u.^2+v.^2)))
```

Instructions to extract single-channel measurment file from a Measurement Set are provided in the [Readme File](https://github.com/basp-group/uSARA/blob/main/pyxisMs2mat/README.md).
Note that the measurement file is of the same format as the input expected in the library [Faceted Hypersara](https://github.com/basp-group/Faceted-HyperSARA) for wideband imaging. 
### Configuration (parameter) file
The configuration file is a ``.json`` format file comprising all parameters to run the code.

## Examples
An example script is provided in the folder ``examples``. To launch these tests, please download the simulated measurements from this (temporary) [Dropbox link](https://www.dropbox.com/scl/fo/et0o4jl0d9twskrshdd7j/h?rlkey=gyl3fj3y7ca1tmoa1gav71kgg&dl=0) and move the folder ``simulated_measurements`` folder inside ``./examples``. Then change your current directory to ``./examples`` and launch the MATLAB scripts inside the folder. The results will be saved in the folder ``./results/3c353_dt8_seed0``. The groundtruth images of these measurements can be found in this (temporary) [Dropbox link](https://www.dropbox.com/scl/fo/mct058u0ww9301vrsgeqj/h?rlkey=hz8py389nay5jmqgzxz4knqja&dl=0).
