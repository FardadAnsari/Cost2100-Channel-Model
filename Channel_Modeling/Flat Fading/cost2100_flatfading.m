%% Demo: COST2100 flat fading — single user, single BS antenna, zero velocity, single frequency
% Minimal script that calls COST2100, builds a SISO omni channel and
% collapses it to a single-tone flat-fading coefficient per snapshot.
%
% Requirements (from the official COST2100 package placed on MATLAB path):
%   - cost2100.m and its dependencies
%   - create_IR_omni.m
%   - visualize_channel_env.m (optional; can be disabled)
%
% Author: ChatGPT

%% --------------------- Scenario & knobs ---------------------
Network = 'Indoor_CloselySpacedUser_2_6GHz';  % environment
Link    = 'Single';                           % one BS–MS link
Antenna = 'SISO_omni';                        % one BS antenna, one MS antenna
Band    = 'Wideband';                         % we will collapse to 1 tone

% Single frequency setup (narrow band around fc)
fc       = 2.60e9;     % carrier (Hz)
BW       = 1e3;        % tiny bandwidth (1 kHz)
freq     = [fc - BW/2, fc + BW/2];

% Snapshots/time
snapRate = 50;         % snapshots per second
snapNum  = 200;        % number of snapshots

% Geometry (single user, zero velocity)
MSPos    = [0 5 0];    % [x y z] meters
MSVelo   = [0 0 0];    % zero velocity

BSPosCenter  = [0 0 0];
BSPosSpacing = [0 0 0];
BSPosNum     = 1;      % one BS antenna position

% Visualization on/off
DO_VIS_ENV = false;    % set true to visualize environment

%% --------------------- Run COST2100 -------------------------
scenario = 'LOS';

fprintf('Running COST2100...\n');
[paraEx, paraSt, link, env] = cost2100( ...
    Network, ...      % Model environment
    scenario, ...     % 'LOS' or 'NLOS'
    freq, ...         % [startFreq endFreq]
    snapRate, ...     % snapshots per second
    snapNum, ...      % number of snapshots
    BSPosCenter, ...  % center position of BS array
    BSPosSpacing, ... % BS inter-position spacing (for VLA)
    BSPosNum, ...     % number of BS positions (antennas)
    MSPos, ...        % MS position(s)
    MSVelo ...        % MS velocity(ies)
);

if DO_VIS_ENV
    try
        visualize_channel_env(paraEx, paraSt, link, env); axis equal; view(2);
        title('COST2100 environment');
    catch
        warning('Visualization skipped (visualize_channel_env not available).');
    end
end

%% ------------------ Build SISO omni channel -----------------
% create_IR_omni returns SISO impulse responses per snapshot with the
% desired frequency sampling delta_f.

assert(strcmp(Antenna,'SISO_omni') && strcmp(Link,'Single'), ...
    'This demo is hard-wired for SISO Single link.');

delta_f = (freq(2) - freq(1)) / 256;   % frequency resolution for FFT domain
h_omni  = create_IR_omni(link, freq, delta_f, Band);  % [snap x delay]

% Convert to frequency response over K bins (K equals number of delay taps)
H_omni = fft(h_omni, [], 2);            % [snap x K]

%% ------------- Collapse to single-tone (flat) ----------------
K  = size(H_omni, 2);
kc = round((K + 1)/2);                  % center subcarrier index
h_flat = H_omni(:, kc);                 % [snap x 1] complex flat coefficient vs time

% Optional: power normalization to E{|h|^2}=1
h_flat = h_flat ./ sqrt(mean(abs(h_flat).^2) + 1e-12);

%% ----------------------- Plots ------------------------------
figure; plot(1:length(h_flat), abs(h_flat)); grid on;
xlabel('Snapshot'); ylabel('|h(t)|');
title('Flat-fading envelope (SISO, zero velocity, single tone)');

% With zero velocity, the channel should be essentially time-invariant
fprintf('Var(|h|) over time = %.3g (expect ~0 for zero velocity)\n', var(abs(h_flat)));

% Envelope histogram vs Rayleigh (for zero velocity this becomes a spike)
figure; histogram(abs(h_flat), 40, 'Normalization','pdf'); grid on;
xlabel('|h|'); ylabel('pdf'); title('Envelope histogram (zero velocity)');

%% ------------------- Sanity checks --------------------------
% Frequency-flatness across tiny band
if K >= 3
    k_lo = max(1, kc-1); 
    k_hi = min(K, kc+1);
    dacc = 0; nacc = 0;
    for ss = 1:snapNum
        H_lo = H_omni(ss, k_lo);
        H_hi = H_omni(ss, k_hi);
        dacc = dacc + abs(H_lo - H_hi);
        nacc = nacc + max(abs(H_lo), 1e-12);
    end
    flat_metric = dacc / nacc;   % smaller => flatter
    fprintf('Flatness metric <|H(lo)-H(hi)|>/|H| ≈ %.3g (lower is flatter)\n', flat_metric);
end

fprintf('Done. A single complex h(t) per snapshot is in variable h_flat.\n');
