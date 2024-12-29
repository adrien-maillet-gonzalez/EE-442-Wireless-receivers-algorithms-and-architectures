clear all

SNR  = -10:2:24;   % set SNR range in dB

BER_QAM4 = Simulator_P1T2_template(SNR, 'QAM4');
BER_QAM16 = Simulator_P1T2_template(SNR, 'QAM16');


% graphical ouput
figure(1)
clf(1)
semilogy(SNR, BER_QAM4, 'bx-' ,'LineWidth',3);
hold on
semilogy(SNR, BER_QAM16, 'rx-' ,'LineWidth',3);

title("BER comparison task 2")
xlabel('SNR (dB)')
ylabel('BER')
legend('QAM4', 'QAM16')
grid on


saveas(gcf, 'P1T2_BER.png')