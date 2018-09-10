function example__free_viewing()

import brains.arduino.calino.bound_funcs.both_eyes;
import brains.arduino.calino.bound_funcs.face_top_and_bottom;

key_file = brains.util.get_latest_far_plane_calibration( [], false );
padding_cm = brains.arduino.calino.define_padding();

%
%   reward
%

reward_period = 8e3;
reward_amount = 0;
task_time = 5 * 60;

%
%   padding info
%

padding_cm.eyes.x = 2.75;
padding_cm.eyes.y = 2.75;
padding_cm.face.x = 0;
padding_cm.face.y = 0;
padding_cm.mouth.x = 0;
padding_cm.mouth.y = 0;

%
%   stimulation params
%

ids = brains.arduino.calino.get_ids();

stim_params = struct();
stim_params.use_stim_comm = true;  % whether to initialize stimulation arduino
stim_params.sync_m1_m2_params = true;  % whether to send m2's calibration data to m1
stim_params.probability = 50; % percent
stim_params.frequency = 5000;  % ISI, ms
stim_params.max_n = intmax( 'int16' );  % maximum number of stimulations. max possible is intmax('int16');
stim_params.active_rois = { 'eyes' }; % which rois will trigger stimulation
% stim_params.protocol = ids.stim_protocols.probabilistic;
stim_params.protocol = ids.stim_protocols.m1_exclusive_event;
% stim_params.protocol = ids.stim_protocols.m2_exclusive_event
% stim_params.protocol = ids.stim_protocols.mutual_event

consts = brains.arduino.calino.define_calibration_target_constants();
key_map = key_file.key_name_map;
key_file.keys = brains.arduino.calino.convert_key_struct( key_file.keys, key_file.key_map );

bounds = struct();
bounds.eyes = both_eyes( key_file.keys, key_map, padding_cm, consts );
bounds.face = face_top_and_bottom( key_file.keys, key_map, padding_cm, consts );
bounds.mouth = zeros( 1, 4 );
       
brains.task.free_viewing( task_time, reward_period ...
  , reward_amount, key_file.keys, key_map, bounds, stim_params );

%%

brains.arduino.close_ports();