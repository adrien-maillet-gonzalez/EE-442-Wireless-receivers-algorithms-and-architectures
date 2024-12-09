function [txsignal, conf] = tx(txbits,conf)
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

    %% Preamble
    % Generate the preamble in BPSK
    conf.preamble_bpsk = preamble_generate(100);

    % Up-sample the preamble
    preamble_up = upsample(conf.preamble_bpsk, conf.os_factor_preamble);

    % Pulse shape the preamble
    preamble = matched_filter(preamble_up, conf);

    %% Training sequence
    conf.training_sequence_bpsk = 2*randi([0, 1], conf.N, 1) - 1;

    %% Bitstream to QPSK
    tx_qpsk = conf.qpsk(bi2de(reshape(txbits, size(txbits, 1)/2, 2), 'left-msb')+1).';

    %% Concatenate the training sequence and the bitstream

    tx_parallel_symbols = reshape(tx_qpsk, conf.N, []);

    size_init_tx_parallel = size(tx_parallel_symbols, 2);

    conf.num_training_symbols = 4; % use '-1' for only one training at the start
    conf.training_period = floor(size_init_tx_parallel/conf.num_training_symbols); 
    

    new_tx_parallel_symbols = [];
    idx = 1;
    conf.num_training = 0;

    if conf.training_period == -1 || ~conf.enable_multi_training
        conf.num_training = 1;
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