function [rxbits conf] = rx(rxsignal,conf)
%
%   This function processes a received time-domain signal (rxsignal) to recover the 
%   transmitted bitstream (rxbits). It performs down-conversion, synchronization, 
%   cyclic prefix removal, FFT, and QPSK demodulation while compensating for channel 
%   effects such as phase distortion.
%
% Inputs:
%   - rxsignal: 
%       A time-domain signal received at the input of the receiver.
%   - conf: 
%       A structure containing configuration parameters for the reception process, including:
%       * f_sampling: Sampling frequency of the system.
%       * f_carrier: Carrier frequency for down-conversion.
%       * BW: Bandwidth of the system.
%       * N: Number of subcarriers.
%       * os_factor_preamble: Oversampling factor for preamble detection.
%       * os_factor_data: Oversampling factor for data symbols.
%       * num_training_symbols: Number of training symbols for channel estimation.
%       * num_symbols: Total number of transmitted symbols.
%       * cyclic_prefix_len: Length of the cyclic prefix.
%       * qpsk: QPSK constellation mapping for demodulation.
%
% Outputs:
%   - rxbits: 
%       A binary vector representing the demodulated and corrected received bitstream.
%   - conf: 
%       Updated configuration structure containing additional fields for signal 
%       processing (e.g., received serial symbols).
%
% Processing Steps:
%   1. Down-Conversion:
%       - Converts the received passband signal to a baseband complex signal using 
%         carrier frequency and low-pass filtering.
%   2. Frame Synchronization:
%       - Identifies the start of the transmitted data using the preamble and matched 
%         filtering.
%   3. Cyclic Prefix Removal:
%       - Reshapes the baseband signal into OFDM symbols and removes the cyclic prefix 
%         to extract the useful signal portion.
%   4. FFT Processing:
%       - Converts the time-domain OFDM symbols into frequency-domain symbols for 
%         subcarrier-based processing.
%   5. Channel Estimation and Phase Correction:
%       - Compensates for channel effects using training symbols and the 
%         `phaseCorrection` function.
%   6. QPSK Demodulation:
%       - Maps the corrected frequency-domain symbols to the nearest QPSK constellation 
%         points and decodes them into a binary bitstream.
%   7. Visualization (Optional):
%       - Plots the received symbols on the QPSK constellation diagram for analysis 
%         and debugging.
%
% Notes:
%   - Ensure that conf contains all required fields before calling the function.
%   - The function assumes that the preamble and training sequences are properly 
%     configured for frame synchronization and channel estimation.
%   - The exported QPSK plot provides insights into symbol alignment and errors.
%   - Supports noise robustness through matched filtering and channel correction.

    %% Analog 
    time = (0:1:(length(rxsignal)-1)) ./ conf.f_sampling;
    
    % Signal Down-Conversion
    r_dc = rxsignal .* exp(-1j*2*pi*conf.f_carrier*time');
    
    % Low-pass filter around DC to keep only the valuable info
    r_bb = 2*ofdmlowpass(r_dc,conf, conf.BW);
    
    %% Identify the beginning of the data
    % Demodulation of the RX signal
    
    filtered_rx_signal = matched_filter(r_bb, conf);
    [start, ~] = frame_sync(filtered_rx_signal, conf.os_factor_preamble, conf);
    
    disp(newline + "---> Preamble Detected : data_start_idx = " + start);
    
    
    %% Start the conversion of the OFDM data
    
    % Down-Sample the data and keep only the one from the start index
    signal_len_with_cp = conf.N * conf.os_factor_data * (conf.num_training_symbols + conf.num_symbols / conf.N) * (conf.cyclic_prefix_len + conf.N) / conf.N;
    rx_data_with_cp = r_bb(start:start+signal_len_with_cp-1);
    
    
    
    %% Remove the cyclic prefix
    
    rx_symbols_with_cp = reshape(rx_data_with_cp, conf.os_factor_data * (conf.cyclic_prefix_len + conf.N), []);
    
    rx_symbols_no_cp = rx_symbols_with_cp(conf.os_factor_data * conf.cyclic_prefix_len + 1:end,:);
    
    %% FFT Processing
    % Perform FFT on each OFDM symbol to convert to frequency domain
    
    num_symbols_with_training = conf.num_training_symbols + conf.num_symbols/conf.N;
    
    rx_FFT = zeros(conf.N, num_symbols_with_training);
    
    for symbol_index = 1:num_symbols_with_training
        rx_FFT(:, symbol_index) = osfft(rx_symbols_no_cp(:, symbol_index), conf.os_factor_data);
    end
    
    %% Channel Estimation and Phase correction
    
    dataCorrected = phaseCorrection(rx_FFT, conf);
    conf.rx_serial_symbols = dataCorrected(:);
    
    %% Demodulation and Symbol Mapping
    
    [~, idx] = min(abs(conf.rx_serial_symbols - conf.qpsk).^2, [], 2);
    rxbits = reshape(de2bi(idx-1, 2, 'left-msb'), [], 1);
    
    figure(4)
    hold on;
    xline(0, '-.')
    yline(0, '-.')
    plot(conf.rx_serial_symbols / rms(conf.rx_serial_symbols), 'b.');
    plot(conf.qpsk, 'rx');
    axis padded
    title("RX symbols");
    hold off;
    exportgraphics(gcf,"plots/image_constellation_rx_"+conf.str_plot+".png",'Resolution',600)



end



function dataCorrected = phaseCorrection(fftSignal, conf)
%
%   This function performs phase correction on the received frequency-domain signal (fftSignal) 
%   using training sequences for channel estimation and continuous phase tracking. 
%   It corrects the phase distortions introduced by the channel and outputs a 
%   phase-corrected data signal.
%
% Inputs:
%   - fftSignal: 
%       A matrix containing the received frequency-domain signal, with subcarriers 
%       along rows and OFDM symbols along columns.
%   - conf: 
%       A structure containing configuration parameters for the phase correction, including:
%       * num_training_symbols: Number of training symbols used for channel estimation.
%       * training_sequence_bpsk: Known training sequence for channel estimation.
%       * training_period: Periodicity of the training symbols.
%       * enable_multi_training: Flag to enable/disable periodic training symbols.
%       * enable_phase_tracking: Flag to enable/disable phase tracking.
%       * audiosystem: Mode of operation (e.g., "bypass").
%       * sigmaDeltaTheta: Standard deviation of phase noise for simulation.
%       * BW: Bandwidth of the system.
%       * N: Number of subcarriers.
%       * f_carrier: Carrier frequency.
%
% Outputs:
%   - dataCorrected: 
%       A matrix containing the phase-corrected frequency-domain signal, with 
%       subcarriers along rows and OFDM symbols along columns (excluding training symbols).
%
% Processing Steps:
%   1. Channel Estimation:
%       - Estimates the channel's frequency response (H_hat) using the received training symbols.
%   2. Add Artificial Phase Noise (Optional):
%       - In "bypass" mode, introduces random phase noise to the received signal 
%         for testing and debugging.
%   3. Phase Tracking and Correction:
%       - Tracks phase changes over OFDM symbols using:
%           * Training symbols for periodic channel estimation (if enabled).
%           * Viterbi-Viterbi algorithm for phase tracking (if enabled).
%       - Corrects the phase distortion for each subcarrier using the estimated 
%         phase offset and channel response.
%   4. Data Extraction:
%       - Outputs the corrected data symbols, excluding training symbols.
%   5. Visualization (Optional):
%       - Plots the magnitude and phase of the channel response, as well as its 
%         time-domain representation via IFFT, for analysis and debugging.
%
% Notes:
%   - Ensure that conf contains all necessary fields before calling the function.
%   - Training sequences are assumed to be known and correctly configured in conf.
%   - The function supports simulation of phase noise for robustness testing.
%   - Visualization can be omitted or modified as needed for deployment.

    nSymb = size(fftSignal, 2) - conf.num_training_symbols; % Compute the number of actual symbols sent
    
    dataCorrected = zeros(size(fftSignal, 1), nSymb);

    if conf.num_training_symbols == 1 || ~conf.enable_multi_training
        H_hat = fftSignal(:,1)./conf.training_sequence_bpsk; % Imagine we have different Training sequences, we would add a loop here
    else
        H_hat = fftSignal(:,1:conf.training_period+1:end-1)./conf.training_sequence_bpsk; % Imagine we have different Training sequences, we would add a loop here
    end

    train_idx = 1;
    symbol_increment = 0;

   %% Add Artificial Phase Noise (using 'bypass')

    if conf.audiosystem == 'bypass' 
        theta_n = zeros(size(fftSignal, 2)-1, 1);

        for i=1:size(theta_n, 1)-1
            theta_n(i+1) = theta_n(i) + conf.sigmaDeltaTheta*randn(1);
        end

        % Plot the evolution of the Phase over time
        nexttile
        plot(theta_n, '.');

        theta_n = repmat(theta_n.', size(fftSignal, 1), 1);
        fftSignal(:, 2:end) = fftSignal(:, 2:end) .* exp(1i*theta_n);
    end

    %% Phase tracking + Training with training symbols

    
    previous_delta_theta = mod(angle(H_hat(:, 1)),2*pi);
    for k = 1 : nSymb % if we use another training sequence, we need to change the training sequence, ex: if k > 4 we change
        
        % Use the data from the new training sequence
        if symbol_increment == conf.training_period && k~=nSymb && conf.enable_multi_training
            train_idx = train_idx + 1;
            %k = k - 1;
            symbol_increment = 0;

            new_delta_theta = mod(angle(H_hat(:, train_idx)),2*pi);
        
        % Estimate the phase using Viterbi-Viterbi
        elseif conf.enable_phase_tracking
            delta_theta_viterbi = 1/4*angle(-fftSignal(:,k+train_idx).^4) + pi/2*(-1:4);


            [~, ind] = min(abs(delta_theta_viterbi.' - previous_delta_theta.'));

            actual_delta_theta_viterbi_matrix = delta_theta_viterbi(:, ind.');
            actual_delta_theta_viterbi = extract_diagonal(actual_delta_theta_viterbi_matrix);


            new_delta_theta = 0.5 * previous_delta_theta + 0.5*actual_delta_theta_viterbi;
            new_delta_theta = mod(new_delta_theta, 2*pi);

        else
            new_delta_theta = mod(previous_delta_theta, 2*pi);

        end
        dataCorrected(:, k) = fftSignal(:,k+train_idx)./abs(H_hat(:, train_idx)).*exp(-1j*new_delta_theta);
        symbol_increment = symbol_increment + 1;
        previous_delta_theta = mod(new_delta_theta, 2*pi);
    end
    
    f = 0:conf.BW/conf.N:conf.BW*(1-1/conf.N);
    f = f + conf.f_carrier - conf.BW/2;

    figure();
    tiledlayout(2,1);
    nexttile
    plot(f,20*log10(abs(H_hat)),'.')
    title("Magnitude of the Channel (in dB)")
    xlabel("Frequency [Hz]")
    ylabel("Magnitude [dB]")
    xlim([f(1) f(end)]);
    legend show;
    
    

    nexttile
    plot(f,180/pi * mod(unwrap(angle(H_hat)), 2*pi),'.')
    title("Phase of the Channel (in degres)")
    xlabel("Frequency [Hz]")
    ylabel("Phase [degres]")
    xlim([f(1) f(end)]);

    exportgraphics(gcf,"plots/channel_state_"+conf.str_plot+".png",'Resolution',600)
    
    figure()
    nexttile
    plot(abs(ifft(H_hat)),'.')
    title("IFFT of the Channel")
    xlabel("Number of sub-carrier")
    ylabel("Amplitude of IFFT")
    xline(8,'r','8')
    xline(16, 'g', '16')
    xline(32, 'b', '32')
    xlim([0 256])
    
end