
rng(32)
% Set parameters
os_factor = 4;
SNR  = 5;

load ber_pn_seq
load pn_sequence

data_length = length(ber_pn_seq)/2; % Number of QPSK data symbols

% convert SNR from dB to linear
SNRlin = 10^(SNR/10);

% add awgn channel
rx_signal = signal + sqrt(1/(2*SNRlin)) * (randn(size(signal)) + 1i*randn(size(signal)) );

% Matched filter
filtered_rx_signal = matched_filter(rx_signal, os_factor, 6);

% Frame synchronization
data_idx = frame_sync(filtered_rx_signal, os_factor); % Index of the first data symbol

data = zeros(1,data_length);
data2 = zeros(1,data_length);

cum_err = 0;
diff_err = zeros(1,data_length);
epsilon  = zeros(1,data_length);

frame_sync_length = 100;

% Use preamble symbols to improve timing offset estimation (Task 3)

%Use preamble symbols to improve timing offset estimation (1 for loop)
%TODO

for ii=1:frame_sync_length % option 1

     idx_start  = data_idx+(ii-1)*os_factor-frame_sync_length*os_factor;

     idx_range  = idx_start:idx_start+os_factor-1;
     segment    = filtered_rx_signal(idx_range);

     % Estimate timing error epsilon
     [~ , cum_err] = epsilon_estimation_solution(segment, cum_err);



end

% % Use preamble symbols to improve timing offset estimation (Task 3)
% for ii = -frame_sync_length:-1 % option 2 (solution moodle)
% 
%     idx_start  = data_idx+ii*os_factor;
% 
%     idx_range  = idx_start:idx_start+os_factor-1;
%     segment    = filtered_rx_signal(idx_range);
% 
%     % Estimate timing error epsilon
%     pwr         = abs(segment).^2;
%     diff_err = [1 -1j -1 1j]*pwr;
%     cum_err     = cum_err + diff_err;
% end

%%%% !!!!!!!

%Attention, ici j'avais un problème avec mon calcul de "diff_err"
%
% puisque l'indice de "idx_range" n'est pas forcément un multiple de 4,
% lorque je calcule la somme (voir 4.7), c'est comme si je calcule la somme
% en partant de k = 1 au lieu de k = 0. Cela signifie que toute la somme
% est "multipliée par 1i". Et la conséquence est que je trouvait une somme
% du préambule "cum_err" opposée à celle que j'aurais du avoir. En
% utilisant le vecteur [1 -1i -1 1i], j'évite ce problème.

% cum_err
% % 2.6544 - 3.3711i
% 
% data_idx

for ii=1:data_length
    
     idx_start  = data_idx+(ii-1)*os_factor;
     
     idx_range  = idx_start:idx_start+os_factor-1;
     segment    = filtered_rx_signal(idx_range);
    
     % Estimate timing error epsilon
     [epsilon_tmp, cum_err] = epsilon_estimation_solution(segment, cum_err);
     epsilon(ii) = epsilon_tmp;
     
     y_hat = linear_interpolation_solution(epsilon(ii), filtered_rx_signal, os_factor, idx_start);
     data(ii) = y_hat;   

end

BER_lin = mean(demapper(data) ~= ber_pn_seq)

% Plot epsilon
figure
plot(1:data_length, epsilon)
xlim([0,400])
title(sprintf("Inital phase estimate = %.2f",epsilon(1)))

