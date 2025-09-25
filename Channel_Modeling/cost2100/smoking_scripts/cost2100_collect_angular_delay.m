%% cost2100_collect_angular_delay.m
% Collect 1000 Angular–Delay CSI realizations (no plots, no other domains)

clear; clc;

% -------- Settings --------
num_samples   = 100;
save_path     = "angular_delay_dataset.mat";

% -------- Scenario (fixed geometry) --------
Network      = 'SemiUrban_VLA_2_6GHz';
scenario     = 'LOS';
freq         = [2.57e9 2.62e9];      % Hz (f_start, f_stop)
snapRate     = 1;
snapNum      = 1;
BSPosCenter  = [0 0 0];
BSPosSpacing = [0.0577 0 0];         % ~lambda/2 @2.6 GHz
BSPosNum     = 32;                    % # BS elements
MSPos        = [30 0 1.5];            % fixed user position
MSVelo       = [0 0 0];

% -------- Precompute constants for angle axis --------
c = 3e8; fc = mean(freq); lambda = c/fc;
if numel(BSPosSpacing) > 1, d = BSPosSpacing(1); else, d = BSPosSpacing; end

% We’ll compute theta_deg once from the first sample (depends only on A,d,lambda)
theta_deg = [];

% IR builder frequency sampling (used inside create_IR_omni_MIMO_VLA)
delta_f = (freq(2)-freq(1))/1024;

% Storage (cell for robustness in case DelayTaps changes)
H_ang_delay_cells = cell(1, num_samples);

fprintf('Collecting %d Angular–Delay CSI samples...\n', num_samples);

for n = 1:num_samples
    % Different fading realization; fixed geometry
    rng(2025 + n);

    % --- Run COST2100 once (single snapshot, single MS) ---
    [~, ~, link, ~] = cost2100( ...
        Network, scenario, freq, snapRate, snapNum, ...
        BSPosCenter, BSPosSpacing, BSPosNum, MSPos, MSVelo);

    link_use = link(1,1);  % BS#1–MS#1

    % --- Build wideband impulse response (IR) ---
    % Expected dims: [snapshot × delay × ms × bsAnt]
    ir_vla = create_IR_omni_MIMO_VLA(link_use, freq, delta_f, 'Wideband');

    % Keep 2D: [DelayTaps × Antennas]
    h_da = squeeze(ir_vla(1, :, 1, :));      % (Delay × A)
    [DelayTaps, A] = size(h_da);

    % --- Angular–Delay: spatial FFT across antennas, fftshifted ---
    H_ang_delay = fftshift(fft(h_da, [], 2), 2);   % (Delay × A)

    % --- Angle axis (compute once) ---
    if isempty(theta_deg)
        k_bins    = (-floor(A/2):ceil(A/2)-1); % length A
        sf_norm   = k_bins / A;                % cycles/element
        sin_theta = sf_norm * (lambda/d);
        sin_theta = max(min(sin_theta,1),-1);  % clamp numeric jitter
        theta_deg = asind(sin_theta);
    end

    % Store (cell)
    H_ang_delay_cells{n} = H_ang_delay;

    if mod(n,100) == 0
        fprintf('  ... %d / %d\n', n, num_samples);
    end
end

% --- Minimal metadata ---
meta.Network      = Network;
meta.scenario     = scenario;
meta.freq_Hz      = freq;
meta.snapRate     = snapRate;
meta.snapNum      = snapNum;
meta.BSPosCenter  = BSPosCenter;
meta.BSPosSpacing = BSPosSpacing;
meta.BSPosNum     = BSPosNum;
meta.MSPos        = MSPos;
meta.MSVelo       = MSVelo;
meta.delta_f      = delta_f;
meta.lambda       = lambda;
meta.d            = d;
meta.note         = 'Angular–Delay only; geometry fixed; varying RNG seed per sample';

% --- Save dataset ---
save(save_path, 'H_ang_delay_cells', 'theta_deg', 'meta', '-v7.3');
fprintf('Saved %d samples to %s\n', num_samples, save_path);
