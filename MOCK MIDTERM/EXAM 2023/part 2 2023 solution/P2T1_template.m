clc,clear,close all

%-------------------------- Load Data -------------------------------
data = load("P2T1_signal.mat");
% Received signal, already synchronized. Each column corresponds to the 
% signal received by one antenna.
rx_signal = data.rx_signal;

% number of payload bits transmitted for each frame
n_bits = data.n_bits; 

%------------------------- Process Data -----------------------------
% TODO: Use pilots to estimate the channel for each frame

% TODO: Use the channel estimate to perform a maximum ratio combining of
% the signals
constellation_original = [1+sqrt(3), 1+1j, 1j*(1+sqrt(3)),-1+1j,-1-sqrt(3),  -1-1j, -1j*(1+sqrt(3)), 1-1j];
power_constellation = mean(abs(constellation_original).^2);

constellation = constellation_original/sqrt(power_constellation);


reference_symbol = (1 + 1j)/sqrt(power_constellation);

nb_antennas = size(rx_signal, 2);
nb_frames = length(rx_signal) / 5000;
pilot_symbols = zeros(nb_frames, nb_antennas);
channel = zeros(nb_frames, nb_antennas);

for i = 1:nb_antennas
    pilot_symbols(:,i) = rx_signal(1:5000:end,i);
    channel(i,:) = abs(pilot_symbols(i,:) * reference_symbol);
end

for k=0:nb_frames-1
    mag = (conj(channel(:,k+1)) /norm(channel(:,k+1))^2);
    mag = reshape(mag,2,1);
    size(rx_signal(k+1:k+1+n_bits,:)')
    for jj =1:2

    rxsymbols(k, 1) = mag(1) * rx_signal(k*5000+1:k+1+n_bits,1);
    rxsymbols(k,2) = mag(2) * rx_signal(k*5000+1:k+1+n_bits,2);
    end
end


% TODO: Demap the payload symbols and recover the bits transmitted

rx_bits = reshape(rxsymbols.',1,nb_frames*n_bits);

% Recover message from rx_bits (a one dimentional vector). 
%msg = char(bi2de(reshape(rx_bits,8,[]).','left-msb').');

%-------------------- Plot Results and save --------------------------
plot(constellation,'x')
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






