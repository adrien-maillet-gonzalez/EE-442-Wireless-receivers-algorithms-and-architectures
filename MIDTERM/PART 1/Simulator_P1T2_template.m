function BER = Simulator_P1T2_template(SNR, mapping_type)
%default values
if nargin < 1
    SNR=100;
    mapping_type ="QAM16";
end

% Initialization
BER = zeros(size(SNR));

% number of bits
numbits = 10^4;

QAM16 = [(-3 + 3j) (-3 + 1j) (-3 - 3j) (-3 -1j) ...   % not normalized symbols
             (-1 + 3j) (-1 + 1j) (-1 - 3j) (-1 - 1j) ...
             (3 + 3j) (3 + 1j) (3 - 3j) (3 -1j) ...
             (1 + 3j) (1 + 1j) (1 - 3j) (1 - 1j)];

power_QAM16 = mean(abs(QAM16).^2);
 
switch mapping_type
       case 'QAM16'
            constellation_norm = QAM16 / sqrt(power_QAM16);

       case 'PSK16'
            constellation_norm = exp([0,1,3,2,7,6,4,5,15,14,12,13,8,9,11,10].*j*2*pi/16);          

    otherwise
        error("Mapping type not supported")
end 

% normalized mapping

for ii = 1: length(SNR)
    % Convert SNR from dB to linear
    SNRlinear = 10^(SNR(ii)/10);

    % Generate source bitstream
    source = randi([0 1],numbits,4);

    % Map input bitstream into Symbols

    tx_symbols = constellation_norm(bi2de(source, 'left-msb', 2)+1);
   
    % Add AWGN

    noisy_signal = tx_symbols + 1/sqrt(2*SNRlinear) * (randn(size(tx_symbols)) + 1i*randn(size(tx_symbols)));
    size(noisy_signal)
    size(constellation_norm)
    % Demapping
    [~, idx] = min(abs(noisy_signal-constellation_norm.').^2, [], 1);

    size(idx)

    rx_bits = de2bi(idx.'-1, 'left-msb', 4);

    % calculate BER
    BER(ii) = mean(source(:) ~= rx_bits(:));

end
