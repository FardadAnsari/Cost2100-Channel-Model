%% Demo (clean) – COST 2100: SemiUrban_VLA_2_6GHz + Single link + MIMO_VLA_omni + Wideband + OFDM
% Flow preserved: params -> cost2100 -> (optional) visualize -> IR -> FFT -> CSI (H) -> (optional) export
% Modified to support OFDM with 1024 frequency tones and add CSI/CIR plots for snapshot 1
clc; clear;
% ------------------------
% Fixed selection (as requested)
% ------------------------
Network = 'SemiUrban_VLA_2_6GHz';
Link = 'Single';
Antenna = 'MIMO_VLA_omni';
Band = 'Wideband';
% ------------------------
% Scenario parameters (from original demo)
% ------------------------
scenario = 'LOS'; % {'LOS','NLOS'}
freq = [2.57e9 2.62e9]; % [Hz], 50 MHz bandwidth
snapRate = 1; % snapshots per second
snapNum = 1; % number of snapshots
MSPos = [30 30 0]; % one MS [x,y,z] (m)
MSVelo = [0 0 0]; % [m/s]
BSPosCenter = [0 0 0]; % BS center [x,y,z] (m)
BSPosSpacing = [0.0577 0 0]; % inter-position spacing (m) ~ λ/2 at 2.6 GHz
BSPosNum = 32; % 32-element very-large array
% ------------------------
% Run COST2100
% ------------------------
tic;
[paraEx, paraSt, link, env] = cost2100( ...
    Network, scenario, freq, snapRate, snapNum, ...
    BSPosCenter, BSPosSpacing, BSPosNum, MSPos, MSVelo);
toc;
% ------------------------
% (Optional) Visualize environment
% ------------------------
% For VLA cases, the standard visual tools may be heavy; enable if needed:
% visualize_channel_env(paraEx, paraSt, link, env); axis equal; view(2);
% ------------------------
% Combine with omni antenna response for VLA
% ------------------------
% Channel impulse response with 32 omni-directional antennas at BS (λ/2 spacing)
% and one omni-directional MS. Helper returns IR over delay; we FFT to frequency.
delta_f = (freq(2)-freq(1))/1024; % 50 MHz / 1024 tones ≈ 48.8281 kHz for OFDM
% Impulse response (helper from original demo):
% EXPECTED SHAPE: h_omni_MIMO: [snap, delay, rx, tx] with rx=1, tx=BS antennas (32)
h_omni_MIMO = create_IR_omni_MIMO_VLA(link, freq, delta_f, Band);
% Transfer function / CSI: FFT along delay
% RESULTING SHAPE: H_omni_MIMO: [snap, freq, rx, tx] with rx=1, tx=32, freq=1024
H_omni_MIMO = fft(h_omni_MIMO, [], 2);
% ------------------------
% Quick sanity plots
% ------------------------
% Plot CSI: |H|^2 for snapshot #1, rx=1 vs BS antenna across frequency
figure;
mesh(1:BSPosNum, (freq(1):delta_f:freq(2))*1e-6, ...
     log10(abs(squeeze(H_omni_MIMO(1,:,1,:))).^2));
xlabel('Base Station Antennas');
ylabel('Frequency [MHz]');
zlabel('Power [dB]');
title('CSI: SemiUrban VLA (Snapshot #1, RX #1): |H(f)|^2, 1024 OFDM Tones');
grid on;

% Plot CSI: Average power vs frequency (across BS antennas)
figure;
plot((freq(1):delta_f:freq(2))*1e-6, ...
     pow2db(squeeze(mean(abs(H_omni_MIMO(1,:,1,:)).^2, 3))));
xlabel('Frequency [MHz]');
ylabel('Avg Power [dB]');
title('CSI: Average Channel Power vs Frequency (Snapshot #1, RX #1)');
grid on;

% Plot CIR: |h|^2 for snapshot #1, rx=1 vs BS antenna across delay
num_delays = size(h_omni_MIMO, 2);
delay_axis = (0:num_delays-1) * (1/delta_f) * 1e6; % Delay in microseconds
figure;
mesh(1:BSPosNum, delay_axis, ...
     log10(abs(squeeze(h_omni_MIMO(1,:,1,:))).^2));
xlabel('Base Station Antennas');
ylabel('Delay [µs]');
zlabel('Power [dB]');
title('CIR: SemiUrban VLA (Snapshot #1, RX #1): |h(τ)|^2');
grid on;

% Plot CIR: Average power vs delay (across BS antennas)
figure;
plot(delay_axis, ...
     pow2db(squeeze(mean(abs(h_omni_MIMO(1,:,1,:)).^2, 3))));
xlabel('Delay [µs]');
ylabel('Avg Power [dB]');
title('CIR: Average Channel Power vs Delay (Snapshot #1, RX #1)');
grid on;

% Plot CSI: Average power vs BS antennas (across frequencies)
figure;
plot(1:BSPosNum, pow2db(squeeze(mean(abs(H_omni_MIMO(1,:,1,:)).^2, 2))));
xlabel('Base Station Antennas');
ylabel('Avg Power [dB]');
title('CSI: Average Channel Power vs BS Antennas (Snapshot #1, RX #1)');
grid on;
% ------------------------
% (Optional) Export CSI and CIR for learning
% ------------------------
out.H = H_omni_MIMO; % complex CSI, [1, 1024, 1, 32]
out.h = h_omni_MIMO; % complex CIR, [1, num_delays, 1, 32]
axes_info.order = {'snap','freq','rx','tx'}; % rx=1, tx=32
axes_info.size = size(H_omni_MIMO);
axes_info.cir_size = size(h_omni_MIMO);
meta = struct('Network', Network, 'scenario', scenario, ...
'freq_start', freq(1), 'freq_stop', freq(2), ...
'delta_f', delta_f, 'snapRate', snapRate, 'snapNum', snapNum, ...
'BSPosNum', BSPosNum, 'BSPosSpacing', BSPosSpacing(1));
save('CSI_CIR_export_VLA_single_ofdm.mat','-struct','out','-v7.3');
save('CSI_CIR_axes_meta_VLA_single_ofdm.mat','axes_info','meta','-v7.3');
fprintf('Saved CSI_CIR_export_VLA_single_ofdm.mat and CSI_CIR_axes_meta_VLA_single_ofdm.mat\n');