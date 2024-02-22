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

``uSARA`` is an unconstrained counterpart of the ``SARA`` algorithm based on forward-backward for solving inverse imaging problem. This repository provides a straightforward MATLAB implementation for the ``uSARA`` to solve small scale monochromatic astronomical imaging problem. The details of these algorithms are discussed in the following papers.

>[1] Terris, M., Dabbech, A., Tang, C., & Wiaux, Y. (2023). [Image reconstruction algorithms in radio interferometry: From handcrafted to learned regularization denoisers](https://doi.org/10.1093/mnras/stac2672). *Monthly Notices of the Royal Astronomical Society, 518*(1), 604-622.
>
>[2] Repetti, A., Birdi, J., Dabbech, A., & Wiaux, Y. (2017). [Non-convex optimization for self-calibration of direction-dependent effects in radio interferometric imaging](https://doi.org/10.1093/mnras/stx1267). *Monthly Notices of the Royal Astronomical Society, 470*(4), 3981-4006.

## Dependencies 

This repository relies on two auxiliary submodules :

1. [`RI-measurement-operator`](https://github.com/basp-group/RI-measurement-operator) for the formation of the radio-interferometric measurement operator;
2. [`SARA-dictionary`](https://github.com/basp-group-private/SARA-dictionary/tree/master) for the implementation of the sparsity priors.

These modules contain codes associated with the following publications

>[3] Dabbech, A., Wolz, L., Pratley, L., McEwen, J. D., & Wiaux, Y. (2017). [The w-effect in interferometric imaging: from a fast sparse measurement operator to superresolution](http://dx.doi.org/10.1093/mnras/stx1775). *Monthly Notices of the Royal Astronomical Society, 471*(4), 4300-4313.
>
>[4] Fessler, J. A., & Sutton, B. P. (2003). Nonuniform fast Fourier transforms using min-max interpolation. *IEEE transactions on signal processing, 51*(2), 560-574.
>
>[5] Onose, A., Dabbech, A., & Wiaux, Y. (2017). [An accelerated splitting algorithm for radio-interferometric imaging: when natural and uniform weighting meet](http://dx.doi.org/10.1093/mnras/stx755). *Monthly Notices of the Royal Astronomical Society, 469*(1), 938-949.
> 
>[6] Průša, Z. D. E. N. Ě. K. (2012). Segmentwise discrete wavelet transform (Doctoral dissertation, Ph. D. thesis, Brno University of Technology, Brno).

## Installation

To properly clone the project with the submodules, you may need to choose one of following set of instructions.

### Cloning the project

- If you plan to clone the project an SSH key for GitHub, you will first need to edit the `.gitmodules` file accordingly, replacing the `https` addresses with the `git@github.com` counterpart. That is

```bash
[submodule "lib/RI-measurement-operator"]
	path = lib/RI-measurement-operator
	url = git@github.com/basp-group/RI-measurement-operator.git
[submodule "lib/RI-measurement-operator"]
	path = lib/RI-measurement-operator
	url = git@github.com/basp-group/RI-measurement-operator.git
```

- Cloning the repository from scratch. If you used `https`, issue the following command

```bash
git clone --recurse-submodules https://github.com/basp-group/uSARA.git
```

If you are using an SSH key for GitHub rather than a personal token, then you will need to clone the repository as follows instead:

```bash
git clone --recurse-submodules git@github.com:basp-group/uSARA.git
```

You will then also need to update the local repository configuration to use this approach for the sub-modules and update the submodules separately as detailed below.

- Submodules update: updating from an existing `uSARA` repository.

```bash
git pull
git submodule sync --recursive # update submodule address, in case the url has changed
git submodule update --init --recursive # update the content of the submodules
git submodule update --remote --merge # fetch and merge latest state of the submodule
```

## Input Files
### Measurement file
Following [``Faceted-HyperSARA``](https://github.com/basp-group/Faceted-HyperSARA/tree/master/pyxisMs2mat) the measurement file is expected to be a ``.mat`` file containing the following fields.

```bash
"frequency" # channel frequency                       
"y"  # data (Stokes I)
"u"  # u coordinate (in units of the wavelength)
"v"  # v coordinate (in units of the wavelength)
"w"  # w coordinate (in units of the wavelength)                       
"nW"  # sqrt(weights)
"nWimag" # imaging weights if available (Briggs or uniform), empty otherwise
"maxProjBaseline" # max projected baseline (in units of the wavelength)
```

The python script that can be used to extract monochromatic measurements from MS files in the above format is also provided in the folder ``pyxisMs2mat``.

### Configuration file
The configuration file is a ``.json`` format file defining the parameters required by different algorithms.

## Examples
An example script is provided in the folder ``examples``. To launch these tests, please download the simulated measurements from this (temporary) [Dropbox link](https://www.dropbox.com/scl/fo/et0o4jl0d9twskrshdd7j/h?rlkey=gyl3fj3y7ca1tmoa1gav71kgg&dl=0) and move the folder ``simulated_measurements`` folder inside ``./examples``. Then change your current directory to ``./examples`` and launch the MATLAB scripts inside the folder. The results will be saved in the folder ``./results/3c353_dt8_seed0``. The groundtruth images of these measurements can be found in this (temporary) [Dropbox link](https://www.dropbox.com/scl/fo/mct058u0ww9301vrsgeqj/h?rlkey=hz8py389nay5jmqgzxz4knqja&dl=0).