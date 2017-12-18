opts = struct();

opts.screen_rect_px = [ 0, 0, 3072, 768 ];
opts.screen_width_cm = 111.3;
opts.screen_height_cm = 30.0;
opts.screen_top_to_ground = 85.8;
opts.inter_monitor_cm = 17;

opts.m1_x_to_monitor_left_cm = 0;
opts.m1_z_to_monitor_front_cm = 0;
opts.m1_y_to_ground_cm = 0;

opts.m2_x_to_monitor_left_cm = 0;
opts.m2_z_to_monitor_front_cm = 0;
opts.m2_y_to_ground_cm = 0;

%%

screen_dist_to_ground_cm = 85.8;
x_dist_to_monitor_cm = 51.0;
y_dist_to_monitor_cm = screen_dist_to_ground_cm - y_dist_to_ground_m1;
z_dist_to_monitor_cm = 65.5;
z_dist_to_m2 = m2_z_dist_to_monitor + z_dist_to_monitor_cm + inter_monitor_gap_cm;

eye_relative_m2_left = screen_width_cm - ( x_dist_to_monitor_m2_cm + x_dist_to_monitor_cm );
eye_relative_m2_bottom = y_dist_to_ground_m2 - y_dist_to_ground_m1;
face_height_cm = 16;
face_width_cm = 16;

y_min = 10;
x_max = 12.9;
y_max = 13.1;
x_min = 2.5;

% roi = [ eye_relative_m2_left, eye_relative_m2_bottom, eye_relative_m2_left + face_width_cm, eye_relative_m2_bottom + face_height_cm ];

roi = [ eye_relative_m2_left+x_min, eye_relative_m2_bottom+y_min, eye_relative_m2_left+x_max, eye_relative_m2_bottom+y_max ];