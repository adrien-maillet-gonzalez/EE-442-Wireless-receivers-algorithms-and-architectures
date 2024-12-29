clear all

SNR  = ...;   % set SNR range in dB

BER_QAM4 = Simulator_P1T2(SNR, 'QAM4');
BER_QAM16 = Simulator_P1T2(SNR, 'QAM16');


% graphical ouput
figure(1)
clf(1)
semilogy(SNR, BER_QAM4, 'bx-' ,'LineWidth',3);
hold on
semilogy(SNR, BER_QAM16, 'rx-' ,'LineWidth',3);

xlabel('SNR (dB)')
ylabel('BER')
legend('QAM4', 'QAM16')
grid on


saveas(gcf, 'P1T2_BER.png')