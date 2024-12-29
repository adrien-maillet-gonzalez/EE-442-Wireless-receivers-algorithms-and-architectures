function [start] = detector(p,r, thr)
% Input :   p: preamble (shape = (100, 1)), r: received signal (shape = (Nr, 1)), thr: scalar threshold 
% output:   start: signal start index
Np = size(p,1);
Nr = size(r,1);
c = zeros(Nr-Np, 1);
c_norm = zeros(Nr-Np, 1);
%% TODO
for i = 1:Nr-Np+1
    c(i) = p'*r(i:i+Np-1);
    
    c_norm(i) = abs(c(i))^2 / sum(abs(r(i:i+Np-1)).^2);
    
    if c_norm(i) > thr
        start = i + Np;
        return;
    end
end



% after loop no threshold reached
disp('Frame start not found.')
start = -1;
end