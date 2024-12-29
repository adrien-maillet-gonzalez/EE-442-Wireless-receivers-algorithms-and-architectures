function BER = Simulator_P1T1_template(SNR, channel_type)
% Initialization
BER = zeros(size(SNR));
% number of symbols

num_frames = ...;  % simulate a number of frames
num_symb_frame = ...;  % define number of symbols in one frame
num_symb = num_frames * num_symb_frame;  % total number of symbols

for ii = 1: length(SNR)  % loop over all SNR values
    sum_error = 0;

    for kk = 1: num_frames   % loop over all frames
        % Convert SNR from dB to linear
        

        % Generate source bitstream
        

        % Map input bitstream using Gray mapping
        
        
        switch channel_type
            case 'awgn'
                h = 1;
            case 'fading'
                % Rayleigh Fading Channel
                h = ...;
        end 
    
        % apply channel
        
        % add AWGN
        
        % invert the effect of the channel h
        
        
        % Demap AWGN

        % calculate error

    end
    
    % BER calculation for Gray mapping
    
    BER(ii) = ...;

end
end
