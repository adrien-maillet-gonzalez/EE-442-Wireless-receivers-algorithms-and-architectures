function [binary_stream, conf] = image_to_bitstream(image_file, conf)
 
    image = imread(image_file);
    
    gray_image = im2gray(image);
    conf.image_size = size(gray_image);
    image_vector = gray_image(:);
    binary_stream_matrix = de2bi(image_vector,"left-msb");
    
    binary_stream = binary_stream_matrix(:);

end