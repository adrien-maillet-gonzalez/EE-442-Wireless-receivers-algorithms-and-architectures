function BER = Simulator_P1T1_template(SNR, channel_type)
% Initialization
BER = zeros(size(SNR));
% number of symbols

num_frames = 10;  % simulate a number of frames
num_symb_frame = 2000;  % define number of symbols in one frame
num_symb = num_frames * num_symb_frame;  % total number of symbols

GrayMap = 1/sqrt(2) * [(-1-1j) (-1+1j) ( 1-1j) ( 1+1j)];

for ii = 1: length(SNR)  % loop over all SNR values
    sum_error = 0;
    for kk = 1: num_frames   % loop over all frames
        % Convert SNR from dB to linear
        SNRlin = 10^(SNR(ii)/10);

        % Generate source bitstream
        source = randi([0 1],num_symb_frame,2);

        % Map input bitstream using Gray mapping
        Frame = GrayMap(bi2de(source, 'left-msb')+1).';
        
        switch channel_type
            case 'awgn'
                h = 1;
            case 'fading'
                % Rayleigh Fading Channel
                h = randn(1)+1i*randn(1);
        end 
    
        % apply channel
        chanFrame = h * Frame;
        % add AWGN
        noise_frame = chanFrame + 1/sqrt(2*SNRlin)*(randn(size(chanFrame)) + 1i*randn(size(chanFrame)));

        % invert the effect of the channel h
        noise_frame = 1 / h * noise_frame;
        % Demap AWGN
        [~,ind] = min((ones(num_symb_frame,length(GrayMap))*diag(GrayMap) - diag(noise_frame)*ones(num_symb_frame,length(GrayMap))),[],2);
        demapped = GrayMap(ind);
        % calculate error
        error = mean(Frame(:) ~= demapped(:));
        sum_error = sum_error + error;

    end
    
    % BER calculation for Gray mapping
    
    BER(ii) = sum_error / num_symb;

end
end
