function example__free_viewing()

data_dir = 'C:\Repositories\brains\data';
dist_file = brains_analysis.util.io.try_json_decode( fullfile(data_dir, 'distances', 'active_distance.json') );
roi_file = brains_analysis.util.io.try_json_decode( fullfile(data_dir, 'rois', 'rois.json') );

key_filename = 'far_plane_calibration.mat';
key_file = load( fullfile(data_dir, brains.util.get_latest_data_dir(), 'calibration', key_filename) );
key_file = key_file.(char(fieldnames(key_file)));

reward_period = 8e3;
% reward_amount = 400;
reward_amount = 0;
task_time = 5 * 60;

other_monk = 'ephron';
       
brains.task.free_viewing( task_time, reward_period, reward_amount, dist_file, roi_file, key_file, other_monk );

%%

brains.arduino.close_ports();