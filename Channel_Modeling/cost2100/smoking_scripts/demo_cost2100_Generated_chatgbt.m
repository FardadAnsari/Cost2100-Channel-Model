%% Demo for COST 2100
% پیش‌نیاز: cost2100.m (با پچ BS(nB).BS_pos اعمال‌شده)

clear; clc; close all;
rng('default');  % بازتولیدپذیری

%% 1) تنظیمات سناریو
network    = 'IndoorHall_5GHz';     % یا یکی از شبکه‌های موجود
scenario   = 'LOS';                  % 'LOS' یا 'NLOS'
fc         = 5e9;                    % Hz
BW         = 20e6;                   % Hz
freq       = [fc-BW/2, fc+BW/2];     % [f_start f_stop]

snapRate   = 200;    % snapshot/s
snapNum    = 64;     % تعداد اسنپ‌شات‌ها

% BS: یک سایت با آرایه خیلی‌کوچک/بزرگ
BSPosCenter = [0, 0, 6];     % [x y z] m
BSPosSpacing= [0.5, 0, 0];   % فاصله بین پوزیشن‌های BS روی محور x (برای VLA)
BSPosNum    = 8;             % تعداد پوزیشن‌ها (المان‌ها) در BS

% MS: یک کاربر متحرک
MSPos  = [20, 0, 1.5];       % نقطه شروع
MSVelo = [1.0, 0.5, 0];      % m/s

%% 2) اجرای مدل
[paraEx, paraSt, link, env] = cost2100( ...
    network, scenario, freq, snapRate, snapNum, ...
    BSPosCenter, BSPosSpacing, BSPosNum, MSPos, MSVelo);

%% 3) بررسی سریع ابعاد و محتوا
assert(iscell(link(1,1).channel), 'channel باید cell باشد');
assert(size(link(1,1).channel,1)==BSPosNum && size(link(1,1).channel,2)==snapNum, ...
    'ابعاد سلول channel با BSPosNum و snapNum همخوان نیست');

% فرض می‌کنیم get_channel ساختاری با فیلد H برمی‌گرداند:
ch = link(1,1).channel{1,1};   % BSpos=1, snapshot=1
assert(isfield(ch,'h'), 'خروجی get_channel باید فیلدی به نام H داشته باشد');
disp(ch)
H = ch.h;  % انتظار: [Nr x Nt x Nf] یا [Nr x Nt x Nf x Ntime]
dims = size(H);
fprintf('H size = %s\n', mat2str(dims));

E = mean(abs(H(:)).^2);
fprintf('Avg |H|^2 = %.4f\n', E);

%% 4) اگر H روی فرکانس تعریف شده، CIR و PDP را بساز
% حالت رایج: H: [Nr x Nt x Nf] برای هر snapshot
if ndims(H) >= 3
    Hf = H;                           % [Nr x Nt x Nf]
    ht = ifft(Hf, [], 3);             % تبدیل فرکانس→زمان روی محور فرکانس
    PDP = squeeze(mean(mean(abs(ht).^2,1),2)); % میانگین روی آنتن‌ها
    figure; stem(PDP,'filled'); grid on;
    title('Power Delay Profile'); xlabel('Delay tap'); ylabel('Power');
end

%% 5) طیف داپلر (اگر سری زمانی داری)
% اگر خروجی برای چند snapshot Hf(.,.,.,t) رو داشته باشی:
hasTime = (size(link(1,1).channel,2) > 1);
if hasTime && ndims(ch.h) == 3
    % ساخت ماتریس [Nr x Nt x Nf x Ntme] با چیدن snapshotها کنار هم
    % این بخش به ساختار دقیق خروجی شما وابسته است؛ اینجا یک نمونه‌ی ساده:
    first = link(1,1).channel{1,1}.H;
    [Nr,Nt,Nf] = size(first);
    Ntme = snapNum;
    H4 = zeros(Nr,Nt,Nf,Ntme);
    for t = 1:Ntme
        H4(:,:,:,t) = link(1,1).channel{1,t}.H;
    end
    ht4 = ifft(H4, [], 3);             % CIR روی محور فرکانس
    x   = squeeze(mean(mean(mean(ht4,1),2),3)); % سیگنال میانگین‌شده در زمان
    S   = fftshift(abs(fft(x)).^2);
    figure; plot(S); grid on;
    title('Doppler Spectrum (avg)'); xlabel('bin'); ylabel('Power');
end

%% 6) همبستگی فضایی Rx
% R_rx = E{ H * H^H } (میانگین روی فرکانس/زمان/تعداد آنتن Tx)
if ndims(H) >= 3
    Hf = H; % [Nr x Nt x Nf]
    Hmat = reshape(permute(Hf,[1 3 2]), size(Hf,1), []);  % Nr × (Nf*Nt)
    R_rx = (Hmat * Hmat') / size(Hmat,2);
    figure; imagesc(abs(R_rx)); axis image; colorbar; grid on;
    title('|R_{rx}| (spatial corr)');
end

%% 7) نماهای مفید از env (VR/cluster)
if isfield(env,'VRtable')
    VR = env.VRtable;
    fprintf('VRtable size = %s\n', mat2str(size(VR)));
end
if isfield(env,'cluster')
    fprintf('Num clusters (far) = %d\n', numel(env.cluster));
end
