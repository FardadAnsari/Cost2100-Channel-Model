%% cost2100_steering_demo.m
% تولید کانال با COST2100 و نمایش حوزه زاویه‌ای با استفاده از FFT فضایی
clear; close all; clc;
rng(2025); % بازتولیدپذیری

%% ------------ 1) پارامترهای سناریو ------------
Network    = 'SemiUrban_VLA_2_6GHz'; % سناریوی مثال (VLA)
scenario   = 'LOS';
freq       = [2.57e9 2.62e9];        % Hz (f_start, f_stop)
snapRate   = 1;
snapNum    = 1;                       % برای شروع یک اسنپ‌شات کافیست
% یک BS با آرایه بزرگ (VLA) و یک MS
BSPosCenter  = [0 0 0];
BSPosSpacing = [0.0577 0 0];          % ~lambda/2 برای ~2.6 GHz
BSPosNum     = 32;                   % تعداد المنت‌های BS
MSPos        = [30 0 1.5];            % موقعیت UE
MSVelo       = [0 0 0];

%% ------------ 2) اجرای COST2100 ------------
tic
[paraEx, paraSt, link, env] = cost2100( ...
    Network, scenario, freq, snapRate, snapNum, ...
    BSPosCenter, BSPosSpacing, BSPosNum, MSPos, MSVelo);
toc
disp(link)


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
Nf = 1024;                                   % FFT length on delay
f_axis = linspace(freq(1), freq(2), Nf);    % Hz




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


% Crop delay dimension: e.g. first 32 taps
crop_len = 32;
H_crop = H_ang_delay(1:crop_len, :);    % [32 × A]

% Compute power in dB
P_crop_dB = 10*log10(abs(H_crop).^2 + eps);

% Plot again
figure('Name','Cropped Angular–Delay (32 taps)');
imagesc(theta_deg, 0:crop_len-1, P_crop_dB); axis xy;
xlabel('Angle of arrival \theta (deg)'); ylabel('Delay tap (cropped)');
title(sprintf('Angular–Delay (first %d taps)', crop_len));
colorbar; colormap gray;