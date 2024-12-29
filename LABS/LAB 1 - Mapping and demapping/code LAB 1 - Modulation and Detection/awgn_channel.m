function [bit_out, noisy_signal] = awgn_channel(signal, image_size, SNR)
    
    % Convert SNR from dB to linear
    SNRlin = 10^(SNR/10);
    sigma = sqrt(1/SNRlin / 2);
    
    % Add AWGN
    wR = randn(size(signal));
    wI = randn(size(signal));
    noisy_signal = signal + sigma * (wR + 1i*wI);
    
    % Demap
    bit_out = demapper(noisy_signal);
    
    % Decode and shown image
    image_decoder(bit_out, image_size);
    
end
