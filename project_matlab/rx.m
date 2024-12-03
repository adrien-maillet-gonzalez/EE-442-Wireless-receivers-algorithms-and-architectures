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

time = 0:1/conf.f_sampling:(length(rxsignal))/conf.f_sampling - 1/conf.f_sampling;

% Signal Down-Conversion
r_dc = rxsignal .* exp(-1j*2*pi*conf.f_carrier*time');

% Low-pass filter around DC to keep only the valuable info
r_bb = 2*ofdmlowpass(r_dc,conf, conf.BW);

%% Identify the beginning of the data
% Demodulation of the RX signal

filtered_rx_signal = matched_filter(r_bb, conf);
[start, theta] = frame_sync(filtered_rx_signal, conf.os_factor_preamble) %#ok<*NOPRT,ASGLU>


%% Start the conversion of the OFDM data
% Down-Sample the data and keep only the one from the start index
signal_len_with_cp = conf.N * conf.os_factor_data * (1 + conf.num_symbols / conf.N) * (conf.cyclic_prefix_len + conf.N) / conf.N;
rx_data_with_cp = r_bb(start:start+signal_len_with_cp-1);



%% Remove the cyclic prefix

rx_symbols_with_cp = reshape(rx_data_with_cp, conf.os_factor_data * (conf.cyclic_prefix_len + conf.N) / conf.N, []);

rx_symbols_no_cp = rx_symbols_with_cp(conf.os_factor_data * conf.cyclic_prefix_len/ conf.N +1:end,:);

rx_no_cp = rx_symbols_no_cp(:);
%% FFT Processing
% Perform FFT on each OFDM symbol to convert to frequency domain
num_symbols_with_training = 1 + conf.num_symbols / conf.N;
rx_parallel = reshape(rx_no_cp, [], 10);



rx_FFT = zeros(conf.N, num_symbols_with_training);

for symbol_index = 1:num_symbols_with_training
    start_data = (symbol_index-1)*conf.os_factor_data+1;
    input_fft = rx_parallel(start_data:start_data+ conf.os_factor_data-1, :);
    rx_FFT(:, symbol_index) = osfft(input_fft, conf.os_factor_data);
end

% Combine frequency domain symbols into a single vector for demodulation
rx_training = rx_FFT(1:conf.N);
rx_serial = rx_FFT(conf.N+1:end);

%% Demodulation and Symbol Mapping


nexttile
plot(rx_serial, 'b.');
title("CONV with phase correction");

% Demapping of the symbols to data bits
[~, idx] = min(abs(rx_serial.' - conf.qpsk).^2, [], 2);
rxbits = reshape(de2bi(idx-1, 2, 'left-msb'), [], 1);





end