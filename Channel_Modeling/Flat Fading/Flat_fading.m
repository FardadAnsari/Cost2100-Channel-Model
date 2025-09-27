%% COST2100 — Flat Fading Demo Pack
% by ChatGPT — drop these files into the same folder as your cost2100.m
% -----------------------------------------------------------------------------
% Files in this pack (all in this single script for easy copy-paste):
%   1) demo_flat_fading_cost2100.m         — end-to-end example (RUN THIS)
%   2) cost2100_flat_wrapper.m             — adapts to your cost2100.m outputs
%   3) reduce_to_flat.m                    — collapses taps to narrowband h
%   4) slim_demo_flat.m                    — fallback generator (no COST2100)
% ----------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1) demo_flat_fading_cost2100.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function demo_flat_fading_cost2100()
    % === User knobs (edit these) ===
    fc_Hz      = 3.5e9;      % carrier freq
    BW_Hz      = 100e3;      % signal bandwidth (keep small for flat fading)
    fs_Hz      = 200e3;      % sampling rate for snapshots / sanity plots
    v_mps      = 5;          % user speed (affects Doppler)
    t_end_s    = 10;         % duration for time series
    Nt         = 4;          % TX antennas
    Nr         = 4;          % RX antennas
    rng_seed   = 42;         % reproducibility

    % === Derived ===
    Ns = round(t_end_s * (fs_Hz));    % number of time samples

    %
    % Try to call your COST2100 model to obtain a rich, multipath channel.
    % If your cost2100.m exposes scenario switches, you can pass them here.
    % The wrapper will attempt to:
    %   - grab either impulse-response h[n] over delays, or
    %   - grab frequency response H[k] over subcarriers, or
    %   - fall back to a simple flat model if those aren’t available.
    %
    fprintf('Running COST2100 via wrapper...\n');
    ch = cost2100_flat_wrapper('fc_Hz',fc_Hz,'BW_Hz',BW_Hz,'Nt',Nt,'Nr',Nr, ...
                               'v_mps',v_mps,'Ns',Ns,'seed',rng_seed);

    % ch struct returns:
    %   .h_flat_ts  — [Nr x Nt x Ns] complex flat-fading over time
    %   .fd_max     — max Doppler used
    %   .fc_Hz, .BW_Hz, .Nt, .Nr

    % === Quick sanity checks ===
    assert(all(size(ch.h_flat_ts)==[Nr Nt Ns]), 'Unexpected h size');

    % === Plot: one link magnitude over time ===
    link = [1,1];  % Rx1-Tx1
    h11 = squeeze(ch.h_flat_ts(link(1),link(2),:));

    figure; plot((0:Ns-1)/fs_Hz, abs(h11)); grid on;
    xlabel('Time (s)'); ylabel('|h_{11}(t)|');
    title('Flat-fading envelope (example link)');

    % === Histogram: Rayleigh check ===
    figure; histogram(abs(h11), 80, 'Normalization','pdf'); hold on;
    % Theoretical Rayleigh PDF with sigma^2 = E[|h|^2]/2
    m2 = mean(abs(h11).^2);
    sigma = sqrt(m2/2);
    r = linspace(0,max(abs(h11))*1.1,400);
    ray_pdf = (r./sigma.^2).*exp(-r.^2/(2*sigma.^2));
    plot(r, ray_pdf, 'LineWidth',1.5);
    grid on; xlabel('|h|'); ylabel('pdf');
    title('Envelope distribution vs. Rayleigh'); legend('Empirical','Rayleigh');

    % === Frequency flatness sanity: compare two tones inside BW ===
    % If truly flat, response difference across small BW should be tiny.
    f_rel = [-0.4, +0.4]*BW_Hz/2;  % two test tones inside the band
    H1 = mean(h11 .* exp(-1j*2*pi*f_rel(1)*(0:Ns-1)'/fs_Hz));
    H2 = mean(h11 .* exp(-1j*2*pi*f_rel(2)*(0:Ns-1)'/fs_Hz));
    fprintf('Freq flatness check |H1-H2|/|H1| = %.3g\n', abs(H1-H2)/max(abs(H1),1e-12));

    disp('Done. Tips: reduce BW_Hz or enforce single-tap in reduce_to_flat() for stricter flatness.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2) cost2100_flat_wrapper.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ch = cost2100_flat_wrapper(varargin)
    % Parse inputs
    p = inputParser; p.FunctionName = 'cost2100_flat_wrapper';
    addParameter(p,'fc_Hz',3.5e9);
    addParameter(p,'BW_Hz',100e3);
    addParameter(p,'Nt',1);
    addParameter(p,'Nr',1);
    addParameter(p,'v_mps',0);
    addParameter(p,'Ns',1000);
    addParameter(p,'seed',0);
    parse(p,varargin{:}); S = p.Results;

    rng(S.seed);

    % ---------------------------------------------------------------------
    %  A) Try to obtain a COST2100 channel realization from your cost2100.m
    % ---------------------------------------------------------------------
    % EXPECTED (flexible) outputs from your cost2100.m (any of these):
    %   - TD taps:  h_td [Nr x Nt x L x Ns]  (time-varying impulse response)
    %   - FD resp:  H_fd [Nr x Nt x K x Ns]  (time-varying freq response)
    %   - Static:   h_td [Nr x Nt x L] or H_fd [Nr x Nt x K]
    % If unavailable, we will fall back to a Jakes-like flat process.

    h_td = []; H_fd = []; K = []; L = [];
    try
        % NOTE: Replace this call signature with your own cost2100.m API.
        % For example:  out = cost2100('fc',S.fc_Hz,'Nt',S.Nt,'Nr',S.Nr, ...)
        out = cost2100(S.fc_Hz, S.Nt, S.Nr);  %#ok<NASGU>
        % Try common field names (edit if your struct differs):
        if exist('out','var')
            if isstruct(out)
                if isfield(out,'h_td'), h_td = out.h_td; end
                if isfield(out,'H_fd'), H_fd = out.H_fd; end
            else
                % If your function returns h_td directly, capture here
                if ndims(out)>=3, h_td = out; end
            end
        end
    catch ME
        warning('cost2100() call failed (%s). Using fallback flat model.', ME.message);
    end

    % ---------------------------------------------------------------------
    %  B) Reduce to flat fading per snapshot (narrowband equivalent)
    % ---------------------------------------------------------------------
    if ~isempty(h_td)
        % Ensure time axis exists
        if ndims(h_td)==3, h_td = repmat(h_td,1,1,1,S.Ns); end
        [Nr,Nt,L,~] = size(h_td);
        h_flat_ts = reduce_to_flat('from','td','h_td',h_td,'fc_Hz',S.fc_Hz,'BW_Hz',S.BW_Hz);
    elseif ~isempty(H_fd)
        if ndims(H_fd)==3, H_fd = repmat(H_fd,1,1,1,S.Ns); end
        [Nr,Nt,K,~] = size(H_fd);
        h_flat_ts = reduce_to_flat('from','fd','H_fd',H_fd,'fc_Hz',S.fc_Hz,'BW_Hz',S.BW_Hz);
    else
        % -----------------------------------------------------------------
        %  C) Fallback: generate a time-varying flat (Jakes-like) process
        % -----------------------------------------------------------------
        fd_max = (S.v_mps / 3e8) * S.fc_Hz;  % f_D = v/λ with c≈3e8
        t = (0:S.Ns-1)/S.Ns; t = t(:);
        % Simple sum-of-tones Clarke/Jakes approximation per MIMO entry
        M = 16;  % number of sinusoids
        phi = 2*pi*rand(S.Nr,S.Nt,M);
        theta = 2*pi*rand(1,M);
        w = 2*pi*fd_max*cos(theta);
        h_flat_ts = zeros(S.Nr,S.Nt,S.Ns);
        for r=1:S.Nr
            for tt=1:S.Nt
                x = zeros(S.Ns,1);
                for m=1:M
                    x = x + exp(1j*(w(m)*(0:S.Ns-1)' + phi(r,tt,m)));
                end
                % Normalize to unit power per link
                x = x / sqrt(2*M);
                h_flat_ts(r,tt,:) = x;
            end
        end
    end

    % Estimate fd_max (if not from fallback)
    if ~exist('fd_max','var')
        fd_max = (S.v_mps / 3e8) * S.fc_Hz; 
    end

    ch = struct('h_flat_ts',h_flat_ts, 'fd_max',fd_max, ...
                'fc_Hz',S.fc_Hz,'BW_Hz',S.BW_Hz,'Nt',S.Nt,'Nr',S.Nr);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3) reduce_to_flat.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h_flat_ts = reduce_to_flat(varargin)
    % Collapse a frequency-selective channel to a single complex tap per (r,t)
    % by evaluating the frequency response at the carrier (f=0 baseband) or
    % by weighted combining across K subcarriers / L taps within a tiny BW.

    p = inputParser; p.FunctionName = 'reduce_to_flat';
    addParameter(p,'from','td'); % 'td' or 'fd'
    addParameter(p,'h_td',[]);
    addParameter(p,'H_fd',[]);
    addParameter(p,'fc_Hz',3.5e9);
    addParameter(p,'BW_Hz',100e3);
    parse(p,varargin{:}); S = p.Results;

    switch lower(S.from)
        case 'td'
            % h_td: [Nr x Nt x L x Ns]
            h_td = S.h_td;
            [Nr,Nt,L,Ns] = size(h_td);
            % Evaluate the continuous-time H(f) at baseband f=0:
            % H(f) = sum_l h_l * exp(-j2π f τ_l). If unknown τ_l, assume
            % uniform Δτ and pick the 0-delay tap or energy-weighted average.

            % Strategy: energy-weighted single-tap equivalent (widely used)
            h_flat_ts = zeros(Nr,Nt,Ns);
            for n=1:Ns
                hn = h_td(:,:,:,n);             % [Nr x Nt x L]
                % Option A (strict flat): use the strongest (earliest) tap only
                %   [~,i0] = max(sum(abs(hn).^2,[1 2]));
                %   h_eq = hn(:,:,i0);

                % Option B (recommended): sum all taps coherently at f=0
                h_eq = sum(hn,3);                % H(f=0)

                h_flat_ts(:,:,n) = h_eq;
            end

        case 'fd'
            % H_fd: [Nr x Nt x K x Ns]; choose center subcarrier
            H_fd = S.H_fd; 
            [Nr,Nt,K,Ns] = size(H_fd);
            kc = round((K+1)/2); % center tone

            % Option A: pick center tone only (narrowband equivalent)
            h_flat_ts = squeeze(H_fd(:,:,kc,:));
            if ndims(h_flat_ts)==2, h_flat_ts = reshape(h_flat_ts,Nr,Nt,1); end

            % Option B: tiny-BW coherent combine (uncomment to average)
            % bw_bins = max(1, round(0.1*K));
            % k1 = max(1, kc - floor(bw_bins/2));
            % k2 = min(K, kc + floor(bw_bins/2));
            % h_flat_ts = squeeze(mean(H_fd(:,:,k1:k2,:),3));

        otherwise
            error('reduce_to_flat: unknown source "%s"', S.from);
    end

    % Normalize so E[|h|^2]≈1 per link
    pwr = mean(abs(h_flat_ts).^2, 3);
    scale = 1 ./ sqrt(max(pwr, 1e-12));
    for n=1:size(h_flat_ts,3)
        h_flat_ts(:,:,n) = h_flat_ts(:,:,n) .* scale;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4) slim_demo_flat.m  (no COST2100 required)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h = slim_demo_flat(Nr,Nt,Ns,fd_max,seed)
    if nargin<5, seed = 0; end
    rng(seed);
    M = 16; t = (0:Ns-1)';
    phi = 2*pi*rand(Nr,Nt,M); theta = 2*pi*rand(1,M); w = 2*pi*fd_max*cos(theta);
    h = zeros(Nr,Nt,Ns);
    for r=1:Nr
        for tt=1:Nt
            x = zeros(Ns,1);
            for m=1:M
                x = x + exp(1j*(w(m)*t + phi(r,tt,m)));
            end
            h(r,tt,:) = x / sqrt(2*M);
        end
    end
end
