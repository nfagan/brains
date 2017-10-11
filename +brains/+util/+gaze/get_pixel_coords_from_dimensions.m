function coords = get_pixel_coords_from_dimensions(dims, screen_dims, screen_rect)

fractional_x = dims(1) / screen_dims(1);
fractional_y = dims(2) / screen_dims(2);

x1 = screen_rect(1);
x2 = screen_rect(3);
y1 = screen_rect(2);
y2 = screen_rect(4);

width_pixels = x2 - x1;
height_pixels = y2 - y1;

x1_pixel = width_pixels * fractional_x + x1;
y1_pixel = height_pixels * fractional_y + y1;

coords = [ x1_pixel, y1_pixel ];

end