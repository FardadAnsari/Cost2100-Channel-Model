clear; clc; close all;
% پارامترها
Ntap = 8; Nf = 256;                       % تعداد تپ و نقاط فرکانس
tau_idx = [0 1 3 6];                      % ایندکس‌های تپ‌ها
gain = [1.0 0.7 0.5 0.2].*exp(1j*2*pi*rand(1,4));  % دامنه‌های پیچیده

h = zeros(1, Ntap); h(tau_idx+1) = gain;  % CIR گسسته (tap-domain)
H = fft(h, Nf);                            % پاسخ فرکانسی

PDP = abs(h).^2;                           % پروفایل توان–تأخیر

figure; stem(0:Ntap-1, PDP,'filled'); grid on;
xlabel('Delay tap'); ylabel('Power'); title('PDP');

f_axis = linspace(0,1,Nf);                 % محور فرکانس نرمال
figure; plot(f_axis, 20*log10(abs(H)+eps)); grid on;
xlabel('Normalized freq'); ylabel('|H| [dB]'); title('Frequency Response');
