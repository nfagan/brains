function in_bounds = debug__test_roi(tracker, opts, roi)

import brains.util.gaze.*;

if ( opts.INTERFACE.is_master_arduino )
  m_str = 'M1';
else
  m_str = 'M2';
end

z_dist_to_monitor_cm = 1000;
x_dist_to_monitor_cm = 100;
y_dist_to_monitor_cm = 100;
screen_dims_cm = [43.625, 10.75];
dist_to_roi_cm = 1e4;

pixel_coords = tracker.coordinates;

scr_rect_full = opts.SCREEN.rect.(m_str);

width_pixels = scr_rect_full(3) - scr_rect_full(1);
height_pixels = scr_rect_full(4) - scr_rect_full(2);

scr_rect = [0, 0, width_pixels, height_pixels];

pos = get_position_in_monitor( pixel_coords, scr_rect, screen_dims_cm );
pos = set_eye_as_origin( pos, x_dist_to_monitor_cm, y_dist_to_monitor_cm );
angle = get_gaze_angle( [0, 0], pos, z_dist_to_monitor_cm );
projected_pos = get_projected_position( angle, dist_to_roi_cm );

proj_x = projected_pos(1);
proj_y = projected_pos(2);

in_bounds = proj_x >= roi(1) && proj_x <= roi(3) && ...
  proj_y >= roi(2) && proj_y <= roi(4);

end