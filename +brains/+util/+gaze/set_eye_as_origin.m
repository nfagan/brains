function pos = set_eye_as_origin(pos, x_dist_to_monitor, y_dist_to_monitor)

pos(1) = pos(1) - x_dist_to_monitor;
pos(2) = pos(2) - y_dist_to_monitor;

end