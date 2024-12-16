
function [beginning_of_data, phase_of_peak] = frame_sync(rx_signal, OS_factor, conf)

% Frame synchronizer.
% rx_signal is the noisy received signal, andOS_factor is the oversampling factor (OS_factor=1 in chapter 2, OS_factor=4 in all later chapters).
% The returned value is the index of the first data symbol in rx_signal.


detection_threshold = 12;

% Calculate the frame synchronization sequence and map it to BPSK: 0 -> +1, 1 -> -1
frame_sync_sequence = conf.preamble_bpsk;
frame_sync_length = length(frame_sync_sequence);
% When processing an oversampled signal (L>1), the following is important:
% Do not simply return the index where T exceeds the threshold for the first time. Since the signal is oversampled, so will be the
% peak in the correlator output. So once we have detected a peak, we keep on processing the next OS_factor samples and return the index
% where the test statistic takes on the maximum value.
% The following two variables exist for exactly this purpose.
current_peak_value = 0;
samples_after_threshold = OS_factor;



T_list = [];

corVal = [];
for i = OS_factor * frame_sync_length + 1 : length(rx_signal)
    r = rx_signal(i -OS_factor * frame_sync_length :OS_factor : i -OS_factor); % The part of the received signal that is currently inside the correlator.
    c = frame_sync_sequence' * r;
    T = abs(c)^2 / abs(r' * r);

    T_list = [T_list, T];
   
    
    corVal = [corVal T]; 
    
    if (T > detection_threshold || samples_after_threshold < OS_factor)
        samples_after_threshold = samples_after_threshold - 1;
        if (T > current_peak_value)
            beginning_of_data = i;
            current_peak_value = T;
            phase_of_peak = mod(angle(c), 2*pi);
        end
        if (samples_after_threshold == 0)
            %display(['Frame starts at ',num2str(beginning_of_data),'th symbol'])
            %plot(corVal,'r-')
            %xlabel('Offset [symbols]')
            %ylabel('Normalized autocorrelation')
            %grid on
            nexttile
            plot(T_list)
            title("T list");
            return;
        end
    end
    
end

nexttile
plot(T_list)
title("T list");
error('No synchronization sequence found.');
end




function output = lfsr_framesync(output_length)
% A linear feedback shift register (LFSR) which outputs a PN sequence of length output_length.
% The current LFSR has a period length of 255, but the polynomial can easily be changed for a longer one.

% The implementation of this shift register is not very efficient, bit operations would be faster.
% But this version is more readable, so who cares...

% feed back polynomial
% this one here means:
% x^0 + x^2 + x^3 + x^4 + x^8
% The term x^8 is only implicitly given by the length of the polynomial
polynomial = [1 0 1 1 1 0 0 0]';

% All memories are initialized with ones
state = ones(size(polynomial));

output = zeros(output_length, 1);

for i = 1:output_length,
    output(i) = state(1);
    feedback = mod(sum(state .* polynomial), 2);
    state = circshift(state, -1);
    state(end) = feedback;
end
end
