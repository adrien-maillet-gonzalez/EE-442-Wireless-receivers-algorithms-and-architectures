clear,clc
load P1T2.mat

Nr = length(signal_rx);
Np = length(preamble);

% use one loop to detect the preamble
for i = 1:Nr-Np+1
    % detect where the signal starts
    % estimate the channel here
end

% read payload
payload_len = image_size(1)*image_size(2)*8/2;
payload_rx = signal_rx(start:start + payload_len -1);

% compensate the effect of the channel with your channel estimate from the
% preamble detection
payload_rx_comp_h = ...

% Demap
bits_vec = demap_function_solution(payload_rx_comp_h);
image_decoder(bits_vec, image_size);
