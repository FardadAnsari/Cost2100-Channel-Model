%% visualize_from_ir_vla.m
% ورودی مورد نیاز در workspace:
% - ir_vla      : impulse response (خروجی create_IR_... ), ابعاد ممکن: [snap, delay, ms, ant] (معمول)
% - freq        : [f_start f_stop] (Hz)
% - BSPosSpacing: [dx dy dz] یا اسکالر فاصله بین المنت‌ها (m)
% اگر اینها در workspace نیستند، قبل از اجرا مقداردهی کن.

%clearvars -except ir_vla freq BSPosSpacing; 
%close all; clc;

% ---------- پارامترهای پیش‌فرض ----------
if ~exist('ir_vla','var')
    error('متغیر ir_vla در workspace وجود ندارد. ابتدا ir_vla را بسازید یا load کنید.');
end
if ~exist('freq','var')
    warning('متغیر freq تعریف نشده؛ مقدار پیش‌فرض 2.58-2.62 GHz قرار داده شد.');
    freq = [2.58e9 2.62e9];
end
if ~exist('BSPosSpacing','var')
    warning('BSPosSpacing تعریف نشده؛ مقدار پیش‌فرض lambda/2 (تقریبی) قرار داده شد.');
    fc = mean(freq);
    BSPosSpacing = (3e8/fc)/2; % m
end

% تعداد نقاط FFT روی بعد delay (برای فرکانس)
Nf = 1024;  % قابل تغییر برای دقت فرکانسی

% ---------- بازرسی و تشخیص ابعاد ir_vla ----------
sz = size(ir_vla);
nd = ndims(ir_vla);
fprintf('size(ir_vla) = %s\n', mat2str(sz));

% هدف: پیدا کردن ابعاد: snap_dim, delay_dim, user_dim, ant_dim
% حالت متداول: [snap, delay, ms, ant]
% heuristic: ابعادی که خیلی بزرگ‌تر هستند (مثلاً >=16) غالباً آنتن‌اند
ant_dim = find(sz >= 16, 1, 'last'); % فرض: آنتن ها بزرگ‌ترند (مثلاً 32, 64, 128)
if isempty(ant_dim)
    % fallback: فرض حالت متداول
    snap_dim = 1; delay_dim = 2; user_dim = 3; ant_dim = 4;
    ant_dim = min(4, nd);
    warning('تشخیص بعد آنتن خودکار موفق نبود؛ فرض شد آنتن بعد 4 است.');
else
    % بقیه ابعاد را حدس می‌زنیم: delay معمولاً کوچک (مثلاً <64)
    dims = 1:nd;
    remaining = setdiff(dims, ant_dim);
    % فرض متداول: snap=1, delay=2, user=3 (اگر وجود داشته باشد)
    snap_dim = remaining(1);
    delay_dim = remaining(2);
    if length(remaining) >= 3
        user_dim = remaining(3);
    else
        user_dim = []; % تک-کاربر
    end
end

% اگر ترتیب متفاوت است، permute انجام می‌دهیم تا در ادامه کد فرض شود:
% ترتیب هدف: [snap, delay, user, ant]
target_order = [snap_dim, delay_dim, user_dim, ant_dim];
% پاک‌سازی مقادیر تهی
target_order = target_order(~isnan(target_order) & target_order>0);
if ~isequal(1:nd, target_order)
    % permute فقط اگر نیاز است
    try
        ir_vla = permute(ir_vla, target_order);
        fprintf('ir_vla permuted to order [snap, delay, user, ant] (dims now = %s)\n', mat2str(size(ir_vla)));
    catch
        warning('permute نتوانست اجرا شود. فرض بر ترتیب اولیه باقی می‌ماند.');
    end
else
    fprintf('ir_vla order assumed [snap, delay, user, ant]\n');
end

% برو برای ابعاد نهایی
sz2 = size(ir_vla);
S = sz2(1);
DelayTaps = sz2(2);
if length(sz2) >= 3
    NumUsers = sz2(3);
else
    NumUsers = 1;
end
A = sz2(4);

fprintf('Final dims: snap=%d, DelayTaps=%d, Users=%d, Antennas=%d\n', S, DelayTaps, NumUsers, A);

% ---------- انتخاب snapshot و user برای نمایش ----------
snap_idx = 1;
user_idx = 1;
if S < snap_idx, snap_idx = 1; end
if NumUsers < user_idx, user_idx = 1; end

% ---------- 1) Delay–Antenna (CIR across antennas) ----------
% اخذ پاسخ ضربه برای snapshot,user : h(delay, ant)
h_da = squeeze(ir_vla(snap_idx, :, user_idx, :));   % [DelayTaps × A]
P_da = abs(h_da).^2; % توان روی هر تپ و آنتن

figure('Name','Delay–Antenna (CIR)'); 
imagesc(1:A, 0:DelayTaps-1, 10*log10(P_da + eps)); axis xy;
xlabel('BS antenna index'); ylabel('Delay tap'); 
title(sprintf('Delay–Antenna (snap=%d, user=%d) [Power dB]', snap_idx, user_idx));
colorbar;colormap gray;

% ---------- 2) Frequency–Antenna (FFT on delay) ----------
H = fft(h_da, Nf, 1);   % FFT روی بعد delay -> [Nf × A]
% محور فرکانس بر اساس Nf و freq
f_axis = linspace(freq(1), freq(2), Nf);

figure('Name','Frequency–Antenna |H(f,ant)|');
imagesc(1:A, f_axis*1e-6, 20*log10(abs(H) + eps)); axis xy;
xlabel('BS antenna index'); ylabel('Frequency [MHz]');
title(sprintf('Spatial–Frequency |H| (snap=%d, user=%d)', snap_idx, user_idx));
colorbar;

% ---------- 3) Frequency–Angle (FFT spatial on antennas) ----------
H_fft_space = fftshift(fft(H, [], 2), 2);   % FFT روی بعد آنتن -> [Nf × A]
P_angf = 20*log10(abs(H_fft_space) + eps);

% محور فرکانس فضایی -> نگاشت به زاویه (برای ULA)
fc = mean(freq); c = 3e8; lambda = c/fc;
if numel(BSPosSpacing) > 1
    d = BSPosSpacing(1);
else
    d = BSPosSpacing;
end

sf_axis = (-floor(A/2):ceil(A/2)-1)/A;  % cycles/element
sin_th = sf_axis * (lambda/d);
sin_th(sin_th>1) = 1; sin_th(sin_th<-1) = -1;
ang_axis = asind(sin_th); % degree

figure('Name','Angle–Frequency |H(theta,f)|');
imagesc(ang_axis, f_axis*1e-6, P_angf); axis xy;
xlabel('Angle [deg]'); ylabel('Frequency [MHz]');
title(sprintf('Angle–Frequency |H~(\\theta,f)| (snap=%d, user=%d)', snap_idx, user_idx));
colorbar;

% ---------- 4) میانگین روی فرکانس -> پروفایل زاویه‌ای ----------
Pang_mean = mean(abs(H_fft_space).^2, 1);  % میانگین توان روی فرکانس -> [1×A]
figure('Name','Avg Angle Power'); plot(ang_axis, 10*log10(Pang_mean + eps), '-o'); grid on;
xlabel('Angle [deg]'); ylabel('Power [dB]'); title('Average angle-power');

% ---------- 5) مثال ساده beamforming: steering vector و پاسخ آن ----------
theta_test = 20; % deg steered
n = 0:A-1;
delta_phi = 2*pi*(d/lambda)*sin(deg2rad(theta_test));
a_theta = exp(-1j * n * delta_phi).';  % [A×1]

% inner product per frequency (beamformer steered to theta_test)
BF_resp = H * conj(a_theta);  % [Nf x 1]
figure('Name','Beamformer response vs freq');
plot(f_axis*1e-6, 20*log10(abs(BF_resp)+eps)); grid on;
xlabel('Frequency [MHz]'); ylabel('Beamformer |resp| [dB]');
title(sprintf('Beamformer steered to %d deg (snap=%d)', theta_test, snap_idx));

% پایان
fprintf('Done. Plots created: Delay–Antenna, Frequency–Antenna, Angle–Frequency, AvgAnglePower, Beamformer response.\n');
