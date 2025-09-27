% Sizes and array params
T = 8; A = 8;
lambda = 1; d = lambda/2;             % half-wavelength spacing
n = 0:A-1;

% Sparse 3-tap channel (Delay x Antenna)
h = zeros(T,A);

% [|alpha|, phase_deg, theta_deg, tau_idx]
paths = [ 1.0,  20,  20, 2;    % alpha1, theta1, tau1
          0.7, -50, -35, 5;    % alpha2, theta2, tau2
          0.4,  10,   0, 7 ];  % alpha3, theta3, tau3

for p = 1:size(paths,1)
    mag   = paths(p,1);
    phdeg = paths(p,2);
    thdeg = paths(p,3);
    tau   = paths(p,4);
    alpha   = mag * exp(1j*deg2rad(phdeg));
    a_theta = exp(-1j*2*pi*(d/lambda)*n*sin(deg2rad(thdeg)));  % 1xA
    h(tau,:) = h(tau,:) + alpha * a_theta;                      % inject row
end

% ---- Spatial DFT across antennas → Angular–Delay ----
H_ang_delay = fftshift(fft(h, [], 2), 2);   % [T x A]

% Centered bin indices that match fftshift:
k_bins = (-floor(A/2)):(ceil(A/2)-1);       % length A

% Map bins → angle
sf_norm   = k_bins / A;                     % cycles/element
sin_theta = sf_norm * (lambda/d);           % (k/A)*(lambda/d)
sin_theta = max(min(sin_theta,1),-1);       % clamp numerical leakage
theta_deg = asind(sin_theta);

% Power (dB) for plotting
P_ad_dB = 10*log10(abs(H_ang_delay).^2 + eps);

% Plot: θ on x-axis, delay tap τ on y-axis
figure('Name','Angular–Delay');
imagesc(theta_deg, 1:T, P_ad_dB); axis xy
xlabel('Angle of arrival \theta (deg)'); ylabel('Delay tap \tau');
title('Angular–Delay: 10log10(|\tilde{H}(\theta,\tau)|^2 + \epsilon)');
colorbar
