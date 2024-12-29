function [message] = decode_msg(rx_symb,const)
%DECODE_MSG extract the string encoded in the provided symbols using
%ASCII code.
%   rx_symb: vector of symbols
%   const: the constellation to use to demap the symbols the message
%
%   message: The decoded string

% ensure rx_symb is a column vector
rx_symb = rx_symb(:);
[~,idx] = min(repmat(const,length(rx_symb),1)-repmat(rx_symb,1,length(const)),[],2);

%get bytes
bin_char = reshape(dec2bin(idx-1).',8,[]).';
message = reshape(char(bin2dec(bin_char)),1,[]);
end

