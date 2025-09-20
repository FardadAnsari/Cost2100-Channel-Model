clear; clc; close all;
A = 16;                                   % تعداد آنتن‌های BS
fc = 2.6e9; c = 3e8; lambda = c/fc;
d = lambda/2;                             % فاصله بین المنت‌ها
theta_deg = 30;                           % زاویه ورود
theta = deg2rad(theta_deg);

n = 0:A-1;                                % ایندکس آنتن‌ها
a_theta = exp(1j*2*pi*(d/lambda)*sin(theta)*n);   % بردار هد
Hfa = a_theta;                            % کانال فضایی (یک مسیر)

% FFT فضایی و نگاشت به زاویه
H_fft = fftshift(fft(Hfa));               % فرکانس فضایی
sf = (-floor(A/2):ceil(A/2)-1)/A;         % cycles/element
sin_th = max(min(sf*(lambda/d),1),-1);
ang = asind(sin_th);

figure; stem(0:A-1, 20*log10(abs(Hfa)+eps),'filled'); grid on;
xlabel('Antenna index'); ylabel('|H| [dB]'); title('Spatial samples');

figure; plot(ang, 20*log10(abs(H_fft)+eps)); grid on;
xlabel('Angle [deg]'); ylabel('|H̃(\theta)| [dB]'); title('Spatial FFT → Angle');
