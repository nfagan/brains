function in_bounds = debug__test_roi_2(pixel_coords, scr_rect, roi, opts)

import brains.util.gaze.*;

z_dist_to_monitor_cm = opts.dist_to_monitor_cm;
x_dist_to_monitor_cm = opts.x_dist_to_monitor_cm;
y_dist_to_monitor_cm = opts.y_dist_to_monitor_cm;
screen_dims_cm = opts.screen_dims_cm;
dist_to_roi_cm = opts.dist_to_roi_cm;

if ( isempty(pixel_coords) )
	in_bounds = false; return;
end

pos = get_position_in_monitor( pixel_coords, scr_rect, screen_dims_cm );
pos(1) = pos(1) - x_dist_to_monitor_cm;
pos(2) = y_dist_to_monitor_cm - pos(2);

% pos = set_eye_as_origin( pos, x_dist_to_monitor_cm, y_dist_to_monitor_cm );
angle = get_gaze_angle( [0, 0], pos, z_dist_to_monitor_cm );
projected_pos = get_projected_position( angle, dist_to_roi_cm );

proj_x = projected_pos(1);
proj_y = projected_pos(2);

in_bounds_x = proj_x >= roi(1) && proj_x <= roi(3);
in_bounds_y = proj_y >= roi(2) && proj_y <= roi(4);

% if ( in_bounds_x )
%   disp( 'in bounds x' );
% end
% if ( in_bounds_y )
%   disp( 'in_bounds_y' );
% end

in_bounds = in_bounds_x && in_bounds_y;

end