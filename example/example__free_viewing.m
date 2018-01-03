%   put back in sync_pulse
%   change is_master_arduino -> false
%   change ports COM4 -> COM3

data_dir = 'C:\Repositories\brains\data';
dist_file = brains_analysis.util.io.try_json_decode( fullfile(data_dir, 'distances', 'active_distance.json') );
roi_file = brains_analysis.util.io.try_json_decode( fullfile(data_dir, 'rois', 'rois.json') );

key_filename = 'far_plane_calibration.mat';
key_file = load( fullfile(data_dir, brains.util.get_latest_data_dir(), 'calibration', key_filename) );
key_file = key_file.(char(fieldnames(key_file)));

reward_period = 8e3;
reward_amount = 400;
task_time = 5 * 60;

other_monk = 'ephron';
       
brains.task.free_viewing( task_time, reward_period, reward_amount, dist_file, roi_file, key_file, other_monk );

%%

brains.arduino.close_ports();

%%

screen_constants = brains_analysis.gaze.util.get_screen_constants();

% screen_min_x = -dist_file.m1.eye_to_monitor_left_cm;
% screen_max_x = screen_constants.SCREEN_WIDTH_CM - dist_file.m1.eye_to_monitor_left_cm;

screen_min_x = -screen_constants.SCREEN_WIDTH_CM / 2;
screen_max_x = screen_constants.SCREEN_WIDTH_CM / 2;

screen_min_y = -screen_constants.SCREEN_HEIGHT_CM / 2;
screen_max_y = screen_constants.SCREEN_HEIGHT_CM / 2;

screen_rect_cm = [ screen_min_x, screen_min_y, screen_max_x, screen_max_y ];
screen_rect_mm = round( screen_rect_cm * 10 );

% Eyelink( 'Command', 'screen_phys_coords = %d %d %d %d' ...
%  , screen_rect_mm(1), screen_rect_mm(2), screen_rect_mm(3), screen_rect_mm(4) );