function dims = get_reprojected_dimensions(width_cm, height_cm, z_far_cm, z_near_cm)

x_near = width_cm * z_near_cm / z_far_cm;
y_near = height_cm * z_near_cm / z_far_cm;

dims = [x_near, y_near];

end