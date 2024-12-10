function [v] = extract_diagonal(M)
    v = zeros(size(M, 1), 1);
    
    for i = 1 : length(v)
        v(i) = M(i, i);
    end
end