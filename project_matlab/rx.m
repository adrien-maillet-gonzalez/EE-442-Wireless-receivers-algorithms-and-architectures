function [rxbits conf] = rx(rxsignal,conf,k)
% Digital Receiver
%
%   [txsignal conf] = tx(txbits,conf,k) implements a complete causal
%   receiver in digital domain.
%
%   rxsignal    : received signal
%   conf        : configuration structure
%   k           : frame index
%
%   Outputs
%
%   rxbits      : received bits
%   conf        : configuration structure
%

time = (0:1:(length(rxsignal)-1)) ./ conf.f_sampling;

% Signal Down-Conversion
r_dc = rxsignal .* exp(-1j*2*pi*conf.f_carrier*time');

% Low-pass filter around DC to keep only the valuable info
r_bb = 2*ofdmlowpass(r_dc,conf, conf.BW);

%% Identify the beginning of the data
% Demodulation of the RX signal

filtered_rx_signal = matched_filter(r_bb, conf);
[start, ~] = frame_sync(filtered_rx_signal, conf.os_factor_preamble, conf) %#ok<*NOPRT>


%% Start the conversion of the OFDM data
% Down-Sample the data and keep only the one from the start index
signal_len_with_cp = conf.N * conf.os_factor_data * (conf.num_training + conf.num_symbols / conf.N) * (conf.cyclic_prefix_len + conf.N) / conf.N;
rx_data_with_cp = r_bb(start:start+signal_len_with_cp-1);



%% Remove the cyclic prefix

rx_symbols_with_cp = reshape(rx_data_with_cp, conf.os_factor_data * (conf.cyclic_prefix_len + conf.N), []);

rx_symbols_no_cp = rx_symbols_with_cp(conf.os_factor_data * conf.cyclic_prefix_len + 1:end,:);

%% FFT Processing
% Perform FFT on each OFDM symbol to convert to frequency domain

num_symbols_with_training = conf.num_training + conf.num_symbols/conf.N;

rx_FFT = zeros(conf.N, num_symbols_with_training);

for symbol_index = 1:num_symbols_with_training
    rx_FFT(:, symbol_index) = osfft(rx_symbols_no_cp(:, symbol_index), conf.os_factor_data);
end

%% Channel Estimation and Phase correction

dataCorrected = phaseCorrection(rx_FFT, conf);
rx_serial = dataCorrected(:);

%% Demodulation and Symbol Mapping

[~, idx] = min(abs(rx_serial - conf.qpsk).^2, [], 2);
rxbits = reshape(de2bi(idx-1, 2, 'left-msb'), [], 1);

nexttile
hold on;
xline(0, '-.')
yline(0, '-.')
plot(rx_serial / rms(rx_serial), 'b.');
plot(conf.qpsk, 'rx');
axis padded
title("RX symbols");
hold off;


end



function dataCorrected = phaseCorrection(fftSignal, conf)
    nSymb = size(fftSignal, 2) - conf.num_training;
    
    dataCorrected = zeros(size(fftSignal, 1), nSymb);

    if conf.training_period == -1
        H_hat = fftSignal(:,1)./conf.training_sequence_bpsk; % Imagine we have different Training sequences, we would add a loop here
    else
        H_hat = fftSignal(:,1:conf.training_period+1:end)./conf.training_sequence_bpsk; % Imagine we have different Training sequences, we would add a loop here
    end

    train_idx = 1;
    symbol_increment = 0;

    %% Phase tracking

    
    previous_delta_theta = mod(angle(H_hat(:, 1)),2*pi);
    for k = 1 : nSymb % if we use another training sequence, we need to change the training sequence, ex: if k > 4 we change
        

        if symbol_increment == conf.training_period && conf.training_period ~= -1
            train_idx = train_idx + 1;
            symbol_increment = 0;

            new_delta_theta = mod(angle(H_hat(:, train_idx)),2*pi);

        else % Viterbi-Viterbi implementation
            delta_theta_viterbi = 1/4*angle(-fftSignal(:,k+train_idx).^4) + pi/2*(-1:4);

            [~, ind] = min(abs(delta_theta_viterbi.' - previous_delta_theta.'));
            actual_delta_theta_viterbi = mod(delta_theta_viterbi(ind), 2*pi).';

            new_delta_theta = 0.999 * previous_delta_theta + 0.001*actual_delta_theta_viterbi;
        end

        dataCorrected(:, k) = fftSignal(:,k+train_idx)./abs(H_hat(:, train_idx)).*exp(-1j*new_delta_theta);
        symbol_increment = symbol_increment + 1;
        previous_delta_theta = new_delta_theta;
    end
    
    f = 0:conf.BW/conf.N:conf.BW*(1-1/conf.N);
    f = f + conf.f_carrier - conf.BW/2;

    nexttile
    plot(f,20*log10(abs(H_hat)),'.')
    title("Magnitude of the Channel depending on the frequency")
    xlabel("Frequency [Hz]")
    ylabel("Magnitude [dB]")
    xlim([f(1) f(end)]);
    
    

    nexttile
    plot(f,180/pi * unwrap(angle(H_hat)),'.')
    title("Phase of the Channel depending on the frequency")
    xlabel("Frequency [Hz]")
    ylabel("Phase [degres]")
    xlim([f(1) f(end)]);
    
    
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