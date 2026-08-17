%   CEP

% Step 1: Load ECG Signal from .mat file
% Replace with the path to the specific .mat file from the dataset
data_file = 'D:/soft/Matlab/SimEMG database- simultaneous recordings of noise-free and noise-contaminated ECG signals/P1_1_Ag-AgCl.mat';

% Load the .mat file (this assumes the variable names are like 'ecg_signal', adjust based on the data structure)
data = load(data_file);

% Display the variable names in the loaded file
disp('Variables in the loaded file:');
disp(fieldnames(data));

% Extract the ECG signal (assuming the ECG data is stored under 'ecg_signal' or a similar name)
% You will need to modify this if the signal variable has a different name in your file
ecg_signal = data.ecg_signal; % Replace with actual variable name

% Check the size of the signal to ensure it loaded correctly
disp('Size of the ECG signal:');
disp(size(ecg_signal));

% Step 2: Simulate Noise (Powerline interference, Baseline wander, EMG noise)
fs = 360; % Sampling frequency
t = (0:length(ecg_signal)-1)/fs; % Time vector

% Simulate Powerline Interference (50Hz)
powerline_noise = 0.5 * sin(2*pi*50*t);

% Simulate Baseline Wander (0.5Hz)
baseline_wander = 0.2 * sin(2*pi*0.5*t);

% Simulate Muscle Noise (High-frequency random noise)
emg_noise = 0.1 * randn(size(t));

% Add noise to the original ECG signal
noisy_signal = ecg_signal + powerline_noise + baseline_wander + emg_noise;

% Plot Original and Noisy ECG Signal
figure;
subplot(2,1,1); plot(t, ecg_signal); title('Original ECG Signal');
subplot(2,1,2); plot(t, noisy_signal); title('Noisy ECG Signal');

% Step 3: Filter Design Using FDA Tool

% Create Notch Filter for Powerline Noise (50 Hz)
fdatool; % Open FDA tool for manual filter design
notch_filter = designfilt('bandstopiir', 'FilterOrder', 2, ...
    'HalfPowerFrequency1', 49, 'HalfPowerFrequency2', 51, 'SampleRate', fs);

% Apply Notch Filter to remove powerline interference
filtered_signal_notch = filter(notch_filter, noisy_signal);

% Create High-pass Filter for Baseline Wander (cut-off at 0.5 Hz)
highpass_filter = designfilt('highpassiir', 'FilterOrder', 2, ...
    'CutoffFrequency', 0.5, 'SampleRate', fs);
filtered_signal_hp = filter(highpass_filter, filtered_signal_notch);

% Create Low-pass Filter for EMG Noise (cut-off at 50 Hz)
lowpass_filter = designfilt('lowpassiir', 'FilterOrder', 2, ...
    'CutoffFrequency', 50, 'SampleRate', fs);
filtered_signal = filter(lowpass_filter, filtered_signal_hp);

% Plot the Filtered ECG Signal
figure;
subplot(2,1,1); plot(t, noisy_signal); title('Noisy ECG Signal');
subplot(2,1,2); plot(t, filtered_signal); title('Filtered ECG Signal');

% Step 4: Evaluate the Performance (SNR and RMSE)

% Calculate SNR before and after filtering
snr_before = snr(noisy_signal, powerline_noise + baseline_wander + emg_noise);
snr_after = snr(filtered_signal, powerline_noise + baseline_wander + emg_noise);

% Calculate RMSE between original and filtered ECG signal
rmse = sqrt(mean((ecg_signal - filtered_signal).^2));

% Display SNR and RMSE Results using disp
disp('Performance Metrics:');
disp(['SNR Before Filtering: ', num2str(snr_before), ' dB']);
disp(['SNR After Filtering: ', num2str(snr_after), ' dB']);
disp(['RMSE: ', num2str(rmse)]);

% Step 5: Real-Time Simulation (Moving Window Approach)

% Simulate Real-Time Filtering using a moving window technique
window_size = 500; % Window size for real-time processing
real_time_filtered_signal = zeros(size(noisy_signal));

for i = window_size:length(noisy_signal)
    real_time_filtered_signal(i) = filter(lowpass_filter, noisy_signal(i-window_size+1:i));
end

% Plot the Real-Time Filtered ECG Signal using plot
figure;
plot(t, real_time_filtered_signal);
title('Real-Time Filtered ECG Signal');

% Step 6: Final Visualization (All Signals)
figure;
subplot(3,1,1); plot(t, ecg_signal); title('Original ECG Signal');
subplot(3,1,2); plot(t, noisy_signal); title('Noisy ECG Signal');
subplot(3,1,3); plot(t, filtered_signal); title('Filtered ECG Signal');