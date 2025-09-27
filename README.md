# Flat Fading with COST2100 — README (Explanations Only)

This guide explains, in plain language, how to produce and verify a **flat‑fading (narrowband)** channel from the COST2100 model. All math has been removed; the focus is on concepts and practical steps.

---

## 1) What “flat fading” means

- A channel is **flat** when your signal bandwidth is small enough that all frequencies in the band experience the **same** channel gain.
- In this case, the channel can be treated as a **single complex number that changes over time** (because of motion). This is much simpler than a frequency‑selective channel with many taps.

---

## 2) How we get flat fading from COST2100

COST2100 builds a **wideband** channel (many delay taps). We convert that to flat fading by:

1. Generating the channel impulse response for each snapshot (time step).
2. Converting each snapshot to a frequency response across many closely‑spaced frequency bins.
3. **Picking one bin at the center** of the band (or averaging a few bins around it). That single complex value per snapshot is our **flat‑fading coefficient**.
4. Optionally normalizing so the average power is one (handy for comparisons).

Result: a sequence of complex numbers over time — your flat channel.

---

## 3) What controls the time variation

- **User speed and direction**: faster movement causes quicker fluctuations in the channel.
- **Carrier frequency**: higher carrier means faster fluctuations for the same speed.
- **Scattering environment**: with a clear line‑of‑sight (LOS) the envelope varies less; in rich scattering it varies more.

In our script you can set the speed and heading; the figures will show you how fast the channel changes.

---

## 4) What the script does

Script: `demo_flat_siso_single_tone.m`

- **Scenario**: single user, one BS antenna and one MS antenna (SISO), either static or moving.
- **Bandwidth**: extremely small (for example, 1 kHz around the carrier) so the channel is effectively flat.
- **Steps**:
  - Calls COST2100 to generate wideband snapshots.
  - Converts to frequency response per snapshot.
  - Picks the center bin to form a single complex value per snapshot (flat channel).
  - Normalizes (optional) and plots:
    - Envelope vs. time (magnitude of the complex channel).
    - Histogram of the envelope (helps see LOS vs. rich scattering behavior).
    - A simple spectrum view that shows how quickly the channel fluctuates in time.

**Output**: a vector called `h_flat` — one complex value per snapshot.

---

## 5) How to run

1. Put the script in the same folder as the official COST2100 functions (or add that folder to your MATLAB path).
2. Open the script and adjust these knobs near the top:
   - `fc` (carrier), `BW` (tiny bandwidth), `snapRate`, `snapNum`.
   - Mobility: `v_mps` (speed) and `v_az_deg` (heading). Set speed to 0 for a static user.
3. Run the script. Inspect the plots and the `h_flat` variable.

---

## 6) What to check to be confident it’s really flat

- **Across frequency**: values in nearby frequency bins look almost the same. If they don’t, reduce the bandwidth further or average a few bins.
- **Over time**:
  - With **zero speed**, the envelope should be almost constant.
  - With **non‑zero speed**, the envelope fluctuates; faster speed → faster fluctuations.
- **Envelope shape**:
  - With a strong LOS component, the envelope clusters around a nonzero level (narrow distribution).
  - In rich scattering without LOS, the envelope spreads more (broader distribution).

---

## 7) Troubleshooting

- **Looks frequency‑selective**: narrow the bandwidth or average 3–5 bins around the center.
- **Fluctuations are too slow**: increase the snapshot rate or increase speed.
- **Plots are noisy**: run longer (more snapshots) or smooth/average more bins.
- **Nothing changes over time**: make sure speed is not zero and the motion direction is sensible.

---

## 8) Extending beyond SISO

- For **MIMO**, repeat the same reduction for each receive–transmit antenna pair to get a flat channel matrix per snapshot.
- You can then study spatial properties (rank, conditioning) while still staying in the flat‑fading regime.

---

## 9) Files in this project

- `demo_flat_siso_single_tone.m` — the runnable demo with mobility controls and plots.
- (Optional) a short “slim” generator that produces a statistical flat channel without geometry, useful for sanity checks.

---

## 10) Summary

- COST2100 gives you a realistic wideband channel.
- By selecting a single frequency bin (or a tiny average) per snapshot, you get a **flat‑fading** time series.
- Control speed and snapshot rate to explore how the channel changes over time.
- Validate by checking near‑identical behavior across nearby frequencies and sensible time‑variation with speed.

