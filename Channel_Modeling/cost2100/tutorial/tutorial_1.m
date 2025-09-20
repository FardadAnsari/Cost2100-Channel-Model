clear; clc; close all;
N = 1000; t = linspace(0,1,N);            % بردار زمان
f0 = 5;                                   % Hz
x = exp(1j*2*pi*f0*t);                    % e^{j2πf0 t}
mag = abs(x); phase = angle(x);

figure; plot(t, real(x)); grid on; xlabel('t'); ylabel('Re\{x\}');
figure; plot(t, imag(x)); grid on; xlabel('t'); ylabel('Im\{x\}');
figure; plot(t, 20*log10(mag+eps)); grid on; xlabel('t'); ylabel('|x| [dB]');
