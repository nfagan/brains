function bounds = social_control_dots_left(calibration_data, key_map, padding_info, const)

eyel = key_map( 'eyel' );
eyer = key_map( 'eyer' );

eyel_coord = brains.arduino.calino.get_coord( calibration_data, eyel );
eyer_coord = brains.arduino.calino.get_coord( calibration_data, eyer );

dist_eyes_px = eyer_coord(1) - eyel_coord(1);
dist_eyes_cm = const.INTER_EYE_DISTANCE_CM;
ratio = dist_eyes_px / dist_eyes_cm;

left_to_dot_center = 6;
top_to_dot_center = 0;
dot_radius_cm = 2.5;

dot_radius_px = dot_radius_cm * ratio;

l_px = eyel_coord(1) - (left_to_dot_center * ratio) - dot_radius_px;
r_px = eyel_coord(1) - (left_to_dot_center * ratio) + dot_radius_px;

b_px = eyel_coord(2) - (top_to_dot_center * ratio) - dot_radius_px;
t_px = eyel_coord(2) + (top_to_dot_center * ratio) + dot_radius_px;

bounds = [ l_px, b_px, r_px, t_px ];

% eyel_px = eyel_coord(1) - (padding_info.eyes.x * ratio);
% eyer_px = eyer_coord(1) + (padding_info.eyes.x * ratio);
% eyeb_px = eye_y - (padding_info.eyes.y * ratio);
% eyet_px = eye_y + (padding_info.eyes.y * ratio);
% 
% bounds = [ eyel_px, eyeb_px, eyer_px, eyet_px ];


end