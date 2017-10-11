function verts = get_fractional_vertices(verts, dims)

verts([1, 3]) = verts([1, 3]) / dims(1);
verts([2, 4]) = verts([2, 4]) / dims(2);


end