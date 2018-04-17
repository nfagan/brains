function example__free_viewing()

key_file = brains.util.get_latest_far_plane_calibration( [], false );

reward_period = 8e3;
% reward_amount = 400;
reward_amount = 0;
task_time = 5 * 60;

padding_info = brains.arduino.calino.define_padding();
consts = brains.arduino.calino.define_calibration_target_constants();
key_map = key_file.key_name_map;
key_file.keys = brains.arduino.calino.convert_key_struct( key_file.keys, key_file.key_map );

padding_info.eyes.x = 2.75;
padding_info.eyes.y = 2.75;
padding_info.face.x = 0;
padding_info.face.y = 0;

bounds = struct();
bounds.eyes = brains.arduino.calino.bound_funcs.both_eyes( key_file.keys, key_map, padding_info, consts );
bounds.face = brains.arduino.calino.bound_funcs.face_top_and_bottom( key_file.keys, key_map, padding_info, consts );
       
brains.task.free_viewing( task_time, reward_period, reward_amount, key_file.keys, key_map, bounds );

%%

brains.arduino.close_ports();