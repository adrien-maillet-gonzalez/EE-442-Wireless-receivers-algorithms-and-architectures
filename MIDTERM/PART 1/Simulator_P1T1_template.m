function BER = Simulator_P1T1_template(SNR, channel_type)
% Initialization
BER = zeros(size(SNR));
% number of symbols

num_frames = 100;  % simulate a number of frames
num_bits_frame = 2000;
num_symb_frame = num_bits_frame/2;  % define number of symbols in one frame
num_symb = num_frames * num_symb_frame;  % total number of symbols

num_bits = 2*num_symb;

GrayMap = 1/sqrt(2) * [(-1-1j) (-1+1j) ( 1+1j) ( 1-1j)];

for ii = 1: length(SNR)  % loop over all SNR values
    sum_error = 0;

    for kk = 1: num_frames   % loop over all frames
        % Convert SNR from dB to linear
        SNRlinear = 10^(SNR(ii)/10);

        % Generate source bitstream
        source = randi([0 1],num_symb_frame,2);

        % Map input bitstream using Gray mapping
        signal_Mapped = GrayMap(bi2de(source, 'left-msb')+1).';
        
        switch channel_type
            case 'awgn'
                h = 1;
            case 'fading'
                % Rayleigh Fading Channel
                h = (randn(1)+1i*randn(1))/sqrt(2); % !!!! we have to scale the noise as well
        end 
    
        % apply channel
        signal_Mapped_Channel = h * signal_Mapped;
        
        % add AWGN
        signal_Mapped_Channel_Noise = signal_Mapped_Channel + 1/sqrt(2*SNRlinear)*(randn(size(signal_Mapped_Channel))+ 1i*randn(size(signal_Mapped_Channel)));
        
        % invert the effect of the channel h
        signal_Mapped_Channel_Noise_InvChannel = 1/h * signal_Mapped_Channel_Noise;
        
        % Demap AWGN
        [~, idx] = min(abs(GrayMap - signal_Mapped_Channel_Noise_InvChannel).^2, [], 2);

        % remapped_signal = GrayMap(idx);

        bit_rx = de2bi(idx-1, 'left-msb', 2);


        % calculate error
        error = sum(source(:) ~= bit_rx(:));
        sum_error = sum_error + error;

    end
    
    % BER calculation for Gray mapping
    
    
    BER(ii) = sum_error / (num_bits);

end
end
