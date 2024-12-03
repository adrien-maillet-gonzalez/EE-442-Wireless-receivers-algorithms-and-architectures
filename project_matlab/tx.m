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

    %% Preamble (do we need to normalize the preamble before normalizing the overall signal)
    % Generate the preamble in BPSK
    conf.preamble_bpsk = preamble_generate(100);

    % Up-sample the preamble
    preamble_up = upsample(conf.preamble_bpsk, conf.os_factor_preamble);

    % Pulse shape the preamble
    preamble = matched_filter(preamble_up, conf);

    %% Training sequence
    conf.training_sequence_bpsk = 2*randi([0, 1], conf.N, 1) - 1;

    %% Bitstream
    tx_qpsk = conf.qpsk(bi2de(reshape(txbits, size(txbits, 1)/2, 2), 'left-msb')+1).';

    %% Concatenate the training sequence and the bitstream  %(CHECKED, IT WORKS AS DESIRED)
    tx_training_and_bitstream = [conf.training_sequence_bpsk; tx_qpsk];
    % Serial to parallel conversion
    tx_parallel_symbols = reshape(tx_training_and_bitstream, conf.N, []);

    %% OS-Inv-FFT (OSIFFT)

    % Concatenate the series signals
    tx_OSIFFT_parallel = zeros(conf.os_factor_data * conf.N, size(tx_parallel_symbols, 2)); % do we really need to add the +1 here?

    for symbol_index = 1:size(tx_parallel_symbols, 2)

        tx_OSIFFT_parallel(:, symbol_index) = osifft(tx_parallel_symbols(:, symbol_index), conf.os_factor_data);

    end

    %% Add the Cyclic Prefix

    for symbol_index = 1:size(tx_parallel_symbols, 2)

        CP_len = conf.cyclic_prefix_len * conf.os_factor_data; % could be smart to create a function for this part
        X = tx_OSIFFT_parallel(:, symbol_index);
        X_withCP = [X(end-CP_len+1:end); X];

        tx_OSIFFT_withCP_parallel(:, symbol_index) = X_withCP; %#ok<AGROW>
        

    end


    %% Parallel to serial conversion
    tx_OFDM = tx_OSIFFT_withCP_parallel(:);
   

    %% Normalize the signals
    tx_OFDM = tx_OFDM / rms(tx_OFDM);
    preamble = preamble / rms(preamble); % Le fait de faire comme ça permet d'avoir le preamble et le Signal avec exactement la même puissance
    
    %% Concatenate the overall message to send (Starting with the preamble and followed by the data)
    signal = [preamble; tx_OFDM; zeros(conf.gap_between_frames, 1)];

    
    %% NOISE (for bypass mode, add some noise to check if we introduce some errors)
    if conf.audiosystem == 'bypass'
        "Add some noise to the signal" %#ok<NOPRT>
        noise = 1/sqrt(2*conf.SNR_lin)*randn(size(signal));
        signal = signal + noise + 1j*noise ;
    end

    %% Up-Convert of the TX signal

    time = (0:1:(length(signal)-1)) ./ conf.f_sampling;
    txsignal = real(signal.*exp(1j*2*pi*conf.f_carrier.*time.'));

end