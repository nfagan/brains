function el_draw_rect( rect, color )

if ( numel(rect) == 1 && rect(1) == 0 )
  Eyelink( 'Command', 'clear_screen 0' );
  return;
end

Eyelink( 'Command', 'draw_filled_box %d %d %d %d %d', ...
  rect(1), rect(2), rect(3), rect(4), color );

end