close all
clear all

%%
port = "/dev/tty.usbserial-110";
baud_rate = 921600;
s = serialport(port, baud_rate, "Timeout", 2);

%%
index = 0;
max_samples = 26624;
base_name = "test_data_";
iterations = 0;
read_data = false;
data_buffer = cell(max_samples, 2); 
fs = 40e3;  

velocity_history = [];
time_history = [];

%% 
adc_bits = 12;
v_ref = 3.3;
v_swing_threshold = 0.3;  

%% 
cleaner = onCleanup(@() safe_exit(s, data_buffer, index, base_name, ...
    iterations, read_data));

disp("[INFO] Waiting for data...");

%%
while true
    try
        data = readline(s);
        data = strtrim(data);  

        if data == "START"
            index = 1;
            read_data = true;
            tic;
            continue;
        end

        if read_data
            data_buffer{index, 1} = index - 1; 
            data_buffer{index, 2} = data;       
            index = index + 1;
        end

        if data == "END" && read_data
            elapsed = toc;
            fprintf("[INFO] Read complete in %.2f seconds\n", elapsed);

            raw_column = data_buffer(1:index-1, 2);
            valid_mask = cellfun(@(x) isnumeric(x) || ~isnan(str2double(x)), raw_column);
            numeric_values = cellfun(@(x) str2double(x), raw_column(valid_mask));

            radar_v = (numeric_values / (2^adc_bits - 1)) * v_ref;

            v_swing = max(radar_v) - min(radar_v);
            fprintf('[DEBUG] Voltage swing: %.3f V\n', v_swing);

            if v_swing < v_swing_threshold
                disp('[INFO] Chirp rejected: voltage swing too low (< 300 mV)');
                read_data = false;
                index = 0;
                data_buffer(:) = {[]};
                continue;
            end

            signals = numeric_values - mean(numeric_values); 

            N = length(signals);
            fft_signal = fft(signals);
            half_N = floor(N/2);
            fft_mag = abs(fft_signal(1:half_N));
            f = fs * (0:half_N-1) / N;

            [~, peak_idx] = max(fft_mag);
            peak_freq = f(peak_idx);
            fprintf('[INFO] Peak Frequency: %.2f Hz\n', peak_freq);


            fc = 2.4e9;     
            c = 3e8;        
            lambda = c / fc;
            velocity = (peak_freq * lambda) / 2;
            fprintf('[INFO] Estimated Velocity: %.3f m/s\n', velocity);

            velocity_history(end+1) = velocity;
            time_history(end+1) = iterations;

            figure(1); clf;

            subplot(2,1,1);
            power_db = 20 * log10(fft_mag / max(fft_mag));
            plot(f, power_db, 'LineWidth', 1.5);
            xlabel('Frequency (Hz)');
            ylabel('Magnitude (dB)');
            title("FFT Spectrum #" + iterations + " — Peak: " + num2str(peak_freq, '%.2f') + " Hz");
            set(gca, 'FontSize', 14); grid on;
            xlim([0 80]);
            ylim([-100 50]);

            subplot(2,1,2);
            plot(time_history, velocity_history, '-o', 'LineWidth', 1.5);
            xlabel('Iteration');
            ylabel('Velocity (m/s)');
            title('Estimated Velocity Over Time');
            set(gca, 'FontSize', 14); grid on;
            drawnow;

            read_data = false;
            index = 0;
            iterations = iterations + 1;
            data_buffer(:) = {[]};  
        end

    catch ME
        disp("[ERROR] Something went wrong:");
        disp(ME.message);
        break;
    end
end