function combined_rxsymbols = receiver_diversity(signal, param)

os_factor = param.os_factor;

% SNR
SNR = param.SNR;
noAntenna = param.noAntenna;
receiverMode = param.receiverMode;
data_length = param.data_length;
noframes = param.noframes;

symbolsperframe = data_length/noframes;
rxsymbols = zeros(noframes,symbolsperframe);


    
% Loop through all frames in this part there is only one frame
for k=1:noframes
   
    Frame = signal(k,:);
    
    % Apply Rayleigh Fading Channel
    h = randn(noAntenna,1)+1i*randn(noAntenna,1);
    chanFrame = h * Frame;
    
    % Add White Noise
    SNRlin = 10^(SNR/10);
    noiseFrame = chanFrame + 1/sqrt(2*SNRlin)*(randn(size(chanFrame)) + 1i*randn(size(chanFrame)));
    
    for i=1:noAntenna
        % Matched Filter
        filtered_rx_signal(i,:) = matched_filter(noiseFrame(i,:), os_factor, 6); % 6 is a good value for the one-sided RRC length (i.e. the filter has 13 taps in total)

        % Frame synchronization
        [data_idx(i) theta(i) magnitude(i)] = frame_sync_solution(filtered_rx_signal(i,:).', os_factor); % Index of the first data symbol
    end
  
    switch receiverMode
            case 'singleAntenna',
                %TODO 1: Use only the signal of the 1st antenna             
    
                
                correct_samples = filtered_rx_signal(1,data_idx(1):os_factor:data_idx(1)+(symbolsperframe*os_factor)-1);

                h1 = magnitude(1) * exp(1j*theta(1)); % Channel of the first antenna

                rxsymbols(k,:) = 1/h1 * correct_samples;
                    
            case 'AntennaSelect',
                %TODO 2: Use the signal of the antenna with the maximum received amplitude

                [~, idx_h] = max(magnitude);


                correct_samples = filtered_rx_signal(idx_h,data_idx(idx_h):os_factor:data_idx(idx_h)+(symbolsperframe*os_factor)-1);

                h_selected = magnitude(idx_h) * exp(1j*theta(idx_h)); % Channel of the first antenna

                rxsymbols(k,:) = 1/h_selected * correct_samples;               
                
            case 'MaximumRatioCombining',
                %TODO 3: Coherently combine the signal the signal of all available antennas
                % combine all the antennas signal
                h_conj = exp(-1j*theta).*magnitude;
                correct_samples = filtered_rx_signal(:,data_idx(1):os_factor:data_idx(1)+(symbolsperframe*os_factor)-1);
                rxsymbols(k,:)  = h_conj/norm(h_conj)^2 * correct_samples;    
    end   
end

combined_rxsymbols = reshape(rxsymbols.',1,noframes*symbolsperframe);
end