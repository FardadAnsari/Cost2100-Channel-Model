%% cost2100_steering_demo.m (4-figure version)
% COST2100 -> IR -> 4 views with proper index/axis configs
clear; close all; clc;
rng(2025);

%% ------------ 1) Scenario ------------
Network    = 'SemiUrban_VLA_2_6GHz';
scenario   = 'LOS';
freq       = [2.57e9 2.62e9];        % Hz (f_start, f_stop)
snapRate   = 1;
snapNum    = 1;
BSPosCenter  = [0 0 0];
BSPosSpacing = [0.0577 0 0];          % ~ lambda/2 around 2.6 GHz
BSPosNum     = 32;                    % # BS elements
MSPos        = [30 0 1.5];
MSVelo       = [0 0 0];

%% ------------ 2) Run COST2100 ------------
[paraEx, paraSt, link, env] = cost2100( ...
    Network, scenario, freq, snapRate, snapNum, ...
    BSPosCenter, BSPosSpacing, BSPosNum, MSPos, MSVelo);

%% ------------ 3) Build IR (Delay×Ant) and FFT to freq ------------
delta_f = (freq(2)-freq(1))/1024;             % frequency sampling for IR builder
link_use = link(1,1);                          % single link: BS#1–MS#1
ir_vla   = create_IR_omni_MIMO_VLA(link_use, freq, delta_f, 'Wideband');
% Expected dims: [snapshot × delay × ms × bsAnt]
sz_ir = size(ir_vla);
fprintf('ir_vla size = [snap=%d, delay=%d, user=%d, ant=%d]\n', sz_ir(1), sz_ir(2), sz_ir(3), sz_ir(4));

% Select one snapshot & user, keep 2D [Delay × Ant]
snap_idx = 1; user_idx = 1;
h_da = squeeze(ir_vla(snap_idx, :, user_idx, :));   % [DelayTaps × A]
[DelayTaps, A] = size(h_da);
fprintf('h_da (Delay×Ant) size = [%d × %d]\n', DelayTaps, A);

% Physical constants for angle mapping
c = 3e8; fc = mean(freq); lambda = c/fc;
if numel(BSPosSpacing) > 1, d = BSPosSpacing(1); else, d = BSPosSpacing; end

% Frequency axis for later (after delay FFT)
Nf = 256;                                   % FFT length on delay
f_axis = linspace(freq(1), freq(2), Nf);    % Hz

%% ========== FIGURE 1: Spatial–Delay (create_IR output) ==========
% Power in dB over Delay (rows) × Antenna (cols)
P_da_dB = 10*log10(abs(h_da).^2 + eps);
figure('Name','Fig1: Spatial–Delay (IR)');
imagesc(1:A, 0:DelayTaps-1, P_da_dB); axis xy;
xlabel('BS antenna index (n)'); ylabel('Delay tap (\tau index)');
title('Fig 1 — Spatial–Delay: 10log10(|h(\tau,n)|^2 + \epsilon)');
colorbar; colormap gray;

%% ========== FIGURE 2: Angular–Delay (spatial FFT over antennas) ==========
% FFT across antenna dimension (columns) -> spatial frequency bins
H_ang_delay = fftshift(fft(h_da, [], 2), 2);    % [DelayTaps × A]
% Spatial-frequency bins after shift:
k_bins = (-floor(A/2):ceil(A/2)-1);             % length A
sf_norm = k_bins / A;                           % cycles/element
sin_theta = sf_norm * (lambda/d);
sin_theta = max(min(sin_theta,1),-1);           % clamp
theta_deg = asind(sin_theta);                   % deg

fprintf('Angular–Delay: fft along antennas, A=%d\n', A);
fprintf('k bins (fftshifted): [%s]\n', num2str(k_bins));
fprintf('theta range [deg]: [%.1f .. %.1f]\n', theta_deg(1), theta_deg(end));

P_ad_dB = abs(H_ang_delay+ eps);
%size(H_ang_delay)
figure('Name','Fig2: Angular–Delay');
imagesc(theta_deg, 0:DelayTaps-1, P_ad_dB); axis xy;
xlabel('Angle of arrival \theta (deg)'); ylabel('Delay tap (\tau index)');
title('Fig 2 — Angular–Delay: 10log10(|\tilde{H}(\theta,\tau)|^2 + \epsilon)');
colorbar; colormap jet;
%% Save Angular–Delay matrix to .mat file
save('H_ang_delay.mat', 'H_ang_delay', 'theta_deg');
fprintf('Saved H_ang_delay [%d×%d] and theta_deg [%d]\n', ...
    size(H_ang_delay,1), size(H_ang_delay,2), numel(theta_deg));

%% Prepare: Delay FFT -> Frequency (will be used in Fig3 & Fig4)
H_fa = fft(h_da, Nf, 1);                      % FFT along delay -> [Nf × A]
fprintf('Delay FFT (Nf=%d): frequency axis = linspace(%.2f MHz, %.2f MHz, %d)\n', ...
        Nf, f_axis(1)*1e-6, f_axis(end)*1e-6, Nf);

%% ========== FIGURE 3: Angular–Frequency ==========
% Then spatial FFT across antennas on H_fa
H_ang_freq = fftshift(fft(H_fa, [], 2), 2);    % [Nf × A]
% Angle axis identical mapping (A, d, lambda)
% (theta_deg already computed; reuse)
fprintf('Angular–Frequency: spatial fft along antennas (A=%d), same theta bins reused.\n', A);

P_af_dB = 20*log10(abs(H_ang_freq) + eps);
figure('Name','Fig3: Angular–Frequency');
imagesc(theta_deg, f_axis*1e-6, P_af_dB); axis xy;
xlabel('Angle of arrival \theta (deg)'); ylabel('Frequency [MHz]');
title('Fig 3 — Angular–Frequency: 20log10(|\tilde{H}(\theta,f)| + \epsilon)');
colorbar; colormap jet;

%% ========== FIGURE 4: Spatial–Frequency (no spatial FFT) ==========
% Just the delay FFT result H_fa (freq × antenna)
P_sf_dB = 20*log10(abs(H_fa) + eps);
figure('Name','Fig4: Spatial–Frequency');
imagesc(1:A, f_axis*1e-6, P_sf_dB); axis xy;
xlabel('BS antenna index (n)'); ylabel('Frequency [MHz]');
title('Fig 4 — Spatial–Frequency: 20log10(|H(f,n)| + \epsilon)');
colorbar; colormap gray;

%% End (exactly 4 figures produced)
fprintf('Done. Produced 4 figures: Spatial–Delay, Angular–Delay, Angular–Frequency, Spatial–Frequency.\n');
