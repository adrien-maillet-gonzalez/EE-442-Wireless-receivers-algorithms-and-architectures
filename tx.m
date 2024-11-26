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

% Generate the preamble in BPSK
preamble = preamble_generate(100);
preamble_bpsk = -2.*preamble+1;

% Combine the preamble in BPSK and the data in QPSK
tx_symbols = [preamble_bpsk.', conf.qpsk(bi2de(reshape(txbits, size(txbits, 1)/2, 2), 'left-msb')+1)];

% Up-Sampling of the signal
symbol_up = upsample(tx_symbols, conf.os_factor);

% Modulation of the RX Signal
pulse = rrc(conf.os_factor, conf.rolloff, conf.tx_filter_len*conf.os_factor);
tx_signal_BB = conv(symbol_up, pulse, 'full');

% (for bypass mode, add some noise to check if we introduce some errors)
if conf.audiosystem == 'bypass'
    output_text = "Add some noise to the signal"
    noise = 1/sqrt(2*conf.SNR_lin)*randn(size(tx_signal_BB));
    tx_signal_BB = tx_signal_BB + noise + 1j*noise ;
end



% Up-Sampling of the TX signal
time = 0:1/conf.f_s:(length(tx_signal_BB)/conf.f_s)-1/conf.f_s;
txsignal = real(tx_signal_BB.*exp(1j*2*pi*conf.f_c.*time)).';