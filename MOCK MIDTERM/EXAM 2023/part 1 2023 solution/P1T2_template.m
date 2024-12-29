clc,clear,close all
% Parameters
snr_db = 10;
os_factor = 10;
rolloff = 0.22;  
tx_filterlen = 20; % you need to decide a proper tx filter length  % filterlength is the _onesided_ filterlength, i.e. the total number of taps is 2*filterlength+1.
rx_filterlen = 6; % you need to decide a proper rx filter length

% number of symbols
numSym = 100;


% Convert SNR from dB to linear
SNRlin = 10^(snr_db/10);

% Generate source bitstream
tx_bits = randi([0 1], 1, numSym);  % generate a row vector of size 1*numSym

% Map input bitstream using Gray mapping
tx_symb = P1T2_BPSK_map_sol(tx_bits);  % P1T2_BPSK_map_sol() takes input of row vector of size 1*numSym
                                  % P1T2_BPSK_map_sol() return a row vector of size 1*numSym

% Pulse shaping
% oversampling and pulse shaping filtering
signal_up  = upsample(tx_symb,os_factor);
pulse_tx = rrc(os_factor,rolloff,tx_filterlen);
signal_filtered = conv(signal_up,pulse_tx,'full');

% AWGN channel, h=1
h=1;

% apply channel
tx_signal = signal_filtered*h;
% add AWGN
noise = 1/sqrt(2*SNRlin)*(randn(size(tx_signal)) + 1i*randn(size(tx_signal)));
rx_signal = tx_signal + noise;
    
% generate rx filter
pulse_rx = rrc(os_factor,rolloff, rx_filterlen);

% filtering
filtered_rx_signal = conv(rx_signal,pulse_rx,"full");

% downsampling
rx_symb = filtered_rx_signal(1+tx_filterlen+rx_filterlen:os_factor:end-tx_filterlen-rx_filterlen);

% Demap
[rx_bits] = P1T2_BPSK_demap_sol(rx_symb);  % P1T2_BPSK_demap_sol() takes input of row vector of size 1*numSym
                                      % P1T2_BPSK_demap_sol() return a row vector of size 1*numSym
% calculate error
error_bits = sum(rx_bits~=tx_bits);


disp(['There are ', int2str(error_bits), ' error bits.'] )

figure(1)
plot(abs(fft(rrc(os_factor, 0.22, tx_filterlen))))
hold on
plot(abs(fft(rrc(os_factor, 0.88, tx_filterlen))))
grid on
legend('rolloff 0.22','rolloff 0.88',Location='north')
saveas(gcf, 'fft.png')

figure(2)
plot(rrc(os_factor, 0.22, tx_filterlen), '.-')
hold on
plot(rrc(os_factor, 0.88, tx_filterlen), '.-')
grid on
legend('rolloff 0.22','rolloff 0.88')
saveas(gcf,'rcc.png')
