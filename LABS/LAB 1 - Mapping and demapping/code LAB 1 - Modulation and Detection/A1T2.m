const_blue = [-6-6i,-3i,3i,-3,3,6+6i];
const_red  = [-3-3i,-3+3i,3-3i,3+3i];
% Calculate here:



average_energy_blue = mean(abs(const_blue).^2);


average_energy_red = mean(abs(const_red).^2);

%normalized the constellation (we expect value with size(1, 6))
const_blue_norm = const_blue / sqrt(average_energy_blue);
    
const_red_norm = const_red / sqrt(average_energy_red);

%plot normalized constellations

% 3.2 observations
%
figure;

% Plot the first constellation (const_blue_norm)
plot(real(const_blue_norm), imag(const_blue_norm), 'bo', 'MarkerSize', 10, 'LineWidth', 2);

% Hold the current plot to add another constellation
hold on;

% Plot the second constellation (const_red_norm)
plot(real(const_red_norm), imag(const_red_norm), 'ro', 'MarkerSize', 10, 'LineWidth', 2); % Changed color to red for distinction

% Add grid and labels
grid on;
xlabel('In-Phase (Real Part)');
ylabel('Quadrature (Imaginary Part)');
title('Normalized Constellations of const\_blue and const\_red');

% Keep axes equal to ensure proper scaling
axis equal;

% Release the hold
hold off;
