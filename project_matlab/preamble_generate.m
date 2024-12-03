function [preamble] = preamble_generate(length)
% preamble_generate() 
% input : length: a scaler value, desired length of preamble.
% output: preamble: preamble bits

preamble = ones(length, 1);

LFSR = ones(11, 1);

LFSR(9) = xor(LFSR(6), LFSR(8));
LFSR(10) = xor(LFSR(5), LFSR(9));
LFSR(11) = xor(LFSR(4), LFSR(10));

for i = 2:length
    LFSR(2:8) = LFSR(1:7);
    LFSR(1) = LFSR(11);
    LFSR(9) = xor(LFSR(6), LFSR(8));
    LFSR(10) = xor(LFSR(5), LFSR(9));
    LFSR(11) = xor(LFSR(4), LFSR(10));
    
    preamble(i) = LFSR(8);
end

preamble = 1 - 2*preamble;
end


