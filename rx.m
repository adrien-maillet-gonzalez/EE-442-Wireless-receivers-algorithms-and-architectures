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

time = 0:1/conf.f_s:(length(rxsignal))/conf.f_s - 1/conf.f_s;

% Signal UP-conversion
r_dc = rxsignal .* exp(-1j*2*pi*conf.f_c*time');

% Low pass filter around DC to keep only the valuable info
r_bb = 2*lowpass(r_dc,conf);

% Demodulation of the RX signal
pulse = rrc(conf.os_factor, conf.rolloff, conf.tx_filter_len*conf.os_factor);
filtered_rx_signal = conv(r_bb, pulse, 'full');

% Use the preamble to get the index where the data starts
start = frame_sync(filtered_rx_signal, conf.os_factor);

% Down-Sample the data and keep only the one from the start idex
rx_signal = filtered_rx_signal(start:conf.os_factor:start + conf.os_factor*conf.nbits/2-1);

% Demapping of the symbols to data bits
[~, idx] = min(abs(rx_signal - conf.qpsk).^2, [], 2);
rxbits = reshape(de2bi(idx-1, 2, 'left-msb'), [], 1);

