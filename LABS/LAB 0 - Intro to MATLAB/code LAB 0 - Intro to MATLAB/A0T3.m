% Start time measurement
tic();

% Source: Generate random bits
txbits = randi([0 1],1000,1);

% Mapping: Bits to symbols 
symbols = ['A', 'B'];  % Define symbols once
tx = symbols(txbits + 1)';  % Use the bits to index into the symbols array


% Channel: Apply BSC
% Generate random values for the error occurrence
randvals = rand(1000, 1);

% Create rx array, initially identical to tx
rx = tx;

% Logical indexing for positions where randvals < 0.2
flipIndices = randvals < 0.2;

% Flip the values at the specified indices
rx(flipIndices & (tx == 'A')) = 'B';
rx(flipIndices & (tx == 'B')) = 'A';

% Demapping: Symbols to bits
rxbits = rx == 'B';  % Logical comparison: 'B' corresponds to 1, 'A' to 0


% BER: Count errors
errors = sum(rxbits ~= txbits);  % Count where bits are not equal


% Output result
err_rate = errors/1000;
disp(['BER: ' num2str(err_rate*100) '%'])

% Stop time measurement
runTime = toc
