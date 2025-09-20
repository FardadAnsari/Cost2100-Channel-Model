%% load_HangDelay.m
clear; clc; close all;

% Load saved matrix
load('H_ang_delay.mat');   % loads H_ang_delay [Delay × A] and theta_deg [1×A]

% Crop delay dimension: e.g. first 32 taps
crop_len = 32;
H_crop = H_ang_delay(1:crop_len, :);    % [32 × A]

% Compute power in dB
P_crop_dB = 10*log10(abs(H_crop).^2 + eps);

% Plot again
figure('Name','Cropped Angular–Delay (32 taps)');
imagesc(theta_deg, 0:crop_len-1, P_crop_dB); axis xy;
xlabel('Angle of arrival \theta (deg)'); ylabel('Delay tap (cropped)');
title(sprintf('Angular–Delay (first %d taps)', crop_len));
colorbar; colormap gray;
