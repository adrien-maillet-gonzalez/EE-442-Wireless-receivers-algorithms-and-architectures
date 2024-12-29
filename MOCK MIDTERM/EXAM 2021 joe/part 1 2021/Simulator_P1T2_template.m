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
         

for ii = 1: length(SNR)
    % Convert SNR from dB to linear

    % Generate source bitstream
    

    % Map input bitstream into Symbols
    
    
    % Add AWGN
    
    % Demapping
    
    % calculate BER
    BER(ii) = ...;

end
