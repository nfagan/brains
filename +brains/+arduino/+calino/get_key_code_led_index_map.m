function map = get_key_code_led_index_map()

map = containers.Map( 'keyType', 'double', 'valueType', 'double' );

num_pad_zero = 96;
num_row_one = 49;

for i = 1:9
  map(i) = num_pad_zero + i;
end

map(10) = num_pad_zero;
map(11) = num_row_one;

for i = 1:9
  map(11+i) = num_row_one + i;
end

end