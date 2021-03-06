function map = get_outer_key_code_led_index_map()

map = containers.Map( 'keyType', 'double', 'valueType', 'double' );

num_pad_zero = 96;

map(4) = num_pad_zero + 1;
map(10) = num_pad_zero + 2;
map(14) = num_pad_zero + 3;
map(6) = num_pad_zero + 4;
map(8) = num_pad_zero + 5;
map(12) = num_pad_zero + 6;
%   consider whether mouth should be top or bottom
map(1) = num_pad_zero + 7;
map(13) = num_pad_zero + 8;
map(7) = num_pad_zero + 9;
map(2) = num_pad_zero;

end