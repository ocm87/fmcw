close all;
clear all;

%% 
radar_data = readmatrix('march26_dataset1/radar_waveform.CSV');
pulse_data = readmatrix('march26_dataset1/sync_pulse.CSV');

t_radar = radar_data(:,1);
radar_signal = radar_data(:,2);

t_pulse = pulse_data(:,1);
pulse_signal = pulse_data(:,2);

%%
if max(abs(t_radar - t_pulse)) < 1e-9
    disp('[DEBUG] Time vectors are aligned');
else
    error('[ERROR] Time vectors are not aligned');
end

%% 
pulse_threshold = 0.5;
rising_edges = find(diff(pulse_signal > pulse_threshold) == 1) + 1;
chirp_start_times = t_pulse(rising_edges);

pulse_periods = diff(chirp_start_times);
avg_pulse_period = mean(pulse_periods);  
disp(['[INFO] Full Chirp Period: ', num2str(avg_pulse_period*1e3), ' ms']);

%%
fs = 1 / mean(diff(t_radar));  % Hz
disp(['[INFO] Estimated Sampling Rate: ', num2str(fs/1e3), ' kHz']);

%% 
half_chirp_time = avg_pulse_period / 2;        
half_chirp_len = round(half_chirp_time * fs);  
upchirps = [];

for i = 1:length(chirp_start_times)
    t_start = chirp_start_times(i);
    t_end = t_start + half_chirp_time;

    chirp_idx = find(t_radar >= t_start & t_radar < t_end);

    if length(chirp_idx) == half_chirp_len
        upchirps(:,i) = radar_signal(chirp_idx);
    end
end

disp(['[INFO] Extracted ' num2str(size(upchirps, 2)) ' up-chirps.']);

%% 
chirp_id = 2;
if chirp_id > size(upchirps,2)
    error('[ERROR] chirp_id exceeds number of available up-chirps.');
end

signal = upchirps(:, chirp_id);

figure;
plot(signal);
title(['Up-Chirp #' num2str(chirp_id) ' (Time Domain)']);
xlabel('Samples'); ylabel('Amplitude');
grid on;
set(gca, 'FontSize', 16);
xlim([0 length(signal)]);

%%
N = length(signal);
window = hann(N);
signal_windowed = signal .* window;

Nfft = 4 * N;  
fft_signal = fft(signal_windowed, Nfft);
fft_mag = abs(fft_signal(1:Nfft/2));
f_axis = linspace(0, fs/2, Nfft/2);

[~, peak_idx] = max(fft_mag);
fb = f_axis(peak_idx);  

figure;
plot(f_axis, 20*log10(fft_mag / max(fft_mag)), 'LineWidth', 1.5);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title(['FFT of Up-Chirp #' num2str(chirp_id)]);
grid on;
xlim([0 2000]);
set(gca, 'FontSize', 16);

disp(['[INFO] Beat Frequency from Up-Chirp #' num2str(chirp_id) ': ' num2str(fb, '%.2f') ' Hz']);

%%
c = 3e8;  
B = 100e6;  
T_up = half_chirp_time;  

R = (c * fb) / (2 * B / T_up);
disp(['[INFO] Estimated Range: ' num2str(R, '%.2f') ' meters']);