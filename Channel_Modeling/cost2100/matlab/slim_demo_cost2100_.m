%% slim_demo_cost2100.m
clear; clc; close all; rng('default');

% --- config ---
Network = 'Indoor_CloselySpacedUser_2_6GHz';
scenario = 'LOS';
freq = [2.58e9 2.62e9];
snapRate = 50; snapNum = 50;
MSPos  = [-2.56 1.73 2.23; -3.08 1.73 2.23];    % مثال: دو کاربر
MSVelo = repmat([-.25 0 0], size(MSPos,1), 1);
BSPosCenter = [0.30 -4.37 3.20];
BSPosSpacing = [0 0 0];
BSPosNum = 1;

% --- run model ---
[paraEx, paraSt, link, env] = cost2100(Network, scenario, freq, snapRate, snapNum, ...
    BSPosCenter, BSPosSpacing, BSPosNum, MSPos, MSVelo);

% --- build IR with omni (یک BS، دو MS) ---
delta_f = (freq(2)-freq(1))/256;

% MS #1
h1 = create_IR_omni(link(1,1), freq, delta_f, 'Wideband');   % [snap, delay]
H1 = fft(h1, [], 2);
% MS #2
h2 = create_IR_omni(link(1,2), freq, delta_f, 'Wideband');
H2 = fft(h2, [], 2);

% --- freq axis aligned with FFT length ---
f_axis = linspace(freq(1), freq(2), size(H1,2));

% --- quick checks ---
assert(~any(isnan(H1(:))) && ~any(isinf(H1(:))));
Pavg1 = mean(abs(H1(:)).^2); fprintf('MS1 Avg |H|^2 = %.4f\n', Pavg1);

% --- plots ---
figure; mesh(f_axis*1e-6, 1:size(H1,1), 10*log10(abs(H1)+eps));
xlabel('Freq [MHz]'); ylabel('Snapshot'); zlabel('Mag [dB]'); title('MS1 |H|');

figure; plot(1:size(H1,1), pow2db(mean(abs(H1).^2,2))); grid on;
xlabel('Snapshot'); ylabel('Power [dB]'); title('MS1 mean power over freq');

% --- optional: PDP ---
ht1 = ifft(H1, [], 2);
PDP1 = mean(abs(ht1).^2, 1); figure; stem(PDP1,'filled'); grid on;
title('MS1 PDP'); xlabel('Tap'); ylabel('Power');
