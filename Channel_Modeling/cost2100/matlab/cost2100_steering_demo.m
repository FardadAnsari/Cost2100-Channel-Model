%% cost2100_steering_demo.m
% تولید کانال با COST2100 و نمایش حوزه زاویه‌ای با استفاده از FFT فضایی
clear; close all; clc;
rng("default"); % بازتولیدپذیری

%% ------------ 1) پارامترهای سناریو ------------
Network    = 'SemiUrban_VLA_2_6GHz'; % سناریوی مثال (VLA)
scenario   = 'LOS';
freq       = [2.57e9 2.62e9];        % Hz (f_start, f_stop)
snapRate   = 1;
snapNum    = 1;                       % برای شروع یک اسنپ‌شات کافیست
% یک BS با آرایه بزرگ (VLA) و یک MS
BSPosCenter  = [0 0 0];
BSPosSpacing = [0.0577 0 0];          % ~lambda/2 برای ~2.6 GHz
BSPosNum     = 128;                   % تعداد المنت‌های BS
MSPos        = [0.5 0 1.5];            % موقعیت UE
MSVelo       = [0 0 0];

%% ------------ 2) اجرای COST2100 ------------
tic
[paraEx, paraSt, link, env] = cost2100( ...
    Network, scenario, freq, snapRate, snapNum, ...
    BSPosCenter, BSPosSpacing, BSPosNum, MSPos, MSVelo);
toc
disp(link)
%% ------------ 3) ساخت IR و تبدیل به حوزه فرکانس ------------
% از تابع VLA آماده استفاده می‌کنیم (اگر در پکیج تو نیست، به بخش توضیحات نگاه کن)
delta_f = (freq(2)-freq(1))/256;  % طول FFT فرکانسی = 256 (قابل تغییر)
% نکته: ورودی تابع باید لینکِ دقیق باشد: link(BSindex, MSindex)
link_use = link(1,1); % BS #1, MS #1 (ساده‌سازی برای مثال تک-لینک)
disp(link_use)
% create_IR_... احتمالاً خروجی‌اش: [snapshot × delay × ms × bsAnt]
ir_vla = create_IR_omni_MIMO_VLA(link_use, freq, delta_f, 'Wideband'); 
% تبدیل به H در حوزه فرکانس: [snapshot × freq × ms × bsAnt]
%size(ir_vla)
H_vla = fft(ir_vla, [], 2);
%size(H_vla)
%% ------------ 4) انتخاب snapshot / user و تنظیم محورها ------------
snap_idx = 1;
user_idx = 1;
Hfa = squeeze(H_vla(snap_idx, :, user_idx, :));   % اندازه: [F × A]
size(Hfa)
[F, A] = size(Hfa);
 
% محور فرکانس دقیق بر مبنای طول F:
f_axis = linspace(freq(1), freq(2), F); % [Hz]

% محور آنتن (اندیس‌ها)
ant_idx = 1:A;

% مشخصه‌های فیزیکی آرایه برای نگاشت 공간→زاویه
c = 3e8;
fc = mean(freq);
lambda = c/fc;
d = BSPosSpacing(1);   % فاصله بین المنت‌ها به متر

%% ------------ 5) رسم Spatial–Frequency (|H(f,ant)|) ------------
Pfa_dB = 20*log10(abs(Hfa) + eps);

figure('Name','Spatial-Frequency |H(f,ant)|');
imagesc(ant_idx, f_axis*1e-6, Pfa_dB); axis xy;
xlabel('BS antenna index'); ylabel('Frequency [MHz]');
title(sprintf('Spatial–Frequency |H| (snap=%d, user=%d)', snap_idx, user_idx));
colorbar; colormap jet;

%% ------------ 6) تبدیل فضایی → زاویه با FFT فضایی ------------
% FFT روی محور آنتن (ستون‌ها). سپس fftshift برای مرتب‌سازی فرکانس فضایی
Hfa_fft = fftshift(fft(Hfa, [], 2), 2);  % اندازه: [F × A]
Pangf_dB = 20*log10(abs(Hfa_fft) + eps);

% محور فرکانس فضایی نرمال (cycles/element)
sf_axis = (-floor(A/2):ceil(A/2)-1)/A;    % length A, centered
% نگاشت به زاویه برای ULA: sin(theta) = sf * lambda/d
sin_theta = sf_axis * (lambda/d);
sin_theta(sin_theta>1) = 1; sin_theta(sin_theta<-1) = -1; % ایمن‌سازی
ang_axis = asind(sin_theta); % [deg]

figure('Name','Angle-Frequency |H(theta,f)|');
imagesc(ang_axis, f_axis*1e-6, Pangf_dB); axis xy;
xlabel('Angle of arrival [deg]'); ylabel('Frequency [MHz]');
title(sprintf('Angle–Frequency |H~(\\theta,f)| (snap=%d, user=%d)', snap_idx, user_idx));
colorbar; colormap jet;

%% ------------ 7) پروفایل زاویه‌ای میانگین روی فرکانس ------------
% میانگین توان روی فرکانس → پروفایل زاویه‌ای کلی
Pang_mean = mean(abs(Hfa_fft).^2, 1);   % میانگین روی فرکانس → [1×A]
figure('Name','Average Angle Power');
plot(ang_axis, 10*log10(Pang_mean + eps)); grid on;
xlabel('Angle [deg]'); ylabel('Power [dB]');
title('Average angle-power (averaged over freq)');

%% ------------ 8) مثال: ساخت steering vector و inner-product با H ------------
% ساخت یک steering vector برای زاویه دلخواه و دیدن پاسخ
theta_test = 20; % deg
n = 0:A-1;
delta_phi = 2*pi*(d/lambda)*sin(deg2rad(theta_test));
a_theta = exp(-1j * n * delta_phi).'; % [A×1]

% مقایسه: inner product بین بردار هد و H(f,:) برای یک فرکانس میانه
f_mid_idx = round(F/2);
H_mid = Hfa(f_mid_idx, :).'; % [A×1]
beam_response = a_theta' * H_mid; % اسکالر: پاسخ beamformer در آن فرکانس
fprintf('Beam response at theta=%d deg (freq mid) : mag=%.4f, phase=%.2f rad\n', ...
    theta_test, abs(beam_response), angle(beam_response));

% همچنین می‌توانیم beamformer را روی کل فرکانس اعمال کنیم:
BF_resp = (Hfa * conj(a_theta)); % [F × 1]  (هر سطر: inner product)
figure('Name','Beamformer response vs freq');
plot(f_axis*1e-6, 20*log10(abs(BF_resp)+eps)); grid on;
xlabel('Frequency [MHz]'); ylabel('Beamformer |resp| [dB]');
title(sprintf('Beamformer steered to %d deg (snap=%d)', theta_test, snap_idx));

%% پایان
disp('Done.');
