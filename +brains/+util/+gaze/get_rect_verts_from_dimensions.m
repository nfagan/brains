function image_verts = get_rect_verts_from_dimensions(dims, rect)

center_x = (rect(3) - rect(1)) / 2 + rect(1);
center_y = (rect(4) - rect(2)) / 2 + rect(2);

width = dims(1);
height = dims(2);
w2 = width / 2;
h2 = height / 2;

image_verts = [ center_x - w2, center_y - h2, center_x + w2, center_y + w2 ];

end