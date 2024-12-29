clc,clear

% load the received samples
load diversity_task_2_frames

% Constellation and pilot symbol
constellation = [1+j -1+j 1-j -1-j]*1/sqrt(2);
pilot_symb = (1+1j)/sqrt(2);

% ToDo 1.1:
h1_est = ...

% ToDo 1.2:

msg1 = decode_msg(...,constellation)

% ToDo 1.3:

h2_est = ...

msg2 = decode_msg(...,constellation)

% ToDo 1.4

msg_comb = decode_msg(...,constellation)
    
% Plot and save the constellation
% ToDo 1.5
plot(..., '.','Markersize',12),hold on
    
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



