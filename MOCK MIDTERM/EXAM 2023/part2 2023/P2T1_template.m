clc,clear all,close all

%-------------------------- Load Data -------------------------------
data = load("P2T1_signal.mat");
% Received signal, already synchronized. Each column corresponds to the 
% signal received by one antenna.
rx_signal = data.rx_signal;

n_antennas = size(rx_signal,2);

% number of payload bits transmitted for each frame
n_bits = data.n_bits; 

%------------------------- Process Data -----------------------------
% TODO: Use pilots to estimate the channel for each frame

constellation_original = [1+sqrt(3), 1+1j, 1j*(1+sqrt(3)),-1+1j,-1-sqrt(3),  -1-1j, -1j*(1+sqrt(3)), 1-1j];
power_constellation = mean(abs(constellation_original).^2);

constellation = constellation_original/sqrt(power_constellation);


pilot_ref = (1 + 1j)/sqrt(power_constellation);

nb_antennas = size(rx_signal, 2);
nb_frames = length(rx_signal) / 5000;
pilot_rx = zeros(nb_frames, nb_antennas);
channel = zeros(nb_frames, nb_antennas);

for i = 1:nb_antennas
    pilot_rx(:,i) = rx_signal(1:5000:end,i);
    channel(:,i) = pilot_rx(:,i)./pilot_ref;
end

% TODO: Use the channel estimate to perform a maximum ratio combining of
% the signals
channel = reshape(channel, 8, 1);
magnitude_channel = abs(channel);
theta_channel = mod(angle(channel), 2*pi);

h_conj = magnitude_channel(:).*exp(-1j*theta_channel(:));

data_length = 8*271 + 1;
received_data = [rx_signal(2:data_length, 1), rx_signal(2+5000:data_length+5000,1) , rx_signal(2+2*5000:data_length+2*5000,1), rx_signal(2+3*5000:data_length+3*5000,1), ...
    rx_signal(2:data_length, 2), rx_signal(2+5000:data_length+5000,2) , rx_signal(2+2*5000:data_length+2*5000,2), rx_signal(2+3*5000:data_length+3*5000,2)];

rx_symb_comb = received_data * h_conj / norm(h_conj)^2;

% TODO: Demap the payload symbols and recover the bits transmitted

[~, idx] = min(abs(rx_symb_comb - constellation).^2,[], 2);


rx_bits = de2bi(idx-1, 3, 'left-msb');


% Recover message from rx_bits (a one dimentional vector). 
msg = char(bi2de(reshape(rx_bits,8,[]).','left-msb').');

%-------------------- Plot Results and save --------------------------
fig = figure;
subplot(1,2,1), grid on, axis square, hold on
plot(rx_signal(:),'.')
plot(rx_symb_comb(:),'.')
plot(constellation,'x')
title('IQ plot')
xlabel('I'), ylabel('Q')
legend('Received symbols','Corrected symbols','Constellation',Location="southoutside");

subplot(1,2,2)
text(0,0.45,msg,FontSize=8,fontname="Monospaced"); axis off
title("Decoded message")
saveas(fig, 'P2T1_results.png');






