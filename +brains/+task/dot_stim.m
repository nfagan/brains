function dot_stim(task_time, key_file, key_map, bounds, stim_params)

%   DOT_STIM -- Deliver reward every x ms.
%
%     IN:
%       - `reward_period` (double) -- Inter-reward interval, in ms.
%       - `reward_amount` (double) -- Reward-sie, in ms.

conf = brains.config.reconcile( brains.config.load() );

stim_comm = [];

save_p = fullfile( conf.IO.repo_folder, 'brains', 'data' ...
  , datestr(now, 'mmddyy'), 'social_control' );
if ( exist(save_p, 'dir') ~= 7 ), mkdir(save_p); end

edfs = shared_utils.io.find( save_p, '.edf' );
n_edfs = numel( edfs );
edf_file = sprintf( '%s%d.edf', conf.IO.edf_file, n_edfs + 1 );

brains.util.assert__file_does_not_exist( fullfile(save_p, edf_file) );

opts = struct();
opts.first_invocation = true;

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

%
%   DOT INIT
%

dot_dirs = [ 0, 0 ];
dot_coh = 10;

dot_coh = min( 999, dot_coh * 10 );

dot_info = createDotInfo(); % initialize dots
dot_info.apXYD(1, 3) = 30;
dot_info.apXYD(2, 3) = 30;
dot_info.numDotField = 2;

dot_info.coh(:) = dot_coh;
dot_info.dir = dot_dirs(:);
dot_info.dotSize = 8;
dot_info.maxDotTime = 2;

screen_ind = conf.SCREEN.index;
screen_rect = conf.SCREEN.rect.M1;

screen_info = openExperiment( 38, 50, screen_ind, screen_rect );

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
  
  stim_comm = init_stim_comm( conf, [], stim_params, bounds );
  
  opts.plex_sync_times(opts.plex_sync_stp) = toc( task_timer );
  opts.plex_sync_stp = opts.plex_sync_stp + 1;
  
  opts.next_edf_pulse_time = toc( task_timer ) + opts.edf_sync_interval;
  
  callback = @() update( tracker, conf, opts );
  
  if ( conf.INTERFACE.use_eyelink )
    brains.util.el_draw_rect( round(bounds.social_control_dots_left), 3 );
  end
  
  while ( toc(task_timer) < task_time )
    should_abort = dots_callback( screen_info, dot_info, callback );
    
    if ( should_abort )
      break
    end
  end
  
  print_n_stim( stim_comm );
  
  local_cleanup( comm, tracker, conf, stim_comm );
catch err
  if ( ~tracker_exists )
    tracker = [];
  end
  local_cleanup( comm, tracker, conf, stim_comm );
  throw( err );
end

end

function should_abort = update(tracker, conf, opts)

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

fprintf( '\n\n TOTAL N STIMULATIONS: %d', n );

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
  tracker.shutdown();
end

end