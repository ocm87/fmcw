function safe_exit(s, data_buffer, index, base_name, iterations, read_data)
    disp("[INFO] Exiting... cleaning up");

    if read_data && index > 1
        filename = base_name + iterations + "_partial.csv";
        writematrix(data_buffer(1:index-1, :), filename);
        fprintf("[INFO] Saved partial file: %s\n", filename);
    end

    if ~isempty(s) && isvalid(s)
        clear s;
        % delete(s);
        disp("[INFO] Serial port closed.");
    end
end