SNR_range = -6:2:12;
L = 1e4;

rng(123)

% Initialize
BER_list_Gray = zeros(size(SNR_range));
BER_list_NonGray = zeros(size(SNR_range));
    

% Gray mapping (Symbols, normalized)
GrayMap = 1/sqrt(2) * [(-1-1j) (-1+1j) ( 1-1j) ( 1+1j)];

% Non-Gray mapping (Symbols, normalized)
NonGrayMap = 1/sqrt(2) * [( 1-1j) ( 1+1j) (-1+1j) (-1-1j)];


    
for ii = 1:numel(SNR_range) 
    % Convert SNR from dB to linear (in one loop SNRlin a scalar value)
    SNRlin = 10^(SNR_range(ii)/10);
    
    % Generate source bitstream
    source = randi([0 1],L,2);
       
    % Map input bitstream using Gray mapping
    mappedGray = GrayMap(bi2de(source, 'left-msb')+1);
        
    if ii == 1
        mappedGray_record = mappedGray;
    end
      
    % Add AWGN
    mappedGrayNoisy = add_awgn_solution(mappedGray, SNRlin);
        
    % Demap
    

    [~, idx_map] = min(abs(GrayMap - mappedGrayNoisy.').^2, [], 2);

    demappedGray = de2bi(idx_map-1, 2, 'left-msb');

 


    if ii == 1
        demappedGray_record = demappedGray;
    end
        
    % BER calculation for Gray mapping
    BER_list_Gray(ii) = mean(source(:) ~= demappedGray(:));
        
    % Map input bitstream using non-Gray mapping
    mappedNonGray = NonGrayMap(bi2de(source, 'left-msb')+1).';
    if ii == 1
        mappedNonGray_record = mappedNonGray;
    end
          
          
    % Add AWGN
    mappedNonGrayNoisy = add_awgn_solution(mappedNonGray, SNRlin);
        
    % Demap
    demappedNonGray = zeros(L, 2);
    for k=1:L
        b = demapper_nonGray(mappedNonGrayNoisy(k));
        demappedNonGray(k, 1) = b(1);
        demappedNonGray(k, 2) = b(2);
    end

    if ii == 1
        demappedNonGray_record = demappedNonGray;
    end
        
        
    % BER calculation for Gray mapping
    BER_list_NonGray(ii) = mean(source(:) ~= demappedNonGray(:));
end


%% uncomment this part for plot
%% graphical output
figure;
semilogy(SNR_range, BER_list_Gray, 'bx-' ,'LineWidth',3)

hold on
semilogy(SNR_range, BER_list_NonGray, 'r*--','LineWidth',3);

xlabel('SNR (dB)')
ylabel('BER')
legend('Gray Mapping', 'Non-Gray Mapping')
grid on

