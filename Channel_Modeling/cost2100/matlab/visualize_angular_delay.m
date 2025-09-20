%% visualize_angular_delay_fixed_crop.m
clear; close all; clc;

% -------- Load dataset --------
load("angular_delay_dataset.mat", "H_ang_delay_cells", "theta_deg", "meta");

num_samples = numel(H_ang_delay_cells);
fprintf("Loaded %d Angular–Delay samples\n", num_samples);

% -------- Which 20 to show --------
num_show = 20;
idx = 1:min(num_show, num_samples);

% -------- Fixed crop settings --------
DelayCrop = 32;   % keep first 32 delay taps for all samples

% ==================== REAL PART (gray) ====================
figR = figure('Name','Angular–Delay (Real part, 32 taps)','Position',[50 50 1300 850]);
for k = 1:numel(idx)
    H = H_ang_delay_cells{idx(k)};   % [Delay × AngleBins]
    
    % Ensure at least 32 taps available
    taps_to_keep = min(DelayCrop, size(H,1));
    Hc = H(1:taps_to_keep, :);  % crop to [32 × 32] ideally

    R = real(Hc);
    vmax = max(abs(R(:))); vmax = max(vmax, eps);

    subplot(4,5,k);
    imagesc(theta_deg, 1:taps_to_keep, R); axis xy;
    colormap(gca, gray);
    caxis([-vmax, vmax]); colorbar;
    xlabel('\theta [deg]'); ylabel('Delay tap index');
    title(sprintf('Sample #%d (Real)', idx(k)));
end
sgtitle(sprintf('Angular–Delay (Real part), first %d delay taps', DelayCrop));

% ==================== IMAG PART (gray) ====================
figI = figure('Name','Angular–Delay (Imag part, 32 taps)','Position',[100 80 1300 850]);
for k = 1:numel(idx)
    H = H_ang_delay_cells{idx(k)};   % [Delay × AngleBins]
    
    taps_to_keep = min(DelayCrop, size(H,1));
    Hc = H(1:taps_to_keep, :);

    I = imag(Hc);
    vmax = max(abs(I(:))); vmax = max(vmax, eps);

    subplot(4,5,k);
    imagesc(theta_deg, 1:taps_to_keep, I); axis xy;
    colormap(gca, gray);
    caxis([-vmax, vmax]); colorbar;
    xlabel('\theta [deg]'); ylabel('Delay tap index');
    title(sprintf('Sample #%d (Imag)', idx(k)));
end
sgtitle(sprintf('Angular–Delay (Imag part), first %d delay taps', DelayCrop));
