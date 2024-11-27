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

% Signal Down-Conversi
r_dc = rxsignal .* exp(-1j*2*pi*conf.f_carrier*time');

% Low pass filter around DC to keep only the valuable info
r_bb = 2*ofdmlowpass(r_dc,conf, conf.BW);

%% Identify the beginning of the data
% Demodulation of the RX signal

filtered_rx_signal = matched_filter(r_bb, conf);
[start, theta] = frame_sync(filtered_rx_signal, conf.os_factor_preamble) %#ok<*NOPRT,ASGLU>


%% Start the conversion of the OFDM data
% Down-Sample the data and keep only the one from the start index
signal_len = conf.f_sampling * (conf.N + conf.cyclic_prefix_len)/conf.N;
rx_data = r_bb(start:start+signal_len-1);


%%
%%
%% 
% Extract the training sequence and remove the cyclic prefix




%%
%%
%%


nexttile
plot(rx_signal, 'b.');
title("CONV with phase correction");
% Demapping of the symbols to data bits
[~, idx] = min(abs(rx_signal - conf.qpsk).^2, [], 2);
rxbits = reshape(de2bi(idx-1, 2, 'left-msb'), [], 1);





end