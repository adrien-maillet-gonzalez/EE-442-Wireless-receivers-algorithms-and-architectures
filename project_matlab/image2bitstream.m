% image2bitstream - Convert an image matrix to a binary bitstream
%
% Syntax: [bitstream] = image2bitstream(conf, image)
%
% Inputs:
%    conf - Configuration parameters for the conversion
%    image - Input image matrix
%
% Outputs:
%    bitstream - Binary bitstream representing the image
%
% Example:
%    conf.nb_frames = 16;
%    image = imread('image.jpg');
%    bitstream = image2bitstream(conf, image);
%
% Other Requirements:
%    This function requires the Image Processing Toolbox.
%
% See also: reshape, de2bi
% Author(s): [Vincent Roduit, Filippo Quadri]
% Date: [2023-12-05]
% Version: [1.0]

function [bitstream] = image2bitstream(conf, image)
    % Reshape the image matrix to a column vector
    image_vector = reshape(image, [], 1);
    
    % Convert the values to a binary representation
    binary_stream = de2bi(image_vector,"left-msb")';
    binary_stream = binary_stream(:);
    % Reshape the binary stream to a column vector% Determine the number of rows needed for 16 columns
    num_rows = numel(binary_stream) / conf.num_frames;
    
    % Reshape the binary stream to have 16 columns
    bitstream = reshape(binary_stream, num_rows, conf.num_frames);
end
