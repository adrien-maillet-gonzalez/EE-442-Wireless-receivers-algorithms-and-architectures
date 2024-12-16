close all; clear all; clc;
rng(123);

addpath("functions/");
addpath("images/");
addpath("audio/");
addpath('plots/');


% Configuration Values
conf.audiosystem = 'matlab'; % Values: 'matlab','native','bypass'
conf.data_type = "random"; % Values: 'image', 'random'

conf.enable_phase_tracking = false;

conf.enable_multi_training = false;
conf.num_training_symbols = 1;

%% Upload image

image_file = 'pyramid.png';

[binary_stream, conf] = image_to_bitstream(image_file, conf);

%% Select the data to transmit

%% change the cyclic prefix len
num_sub_carrier_list = [16 32 64 128 256 512 1024 2048];
SER_list = zeros(1, length(num_sub_carrier_list));



for x=1:length(num_sub_carrier_list)

conf.N       = num_sub_carrier_list(x)  % number of subcarriers



if conf.data_type == "image"
    txbits = binary_stream;

elseif conf.data_type == "random"
    num_ofdm_symbols = 5; % Specify the number of random OFDM symbols to send
    txbits = randi([0 1],conf.N*2*num_ofdm_symbols,1);

end

%% Configure frequencies
conf.f_carrier            = 4000;
conf.cyclic_prefix_len    = conf.N/2;



    
    conf.frequency_spacing    = 5;%num_sub_carrier_list(x);
    
    conf.preamble_len         = 100;
    
    conf.SNR_db               = 20;   % artificial noise 
    conf.sigmaDeltaTheta      = 0.05; % artificial phase shift
        
    
    conf = init_conf(conf, txbits);   % initialize the configuration variable
    
    
        
    
    %% Transmission of data  
    [txsignal, conf] = tx(txbits,conf);
    
    
    % % % % % % % % % % % %
    % Begin
    % Audio Transmission
    %
    for audio_transmission = 1 % used to minimize this section
    
    % normalize values (to avoid saturation of the speaker)
    peakvalue       = max(abs(txsignal));
    normtxsignal    = txsignal / (peakvalue + 0.3);
    
    
    % create vector for transmission
    rawtxsignal = [ zeros(conf.f_sampling,1) ; normtxsignal ;  zeros(conf.f_sampling,1) ]; % add padding before and after the signal
    rawtxsignal = [  rawtxsignal  zeros(size(rawtxsignal)) ]; % add second channel: no signal
    txdur       = length(rawtxsignal)/conf.f_sampling; % calculate length of transmitted signal
    
    % wavwrite(rawtxsignal,conf.f_s,16,'out.wav')   
    audiowrite('audio/out.wav',rawtxsignal,conf.f_sampling)  
    
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
    
    
    %% Reception of Data
    [rxbits, conf]       = rx(rxsignal,conf);
    
    %% Determine the transmission error values
    res.rxnbits      = length(rxbits);  
    res.biterrors    = sum(rxbits ~= txbits);
        
    
    per = sum(res.biterrors > 0);
    ber = sum(res.biterrors)/sum(res.rxnbits); 
    
    disp(newline + "---> BER = " + ber);
    
    %% Plot the error in terms of time
    
    % Evolution of the Symbol error over time
    
    tx_qpsk_plot = conf.qpsk(bi2de(reshape(txbits, size(txbits, 1)/2, 2), 'left-msb')+1).';
    rx_qpsk_plot = conf.qpsk(bi2de(reshape(rxbits, size(rxbits, 1)/2, 2), 'left-msb')+1).';
    
    SER_list(x) = sum(tx_qpsk_plot ~= rx_qpsk_plot)/length(tx_qpsk_plot);
    



end

figure();
semilogx(num_sub_carrier_list, SER_list, '.', 'MarkerSize',20);
title("Symbol error vs Subcarrier Frequency Spacing");
xlabel("Subcarrier Frequency Spacing");
ylabel("Symbol Error Rate");
axis padded;
yline(0, '-.');
xticks(num_sub_carrier_list)



exportgraphics(gcf,'plots/SER_FreqSpacing_test.png','Resolution',600)
