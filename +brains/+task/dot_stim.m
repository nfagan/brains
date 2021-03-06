function dot_stim(task_time, key_file, key_map, bounds, stim_params, dot_params)

%   DOT_STIM -- Deliver reward every x ms.
%
%     IN:
%       - `reward_period` (double) -- Inter-reward interval, in ms.
%       - `reward_amount` (double) -- Reward-sie, in ms.

conf = brains.config.reconcile( brains.config.load() );

stim_comm = [];

save_p = fullfile( conf.IO.repo_folder, 'brains', 'data' ...
  , datestr(now, 'mmddyy'), 'nonsocial_control' );
if ( exist(save_p, 'dir') ~= 7 ), mkdir(save_p); end

edfs = shared_utils.io.find( save_p, '.edf' );
n_edfs = numel( edfs );
edf_file = sprintf( '%s%d.edf', conf.IO.edf_file, n_edfs + 1 );

brains.util.assert__file_does_not_exist( fullfile(save_p, edf_file) );

opts = struct();
opts.first_invocation = true;
opts.debug = conf.INTERFACE.DEBUG;

edf_sample_rate = 1e3;

if ( ~isinf(task_time) )
  opts.gaze_data = nan( 4, task_time * edf_sample_rate );
else
  opts.gaze_data = nan( 4, 1 );
end

tracker_exists = false;

opts.gaze_sync_times = nan( 10e3, 2 );
opts.plex_sync_times = nan( 10e3, 1 );
opts.reward_sync_times = nan( 10e3, 1 );

opts.plex_sync_stp = 1;
opts.reward_sync_stp = 1;
opts.plex_sync_index = 0;

if ( conf.INTERFACE.use_arduino )
  comm = brains.arduino.get_serial_comm();
else
  comm = brains.arduino.get_dummy_serial_comm();
end

comm.start();

opts.comm = comm;

opts.reward_key_timer = NaN;
opts.reward_period_timer = NaN;

opts.edf_sync_interval = 1;

sync_pulse_map = brains.arduino.get_sync_pulse_map();
required_fields = { 'start', 'periodic_sync', 'reward' };
shared_utils.assertions.assert__are_fields( sync_pulse_map, required_fields );

opts.sync_pulse_map = sync_pulse_map;

screen_ind = conf.SCREEN.index;
screen_rect = conf.SCREEN.rect.M1;

screen_info = openExperiment( 38, 50, screen_ind, screen_rect );

dot_iter = 1;
dot_directions = dot_params.dot_directions;
dot_direction_stp = 1;
dot_direction_switch_delays = dot_params.direction_switch_delays;
current_direction_block_size = 0;

dot_sync = struct();
dot_sync.iter = 1;
dot_sync.times = [];
dot_sync.directions = [];
dot_sync.block_sizes = [];

%
%   DOT INIT
%

dot_params.direction = dot_directions(1);
dot_info = make_dots( dot_params );

try
  tracker = EyeTracker( edf_file, save_p, 0 );
  tracker_exists = true;
  tracker.bypass = ~conf.INTERFACE.use_eyelink;
  tracker.init();
  
  task_timer = tic();
  opts.task_timer = task_timer;
  
  tracker.send_message( 'SYNCH' );
  fprintf( '\n Sync!' );
  comm.sync_pulse( sync_pulse_map.start );
  
  if ( conf.INTERFACE.use_arduino )
    brains.util.increment_start_pulse_count();
    opts.plex_sync_index = brains.util.get_current_start_pulse_count();
  end
  
  stim_comm = init_stim_comm( conf, [], stim_params, bounds );
  
  opts.plex_sync_times(opts.plex_sync_stp) = toc( task_timer );
  opts.plex_sync_stp = opts.plex_sync_stp + 1;
  
  opts.next_edf_pulse_time = toc( task_timer ) + opts.edf_sync_interval;
  
  if ( conf.INTERFACE.use_eyelink )
%     brains.util.el_draw_rect( round(bounds.social_control_dots_left), 3 );
    brains.util.el_draw_rect( round(bounds.eyes), 4 );
  end
  
  while ( toc(task_timer) < task_time )
    %   flip directions
    if ( dot_iter > current_direction_block_size )      
      rng( 'shuffle' );
      
      if ( dot_direction_stp > numel(dot_directions) )
        dot_direction_stp = 1;
      end
      
      dot_params.direction = dot_directions(dot_direction_stp);
      dot_info = make_dots( dot_params );
      dot_iter = 1;
      current_direction_block_size = get_dot_direction_switch_block_size( dot_direction_switch_delays );
      dot_direction_stp = dot_direction_stp + 1;
      
      if ( opts.debug )
        disp( ['Current block size: ', num2str(current_direction_block_size)] );
        disp( ['Current direction is: ', num2str(dot_params.direction)] );
      end
      
      dot_sync.times(dot_sync.iter) = toc( task_timer );
      dot_sync.directions(dot_sync.iter) = dot_params.direction;
      dot_sync.block_sizes(dot_sync.iter) = current_direction_block_size;
      
      dot_sync.iter = dot_sync.iter + 1;
    end
    
    callback = @(x) update( tracker, conf, x );
    [should_abort, opts] = dots_callback( screen_info, dot_info, callback, opts );
    
    if ( should_abort )
      break
    end
    
    dot_iter = dot_iter + 1;
  end
  
  mats = shared_utils.io.dirnames( save_p, '.mat' );
  next_id = numel( mats ) + 1;
  data_file = sprintf( 'dot_%d.mat', next_id );
  to_save = struct( ...
      'config', conf ...
    , 'sync_times', opts.gaze_sync_times ...
    , 'plex_sync_times', opts.plex_sync_times ...
    , 'plex_sync_index', opts.plex_sync_index ...
    , 'dot_sync', dot_sync ...
    , 'reward_sync_times', opts.reward_sync_times ...
    , 'rois', bounds ...
    , 'stimulation_params', stim_params ...
    , 'dot_params', dot_params ...
    , 'date', datestr( now ) ...
    , 'edf_file', edf_file ...
    );
  save( fullfile(save_p, data_file), 'to_save' );
  
  print_n_stim( stim_comm );
  
  local_cleanup( comm, tracker, conf, stim_comm );
catch err
  brains.util.print_error_stack( err );
  
  if ( ~tracker_exists )
    tracker = [];
  end
  local_cleanup( comm, tracker, conf, stim_comm );
  throw( err );
end

end

function n = get_dot_direction_switch_block_size(direction_switch_delays)

n = direction_switch_delays( randi(numel(direction_switch_delays)) );

end

function dot_info = make_dots(dot_params)

dot_info = createDotInfo(); % initialize dots
dot_info.numDotField = 2;

dot_info.apXYD(:, 3) = dot_params.aperture_size;

dot_info.apXYD(1, 1) = -dot_params.x_spread + dot_params.x_shift;
dot_info.apXYD(2, 1) = dot_params.x_spread + dot_params.x_shift;
dot_info.apXYD(:, 2) = dot_params.y_shift;

dot_info.dotSize = dot_params.dot_size;
dot_info.coh(:) = min( 999, dot_params.coherence * 10 );
dot_info.dir = repmat( dot_params.direction, dot_info.numDotField, 1 );
dot_info.maxDotTime = 1;

end

function [should_abort, opts] = update(tracker, conf, opts)

should_abort = false;

tracker.update_coordinates();
[key_pressed, ~, key_code] = KbCheck();

if ( key_pressed )
  if ( key_code(conf.INTERFACE.stop_key) )
    should_abort = true;
    return
  end
  if ( key_code(conf.INTERFACE.rwd_key) )
    if ( isnan(opts.reward_key_timer) )
      should_reward = true;
    else
      should_reward = toc( opts.reward_key_timer ) > conf.REWARDS.main/1e3;
    end
    if ( should_reward )
      opts.comm.reward( 1, conf.REWARDS.main );
      opts.reward_key_timer = tic;
    end
  end
end

if ( toc(opts.task_timer) > opts.next_edf_pulse_time )
  tracker.send_message( 'RESYNCH' );
  opts.comm.sync_pulse( opts.sync_pulse_map.periodic_sync );
  opts.next_edf_pulse_time = toc( opts.task_timer ) + opts.edf_sync_interval;
  opts.plex_sync_times(opts.plex_sync_stp) = toc( opts.task_timer );
  opts.plex_sync_stp = opts.plex_sync_stp + 1;
  
  if ( opts.debug )
    disp( 'sync' );
  end
end


end

function print_n_stim( stim_comm )

if ( isempty(stim_comm) )
  return;
end

try
  n = brains.arduino.calino.check_n_stim( stim_comm );
catch err
  warning( err.message );
  n = -1;
end

fprintf( '\n\n TOTAL N STIMULATIONS: %d\n\n', n );

end

function stim_comm = init_stim_comm(conf, tcp_comm, stim_params, bounds)

import brains.arduino.calino.send_bounds;
import brains.arduino.calino.get_ids;
import brains.arduino.calino.send_stim_param;

if ( ~stim_params.use_stim_comm )
  stim_comm = [];
  return;
end

is_master = conf.INTERFACE.is_master_arduino;

own_screen = conf.CALIBRATION.cal_rect;

own_eyes = bounds.eyes;
own_face = bounds.face;
own_mouth = bounds.mouth;
own_sc_dots_left = bounds.social_control_dots_left;

other_screen = zeros( 1, 4 );
other_eyes = repmat( -1, 1, 4 );
other_face = repmat( -1, 1, 4 );
other_mouth = repmat( -1, 1, 4 );
other_sc_dots_left = repmat( -1, 1, 4 );

if ( is_master )
  baud = 9600;
  port = conf.SERIAL.ports.stimulation;
  stim_comm = brains.arduino.calino.init_serial( port, baud );
else
  stim_comm = [];
end

if ( ~is_master )
  return;
end

send_bounds( stim_comm, 'm1', 'screen', round(own_screen) );
send_bounds( stim_comm, 'm2', 'screen', round(other_screen) );

send_bounds( stim_comm, 'm1', 'eyes', round(own_eyes) );
send_bounds( stim_comm, 'm2', 'eyes', round(other_eyes) );

send_bounds( stim_comm, 'm1', 'face', round(own_face) );
send_bounds( stim_comm, 'm2', 'face', round(other_face) );

send_bounds( stim_comm, 'm1', 'mouth', round(own_mouth) );
send_bounds( stim_comm, 'm2', 'mouth', round(other_mouth) );

send_bounds( stim_comm, 'm1', 'social_control_dots_left', round(own_sc_dots_left) );
send_bounds( stim_comm, 'm2', 'social_control_dots_left', round(other_sc_dots_left) );

send_stim_param( stim_comm, 'all', 'probability', stim_params.probability );
send_stim_param( stim_comm, 'all', 'frequency', stim_params.frequency );
send_stim_param( stim_comm, 'all', 'stim_stop_start', 0 );
send_stim_param( stim_comm, 'all', 'max_n', stim_params.max_n );
send_stim_param( stim_comm, 'all', 'radius', round(stim_params.radius) );

active_rois = stim_params.active_rois;

if ( ~iscell(active_rois) ), active_rois = { active_rois }; end

send_stim_param( stim_comm, 'all', 'protocol', stim_params.protocol );

for i = 1:numel(active_rois)
  send_stim_param( stim_comm, active_rois{i}, 'stim_stop_start', 1 );
end

end

function local_cleanup(comm, tracker, conf, stim_comm)

closeExperiment();

if ( ~isempty(stim_comm) )
  brains.arduino.abort_stim( stim_comm );
%   brains.arduino.calino.send_stim_param( stim_comm, 'all', 'stim_stop_start', 0 );
  fclose( stim_comm );
end

brains.arduino.close_ports();

if ( ~isempty(tracker) )
  warning( 'off', 'all' );
  tracker.shutdown();
  warning( 'on', 'all' );
end

end