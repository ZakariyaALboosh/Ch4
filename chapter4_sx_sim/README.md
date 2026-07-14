# Chapter 4 S/X-Band Ground-Station Simulations

This MATLAB R2022b project supports Chapter 4 of a BSc telecommunications thesis, **SDR-Based Ground Station Design**. The existing physical station is a UHF 435 MHz receive station using a QFH antenna, LNA, bladeRF x40, and Raspberry Pi. This package studies future receive-only S-band and X-band extensions.

## Folder structure

- `run_all_chapter4.m` — main deterministic run script.
- `config_chapter4.m` — editable engineering assumptions.
- `src/` — base-MATLAB analytical functions.
- `openems_antenna/` — standalone open-source full-wave S/X-band reflector simulations using openEMS.
- `results/figures`, `results/tables`, `results/mat` — generated outputs.
- `appendix_code/` — compact thesis-appendix version of the core equations.

## How to run

```matlab
cd chapter4_sx_sim
run_all_chapter4
```

Core calculations require only base MATLAB syntax compatible with MATLAB R2022b. Optional `satelliteScenario` support may use Satellite Communications Toolbox or Aerospace Toolbox. The separate reflector EM models use the open-source openEMS solver and do not require MATLAB Antenna Toolbox. Simulink, STK, Communications Toolbox, GNU Radio, and SDR hardware are not required for the core analytical run.

## Antenna modelling

The main Chapter 4 run performs analytical dish sizing, gain, beamwidth, and pointing-loss trade studies. These are engineering calculations, not full-wave antenna simulations.

Real full-wave reference models are provided separately in `openems_antenna/`. They solve complete prime-focus PEC reflector antennas with circular-waveguide TE11 feeds using openEMS FDTD and produce S11, input impedance, NF2FF far-field cuts, directivity, and aperture-efficiency results. See `openems_antenna/README.md` for software requirements, attribution, and run instructions.

## Fallback behavior

If the real orbital-propagation path fails, the code may use a deterministic synthetic representative LEO pass. That fallback is labeled as synthetic and must not be presented as precise orbital propagation. The openEMS antenna simulations are separate runs and do not silently fall back to analytical radiation patterns.

## Generated outputs

The main run creates receiver-noise, dish-trade, pointing-loss, pass-geometry, Doppler, dynamic-link, data-budget, component-selection, and BOM CSV files; thesis-ready PNG/PDF figures; `results/mat/chapter4_results.mat`; and `results/chapter4_simulation_summary.txt`.

The openEMS runs write their own electromagnetic results under `openems_antenna/results/`.

## Assumptions to edit first

Review station coordinates, orbit, transmit power and spacecraft antenna gain, receiver LNA/LNB gain and noise figure, losses before the first active device, dish diameter and efficiency, antenna temperature, environmental losses, data rate, required `(E_b/N_0)`, and number of passes per day.

## Link-budget reference plane

The dynamic link budget calculates received carrier power at the antenna-feed/receiver-input reference plane. Receiver equivalent noise temperature is computed from a Friis cascade that already includes loss before the LNA/LNB, active-device noise, and loss after the LNA/LNB. Therefore those receiver losses are **not subtracted again** from carrier power; they degrade the link through the system noise temperature.

## Limitations

These are preliminary design simulations based on simplified assumptions and datasheet-level values. They are not experimental verification of a constructed S-band or X-band station. The openEMS models are reference full-wave simulations and are not claimed as original optimized or manufacturing-ready antenna designs. Transmitter values are representative assumptions for analysis, not a transmitter hardware design. Component-selection and BOM CSV files are editable worksheets and not final procurement selections; commercial model fields are intentionally `TBD`.
