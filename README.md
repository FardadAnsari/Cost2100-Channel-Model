# 8×8 Numerical Example — Three Paths (Sparse in Delay)

This note records a small **sanity check** for an \(8\times8\) setup with three propagation paths and predicts where the **delay–angle DFT** should exhibit bright peaks.

---

## Setup
``` latex 
- Array / DFT sizes: \(A = T = 8\)
- Element spacing: \(d = \lambda/2\)  (no grating lobes)
- Each path is specified by delay \(\tau\), angle \(\theta\), and complex gain \(\alpha\) (polar form)

| Path | \(\tau\) | \(\theta\) | \(\alpha\) |
|:---:|:---:|:---:|:---:|
| 1 | 2 | \(20^\circ\)  | \(1\angle 20^\circ\) |
| 2 | 5 | \(-35^\circ\) | \(0.7\angle (-50^\circ)\) |
| 3 | 7 | \(0^\circ\)   | \(0.4\angle 10^\circ\) |

> Interpretation: \(A\) is the spatial DFT size (e.g., number of array elements along one dimension) and \(T\) the lag/temporal DFT size.
```
---

## Predicting the Spatial DFT Bin
``` latex
With \(d/\lambda = \tfrac12\), the **signed** spatial DFT bin index \(k_{\mathrm{sh}}\) for a plane wave at angle \(\theta\) satisfies
\[
\begin{aligned}
k_{\mathrm{sh}}
&\approx A\,\frac{d}{\lambda}\,\sin\theta \\[2pt]
&= 8\cdot \tfrac12\,\sin\theta \\[2pt]
&= 4\,\sin\theta.
\end{aligned}
\]
```
Numerical evaluations (rounded to the nearest integer bin):
``` latex
\[
\begin{aligned}
\theta_1&=20^\circ: && 4\sin 20^\circ \approx 4\times 0.3420 = 1.368 \;\Rightarrow\; k_{\mathrm{sh}}=+1,\\
\theta_2&=-35^\circ: && 4\sin (-35^\circ) \approx 4\times(-0.5736) = -2.294 \;\Rightarrow\; k_{\mathrm{sh}}=-2,\\
\theta_3&=0^\circ: && 4\sin 0^\circ = 0 \;\Rightarrow\; k_{\mathrm{sh}}=0.
\end{aligned}
\]
```
---

## Expected Bright Points in \((\tau,k_{\mathrm{sh}})\)
``` latex
\[
(\tau,k_{\mathrm{sh}})\in \{(2,+1),\; (5,-2),\; (7,0)\}.
\]
```
These serve as quick checkpoints for any implementation that generates a delay–angle map (e.g., 2‑D DFT/beamspace).

---

### Notes
``` latex 
- Angles follow the broadside convention for \(\sin\theta\).
- You can validate these locations against your simulated spectrum by marking the predicted bins and ensuring peak energy aligns accordingly.
```
### License
Add your preferred license (MIT, Apache‑2.0, etc.).
