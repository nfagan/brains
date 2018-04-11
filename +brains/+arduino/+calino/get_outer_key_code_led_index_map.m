function map = get_outer_key_code_led_index_map()

map = containers.Map( 'keyType', 'double', 'valueType', 'double' );

num_pad_zero = 96;

map(1) = num_pad_zero;
map(2) = num_pad_zero + 1;
map(3) = num_pad_zero + 2;
map(4) = num_pad_zero + 3;
map(5) = num_pad_zero + 4;
map(6) = num_pad_zero + 5;
map(7) = num_pad_zero + 6;

end