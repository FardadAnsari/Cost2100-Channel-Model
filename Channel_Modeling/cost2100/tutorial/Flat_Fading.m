clear; clc; close all;
fs = 1000; N = 1024;                      % نرخ نمونه‌برداری و طول FFT
f = linspace(-fs/2, fs/2, N);             % محور فرکانس
h = (0.6+0.8j) / sqrt(2);                 % کانال تخت
H = h * ones(1,N);                        % پاسخ فرکانسی ثابت

figure; plot(f, 20*log10(abs(H)+eps)); grid on;
xlabel('Frequency'); ylabel('|H(f)| [dB]'); title('Flat SISO Channel');
