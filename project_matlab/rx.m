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

time = ( 0:1:(length(rxsignal)-1) ) ./ conf.f_sampling;

% Signal Down-Conversion
r_dc = rxsignal .* exp(-1j*2*pi*conf.f_carrier*time');

% Low-pass filter around DC to keep only the valuable info
r_bb = 2*ofdmlowpass(r_dc,conf, conf.BW);

%% Identify the beginning of the data
% Demodulation of the RX signal

filtered_rx_signal = matched_filter(r_bb, conf);
[start, ~] = frame_sync(filtered_rx_signal, conf.os_factor_preamble, conf) %#ok<*NOPRT>


%% Start the conversion of the OFDM data
% Down-Sample the data and keep only the one from the start index
signal_len_with_cp = conf.N * conf.os_factor_data * (1 + conf.num_symbols / conf.N) * (conf.cyclic_prefix_len + conf.N) / conf.N;
rx_data_with_cp = r_bb(start:start+signal_len_with_cp-1);



%% Remove the cyclic prefix

rx_symbols_with_cp = reshape(rx_data_with_cp, conf.os_factor_data * (conf.cyclic_prefix_len + conf.N), []);

rx_symbols_no_cp = rx_symbols_with_cp(conf.os_factor_data * conf.cyclic_prefix_len + 1:end,:);

%% FFT Processing
% Perform FFT on each OFDM symbol to convert to frequency domain

num_symbols_with_training = 1 + conf.num_symbols/conf.N;

rx_FFT = zeros(conf.N, num_symbols_with_training);

for symbol_index = 1:num_symbols_with_training
    rx_FFT(:, symbol_index) = osfft(rx_symbols_no_cp(:, symbol_index), conf.os_factor_data);
end

%% Channel Estimation and Phase correction

dataCorrected = phaseCorrection(rx_FFT, conf);
rx_serial = dataCorrected(:);



%% Demodulation and Symbol Mapping

[~, idx] = min(abs(rx_serial - conf.qpsk).^2, [], 2);
rxbits = reshape(de2bi(idx-1, 2, 'left-msb'), [], 1);

nexttile
hold on;
xline(0, '-.')
yline(0, '-.')
plot(rx_serial / rms(rx_serial), 'b.');
plot(conf.qpsk, 'rx');
axis padded
title("RX symbols");
hold off;

image = bitstream2image(rxbits,conf.original_image);%bitstream2image %demapper(rx_serial)

end



function dataCorrected = phaseCorrection(fftSignal, conf)
    bitstreamBPSK = conf.training_sequence_bpsk;
    nSymb = size(fftSignal, 2) - 1;
    
    dataCorrected = [];
    H = [];

    for k = 1 : nSymb
        H_hat = fftSignal(:,1)./bitstreamBPSK;
              
        correction = fftSignal(:,k+1)./abs(H_hat).*exp(-1j*mod(angle(H_hat),2*pi));
        dataCorrected = [dataCorrected correction];
        H = [H H_hat];
    end

    
    f = 0:conf.BW/conf.N:conf.BW*(1-1/conf.N);
    f = f + conf.f_carrier - conf.BW/2; 
    nexttile
    for i = 1:size(H,2)

        
        plot(f,20*log10(abs(H(:,i))))
        hold on
        
    end
    title("Magnitude of frequency response")
    xlabel("Frequency [Hz]")
    ylabel("Magnitude [dB]")
    xlim([f(1) f(end)]);
    
    nexttile
    for i = 1:size(H,2)

        
        plot(f,unwrap(angle(H(:,i))))
        hold on
        
    end
    title("Phase of frequency response")
    xlabel("Frequency [Hz]")
    ylabel("Phase [rad]")
    xlim([f(1) f(end)]);
    
    
    nexttile
    for i = 1:size(H,2)

        
        plot(abs(ifft(H(:,i))))
        hold on
        
    end
    title("IFFT of the spectrum")
    xlabel("Number of sub-carrier")
    ylabel("Amplitude of IFFT")
    xline(8,'r','8')
    xline(16, 'g', '16')
    xline(32, 'b', '32')
    xlim([0 256])
    
    
    
    
    
    
    
    
end