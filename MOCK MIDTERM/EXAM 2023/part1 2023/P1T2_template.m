clc,clear,close all
% Parameters
snr_db = 10;
os_factor = 10;
rolloff = 0.22;  
tx_filterlen = ...; % you need to decide a proper tx filter length  % filterlength is the _onesided_ filterlength, i.e. the total number of taps is 2*filterlength+1.
rx_filterlen = ...; % you need to decide a proper rx filter length

% number of symbols
numSym = 100;


% Convert SNR from dB to linear
snr_lin = ...;

% Generate source bitstream
tx_bits = randi([0 1], 1, numSym);  % generate a row vector of size 1*numSym

% Map input bitstream using Gray mapping
tx_symb = P1T2_BPSK_map_sol(tx_bits);  % P1T2_BPSK_map_sol() takes input of row vector of size 1*numSym
                                  % P1T2_BPSK_map_sol() return a row vector of size 1*numSym

% Pulse shaping
% oversampling and pulse shaping filtering
signal_up = ...;
pulse_tx = rrc(os_factor,rolloff,tx_filterlen);
signal_filtered = ...;

% AWGN channel, h=1
h=1;

% apply channel
tx_signal = signal_filtered*h;
% add AWGN
noise = ...;
rx_signal = tx_signal + noise;

    
% generate rx filter
pulse_rx = rrc(os_factor,rolloff, rx_filterlen);

% filtering
filtered_rx_signal = ...;

% downsampling
rx_symb = ...;

% Demap
[rx_bits] = P1T2_BPSK_demap_sol(rx_symb);  % P1T2_BPSK_demap_sol() takes input of row vector of size 1*numSym
                                      % P1T2_BPSK_demap_sol() return a row vector of size 1*numSym
% calculate error
error_bits = sum(rx_bits~=tx_bits);


disp(['There are ', int2str(error_bits), ' error bits.'] )

% figure(1)
% plot(abs(fft(rrc(os_factor, 0.22, tx_filterlen))))
% hold on
% plot(abs(fft(rrc(os_factor, 0.88, tx_filterlen))))
% grid on
% legend('rolloff 0.22','rolloff 0.88',Location='north')
% 
% figure(2)
% plot(rrc(os_factor, 0.22, tx_filterlen), '.-')
% hold on
% plot(rrc(os_factor, 0.88, tx_filterlen), '.-')
% grid on
% legend('rolloff 0.22','rolloff 0.88')
