function el_draw_stimulus(stim, color)

Eyelink( 'Command', 'clear_screen 0' );

vertices = round( stim.vertices );

if ( numel(stim.targets) > 0 )
  verts_plus_padding = vertices + stim.targets{1}.padding;
else
  verts_plus_padding = vertices;
end

Eyelink( 'Command', 'draw_filled_box %d %d %d %d %d', ...
  verts_plus_padding(1), verts_plus_padding(2), verts_plus_padding(3), verts_plus_padding(4), color+1 );

Eyelink( 'Command', 'draw_filled_box %d %d %d %d %d', ...
  vertices(1), vertices(2), vertices(3), vertices(4), color );


end