clear all;
close all;
rng(123);

addpath("functions/")
addpath("images/")
addpath("audio/")
addpath('plots/');
conf.str_plot = 'test';


% Configuration Values
conf.audiosystem = 'matlab'; % Values: 'matlab','native','bypass'
conf.data_type = "random"; % Values: 'image', 'random'

conf.enable_phase_tracking = false;

conf.enable_multi_training = true;
conf.training_period = 15;

%% Upload image

image_file = 'pyramid.png';

[binary_stream, conf] = image_to_bitstream(image_file, conf);

%% Select the data to transmit

if conf.data_type == "image"
    txbits = binary_stream;

elseif conf.data_type == "random"
    num_ofdm_symbols = 90; % Specify the number of random OFDM symbols to send
    txbits = randi([0 1],256*2*num_ofdm_symbols,1);

end

%% Configure frequencies
conf.f_carrier            = 14000;
conf.N                    = 256;  % number of subcarriers
conf.cyclic_prefix_len    = 32;
conf.preamble_len         = 100;


conf.SNR_db               = 20;   % artificial noise 
conf.sigmaDeltaTheta      = 0.05; % artificial phase shift
    

conf = init_conf(conf, txbits);   % initialize the configuration variable


%plotting options for the nice unique plot thing
tiledlayout(2,4)
    

%% Transmission of data  
[txsignal, conf] = tx(txbits,conf);


% % % % % % % % % % % %
% Begin
% Audio Transmission
%
for audio_transmission = 1 % used to minimize this section

% normalize values (to avoid saturation of the speaker)
peakvalue       = max(abs(txsignal));
normtxsignal    = txsignal / (peakvalue + 1.5);

nexttile
plot(txsignal);
title("TX Signal");


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

nexttile
plot(rxsignal);
title("RX signal");

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
figure();
tiledlayout(2,1);
nexttile;
tx_qpsk_plot = conf.qpsk(bi2de(reshape(txbits, size(txbits, 1)/2, 2), 'left-msb')+1).';
rx_qpsk_plot = conf.qpsk(bi2de(reshape(rxbits, size(rxbits, 1)/2, 2), 'left-msb')+1).';
moving_average_error = movmean(tx_qpsk_plot ~= rx_qpsk_plot, 1);
plot(moving_average_error, '.');
title("Symbol error");
xlabel("Time");
ylabel("Symbol error");
axis padded;
yline(0, '-.');

% Evolution of the Phase over time
nexttile;
angle_error = movmean(mod(4*angle(conf.rx_serial_symbols(:)).', 2*pi), 1).';
plot(angle_error, '.');
title("Phase (4*angle)");
xlabel("Time");
ylabel("Phase");
axis padded;
yline(pi, '-.');
yline(2*pi, '-.');
yline(0, '-.');


exportgraphics(gcf,"plots/error_image_"+conf.str_plot+".png",'Resolution',600)

%% Output the image
if conf.data_type == "image"
    % convert to uint8
    rxbits_8bits = reshape(rxbits, [], 8);
    gray_image_rx = bi2de(rxbits_8bits,"left-msb");
    
    % reshape into image format
    gray_image_rx = reshape(gray_image_rx, conf.image_size);
    
    % displax image
    figure()
    imshow(gray_image_rx,[0 255]);
    title(image_file)
    exportgraphics(gcf,"plots/image_basic_"+conf.str_plot+".png",'Resolution',600)
end

