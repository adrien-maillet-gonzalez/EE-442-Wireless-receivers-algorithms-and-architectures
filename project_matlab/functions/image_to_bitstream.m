function [binary_stream, conf] = image_to_bitstream(image_file, conf)
%
%   This function converts an input image into a binary stream that can be used 
%   for digital communication or processing. It reads an image file, converts 
%   it to grayscale (if needed), and then transforms its pixel intensity values 
%   into a serialized binary bitstream.
%
% Inputs:
%   - image_file: 
%       The file path of the input image to be converted.
%   - conf: 
%       A configuration structure to store additional information about the 
%       image, such as its dimensions.
%
% Outputs:
%   - binary_stream: 
%       A column vector containing the serialized binary representation of the 
%       grayscale image pixel values.
%   - conf: 
%       The updated configuration structure with the following added field:
%       * image_size: The dimensions of the input grayscale image.
%
% Processing Steps:
%   1. Image Reading:
%       - Reads the input image from the specified file using `imread`.
%   2. Grayscale Conversion:
%       - Converts the image to grayscale using `im2gray` if the input is in 
%         color (RGB). If the image is already grayscale, it remains unchanged.
%   3. Pixel Serialization:
%       - Flattens the grayscale image matrix into a single column vector.
%   4. Binary Conversion:
%       - Converts the intensity values of the flattened image vector into 
%         binary form using `de2bi` with the "left-msb" format.
%   5. Stream Serialization:
%       - Serializes the binary matrix into a single binary stream vector.
%   6. Configuration Update:
%       - Stores the dimensions of the grayscale image in `conf.image_size` 
%         for later reconstruction or reference.
%
% Notes:
%   - The function assumes the input image file exists and is readable by `imread`.
%   - `im2gray` ensures compatibility with both RGB and grayscale images.
%   - The binary stream can be reconstructed into an image using the reverse 
%     process of reshaping and converting binary to decimal values.
%   - Ensure that `conf` is properly initialized before calling the function.

    image = imread(image_file);
    
    gray_image = im2gray(image);
    conf.image_size = size(gray_image);
    image_vector = gray_image(:);
    binary_stream_matrix = de2bi(image_vector,"left-msb");
    
    binary_stream = binary_stream_matrix(:);

end