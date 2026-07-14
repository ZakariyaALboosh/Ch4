# Real openEMS S/X-Band Reflector Simulations

This folder replaces the previous optional MATLAB Antenna Toolbox visualizations with **real full-wave electromagnetic simulations** using the open-source **openEMS** FDTD solver.

The antenna-design work is intentionally kept as a reproducible reference study because the main contribution of the thesis is the SDR ground-station design and the physically implemented UHF subsystem.

## What is simulated

Two complete prime-focus reflector antennas are provided:

1. **S-band reference reflector**
   - Centre frequency: 2.25 GHz
   - Frequency sweep: 2.10-2.40 GHz
   - Prime-focus PEC paraboloid
   - Diameter: 0.60 m
   - f/D: 0.45
   - Dominant-mode circular-waveguide TE11 feed

2. **X-band reference reflector**
   - Centre frequency: 8.20 GHz
   - Frequency sweep: 7.80-8.60 GHz
   - Prime-focus PEC paraboloid
   - Diameter: 0.45 m
   - f/D: 0.45
   - Dominant-mode circular-waveguide TE11 feed

These are **reference electromagnetic models**, not claimed as original optimized feed designs and not presented as manufacturing-ready antennas.

## Why this is a real EM simulation

The scripts do not generate assumed radiation patterns. They:

- create the three-dimensional PEC reflector geometry using `AddRotPoly`;
- create the circular-waveguide feed and excite its TE11 mode;
- discretize the complete structure on the openEMS FDTD mesh;
- solve the electromagnetic fields in time domain;
- calculate feed S11 and input impedance;
- record near fields and transform them to far-field radiation patterns with NF2FF;
- calculate maximum directivity and aperture efficiency from the solved fields.

The analytical dish gain and beamwidth calculations in the main Chapter 4 project remain useful for sizing and trade studies, but they are separate from these full-wave simulations.

## Files

- `run_sband_reflector_openems.m` - S-band configuration and run script.
- `run_xband_reflector_openems.m` - X-band configuration and run script.
- `simulate_prime_focus_reflector_openems.m` - shared full-wave geometry, solver, and post-processing function.

## Required software

- MATLAB R2022b or a compatible Octave installation.
- openEMS with its MATLAB/Octave interface added to the MATLAB path.
- CSXCAD, normally installed with openEMS.

No MATLAB Antenna Toolbox is required for these simulations.

## Running the simulations

From MATLAB:

```matlab
cd chapter4_sx_sim/openems_antenna
run_sband_reflector_openems
```

Then:

```matlab
run_xband_reflector_openems
```

The X-band case is electrically larger and may require substantially more memory and run time.

Results are written to:

```text
openems_antenna/results/sband_2p25GHz_reflector/
openems_antenna/results/xband_8p2GHz_reflector/
```

Each completed run produces:

- `reflector_profile.png`
- `s11.png`
- `input_impedance.png`
- `port_results.csv`
- `farfield_cuts.png`
- `summary.txt`

Set:

```matlab
cfg.calculate3D = true;
```

only after the normal simulation succeeds if a 3D far-field plot is required.

## Numerical convergence

The default meshes are intended to be practical reference runs, not the final word on numerical convergence.

For stronger thesis verification, repeat a successful simulation after increasing:

```matlab
cfg.cellsPerLambda
```

and compare:

- S11 at the design frequency;
- maximum directivity;
- aperture efficiency.

If the differences are small, report the result as a simple mesh-convergence check.

## Source and attribution

The reflector construction and overall openEMS workflow are adapted from the open-source example:

- Paul Klasmann, **Tutorial - Reflector Simulation with openEMS**, `Parabola_Ku_0_34m_v1_1.m`, GitHub, 2018/2020 repository version.

The openEMS project and standard antenna simulation workflow are documented by the openEMS project and its official tutorials, including near-field to far-field processing, ports, meshing, and FDTD execution.

The implementation in this repository changes the reference geometry, frequencies, waveguide dimensions, output handling, validation, and reusable code structure for the S- and X-band ground-station study.

## Suggested thesis wording

> Full-wave reference models of prime-focus S-band and X-band reflector antennas were implemented using the open-source openEMS finite-difference time-domain solver. The reflector modelling workflow was adapted from an openly available openEMS parabolic-reflector example rather than presented as an original antenna design. The simulations were used to obtain S-parameters, input impedance, far-field directivity, and aperture-efficiency estimates for representative higher-band ground-station antennas.

Do not claim that these simulations experimentally validate a constructed S-band or X-band antenna.
