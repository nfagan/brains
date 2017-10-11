function verts = get_pixel_verts_from_fraction(pixel_rect, fractional_verts)

width = pixel_rect(3) - pixel_rect(1);
height = pixel_rect(4) - pixel_rect(2);

min_x = fractional_verts(1) * width + pixel_rect(1);
max_x = fractional_verts(3) * width + pixel_rect(1);
min_y = fractional_verts(2) * height + pixel_rect(2);
max_y = fractional_verts(4) * height + pixel_rect(2);

verts = [ min_x, min_y, max_x, max_y ];

end