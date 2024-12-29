SNR = 10;
[bit_out] = awgn_channel(signal, SNR);

figure
plot(noisy_signal, '.');

function [bit_out] = awgn_channel(signal, SNR)
    
    % Convert SNR from dB to linear
    SNRlin = 10 ^ (SNR/10);
    
    % Add AWGN
    noise = 1/sqrt(2*SNRlin)*randn(size(signal));
    noisy_signal = signal + noise + 1j*noise ;
    % Demap
    bit_out = demapper(noisy_signal);
    
end
function [b] = demapper(symbol)
%DEMAPPER Summary of this function goes here
%   Detailed explanation goes here
bit1 = real(symbol) > 0;
bit2 = imag(symbol) > 0;

% b is a two colomn vector col1: real, col2: imag
b = [bit1 bit2];
b = b';
b = b(:);

end


