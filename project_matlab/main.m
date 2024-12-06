close all; clear all; clc;

"start main" %#ok<*NOPTS>

%load image file
load eiffel_tower.mat
image_input=true;%false%true

image = imread('lena_256.png');
gray_image = im2gray(image);


% Configuration Values
conf.audiosystem = 'bypass'; % Values: 'matlab','native','bypass'

% Image characteristics
conf.original_image = size(gray_image);

% Configure frequencies
conf.f_carrier            = 4000;
conf.f_sampling           = 48000;   % sampling rate
conf.f_s                  = conf.f_sampling;
conf.N                    = 256; % number of subcarriers
conf.frequency_spacing    = 5;
conf.f_symbol_data        = conf.frequency_spacing * conf.N % symbol rate = 50 [Hz]
conf.f_symbol_preamble    = 500 

conf.num_frames           = 1;       % number of frames to transmit
conf.gap_between_frames   = 0;

if image_input
    conf.nbits=prod(conf.original_image) * 8;
else
    conf.nbits= 256*8;    % number of bits
end


conf.num_symbols          = conf.nbits / 2;

conf.cyclic_prefix_len    = conf.N / 2;

% Over-sampling factors
conf.os_factor_data       = conf.f_sampling / conf.f_symbol_data;
conf.os_factor_preamble   = conf.f_sampling / conf.f_symbol_preamble;

conf.BW                   = ceil((conf.N+1)/2) * conf.frequency_spacing;
% default = 4'000


conf.preamble_len         = 100;
conf.tx_filter_len        = 10*conf.os_factor_preamble; % essayer de trouver une manière de déterminer leur valeur bien
conf.rx_filterlen         = 10*conf.os_factor_preamble;
conf.rolloff              = 0.22;

conf.bitsps               = 16;   % bits per audio sample




% Modulation
conf.qpsk                 = [-1-1j -1+1j 1+1j 1-1j]/sqrt(2);


% Noise parameters
conf.SNR_db               = 50;%54; 
conf.SNR_lin              = 10^(conf.SNR_db/10);


% Init Section
% all calculations that you only have to do once


if mod(conf.os_factor_data,1) ~= 0
   disp('WARNING: Sampling rate must be a multiple of the symbol rate'); 
end


% Initialize result structure with zero
res.biterrors   = zeros(conf.num_frames,1);
res.rxnbits     = zeros(conf.num_frames,1);

% TODO: To speed up your simulation pregenerate data you can reuse
% beforehand.



%plotting options for the nice unique plot thing
tiledlayout(2,4)



% Results
    
for k=1:conf.num_frames
    
    % Generate random data
    if image_input
        txbits=image2bitstream(conf, gray_image);
    else
        txbits = randi([0 1],conf.nbits,1);
    end
    
    % TODO: Implement tx() Transmit Function
    [txsignal conf] = tx(txbits,conf,k);

    
    % % % % % % % % % % % %
    % Begin
    % Audio Transmission
    %
    for d = 1
    
    % normalize values (to avoid saturation of the speaker)
    peakvalue       = max(abs(txsignal));
    normtxsignal    = txsignal / (peakvalue + 0.3);
    
    nexttile
    plot(txsignal);
    title("TX Signal");
    

    % create vector for transmission
    rawtxsignal = [ zeros(conf.f_sampling,1) ; normtxsignal ;  zeros(conf.f_sampling,1) ]; % add padding before and after the signal
    rawtxsignal = [  rawtxsignal  zeros(size(rawtxsignal)) ]; % add second channel: no signal
    txdur       = length(rawtxsignal)/conf.f_sampling; % calculate length of transmitted signal
    
    % wavwrite(rawtxsignal,conf.f_s,16,'out.wav')   
    audiowrite('out.wav',rawtxsignal,conf.f_sampling)  
    
    % Platform native audio mode 
    if strcmp(conf.audiosystem,'native')
        
        % Windows WAV mode 
        if ispc()
            disp('Windows WAV');
            wavplay(rawtxsignal,conf.f_sampling,'async');
            disp('Recording in Progress');
            rawrxsignal = wavrecord((txdur+1)*conf.f_sampling,conf.f_sampling);
            disp('Recording complete')
            rxsignal = rawrxsignal(1:end,1);

        % ALSA WAV mode 
        elseif isunix()
            disp('Linux ALSA');
            cmd = sprintf('arecord -c 2 -r %d -f s16_le  -d %d in.wav &',conf.f_sampling,ceil(txdur)+1);
            system(cmd); 
            disp('Recording in Progress');
            system('aplay  out.wav')
            pause(2);
            disp('Recording complete')
            rawrxsignal = audioread('in.wav');
            rxsignal    = rawrxsignal(1:end,1);
        end
        
    % MATLAB audio mode
    elseif strcmp(conf.audiosystem,'matlab')
        disp('MATLAB generic');
        playobj = audioplayer(rawtxsignal,conf.f_sampling,conf.bitsps);
        recobj  = audiorecorder(conf.f_sampling,conf.bitsps,1);
        record(recobj);
        disp('Recording in Progress');
        playblocking(playobj)
        pause(0.5);
        stop(recobj);
        disp('Recording complete')
        rawrxsignal  = getaudiodata(recobj,'int16');
        rxsignal     = double(rawrxsignal(1:end))/double(intmax('int16')) ;
        
    elseif strcmp(conf.audiosystem,'bypass')
        rawrxsignal = rawtxsignal(:,1);
        rxsignal    = rawrxsignal;
    end
    
    end
    %
    % End
    % Audio Transmission   
    % % % % % % % % % % % %
    
    % TODO: Implement rx() Receive Function


    nexttile
    plot(rxsignal);
    title("RX signal");
    [rxbits conf]       = rx(rxsignal,conf);
    
    res.rxnbits(k)      = length(rxbits);  
    res.biterrors(k)    = sum(rxbits ~= txbits);
    
end
    
    
per = sum(res.biterrors > 0)/conf.num_frames;
ber = sum(res.biterrors)/sum(res.rxnbits)


% nexttile
% semilogy(freq_range, ber, 'bx-' ,'LineWidth',3);
% title("BER (log)");
% 
% xlabel('Symbol rate')
% ylabel('BER')
% grid on