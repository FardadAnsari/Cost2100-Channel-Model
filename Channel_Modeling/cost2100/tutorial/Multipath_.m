clear; clc; close all;

% --- پارامترها ---
Ntap = 8;         % تعداد تپ (حداکثر تاخیر = 7 نمونه)
Nf   = 256;       % تعداد نقاط فرکانسی (برای FFT)

% تعریف چند مسیر
tau_idx = [0 2 5];   % مسیرها در تپ‌های 0،2،5
gain    = [1.0 0.7 0.4] .* exp(1j*2*pi*rand(1,3)); % ضرایب پیچیده

% --- پاسخ ضربه‌ای (CIR) ---
h = zeros(1, Ntap);   % بردار خالی
h(tau_idx+1) = gain;  % پرکردن تپ‌های فعال

% --- پروفایل توان-تاخیر (PDP) ---
PDP = abs(h).^2; 

% --- پاسخ فرکانسی ---
H = fft(h, Nf);       % FFT روی تاخیر → حوزه فرکانس
f_axis = linspace(0,1,Nf); % محور فرکانس نرمال (0 تا 1)

% --- ترسیم ---
% 1) PDP
figure; stem(0:Ntap-1, PDP,'filled'); grid on;
xlabel('Delay tap'); ylabel('Power'); title('Power Delay Profile (PDP)');

% 2) پاسخ فرکانسی |H(f)|
figure; plot(f_axis, 20*log10(abs(H)+eps)); grid on;
xlabel('Normalized frequency'); ylabel('|H(f)| [dB]');
title('Frequency response of multipath channel');

% 3) دامنه و فاز
figure;
subplot(2,1,1); plot(f_axis, abs(H)); grid on;
xlabel('Normalized frequency'); ylabel('|H|');
title('Amplitude Response');
subplot(2,1,2); plot(f_axis, angle(H)); grid on;
xlabel('Normalized frequency'); ylabel('∠H [rad]');
title('Phase Response');
