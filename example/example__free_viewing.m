function example__free_viewing()

key_file = brains.util.get_latest_far_plane_calibration();

reward_period = 8e3;
% reward_amount = 400;
reward_amount = 0;
task_time = 5 * 60;

key_map = brains.arduino.calino.get_calibration_key_roi_map();
       
brains.task.free_viewing( task_time, reward_period, reward_amount, key_file, key_map );

%%

brains.arduino.close_ports();