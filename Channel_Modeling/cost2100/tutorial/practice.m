clear; clc; close all;
N = 1000; t = linspace(0,1,N);            % بردار زمان
f0 = 5;  % Hz
f1 = 15;  % Hz
x1 = exp(1j*2*pi*f0*t);                    % e^{j2πf0 t}
x2 = exp(1j*2*pi*f1*t);                    % e^{j2πf0 t}
x_sum=x1+x2;
mag = abs(x_sum); phase = angle(x_sum);




figure; plot(t, real(x1)); grid on; xlabel('t'); ylabel('Re\{x\}');
figure; plot(t, real(x2)); grid on; xlabel('t'); ylabel('Re\{x\}');
%figure; plot(t, imag(x)); grid on; xlabel('t'); ylabel('Im\{x\}');
figure; plot(t, 20*log10(mag+eps)); grid on; xlabel('t'); ylabel('|x| [dB]');
