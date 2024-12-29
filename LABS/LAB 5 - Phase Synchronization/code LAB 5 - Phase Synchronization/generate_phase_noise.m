function theta_n = generate_phase_noise(length_of_noise, sigmaDeltaTheta)
    % Create phase noise
    theta_n = zeros(length_of_noise,1);
    %% TODO
    
    % Set a random starting phase using rand() for uniform distribution
    starting_phase = 2 * pi * rand(); 
    theta_n(1) = starting_phase; % Initialize with the starting phase
    
    for i = 2:length_of_noise
        % Add random increment to the previous value
        delta_theta = sigmaDeltaTheta * randn(); % Generate random increment
        theta_n(i) = mod(theta_n(i-1) + delta_theta, 2*pi); % Random walk step
    end
    
end