function [txsignal, conf] = tx(txbits,conf)
% 
%   This function generates a time-domain transmission signal (txsignal) for a 
%   communication system based on the input bitstream (txbits) and configuration 
%   parameters (conf). The output signal includes a preamble, training sequences, 
%   and QPSK-modulated data symbols, prepared for transmission via an OFDM system.
%
% Inputs:
%   - txbits: 
%       A binary vector containing the input bitstream to be transmitted.
%   - conf: 
%       A structure containing configuration parameters for the transmission, including:
%       * preamble_bpsk: Preamble bitstream in BPSK.
%       * os_factor_preamble: Oversampling factor for the preamble.
%       * qpsk: QPSK constellation mapping.
%       * N: Number of subcarriers in OFDM.
%       * cyclic_prefix_len: Length of the cyclic prefix.
%       * os_factor_data: Oversampling factor for data symbols.
%       * f_sampling: Sampling frequency.
%       * f_carrier: Carrier frequency for up-conversion.
%       * audiosystem: Mode of operation (e.g., "bypass").
%       * SNR_db: Signal-to-noise ratio in dB (if noise is added).
%
% Outputs:
%   - txsignal: 
%       The generated time-domain transmission signal, ready for transmission.
%   - conf: 
%       Updated configuration structure containing additional fields for signal 
%       processing (e.g., training sequences, modified parallel data structure).
%
% Processing Steps:
%   1. Preamble Generation:
%       - Generates a BPSK preamble, upsamples it, and pulse-shapes it using a 
%         matched filter for synchronization purposes.
%   2. Training Sequence Preparation:
%       - Creates a BPSK training sequence for channel estimation and inserts it 
%         periodically into the data stream.
%   3. QPSK Modulation:
%       - Maps input bits to QPSK symbols using a predefined constellation.
%   4. OFDM Signal Construction:
%       - Parallel-to-Serial Mapping: Arranges QPSK symbols into parallel streams.
%       - OSIFFT: Generates the OFDM signal using an oversampled inverse FFT.
%       - Cyclic Prefix Addition: Prepends a cyclic prefix to each OFDM symbol.
%   5. Signal Concatenation:
%       - Concatenates the preamble, training sequences, and OFDM data symbols.
%   6. Normalization:
%       - Normalizes the preamble and OFDM signals to maintain consistent power.
%   7. Noise Addition (Optional):
%       - In "bypass" mode, adds noise to the signal based on the specified SNR.
%   8. Up-Conversion:
%       - Converts the baseband signal to a passband signal using a carrier frequency.
%
% Notes:
%   - Ensure that conf contains all necessary fields before calling the function.
%   - Supports configurations for multiple training symbols and variable cyclic 
%     prefix lengths.
%   - Noise addition provides a bypass mode for debugging.

    %% Preamble
    % Generate the preamble in BPSK
    conf.preamble_bpsk = preamble_generate(conf.preamble_len);

    % Up-sample the preamble
    preamble_up = upsample(conf.preamble_bpsk, conf.os_factor_preamble);

    % Pulse shape the preamble
    preamble = matched_filter(preamble_up, conf);

    %% Training sequence
    conf.training_sequence_bpsk = preamble_generate(conf.N);% 2*randi([0, 1], conf.N, 1) - 1;

    %% Bitstream to QPSK
    tx_qpsk = conf.qpsk(bi2de(reshape(txbits, size(txbits, 1)/2, 2), 'left-msb')+1).';

    %% Concatenate the training sequence and the bitstream

    tx_parallel_symbols = reshape(tx_qpsk, conf.N, []);

    size_init_tx_parallel = size(tx_parallel_symbols, 2)

    
    conf.training_period = floor(size_init_tx_parallel/conf.num_training_symbols) 
    

    new_tx_parallel_symbols = [];
    idx = 1;
    conf.num_training = 0;

    if conf.num_training_symbols == 1 || ~conf.enable_multi_training

        new_tx_parallel_symbols = [conf.training_sequence_bpsk, tx_parallel_symbols];

    else
        while idx < size_init_tx_parallel
    
            if idx + conf.training_period > size_init_tx_parallel
                new_tx_parallel_symbols = [new_tx_parallel_symbols, conf.training_sequence_bpsk, tx_parallel_symbols(:, idx:size_init_tx_parallel)]; %#ok<*AGROW>

            else
                new_tx_parallel_symbols = [new_tx_parallel_symbols, conf.training_sequence_bpsk, tx_parallel_symbols(:, (0:conf.training_period-1) + idx)];

            end
            
            idx = idx + conf.training_period;
            conf.num_training = conf.num_training + 1;
        end
    end


    tx_parallel_symbols = new_tx_parallel_symbols;
    conf.new_tx_parallel_symbols = tx_parallel_symbols;
    size(conf.new_tx_parallel_symbols, 2)
    

    %% OS-Inv-FFT (OSIFFT)

    % Concatenate the series signals
    tx_OSIFFT_parallel = zeros(conf.os_factor_data * conf.N, size(tx_parallel_symbols, 2));

    for symbol_index = 1:size(tx_parallel_symbols, 2)

        tx_OSIFFT_parallel(:, symbol_index) = osifft(tx_parallel_symbols(:, symbol_index), conf.os_factor_data);

    end

    %% Add the Cyclic Prefix

    for symbol_index = 1:size(tx_parallel_symbols, 2)

        CP_len = conf.cyclic_prefix_len * conf.os_factor_data; 
        X = tx_OSIFFT_parallel(:, symbol_index);
        X_withCP = [X(end-CP_len+1:end); X];

        tx_OSIFFT_withCP_parallel(:, symbol_index) = X_withCP;

    end


    %% Parallel to serial conversion
    tx_OFDM = tx_OSIFFT_withCP_parallel(:);

    %% Normalize the signals
    tx_OFDM = tx_OFDM / rms(tx_OFDM);
    preamble = preamble / rms(preamble);
    
    %% Concatenate the overall message to send (Starting with the preamble and followed by the data)
    signal = [preamble; tx_OFDM];

    
    %% NOISE (for bypass mode, add some noise to check if we introduce some errors)
    if conf.audiosystem == 'bypass'
        disp(newline + "---> Using 'bypass' : Add some noise to the signal (SNRdB = " + conf.SNR_db + ")")
        noise = 1/sqrt(2*conf.SNR_lin)*randn(size(signal));
        signal = signal + noise + 1j*noise ;
    end

    %% Up-Convert of the TX signal

    time = (0:1:(length(signal)-1)) ./ conf.f_sampling;
    txsignal = real(signal.*exp(1j*2*pi*conf.f_carrier.*time.'));

end
