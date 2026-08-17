%% === Enhanced ECG Noise Filtering with LMS and Preprocessing ===
clear; close all; clc;

% Load ECG from CSV
filename = 'C:\Users\Hashir\Downloads\100.csv'; % Replace path if needed
data = readtable(filename);

% Extract signals
t_ms = data.time_ms;
ecg_clean = data.MLII(:); % Ensure column vector
t = t_ms / 1000; % Convert to seconds
fs = round(1/mean(diff(t))); % Sampling frequency
fprintf('Detected sampling frequency: %.2f Hz\n', fs);

%% === Simulate noise ===
powerline_noise = 0.1 * sin(2 * pi * 60 * t); % 60 Hz
baseline_drift = 0.5 * sin(2 * pi * 0.3 * t); % 0.3 Hz
emg_noise = 0.1 * randn(size(t)); % Muscle noise

ecg_noisy = ecg_clean + powerline_noise + baseline_drift + emg_noise;

% SNR before filtering
snr_before = snr(ecg_clean, ecg_noisy - ecg_clean);
fprintf('SNR before filtering: %.2f dB\n', snr_before);

%% === IMPROVED FILTER DESIGN ===

% Option 1: IIR Filters (Butterworth filters)

% Butterworth high-pass filter (0.5 Hz) for baseline wander removal
[b_hp, a_hp] = butter(4, 0.5/(fs/2), 'high');

% Butterworth low-pass filter (40 Hz) for high-frequency noise removal
[b_lp, a_lp] = butter(6, 40/(fs/2), 'low');

% Butterworth notch filter (60 Hz) for powerline noise removal
wo = 60/(fs/2);  % Normalized frequency
bw = wo/35;      % Bandwidth (adjust for notch sharpness)
[b_notch, a_notch] = iirnotch(wo, bw);

% Apply IIR filters in sequence

% Apply notch filter (Powerline removal)
ecg_filt = filtfilt(b_notch, a_notch, ecg_noisy); 

% Apply high-pass filter (Baseline removal)
ecg_filt = filtfilt(b_hp, a_hp, ecg_filt);    

% Apply low-pass filter (High-frequency noise removal)
ecg_filt = filtfilt(b_lp, a_lp, ecg_filt);    

% Calculate SNR after filtering
snr_after = snr(ecg_clean, ecg_filt - ecg_clean);
fprintf('SNR after filtering: %.2f dB\n', snr_after);
fprintf('SNR improvement: %.2f dB\n', snr_after - snr_before);

%% === LMS ADAPTIVE FILTER ===
% Initialize LMS parameters
M = 128;               % Filter length
mu = 0.01;             % Step size

% Create dsp.LMSFilter object
lms = dsp.LMSFilter('Length', M, 'StepSize', mu);

% Apply LMS filter (noisy input, desired clean output)
[ecg_filtered_lms, ~] = lms(ecg_noisy, ecg_clean);

% SNR after LMS filtering
snr_after_lms = snr(ecg_clean, ecg_filtered_lms - ecg_clean);
fprintf('SNR after LMS filtering: %.2f dB\n', snr_after_lms);

%% === METRICS ===
% RMSE calculations
rmse_before = sqrt(mean((ecg_clean - ecg_noisy).^2));
rmse_after = sqrt(mean((ecg_clean - ecg_filt).^2));
rmse_lms = sqrt(mean((ecg_clean - ecg_filtered_lms).^2));

fprintf('\nRMSE Metrics:\n');
fprintf('Before filtering: %.4f\n', rmse_before);
fprintf('After IIR filtering: %.4f\n', rmse_after);
fprintf('After LMS filtering: %.4f\n', rmse_lms);

%% === VISUALIZATION ===
% Select time range for zoomed plots (5-10 seconds)
start_time = 5;
end_time = 10;
idx_range = (t >= start_time) & (t <= end_time);

% Time-domain comparison
figure('Name','ECG Comparison','Position',[100 100 1200 800]);
subplot(4,1,1);
plot(t(idx_range), ecg_clean(idx_range), 'b');
title('Clean ECG');
xlabel('Time (s)'); ylabel('Amplitude');
grid on; xlim([start_time end_time]);

subplot(4,1,2);
plot(t(idx_range), ecg_noisy(idx_range), 'r');
title('Noisy ECG');
xlabel('Time (s)'); ylabel('Amplitude');
grid on; xlim([start_time end_time]);

subplot(4,1,3);
plot(t(idx_range), ecg_filt(idx_range), 'g');
title('IIR Filtered ECG');
xlabel('Time (s)'); ylabel('Amplitude');
grid on; xlim([start_time end_time]);

subplot(4,1,4);
plot(t(idx_range), ecg_filtered_lms(idx_range), 'm');
title('LMS Filtered ECG');
xlabel('Time (s)'); ylabel('Amplitude');
grid on; xlim([start_time end_time]);

% Overlay plot
figure;
plot(t(idx_range), ecg_clean(idx_range), 'b', 'LineWidth',1.5); hold on;
plot(t(idx_range), ecg_filt(idx_range), 'g', 'LineWidth',1);
plot(t(idx_range), ecg_filtered_lms(idx_range), 'm', 'LineWidth',1);
legend('Clean','IIR Filtered','LMS Filtered');
title('ECG Signal Comparison');
xlabel('Time (s)'); ylabel('Amplitude');
grid on; xlim([start_time end_time]);

%% === FREQUENCY DOMAIN ANALYSIS ===
nfft = 2^nextpow2(length(ecg_clean));
f = fs/2*linspace(0,1,nfft/2+1);

% Compute FFTs
ECG_CLEAN_FFT = abs(fft(ecg_clean,nfft));
ECG_NOISY_FFT = abs(fft(ecg_noisy,nfft));
ECG_FILT_FFT = abs(fft(ecg_filt,nfft));
ECG_LMS_FFT = abs(fft(ecg_filtered_lms,nfft));

% Normalize and convert to dB
ECG_CLEAN_FFT = 20*log10(ECG_CLEAN_FFT(1:nfft/2+1)/length(ecg_clean));
ECG_NOISY_FFT = 20*log10(ECG_NOISY_FFT(1:nfft/2+1)/length(ecg_noisy));
ECG_FILT_FFT = 20*log10(ECG_FILT_FFT(1:nfft/2+1)/length(ecg_filt));
ECG_LMS_FFT = 20*log10(ECG_LMS_FFT(1:nfft/2+1)/length(ecg_filtered_lms));

% Plot frequency spectrum
figure('Name','Frequency Spectrum','Position',[100 100 1200 600]);
plot(f, ECG_CLEAN_FFT, 'b', 'LineWidth',1.5); hold on;
plot(f, ECG_NOISY_FFT, 'r', 'LineWidth',1);
plot(f, ECG_FILT_FFT, 'g', 'LineWidth',1);
plot(f, ECG_LMS_FFT, 'm', 'LineWidth',1);
legend('Clean','Noisy','IIR Filtered','LMS Filtered');
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title('Frequency Spectrum Comparison');
grid on; xlim([0 100]); % Focus on 0-100 Hz for ECG

%% === SPECTROGRAM ANALYSIS ===
figure('Name','Spectrograms','Position',[100 100 1200 900]);

subplot(4,1,1);
spectrogram(ecg_clean, 256, 250, [], fs, 'yaxis');
title('Clean ECG Spectrogram');
colorbar; clim([-80 -20]);

subplot(4,1,2);
spectrogram(ecg_noisy, 256, 250, [], fs, 'yaxis');
title('Noisy ECG Spectrogram');
colorbar; clim([-80 -20]);

subplot(4,1,3);
spectrogram(ecg_filt, 256, 250, [], fs, 'yaxis');
title('IIR Filtered ECG Spectrogram');
colorbar; clim([-80 -20]);

subplot(4,1,4);
spectrogram(ecg_filtered_lms, 256, 250, [], fs, 'yaxis');
title('LMS Filtered ECG Spectrogram');
colorbar; clim([-80 -20]);