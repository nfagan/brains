function copy = convert_key_struct(key_struct, key_map)

copy = struct();

key_mapk = cell2mat( keys(key_map) );

fs = fieldnames( key_struct );

for i = 1:numel(fs)
  current = key_struct.(fs{i});
  ind = key_mapk == current.led_index;
  
  assert( sum(ind) == 1, 'Some keys were not present in the key struct' );
  
  new_field = sprintf( 'key__%d', key_mapk(ind) );
  
  copy.(new_field) = current;
end

end