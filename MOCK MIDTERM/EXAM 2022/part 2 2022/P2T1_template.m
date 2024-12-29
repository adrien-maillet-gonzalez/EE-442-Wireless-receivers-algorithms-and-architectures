clc,clear,close all
data = load("P2T1_signal.mat");
% Get received signal and number of payload bits from file. 
rx_signal = data.rx_signal; % received signal, already synchronized.
n_bits = data.n_bits;       % number of payload bits transmitted

%initialise variables
rx_bits = zeros(n_bits,1);

%TODO Extract the pilot symbols and use them to compensate the effect of the phase noise.
constellation = [1+1j -1+1j 1-1j -1-1j]*1/sqrt(2);

pilot = (1+1j)/sqrt(2);

% ToDo 1.1:
h1_est = rx_signal(1)/pilot;

% ToDo 1.2:

[~, idx] = min(abs(rx_signal(2:73)/h1_est - constellation).^2, [], 2);
size(idx);
bit_stream = de2bi(idx-1, 2, 'left-msb');

image_decoder(bit_stream,[3, 3]);

% ToDo 1.3:

h2_est = rx_signal(1001)/pilot;

image_decoder(rx_signal(1002:1073)/h2_est,constellation);

% ToDo 1.4
theta_1 = mod(angle(h1_est),2*pi);
theta_2 = mod(angle(h2_est),2*pi);

theta = [theta_1 theta_2];

mag_1 = abs(h1_est);
mag_2 = abs(h2_est);

mag = [mag_1 mag_2];

h_conj = exp(-1j*theta).*mag;

atn = [rx_signal(2:73); rx_signal(1002:1073)];

image_decoder(h_conj/norm(h_conj)^2 * atn,constellation);
    
% Plot and save the constellation
% ToDo 1.5
plot(real(msg_comb),imag(msg_comb), '.','Markersize',12),hold on

%TODO Demodulate the payload symbols and recover the bits transmitted.(Don't forget to remove the pilot symbols)



% Plot Results and save
fig = figure(1);
subplot(1,2,1),grid on,axis('square'),hold on
%TODO plot the requested variables


%plot the payload content (nothing to change)
subplot(1,2,2)
image_decoder(rx_bits, data.img_size);
title('Payload')
saveas(fig, 'P2T1_results.png');





