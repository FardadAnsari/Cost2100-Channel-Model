# Flat Fading with COST2100 — README

This guide shows how to generate and analyze a **flat-fading (narrowband)** wireless channel using the **COST2100** model. It accompanies the MATLAB script `demo_flat_siso_single_tone.m` and explains the assumptions, equations, how to run, and what to verify (envelope statistics and Doppler spectrum).

---

## 1) What is “flat fading”?

A channel is **flat** (a.k.a. **frequency-nonselective**) when its **coherence bandwidth** \(B_c\) is greater than the signal bandwidth \(B\):

\$$
B \ll B_c \quad \Longleftrightarrow \quad \text{no significant frequency selectivity across } B.
\$$

In baseband complex notation, the received signal is

\$$
\boxed{\; y(t) = h(t)\,x(t) + n(t) \;}
\$$

where
- \(x(t)\) is the transmitted waveform (bandwidth \(B\)),
- \(h(t)\in\mathbb{C}\) is a **single complex Gaussian** channel gain that **varies in time** (due to mobility),
- \(n(t)\) is additive noise.

When there is no dominant LOS component, \(|h(t)|\) is **Rayleigh**-distributed; with LOS, it is **Rician**.

---

## 2) Time variation & Doppler

With a terminal moving at speed \(v\) and carrier frequency \(f_c\), the **maximum Doppler shift** is

\$$
\boxed{\; f_D = \frac{v}{\lambda} = \frac{v f_c}{c}\;,}\qquad \lambda=\frac{c}{f_c}.
\$$

For motion with angle \(\theta\) relative to the arrival direction, the **instantaneous** Doppler of a path is \(f_{d}(\theta)=f_D\cos\theta\). In Clarke/Jakes’ isotropic model, the Doppler power spectral density (PSD) is

\$$
S_h(f) = \frac{1}{\pi f_D\sqrt{1-(f/f_D)^2}}\;\mathbf{1}_{\{|f|< f_D\}}.
\$$

In practice we **estimate** the Doppler PSD from a time sequence of channel samples.

---

## 3) From COST2100 to a flat channel

COST2100 returns a **wideband** channel impulse response (IR) per snapshot. Let \(h$$n,\ell$$\) be the discrete-time IR at snapshot \(n\) and delay-tap \(\ell\). Its FFT w.r.t. delay yields the frequency response \(H$$n,k$$\) on subcarrier/bin \(k\):

\$$
H$$n,k$$ \,=\, \sum_{\ell} h$$n,\ell$$\,e^{-j2\pi k\ell/K}.
\$$

To obtain a **flat-fading** coefficient per snapshot, we

- **pick the center bin** \(k_c\) (or **average a few bins** around it if desired) and define

\$$
\boxed{\; h_{\text{flat}}$$n$$ = H$$n,k_c$$ \quad \text{(or)}\quad h_{\text{flat}}$$n$$ = \tfrac{1}{|\mathcal{K}|}\sum_{k\in\mathcal{K}} H$$n,k$$ \;,\;}
\$$

- optionally **normalize** to unit average power: \( h_{\text{flat}}$$n$$ \leftarrow h_{\text{flat}}$$n$$/\sqrt{\mathbb{E}$$|h_{\text{flat}}|^2$$} \).

This produces a **single complex coefficient per snapshot**, i.e., a **narrowband** time-varying channel.

---

## 4) Script you run

Use the provided MATLAB script:

**`demo_flat_siso_single_tone.m`**

Key knobs near the top:

- `fc` — carrier frequency (Hz)
- `BW` — tiny bandwidth around `fc` (e.g., `1e3` for 1 kHz)
- `snapRate`, `snapNum` — snapshots per second and total count
- **Mobility:**
  - `v_mps` — speed in m/s (set `0` for static)
  - `v_az_deg` — motion direction (degrees)

The script:
1. Calls **COST2100** with `SISO_omni`, Single link, `LOS`.
2. Builds the SISO **impulse response per snapshot**, FFTs across delay to get \(H$$n,k$$\).
3. **Collapses** to a single bin → \(h_{\text{flat}}$$n$$\).
4. Plots:
   - Envelope \(|h_{\text{flat}}$$n$$|\) vs time.
   - Envelope histogram (for \(v=0\), it degenerates to a spike; for \(v>0\), it spreads).
   - **Doppler PSD** with reported theoretical \(f_D\) and the estimated peak.

---

## 5) Validation checklist

1. **Flatness across the tiny band**: Adjacent-bin difference should be small
\$$
\frac{\langle |H$$n,k_c\!+\!1$$-H$$n,k_c\! -\!1$$|\rangle}{\langle |H$$n,k_c$$|\rangle} \;\text{is small.}
\$$
2. **Time invariance at \(v=0\)**: \(\operatorname{var}(|h_{\text{flat}}|)\) nearly zero.
3. **Doppler peak near \(f_D\)** for \(v>0\): estimated PSD shows support \(|f|\lesssim f_D\).
4. **Envelope statistics**: With rich scattering & no LOS, \(|h|\) ≈ **Rayleigh**; with LOS, **Rician**.

---

## 6) Troubleshooting & tips

- If the channel still looks frequency-selective, **reduce** `BW` or **average** a few bins around \(k_c\).
- Increase `snapRate` and `snapNum` for a **cleaner Doppler PSD**.
- To emulate a pure statistical flat channel (no COST2100 geometry), use a **Jakes/Clarke sum-of-sinusoids** generator; in this project, see the `slim_demo_flat` function (optional).
- For **MIMO**, collapse each \(\mathrm{Rx}\times\mathrm{Tx}\) entry independently to obtain \(H_{\text{flat}}$$n$$\in\mathbb{C}^{N_r\times N_t}\).

---

## 7) Quick reference formulas

- **Flat-fading baseband model**: \( y(t)=h(t)\,x(t)+n(t) \).
- **Max Doppler**: \( f_D=v/\lambda=v f_c/c \).
- **Doppler PSD (Jakes)**: \( S_h(f)=\big(\pi f_D\sqrt{1-(f/f_D)^2}\big)^{-1}\mathbf{1}_{\{|f|<f_D\}} \).
- **Frequency response from taps**: \( H$$n,k$$=\sum_{\ell} h$$n,\ell$$ e^{-j2\pi k\ell/K} \).
- **Flat reduction**: \( h_{\text{flat}}$$n$$=H$$n,k_c$$ \) or averaged over a tiny set \(\mathcal{K}\).

---

## 8) Minimal example (pseudo-MATLAB)

```matlab
% Build IR per snapshot using COST2100 helpers
h_snap = create_IR_omni(link, freq, delta_f, 'Wideband');  % $$snap x delay$$
H_snap = fft(h_snap, $$$$, 2);                               % $$snap x K$$

% Collapse to flat
kc     = round((size(H_snap,2)+1)/2);
h_flat = H_snap(:, kc);                    % $$snap x 1$$
h_flat = h_flat ./ sqrt(mean(abs(h_flat).^2));

% Doppler PSD
$$PSD,faxis$$ = periodogram(h_flat, $$$$, 4096, snapRate, 'centered');
```

---

## 9) Citations (when you publish)

- L. Liu *et al.*, “The COST 2100 MIMO channel model,” *IEEE Wireless Commun.*, 2012.
- W. C. Jakes, *Microwave Mobile Communications*, Wiley, 1974.

---

**Happy simulating!** Tweak `v_mps`, `BW`, and `snapRate` to explore how time selectivity and frequency selectivity interact. 

