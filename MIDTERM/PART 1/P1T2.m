clear all,clc

SNR  = 0:2:20;   % set SNR range in dB
warning("Choose a proper SNR range")

BER_QAM16 = Simulator_P1T2_template(SNR, 'QAM16');
BER_PSK16 = Simulator_P1T2_template(SNR, 'PSK16');


% graphical ouput
figure(1)
clf(1)
semilogy(SNR, BER_QAM16, 'bx-' ,'LineWidth',3);
hold on
semilogy(SNR, BER_PSK16, 'rx-' ,'LineWidth',3);

xlabel('SNR (dB)')
ylabel('BER')
legend('QAM16', 'PSK16')
grid on
ylim([1e-3,1])

saveas(gcf, 'P1T2_BER.png')