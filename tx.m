function [txsignal conf] = tx(txbits,conf,k)
% Digital Transmitter
%
%   [txsignal conf] = tx(txbits,conf,k) implements a complete transmitter
%   consisting of:
%       - modulator
%       - pulse shaping filter
%       - up converter
%   in digital domain.
%
%   txbits  : Information bits
%   conf    : Universal configuration structure
%   k       : Frame index
%
preamble = preamble_generate(100);
preamble_bpsk = -2.*preamble+1;

tx_symbols = [preamble_bpsk.', conf.qpsk(bi2de(reshape(txbits, size(txbits, 1)/2, 2), 'left-msb')+1)];
% figure
% plot(tx_symbols, '.');

symbol_up = upsample(tx_symbols, conf.os_factor);
% figure
% plot(symbol_up, '.');

%pulse = rrc(os_factor, rolloff, rx_filter_len);

pulse = rrc(conf.os_factor, conf.rolloff, conf.tx_filter_len*conf.os_factor);
% figure
% plot(pulse);


tx_signal_BB = conv(symbol_up, pulse, 'same');
% figure
% plot(tx_signal_BB, '.');


time = 0:1/conf.f_s:(length(tx_signal_BB)/conf.f_s)-1/conf.f_s;
txsignal = real(tx_signal_BB.*exp(1j*2*pi*conf.f_c.*time)).';
% plot(txsignal);

% dummy 400Hz sinus generation
% time = 1:1/conf.f_s:4;
% txsignal = 0.3*sin(2*pi*400 * time.');