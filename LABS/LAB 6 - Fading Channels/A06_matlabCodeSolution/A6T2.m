rng(159)

% Oversampling factor
param.os_factor    = 4;

% SNR
param.SNR          = 6;
param.noAntenna    = 3;
param.receiverMode = 'singleAntenna'; % Possible values; singleAntenna / AntennaSelect / MaximumRatioCombining
param.noframes = 1;

load pn_sequence_fading
load ber_pn_seq
ber_pn_seq = repmat(ber_pn_seq,param.noframes,1);
signal = repmat(signal,param.noframes,1);
param.data_length = length(ber_pn_seq)/2;    

combined_rxsymbols = receiver_diversity(signal, param);


rxbitstream = demapper(combined_rxsymbols); % Demap Symbols


BER = sum(rxbitstream ~= ber_pn_seq)/length(ber_pn_seq)

%% plot with the different SNR to check the curve

SNR = 2:2:12;

listBER = zeros(size(SNR));

for i=1:size(SNR,2)
    
    % SNR
    param.SNR          = SNR(i);
    param.noAntenna    = 3;
    param.receiverMode = 'singleAntenna'; % Possible values; singleAntenna / AntennaSelect / MaximumRatioCombining
    param.noframes = 1;
    
    load pn_sequence_fading
    load ber_pn_seq
    ber_pn_seq = repmat(ber_pn_seq,param.noframes,1);
    signal = repmat(signal,param.noframes,1);
    param.data_length = length(ber_pn_seq)/2;    
    
    combined_rxsymbols = receiver_diversity(signal, param);
    
    
    rxbitstream = demapper(combined_rxsymbols); % Demap Symbols
    
    
    BER = sum(rxbitstream ~= ber_pn_seq)/length(ber_pn_seq);
    listBER(i) = BER;
end

figure(89013);
clf(89013)
semilogy(SNR, listBER);