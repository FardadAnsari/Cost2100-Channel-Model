# 8×8 Numerical Example — Three Paths (Sparse in Delay)

This README summarizes a small sanity‑check example for an **8×8** setup with three propagation paths. We predict where the bright points (peaks) should appear in the **delay–angle DFT** domain.

## Problem Setup

- Fix: \(A = T = 8\), element spacing \(d = \lambda/2\) (no grating lobes).
- Three paths with delay \(\tau\), angle \(\theta\), and complex gain \(\alpha\) (polar form).

| Path | \(\tau\) | \(\theta\) | \(\alpha\) |
|:---:|:---:|:---:|:---:|
| 1 | 2 | \(20^\circ\) | \(1\angle 20^\circ\) |
| 2 | 5 | \(-35^\circ\) | \(0.7\angle (-50^\circ)\) |
| 3 | 7 | \(0^\circ\) | \(0.4\angle 10^\circ\) |

> Interpretation tip: \(A\) can be read as the spatial DFT size (e.g., number of array elements across one dimension), and \(T\) as the temporal/lag DFT size.

## Predicting the DFT Peak Bins (Sanity Check)

With \(d/\lambda = 1/2\), the signed spatial DFT bin index \(k_{\mathrm{sh}}\) is predicted by

\[
k_{\mathrm{sh}} \approx A\,\frac{d}{\lambda}\,\sin\theta
= 8 \times \tfrac12 \sin\theta
= 4\,\sin\theta.
\]

Evaluations:

- For \(\theta_1 = 20^\circ\): \(4\sin 20^\circ \approx 4\times 0.342 = 1.37 \Rightarrow k_{\mathrm{sh}} = +1\).
- For \(\theta_2 = -35^\circ\): \(4\sin(-35^\circ) \approx 4\times (-0.574) = -2.30 \Rightarrow k_{\mathrm{sh}} = -2\).
- For \(\theta_3 = 0^\circ\): \(\sin 0 = 0 \Rightarrow k_{\mathrm{sh}} = 0\).

## Expected Bright Points

We therefore expect peaks near the following **(delay, signed‑bin)** coordinates:

- \((\tau=2,\; k_{\mathrm{sh}}=+1)\)
- \((\tau=5,\; k_{\mathrm{sh}}=-2)\)
- \((\tau=7,\; k_{\mathrm{sh}}=0)\)

These locations serve as a quick check against any simulation or processing pipeline that produces a delay–angle map (e.g., 2‑D DFT/beamspace).

---

### How to Use in Your Repo

- Place this README at the root of the project or inside the example’s folder.
- If you have code that generates the delay–angle spectrum, you can reference this section to verify the peak locations against your output.

### License

Add your preferred license here (MIT, Apache‑2.0, etc.).
