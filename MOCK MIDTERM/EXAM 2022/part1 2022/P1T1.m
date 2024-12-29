clear all, close, clc
SNR  = ...; % set SNR range in dB

BER_AWGN = Simulator_P1T1_template(SNR, 'awgn');
BER_Fading = Simulator_P1T1_template(SNR, 'fading');

% graphical ouput
figure(1)
clf(1)
semilogy(SNR, BER_AWGN, 'bx-' ,'LineWidth',3);
hold on
semilogy(SNR, BER_Fading, 'rx-' ,'LineWidth',3);

xlabel('SNR (dB)')
ylabel('BER')
legend('AWGN', 'Fading')
grid on

saveas(gcf, 'P1T1_BER.png');