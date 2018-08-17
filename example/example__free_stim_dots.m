function example__free_stim_dots()

import brains.arduino.calino.bound_funcs.both_eyes;
import brains.arduino.calino.bound_funcs.face_top_and_bottom;
import brains.arduino.calino.bound_funcs.social_control_dots_left;

try
  key_file = brains.util.get_latest_far_plane_calibration( [], false );
catch err
  key_file = [];
  warning( err.message );
end

padding_cm = brains.arduino.calino.define_padding();

%
%   task info
%

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
stim_params.sync_m1_m2_params = false;  % whether to send m2's calibration data to m1
stim_params.probability = 100; % percent
stim_params.frequency = 1000;  % ISI, ms
stim_params.max_n = intmax( 'int16' );  % maximum number of stimulations. max possible is intmax('int16');
stim_params.active_rois = { 'social_control_dots_left' }; % which rois will trigger stimulation
% stim_params.protocol = ids.stim_protocols.probabilistic;
stim_params.protocol = ids.stim_protocols.m1_exclusive_event;
% stim_params.protocol = ids.stim_protocols.m2_exclusive_event
% stim_params.protocol = ids.stim_protocols.mutual_event

if ( ~isempty(key_file) )
  consts = brains.arduino.calino.define_calibration_target_constants();
  key_map = key_file.key_name_map;
  key_file.keys = brains.arduino.calino.convert_key_struct( key_file.keys, key_file.key_map );

  bounds = struct();
  bounds.eyes = both_eyes( key_file.keys, key_map, padding_cm, consts );
  bounds.face = face_top_and_bottom( key_file.keys, key_map, padding_cm, consts );
  bounds.mouth = zeros( 1, 4 );
  bounds.social_control_dots_left = social_control_dots_left( key_file.keys, key_map, padding_cm, consts );
else
  key_file = struct( 'keys', [] );
  key_map = [];
  bounds = struct();
end
       
brains.task.dot_stim( task_time, key_file.keys, key_map, bounds, stim_params );

end