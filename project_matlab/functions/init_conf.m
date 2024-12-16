function [conf] = init_conf(conf, txbits)
 
  % DO NOT TOUCH
    conf.f_sampling           = 48000;   % sampling rate
    
    conf.f_symbol_data        = conf.frequency_spacing * conf.N; % symbol rate = 50 [Hz]
    conf.f_symbol_preamble    = 1000;
    
    % conf.num_frames           = 1;       % number of frames to transmit
    % conf.gap_between_frames   = 0;

    conf.nbits                = size(txbits, 1); % number of bits
    conf.num_symbols          = conf.nbits / 2;

    % Over-sampling factors
    conf.os_factor_data       = conf.f_sampling / conf.f_symbol_data;
    conf.os_factor_preamble   = conf.f_sampling / conf.f_symbol_preamble;
    
    conf.BW                   = ceil((conf.N+1)/2) * conf.frequency_spacing;
    
    
    conf.tx_filter_len        = 10*conf.os_factor_preamble; % essayer de trouver une manière de déterminer leur valeur bien
    conf.rx_filterlen         = 10*conf.os_factor_preamble;
    conf.rolloff              = 0.22;
    
    conf.bitsps               = 16;   % bits per audio sample
    
    % Modulation
    conf.qpsk                 = [-1-1j -1+1j 1+1j 1-1j]/sqrt(2);
    
    % Noise parameters
    conf.SNR_lin              = 10^(conf.SNR_db/10);

end