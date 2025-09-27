# 8×8 Numerical Example — Three Paths (Sparse in Delay)

This note records a small **sanity check** for an 8×8 setup with three propagation paths and predicts where the **delay–angle DFT** should exhibit bright peaks.

---

## Setup

- Array / DFT sizes: A = T = 8  
- Element spacing: d = λ/2  (no grating lobes)  
- Each path is specified by delay τ, angle θ, and complex gain α (polar form).

| Path | τ | θ | α |
|:---:|:---:|:---:|:---:|
| 1 | 2 | 20°  | 1∠20° |
| 2 | 5 | −35° | 0.7∠−50° |
| 3 | 7 | 0°   | 0.4∠10° |

> Interpretation: A is the spatial DFT size (e.g., number of array elements along one dimension) and T the lag/temporal DFT size.

---

## Predicting the Spatial DFT Bin

With $d/\lambda = \tfrac{1}{2}$, the **signed** spatial DFT bin index $k_{\mathrm{sh}}$ for a plane wave at angle $\theta$ satisfies

$$
\begin{aligned}
k_{\mathrm{sh}}
&\approx A\,\frac{d}{\lambda}\,\sin\theta \\
&= 8\cdot \tfrac{1}{2}\,\sin\theta \\
&= 4\,\sin\theta.
\end{aligned}
$$

Numerical evaluations (rounded to the nearest integer bin):

$$
\begin{aligned}
\theta_1&=20^\circ: && 4\sin 20^\circ \approx 4\times 0.3420 = 1.368 \;\Rightarrow\; k_{\mathrm{sh}}=+1,\\
\theta_2&=-35^\circ: && 4\sin (-35^\circ) \approx 4\times(-0.5736) = -2.294 \;\Rightarrow\; k_{\mathrm{sh}}=-2,\\
\theta_3&=0^\circ: && 4\sin 0^\circ = 0 \;\Rightarrow\; k_{\mathrm{sh}}=0.
\end{aligned}
$$

---

## Expected Bright Points in $(\tau,k_{\mathrm{sh}})$

$\{(\tau,k_{\mathrm{sh}}) : (2,+1),\; (5,-2),\; (7,0)\}$

These serve as quick checkpoints for any implementation that generates a delay–angle map (e.g., 2‑D DFT/beamspace).

---

### Tips if you still see code, not math

- Make sure there are **no backticks** around the formulas and **no leading spaces** that would turn lines into code blocks.  
- Leave a **blank line before and after** each `$$ ... $$` block.  
- GitHub renders math only in Markdown (`.md`) files, not in raw text.  
- Avoid putting LaTeX inside inline code spans like \`$k=4\sin\theta$\`.

### License
Add your preferred license (MIT, Apache-2.0, etc.).
