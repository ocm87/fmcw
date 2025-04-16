close all;
clear all;

%%
radar_data = readmatrix('march26_dataset1/radar_waveform.CSV');
pulse_data = readmatrix('march26_dataset1/sync_pulse.CSV');

% radar_data = readmatrix('march28_range_1/radar.CSV');
% pulse_data = readmatrix('march28_range_1/pulse.CSV');

% radar_data = readmatrix('BODE30.CSV');
% pulse_data = readmatrix('BODE29.CSV');

t_radar = radar_data(:,1);
radar_signal = radar_data(:,2);

t_pulse = pulse_data(:,1);
pulse_signal = pulse_data(:,2);

% figure;
% plot(t_radar, radar_signal);
% xlim([0 0.02]);
% 
% figure;
% plot(t_pulse, pulse_signal);
% xlim([0 0.02]);


%%
if max(abs(t_radar - t_pulse)) < 1e-9
    disp('[DEBUG] Time vectors are aligned');
else
    error('[ERROR] Time vecotors are not aligned');
end

%%
pulse_threshold = 0.5;
rising_edges = find(diff(pulse_signal > pulse_threshold) == 1) + 1;
chirp_start_times = t_pulse(rising_edges);

pulse_periods = diff(chirp_start_times);
avg_pulse_period = mean(pulse_periods);
disp(['[INFO] Average Pulse Period: ', num2str(avg_pulse_period*10^3), ' ms']);

%%
fs = 1 / mean(diff(t_radar));

% fs = 8.75e3;
chirp_len_samples = round(avg_pulse_period * fs);

num_chirps_to_plot = 5;
plot_end = min(num_chirps_to_plot * chirp_len_samples, length(t_radar));

plot_range = 1 : plot_end;

radar_scaled = radar_signal(plot_range);
pulse_scaled = pulse_signal(plot_range) * max(radar_scaled);

N = length(t_radar);
sample_axis = 1:N;

figure;
hold on;

plot(sample_axis(plot_range), radar_scaled, 'r', 'LineWidth', 1.5);
area(sample_axis(plot_range), pulse_scaled, 'FaceColor', 'b', 'FaceAlpha', 0.15, 'EdgeColor', 'none');

title('Radar (Red), Sync Pulse (Blue)');
xlabel('Samples'); ylabel('Amplitude (Scaled)');
legend('Radar', 'Sync Pulse');
grid on;
set(gca, 'FontSize', 55);
xlim([0 1000]);

%%
chirp_len = round(avg_pulse_period * fs);
chirp_len_time = chirp_len / fs;

chirps = [];

for i = 1:length(chirp_start_times)
    t_start = chirp_start_times(i);
    t_end = t_start + chirp_len_time;

    chirp_idx = find(t_radar >= t_start & t_radar < t_end);

    if length(chirp_idx) == chirp_len
        chirps(:,i) = radar_signal(chirp_idx);
    end
end

chirp_id = 25;
signal = chirps(:, chirp_id);

figure;
plot(signal);
title(['Chirp #' num2str(chirp_id) ' (Time Domain)'])
xlabel('Samples'); ylabel('Amplitude');
set(gca, 'FontSize', 55); grid on;
xlim([0 200]);

%%
N = length(signal);
fft_signal = fft(signal);
half_N = floor(N/2);
fft_mag = abs(fft_signal(1:half_N));

f = linspace(0, fs/2, half_N);

[~, peak_idx] = max(fft_mag);
peak_freq = f(peak_idx);
fprintf('[INFO] Beat Frequency of Chirp (no window+zeropadding) #%d: %.2f Hz\n', chirp_id, peak_freq);

c = 3e8;                  
T = avg_pulse_period;        
B = 100e6;
fb = peak_freq;

R = (c * fb) / (2 * (B / T));  

fprintf('[INFO] Range of Chirp #%d: %.2f m\n', chirp_id, R);

power_db = 20 * log10(fft_mag / max(fft_mag));

figure;
plot(f, power_db);
title(['FFT of Chirp #' num2str(chirp_id)]);
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
set(gca, 'FontSize', 55); grid on;
xlim([0 2000]);

%% 
N = length(signal);

window = hann(N);
signal_windowed = signal .* window;

fft_signal = fft(signal, 4*N);
half_N = floor(4*N/2);
fft_mag = abs(fft_signal(1:half_N));

freq = (0:(4*N)-1) * (fs/(4*N));
freq = freq(1:half_N);

[~, peak_idx] = max(fft_mag);
peak_freq = freq(peak_idx);
fprintf('[INFO] Beat Frequency of Chirp (with window+zeropadding) #%d: %.2f Hz\n', chirp_id, peak_freq);

c = 3e8;                  
T = avg_pulse_period;        
B = 100e6;
fb = peak_freq;

R = (c * fb) / (2 * (B / T));  

fprintf('[INFO] Range of Chirp #%d: %.2f m\n', chirp_id, R);

power_db = 20 * log10(fft_mag / max(fft_mag));

figure;
plot(freq(1:half_N), power_db(1:half_N), 'LineWidth', 1.5);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title(['FFT of Chirp #' num2str(chirp_id) ': With zero-padding + windowing']);
set(gca, 'FontSize', 55);

xlim([0 1000]);
grid on;

%%
num_chirps = size(chirps, 2);      
peak_freqs = zeros(1, num_chirps); 

for i = 1:num_chirps
    signal = chirps(:, i);
    N = length(signal);

    windowed = signal .* hann(N);

    % fft_data = fft(signal);
    fft_data = fft(windowed);

    half_N = floor(N/2);
    fft_mag = abs(fft_data(1:half_N));

    [~, idx] = max(fft_mag);
    peak_freqs(i) = f(idx);
end

figure;
plot(peak_freqs);
title('Beat Frequency vs. Chirp Index');
xlabel('Chirp Index'); ylabel('Beat Frequency (Hz)');
grid on;
set(gca, 'FontSize', 55);

%%
avg_beat_freq = mean(peak_freqs);
disp(['[INFO] Average Beat Frequency: ' num2str(avg_beat_freq) ' Hz']);



