function BER = Simulator_P1T2_template(SNR, mapping_type)

% Initialization
BER = zeros(size(SNR));

% number of bits
numbits = 10^4;
 
switch mapping_type
       case 'QAM4'
            bit_per_symbol = 2;
            Map_nonorm = [(-1-1j) (-1+1j) ( 1-1j) ( 1+1j)];  % not normalized symbols
       case 'QAM16'
            bit_per_symbol = 4;
            Map_nonorm = [(-3 + 3j) (-3 + 1j) (-3 - 3j) (-3 -1j) ...   % not normalized symbols
             (-1 + 3j) (-1 + 1j) (-1 - 3j) (-1 - 1j) ...
             (3 + 3j) (3 + 1j) (3 - 3j) (3 -1j) ...
             (1 + 3j) (1 + 1j) (1 - 3j) (1 - 1j)];
end 
numSyms = numbits/bit_per_symbol; % number of symbols 

% normalized mapping
      
switch mapping_type
       case 'QAM4'
            Map_norm = 1/sqrt(2) * Map_nonorm;  % not normalized symbols
       case 'QAM16'
            Map_norm = 1/sqrt(10) * Map_nonorm;
end 

for ii = 1: length(SNR)
    % Convert SNR from dB to linear
    SNRlin(ii) = 10^(SNR(ii)/10);
    % Generate source bitstream
    source = randi([0 1],numSyms,bit_per_symbol);

    % Map input bitstream into Symbols
    
    mappedGray = Map_norm(bi2de(source, 'left-msb')+1).';

    
    % Add AWGN
    
    mappedGrayNoisy = mappedGray + sqrt(1/(2*SNRlin(ii)))*(randn(numSyms,1) + 1j*randn(numSyms,1));

    % Demapping
    
    [~,ind] = min((ones(numSyms,bit_per_symbol*bit_per_symbol)*diag(Map_norm) - diag(mappedGrayNoisy)*ones(numSyms,bit_per_symbol*bit_per_symbol)),[],2);
    demappedGray = de2bi(ind-1, 'left-msb');
    
    % calculate BER
    BER(ii) = mean(source(:) ~= demappedGray(:));

end
