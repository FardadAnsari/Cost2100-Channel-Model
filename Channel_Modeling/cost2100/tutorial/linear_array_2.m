N = 8;              % تعداد آنتن‌ها
d = 0.5;            % فاصله آنتن‌ها برحسب λ (یعنی λ/2)
theta = 30*pi/180;  % زاویه‌ی موج ورودی (۳۰ درجه)
n = 0:N-1;          % شماره آنتن‌ها

% اختلاف فاز بین آنتن‌ها
delta_phi = 2*pi*d*sin(theta);

% بردار هدایت
a = exp(-1j * n * delta_phi).';

disp(a)


theta_scan = -90:0.1:90;     % زاویه اسکن [-90,90]
AF = zeros(size(theta_scan));

for k = 1:length(theta_scan)
    th = theta_scan(k)*pi/180;
    delta_phi = 2*pi*d*sin(th);
    a_theta = exp(-1j * n * delta_phi).';
    AF(k) = abs(a' * a_theta);   % آرایه فاکتور
end

figure; plot(theta_scan, 20*log10(AF/max(AF)));
xlabel('Angle (deg)'); ylabel('Array factor (dB)');
title('Radiation pattern (beam response)');
grid on;
