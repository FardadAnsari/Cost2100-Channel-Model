# Flat Fading with COST2100 — README (Mathematical Form)

This guide derives and documents a **flat‑fading (narrowband)** channel built from the **COST2100** wideband model. All key relations are stated as mathematical formulas (not code) and mapped to where the script `demo_flat_siso_single_tone.m` implements them.

---

## 1) Definition and assumptions

A wireless channel is **flat (frequency‑nonselective)** over bandwidth $B$ if

$$
B \ll B_c, \qquad \text{(coherence bandwidth)}
$$

so that all frequencies inside the band experience (approximately) the **same complex gain**. In baseband complex form the input–output relation is

$$
\boxed{\; y(t) \,=\, h(t)\,x(t) + n(t) \;}
$$

with
- $x(t)$: transmitted waveform (bandwidth $B$),
- $h(t)\in\mathbb C$: **single** complex fading coefficient varying in time (mobility),
- $n(t)$: additive noise.

In rich NLOS scattering, $h(t)$ is **circularly symmetric complex Gaussian**, hence the envelope $|h(t)|$ is **Rayleigh**; with a LOS component it is **Rician**.

---

## 2) From COST2100 (tapped delay line) to a flat coefficient

COST2100 generates a **snapshot‑indexed impulse response** $h[n,\ell]$ (time snapshot $n=0,\dots,N\!-
1$; delay tap $\ell=0,\dots,L\!-
1$). Its **frequency response** on discrete frequency bin $k=0,\dots,K\!-
1$ is the DFT across delay:

$$
H[n,k] \,=\, \sum_{\ell=0}^{L-1} h[n,\ell] \, e^{-j\,2\pi \frac{k\ell}{K}}.
\tag{1}
$$

To obtain a **narrowband (flat) channel per snapshot**, select a single bin $k_c$ (e.g., the center bin) or average a tiny symmetric set $\mathcal K$ of bins around it:

$$
\boxed{\; h_{\text{flat}}[n] \,=\, H[n,k_c] \quad\text{or}\quad h_{\text{flat}}[n] \,=\, \frac{1}{|\mathcal K|}\sum_{k\in\mathcal K} H[n,k] \;}.
\tag{2}
$$

A convenient **unit‑power normalization** is

$$
\boxed{\; \tilde h_{\text{flat}}[n] \,=\, \frac{h_{\text{flat}}[n]}{\sqrt{\,\mathbb E\{|h_{\text{flat}}|^2\}\,}} \;},
\tag{3}
$$
so that $\mathbb E\{|\tilde h_{\text{flat}}|^2\}=1$.

**Frequency‑flatness check.** For a tiny band, adjacent bins should be close:

$$
\eta \;=\; \frac{\,\big\langle\,|H[n,k_c\!+\!1]-H[n,k_c\! -\!1]|\,\big\rangle_n\,}{\,\big\langle\,|H[n,k_c]|\,\big\rangle_n\,} \;\ll\; 1.
\tag{4}
$$

---

## 3) Temporal statistics and Doppler

For a terminal speed $v$ and carrier frequency $f_c$, the **wavelength** is $\lambda=\tfrac{c}{f_c}$ and the **maximum Doppler** is

$$
\boxed{\; f_D \,=\, \frac{v}{\lambda} \,=\, \frac{v f_c}{c} \;}.
\tag{5}
$$

If a multipath component arrives at angle $\theta$ relative to the motion direction, its Doppler is

$$
 f_d(\theta) \,=\, f_D\cos\theta.
\tag{6}
$$

Under Clarke/Jakes’ **isotropic** scattering, the **Doppler power spectral density** (PSD) of $h(t)$ is

$$
\boxed{\; S_h(f) \,=\, \frac{1}{\pi f_D\sqrt{\,1-(f/f_D)^2\,}}\,\mathbb 1_{\{|f|< f_D\}} \;}.
\tag{7}
$$

The corresponding **autocorrelation** is the Bessel form

$$
\boxed{\; R_h(\tau) \,=\, \mathbb E\{h(t) h^*(t+\tau)\} \,=\, J_0\!\left(2\pi f_D\tau\right) \;}.
\tag{8}
$$

---

## 4) Envelope distributions

- **Rayleigh (no LOS):** if $h\sim\mathcal{CN}(0,\sigma^2)$, then $r=|h|$ has pdf
  $$
  f_{\text{Rayleigh}}(r) \,=\, \frac{r}{\sigma^2}\,e^{-\tfrac{r^2}{2\sigma^2}}, \qquad r\ge 0.
  \tag{9}
  $$
- **Rician (with LOS):** with LOS amplitude $s\ge 0$ and diffuse variance $\sigma^2$,
  $$
  f_{\text{Rician}}(r) \,=\, \frac{r}{\sigma^2} \, \exp\!\Big(\!-\frac{r^2+s^2}{2\sigma^2}\Big) \, I_0\!\Big( \frac{r s}{\sigma^2} \Big), \quad r\ge 0,
  \tag{10}
  $$
  where $I_0(\cdot)$ is the modified Bessel function and the **$K$‑factor** is $K=\tfrac{s^2}{2\sigma^2}$.

---

## 5) Mapping formulas to the script

The script `demo_flat_siso_single_tone.m` implements the equations as follows:

- **(1)** The FFT across delay to obtain $H[n,k]$.
- **(2)** Picking the center bin $k_c$ (or averaging a tiny set $\mathcal K$) to define $h_{\text{flat}}[n]$.
- **(3)** Optional normalization to unit average power.
- **(4)** A numerical proxy of $\eta$ to confirm frequency flatness across adjacent bins.
- **(5)–(8)** Doppler theory vs. practice: the script estimates the Doppler PSD of $\{h_{\text{flat}}[n]\}$ and reports $f_D$ predicted by $v$ and $f_c$.
- **(9)–(10)** Envelope histogram lets you visually compare with Rayleigh/Rician behavior depending on the presence of LOS.

---

## 6) Recommended settings for a clean flat‑fading run

- **Bandwidth:** choose a tiny $B$ around $f_c$ (e.g., $B=1\,\text{kHz}$) to ensure $B\ll B_c$.
- **Bin selection:** set $k_c$ to the **center** subcarrier; optionally average 3–5 bins symmetrically (use (2)).
- **Mobility:** set a speed $v$ and direction; the theoretical Doppler bound is (5).
- **Sampling:** increase snapshot rate and count to resolve the PSD support $|f|\le f_D$.

---

## 7) Quick reference (all in math)

- **Baseband flat model:** $\;y(t)=h(t)x(t)+n(t)$.
- **Wideband→FD:** $\;H[n,k]=\sum_{\ell} h[n,\ell] e^{-j2\pi k\ell/K}$.
- **Flat reduction:** $\;h_{\text{flat}}[n]=H[n,k_c]$ or averaged over $\mathcal K$.
- **Normalization:** $\;\tilde h= h/\sqrt{\mathbb E\{|h|^2\}}$.
- **Flatness metric:** $\;\eta = \big\langle |H[n,k_c\!+\!1]-H[n,k_c\! -\!1]| \big\rangle / \big\langle |H[n,k_c]| \big\rangle$.
- **Max Doppler:** $\;f_D=v/\lambda= v f_c/c$.
- **Jakes PSD:** $\;S_h(f)=\big(\pi f_D\sqrt{1-(f/f_D)^2}\big)^{-1}\,\mathbb 1_{\{|f|< f_D\}}$.
- **Autocorrelation:** $\;R_h(\tau)=J_0(2\pi f_D\tau)$.
- **Rayleigh pdf:** $\;f(r)= (r/\sigma^2)\,e^{-r^2/(2\sigma^2)}$.
- **Rician pdf:** $\;f(r)= (r/\sigma^2) e^{-(r^2+s^2)/(2\sigma^2)} I_0(rs/\sigma^2)$.

---

## 8) Practical checklist

1. **Flatness:** verify (4) is small.
2. **Static user ($v=0$):** $\operatorname{var}(|h|)$ is near zero.
3. **Moving user ($v>0$):** the estimated PSD support lies in $|f|\lesssim f_D$ from (5).
4. **Envelope:** histogram resembles Rayleigh (NLOS) or Rician (LOS) per (9)–(10).

---

**That’s it.** The equations above are the mathematical ground truth; the script is merely their numerical realization.

