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

rx_symb_comb = ...

% TODO: Demap the payload symbols and recover the bits transmitted
constellation = ...

rx_bits = ...

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






