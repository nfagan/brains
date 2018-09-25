function example__free_stim_dots(use_stim_comm)

if ( nargin < 1 ), use_stim_comm = true; end

import brains.arduino.calino.bound_funcs.both_eyes;
import brains.arduino.calino.bound_funcs.face_top_and_bottom;
import brains.arduino.calino.bound_funcs.social_control_dots_left;

repadd( 'ShadlenDotsX', true );

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
%   dot params
%

dot_params = struct();
% dot_params.direction = 90;  % direction of motion, degrees
dot_params.coherence = 100; % percent dot coherence
dot_params.dot_size = 6;  % relative size of each dot within the aperture.
%dot_params.dot_directions = [ 180, 0 ]; % direction left and right
dot_params.dot_directions = [ 90, 270]; % direction up and down 

dot_params.direction_switch_delays = [ 15:40 ];
% dot_params.dot_directions = 90;   % use only one direction
% dot_params.direction_switch_delays = 1; % switch every second;

dot_params.x_spread = 40; % distance between aperture centers
dot_params.x_shift = 28;  % x-shift of each aperture center
dot_params.y_shift = 20;  % y-shift of each aperture center
dot_params.aperture_size = 60;  % size of each circle

%
%   stimulation params
%

ids = brains.arduino.calino.get_ids();

stim_params = struct();
stim_params.use_stim_comm = use_stim_comm;  % whether to initialize stimulation arduino
stim_params.sync_m1_m2_params = false;  % whether to send m2's calibration data to m1
stim_params.probability = 50; % percent
stim_params.frequency = 15000;  % ISI, ms
% stim_params.max_n = intmax( 'int16' );  % maximum number of stimulations. max possible is intmax('int16');
stim_params.max_n = 10;
stim_params.active_rois = { 'eyes' }; % which rois will trigger stimulation
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
       
brains.task.dot_stim( task_time, key_file.keys, key_map, bounds, stim_params, dot_params );

end