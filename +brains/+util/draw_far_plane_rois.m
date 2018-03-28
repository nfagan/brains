function draw_far_plane_rois( key_file, sz, colors, bypass )

assert( isa(key_file, 'struct'), 'Input must be struct; was ''%s''.', class(key_file) );

fs = fieldnames( key_file );

if ( numel(colors) ~= 1 )
  assert( numel(colors) == numel(fs), 'Specify one color for each field.' );
else
  colors = repmat( colors, 1, numel(fs) );
end

brains.util.el_draw_square( [], 0, 0, bypass );

for i = 1:numel(fs)
  coords = key_file.(fs{i}).coordinates;
  if ( ~isempty(coords) )
    brains.util.el_draw_square( coords, sz, colors(i), bypass );
  end
end

end