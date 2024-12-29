function BER = Simulator_P1T1_template(SNR, channel_type)
% Initialization
BER = zeros(size(SNR));
% number of symbols

numFrames = 100;  % simulate a number of frames
numSym_frame = 1000;  % define number of symbols in one frame
numSym = numFrames * numSym_frame;  % total number of symbols

GrayMap = 1/sqrt(2) * [(-1-1j) (-1+1j) ( 1-1j) ( 1+1j)];

for ii = 1: length(SNR)  % loop over all SNR values
    sum_error = 0;

    for kk = 1: numFrames   % loop over all frames
        % Convert SNR from dB to linear
        
        SNRlin(ii) = 10^(SNR(ii)/10);
        % Generate source bitstream
        
        source = randi([0 1],numSym_frame,2);

        % Map input bitstream using Gray mapping
        
        mappedGray = GrayMap(bi2de(source, 'left-msb')+1).';
        
        switch channel_type
            case 'awgn'
                h = 1;
            case 'fading'
                % Rayleigh Fading Channel
                h = randn(1) + 1j*randn(1);
                disp(h)
        end 
    
        % apply channel
        
        mapped_channel = h*mappedGray;

        % add AWGN
        
        mappedGrayNoisy = mapped_channel + sqrt(1/(2*SNRlin(ii)))*(randn(numSym_frame,1) + 1j*randn(numSym_frame,1));

        % matched filter
        
        matched_data = mappedGrayNoisy./h;

        
        % Demap AWGN
        
        [~,ind] = min((ones(numSym_frame,4)*diag(GrayMap) - diag(matched_data)*ones(numSym_frame,4)),[],2);
        demappedGray = de2bi(ind-1, 'left-msb');

        % calculate error
        
        sum_error = sum_error + sum(source(:) ~= demappedGray(:));
        
    end
    
    % BER calculation for Gray mapping
    
    BER(ii) = sum_error/numSym ;

end
end
