function el_draw_square(coordinates, sz, color, bypass)

if ( bypass ), return; end

if ( sz == 0 )
  Eyelink( 'Command', 'clear_screen %d', color );
  return;
end

x = coordinates(1);
y = coordinates(2);
sz2 = sz / 2;

rounded_rect = round( [x-sz2, y-sz2, x+sz2, y+sz2] );
rounded_rect( rounded_rect < 0 ) = 0;

Eyelink( 'Command', 'draw_filled_box %d %d %d %d %d', ...
  rounded_rect(1), rounded_rect(2), rounded_rect(3), rounded_rect(4), color );

end