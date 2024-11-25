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
figure
plot(rxsignal)

r_dc = rxsignal .* exp(-1j*2*pi*conf.f_c*time');
figure
plot(r_dc);

r_bb = lowpass(r_dc,conf);


pulse = rrc(conf.os_factor, conf.rolloff, conf.tx_filter_len*conf.os_factor);

filtered_rx_signal = conv(r_bb, pulse, 'full');
figure
plot(filtered_rx_signal, '.');

start = frame_sync(filtered_rx_signal, conf.os_factor)

rx_signal = filtered_rx_signal(start:conf.os_factor:start + conf.os_factor*conf.nbits/2-1);



plot(rxsignal);

[~, idx] = min(abs(rx_signal - conf.qpsk).^2, [], 2);

rxbits = reshape(de2bi(idx-1, 2, 'left-msb'), [], 1);

% preamble = preamble_generate(100);
% preamble_bpsk = -2.*preamble+1;


% dummy 
% rxbits = zeros(conf.nbits,1);