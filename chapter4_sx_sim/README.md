# Chapter 4 S/X-Band Ground-Station Simulations

This MATLAB R2022b project supports Chapter 4 of a BSc telecommunications thesis, **SDR-Based Ground Station Design**. The existing physical station is a UHF 435 MHz receive station using a QFH antenna, LNA, bladeRF x40, and Raspberry Pi. This package studies future receive-only S-band and X-band extensions.

## Folder structure

- `run_all_chapter4.m` — main deterministic run script.
- `config_chapter4.m` — editable engineering assumptions.
- `src/` — base-MATLAB analytical functions.
- `optional_antenna_toolbox/` — optional reflector visualization scripts.
- `results/figures`, `results/tables`, `results/mat` — generated outputs.
- `appendix_code/` — compact thesis-appendix version of the core equations.

## How to run

```matlab
cd chapter4_sx_sim
run_all_chapter4
```

Core calculations require only base MATLAB syntax compatible with MATLAB R2022b. Optional `satelliteScenario` support may use Satellite Communications Toolbox or Aerospace Toolbox. Optional reflector visualizations use Antenna Toolbox if available. Simulink, STK, Communications Toolbox, GNU Radio, and SDR hardware are not required.

## Fallback behavior

If `satelliteScenario` is unavailable, unlicensed, returns invalid data, or finds no pass, the code uses a deterministic synthetic representative LEO pass. That fallback is labeled as synthetic and must not be presented as precise orbital propagation. Antenna Toolbox failures do not stop the core run; analytical dish gain and beamwidth remain the core antenna analysis.

## Generated outputs

The run creates receiver-noise, dish-trade, pointing-loss, pass-geometry, Doppler, dynamic-link, data-budget, component-selection, and BOM CSV files; thesis-ready PNG/PDF figures; `results/mat/chapter4_results.mat`; and `results/chapter4_simulation_summary.txt`.

## Assumptions to edit first

Review station coordinates, orbit, transmit power and spacecraft antenna gain, receiver LNA/LNB gain and noise figure, losses before the first active device, dish diameter and efficiency, antenna temperature, environmental losses, data rate, required `(E_b/N_0)`, and number of passes per day.

## Link-budget reference plane

The dynamic link budget calculates received carrier power at the antenna-feed/receiver-input reference plane. Receiver equivalent noise temperature is computed from a Friis cascade that already includes loss before the LNA/LNB, active-device noise, and loss after the LNA/LNB. Therefore those receiver losses are **not subtracted again** from carrier power; they degrade the link through the system noise temperature.

## Limitations

These are preliminary design simulations based on simplified assumptions and datasheet-level values. They are not experimental verification of a constructed S-band or X-band station. Transmitter values are representative assumptions for analysis, not a transmitter hardware design. Component-selection and BOM CSV files are editable worksheets and not final procurement selections; commercial model fields are intentionally `TBD`.
