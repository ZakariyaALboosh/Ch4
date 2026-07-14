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


## Plug-and-play thesis figure workflow

1. Open MATLAB R2022b.
2. Change directory to `chapter4_sx_sim`.
3. Run `run_all_chapter4`.
4. Confirm that `validate_chapter4_outputs` reports that all required Chapter 4 MATLAB figures exist and are non-empty.
5. Copy or upload `results/overleaf_figures` to Overleaf. The folder contains every generated `fig4_*.png` and a `figure_manifest.csv` describing the source for each figure.
6. Compile `main.tex`, which uses `\graphicspath{{chapter4_sx_sim/results/overleaf_figures/}}` when built from the repository root.

The one-command run deletes stale required thesis PNG/PDF outputs before regenerating them, then validates and packages the Overleaf folder automatically. The MATLAB-generated figures required by Chapter 4 are listed in `src/chapter4_required_figures.m`; manual diagrams such as `designworkflow.png` are copied into the package only when already present and are not fabricated by the simulation.

## Optional toolbox behavior

- `satelliteScenario` support is used when available to propagate the orbit, ground track, access mask, and selected pass. If it is unavailable, unlicensed, or no visible pass is found, the run uses a deterministic synthetic representative LEO pass and labels the orbit/access figures as synthetic representative results rather than precise pass predictions.
- Antenna Toolbox is used when available for reflector geometry and pattern exports. If the toolbox is unavailable or reflector simulation fails, the run creates explicitly labelled analytical approximation figures based on the calculated dish gain and HPBW; these are not presented as full-wave EM simulations.
- Simulink, STK, GNU Radio, Communications Toolbox, SDR hardware, and manual interaction are not required.

## Generated outputs

The run creates receiver-noise, dish-trade, pointing-loss, pass-geometry, Doppler, dynamic-link, data-budget, component-selection, and BOM CSV files; thesis-ready PNG/PDF figures; `results/mat/chapter4_results.mat`; and `results/chapter4_simulation_summary.txt`.

## Assumptions to edit first

Review station coordinates, orbit, transmit power and spacecraft antenna gain, receiver LNA/LNB gain and noise figure, losses before the first active device, dish diameter and efficiency, antenna temperature, environmental losses, data rate, required `(E_b/N_0)`, and number of passes per day.

## Link-budget reference plane

The dynamic link budget calculates received carrier power at the antenna-feed/receiver-input reference plane. Receiver equivalent noise temperature is computed from a Friis cascade that already includes loss before the LNA/LNB, active-device noise, and loss after the LNA/LNB. Therefore those receiver losses are **not subtracted again** from carrier power; they degrade the link through the system noise temperature.

## Limitations

These are preliminary design simulations based on simplified assumptions and datasheet-level values. They are not experimental verification of a constructed S-band or X-band station. Transmitter values are representative assumptions for analysis, not a transmitter hardware design. Component-selection and BOM CSV files are editable worksheets and not final procurement selections; commercial model fields are intentionally `TBD`.
