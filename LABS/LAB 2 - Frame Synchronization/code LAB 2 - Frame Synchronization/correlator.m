function [c, c_norm] = correlator(p,r)
% Input:  p: preamble (shape = (Np, 1)), r: received signal (shape = (Nr, 1))
% output: c: correlated signal (shape = (Nr-Np+1, 1)), c_norm: normalized correlated signal (shape = (Nr-Np+1, 1))
Np = size(p,1);
Nr = size(r,1);
c = zeros(Nr-Np+1, 1);
c_norm = zeros(Nr-Np+1, 1);
%% TODO:
for i = 1:Nr-Np+1
    c(i) = p'*r(i:i+Np-1);
    
    c_norm(i) = abs(c(i))^2 / sum(abs(r(i:i+Np-1)).^2);
    
    % c(i)'*c(i) / (r(i:i+Np-1)'*r(i:i+Np-1))
    % this solution should be correct in theory but using MATLAB grader the
    % answer is not accepted and it says that the values are diff
end



end



