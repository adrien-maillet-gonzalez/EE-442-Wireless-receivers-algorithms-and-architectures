profile on;
load('task2.mat', 'image_size', 'signal'); % load variable 'image_size' and 'signal'
num_sample_img = image_size(1)* image_size(2)*4;
detector_threshold=10;

preamble = preamble_gen_solution(100);
preamble_bpsk = -2*(preamble) + 1;

start = detector_solution(preamble_bpsk, signal, detector_threshold);

% read the payload here
image_bit_number = (prod(image_size) * 4) - 1;
payload = signal(start:start + image_bit_number);  % Extract from start to the last element


image = image_decoder(demapper(payload), image_size);
imshow(image)

profile viewer;
%threshold leading to false positive?
%