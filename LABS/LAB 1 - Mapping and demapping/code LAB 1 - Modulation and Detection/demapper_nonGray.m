function [b] = demapper_nonGray(symbol)
%DEMAPPER Summary of this function goes here
%   Detailed explanation goes here
bit1 = real(symbol) < 0;

if imag(symbol) < 0 && bit1
    bit2 = 1;
elseif imag(symbol) >= 0 && bit1
    bit2 = 0;
elseif imag(symbol) >= 0 && ~bit1
    bit2 = 1;
else
    bit2 = 0;
end

% b is a two colomn vector col1: real, col2: imag
b = [bit1 bit2];
b = b';
b = b(:);

end

