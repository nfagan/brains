function angle = get_gaze_angle(eye_pos, screen_pos, z_dist)

%   GET_GAZE_ANGLE -- Get x and y gaze angles, assuming the eye as the
%     origin.
%
%     IN:
%       - `eye_pos` (2-element double)
%       - `screen_pos` (2-element double) -- Coordinates in real-units.
%       - `z_dist` (double) -- Distance to monitor.

x_dist = eye_pos(1) - screen_pos(1);
y_dist = eye_pos(2) - screen_pos(2);

% x_dist = -x_dist;

angle_x = atan( x_dist / z_dist );
angle_y = atan( y_dist / z_dist );

% angle_x = pi - angle_x;

angle = [ angle_x, angle_y ];

end