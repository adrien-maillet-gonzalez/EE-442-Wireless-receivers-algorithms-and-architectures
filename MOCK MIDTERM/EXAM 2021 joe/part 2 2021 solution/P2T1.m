clc,clear

% load the received samples
load diversity_task_2_frames

% Constellation and pilot symbol
constellation = [1+1j -1+1j 1-1j -1-1j]*1/sqrt(2);
pilot_symb = (1+1j)/sqrt(2);

% ToDo 1.1:
h1_est = signal(1)/pilot_symb;

% ToDo 1.2:

msg1 = decode_msg(signal(2:73)/h1_est,constellation);

% ToDo 1.3:

h2_est = signal(1001)/pilot_symb;

msg2 = decode_msg(signal(1002:1073)/h2_est,constellation);

% ToDo 1.4
theta_1 = mod(angle(h1_est),2*pi);
theta_2 = mod(angle(h2_est),2*pi);

theta = [theta_1 theta_2];

mag_1 = abs(h1_est);
mag_2 = abs(h2_est);

mag = [mag_1 mag_2];

h_conj = exp(-1j*theta).*mag;

atn = [signal(2:73); signal(1002:1073)];

msg_comb = decode_msg(h_conj/norm(h_conj)^2 * atn,constellation);
    
% Plot and save the constellation
% ToDo 1.5
plot(real(msg_comb),imag(msg_comb), '.','Markersize',12),hold on

    
grid on,hold on,axis square
    
plot(constellation,'x','Markersize',12)
xlabel("Real")
xticks(-1:1/4:1)
ylabel("Imag")
yticks(-1:1/4:1)
title({strcat("Message frame 1: ",msg1);
       strcat("Message frame 2: ",msg2);
       strcat("Message combined: ",msg_comb)})

saveas(gcf,'P2T1_const.png')



