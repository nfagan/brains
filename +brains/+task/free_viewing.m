function free_viewing(task_time, reward_period, reward_amount, key_file, key_map, bounds, distances, stim_params)

%   PERIODIC_REWARD -- Deliver reward every x ms.
%
%     IN:
%       - `reward_period` (double) -- Inter-reward interval, in ms.
%       - `reward_amount` (double) -- Reward-sie, in ms.

conf = brains.config.reconcile( brains.config.load() );

stim_comm = [];

save_p = fullfile( conf.IO.repo_folder, 'brains', 'data', datestr(now, 'mmddyy') );
if ( exist(save_p, 'dir') ~= 7 ), mkdir(save_p); end

edfs = shared_utils.io.find( save_p, '.edf' );
n_edfs = numel( edfs );
edf_file = sprintf( '%s%d.edf', conf.IO.edf_file, n_edfs + 1 );

brains.util.assert__file_does_not_exist( fullfile(save_p, edf_file) );

first_invocation = true;

calibration_constants = bfw.calibration.define_calibration_target_constants();
calibration_padding = bfw.calibration.define_padding();

edf_sample_rate = 1e3;

if ( ~isinf(task_time) )
  gaze_data = nan( 4, task_time * edf_sample_rate );
else
  gaze_data = nan( 4, 1 );
end

tracker_exists = false;

gaze_sync_times = nan( 10e3, 2 );
plex_sync_times = nan( 10e3, 1 );
reward_sync_times = nan( 10e3, 1 );

plex_sync_stp = 1;
reward_sync_stp = 1;
gaze_stp = 1;
gaze_sync_stp = 1;

plex_sync_index = 0;

comm = brains.arduino.get_serial_comm();
comm.bypass = ~conf.INTERFACE.use_arduino;
comm.start();

reward_key_timer = NaN;
reward_period_timer = NaN;

edf_sync_interval = 1;
tcp_sync_interval = 0.5;

sync_pulse_map = brains.arduino.get_sync_pulse_map();
required_fields = { 'start', 'periodic_sync', 'reward' };
shared_utils.assertions.assert__are_fields( sync_pulse_map, required_fields );

fixation_keys = { 'eyes', 'face' };
fixations = containers.Map( fixation_keys, zeros(1, numel(fixation_keys)) );
fixation_state = containers.Map( fixation_keys, false(1, numel(fixation_keys)) );

c_bounds = bounds.(stim_params.active_rois{1});

%   TODO: Make this non-specific to eyes.
dist_eyes_cm = distances.eyes;
dist_eyes_px = c_bounds(3) - c_bounds(1);
% stim_params.radius = brains.util.gaze.cm_to_px( stim_params.radius, dist_eyes_cm, dist_eyes_px );

try
  
  tracker = EyeTracker( edf_file, save_p, 0 );
  tracker_exists = true;
  tracker.bypass = ~conf.INTERFACE.use_eyelink;
  tracker.init();
  
  tcp_comm = brains.server.get_tcp_comm();
  tcp_comm.bypass = ~conf.INTERFACE.require_synch;
  tcp_comm.start();
  
  task_timer = tic();
  
  tracker.send_message( 'SYNCH' );
  fprintf( '\n Sync!' );
  comm.sync_pulse( sync_pulse_map.start );
  
  if ( conf.INTERFACE.use_arduino )
    brains.util.increment_start_pulse_count();
    plex_sync_index = brains.util.get_current_start_pulse_count();
  end
  
  stim_comm = init_stim_comm( conf, tcp_comm, stim_params, bounds );
  
  plex_sync_times(plex_sync_stp) = toc( task_timer );
  plex_sync_stp = plex_sync_stp + 1;
  
  next_edf_pulse_time = toc( task_timer ) + edf_sync_interval;
  next_tcp_pulse_time = toc( task_timer ) + tcp_sync_interval;
  
  while ( toc(task_timer) < task_time )
    tracker.update_coordinates();
    tcp_comm.update();
    [key_pressed, ~, key_code] = KbCheck();
    if ( key_pressed )
      if ( key_code(conf.INTERFACE.stop_key) ), break; end;
      if ( key_code(conf.INTERFACE.rwd_key) )
        if ( isnan(reward_key_timer) )
          should_reward = true;
        else
          should_reward = toc( reward_key_timer ) > conf.REWARDS.main/1e3;
        end
        if ( should_reward )
          comm.reward( 1, conf.REWARDS.main );
          reward_key_timer = tic;
        end
      end
    end
    if ( isnan(reward_period_timer) || toc(reward_period_timer) > reward_period/1e3 )
      if ( ~isinf(reward_period) )
        comm.sync_pulse( sync_pulse_map.reward );
        comm.reward( 1, reward_amount );
        reward_sync_times(reward_sync_stp) = toc( task_timer );
        reward_sync_stp = reward_sync_stp + 1;
      end
      reward_period_timer = tic;
    end
    
    if ( first_invocation )      
      brains.util.draw_far_plane_rois( key_file, 20, 1, tracker.bypass );
      
      if ( brains.arduino.calino.is_radius_excluding_inner_rect_protocol(stim_params.protocol) )
        if ( numel(stim_params.active_rois) ~= 0 )
          c_bounds = bounds.face;
          s = round( get_square_centered_on(c_bounds, round(stim_params.radius)) );
          brains.util.el_draw_rect( s, 5 );
        else
          warning( 'No active roi was specified.' );
        end
      end
      
      brains.util.el_draw_rect( round(bounds.face), 3 );
      brains.util.el_draw_rect( round(bounds.eyes), 4 );
      
      first_invocation = false;
    end
    
    other_time = tcp_comm.consume( 'choice' );
    if ( ~isnan(other_time) )
      gaze_sync_times( gaze_sync_stp, 1) = toc( task_timer );
      gaze_sync_times( gaze_sync_stp, 2 ) = other_time;
      gaze_sync_stp = gaze_sync_stp + 1;
    end
    
    if ( toc(task_timer) > next_tcp_pulse_time )
      try
        tcp_comm.send_when_ready( 'choice', toc(task_timer) );
      catch
        break;
      end
      next_tcp_pulse_time = toc( task_timer ) + tcp_sync_interval;
    end
    
    if ( toc(task_timer) > next_edf_pulse_time )
      tracker.send_message( 'RESYNCH' );
      comm.sync_pulse( sync_pulse_map.periodic_sync );
      next_edf_pulse_time = toc( task_timer ) + edf_sync_interval;
      plex_sync_times(plex_sync_stp) = toc( task_timer );
      plex_sync_stp = plex_sync_stp + 1;
    end
    
    if ( ~isempty(tracker.coordinates) )
      gaze_data(1:2, gaze_stp) = tracker.coordinates;
      gaze_data(3, gaze_stp) = tracker.pupil_size;
      gaze_data(4, gaze_stp) = toc( task_timer );
      gaze_stp = gaze_stp + 1;
      
      x = tracker.coordinates(1);
      y = tracker.coordinates(2);
      
      face_bounds = bfw.calibration.rect_face( key_file, key_map, calibration_padding, calibration_constants );
      eye_bounds = bfw.calibration.rect_eyes( key_file, key_map, calibration_padding, calibration_constants );
      
      clc;
      
      if ( bfw.bounds.rect(x, y, face_bounds) )
        fprintf( '\n In bounds face!' );
        if ( ~fixation_state('face') )
          fixation_state('face') = true;
          fixations('face') = fixations('face') + 1;
        end
      else
        fprintf( '\n -- ' );
        fixation_state('face') = false;
      end
      if ( bfw.bounds.rect(x, y, eye_bounds) )
        fprintf( '\n In bounds eyes!' );
        if ( ~fixation_state('eyes') )
          fixation_state('eyes') = true;
          fixations('eyes') = fixations('eyes') + 1;
        end
      else
        fprintf( '\n -- ' );
        fixation_state('eyes') = false;
      end
      
      for j = 1:numel(fixation_keys)
        fprintf( '\n %s: %d', fixation_keys{j}, fixations(fixation_keys{j}) );
      end
    end
  end
  
  mats = shared_utils.io.dirnames( save_p, '.mat' );
  next_id = numel( mats ) + 1;
  gaze_data_file = sprintf( 'position_%d.mat', next_id );
  gaze_data = struct( ...
      'gaze', gaze_data ...
    , 'config', conf ...
    , 'sync_times', gaze_sync_times ...
    , 'plex_sync_times', plex_sync_times ...
    , 'reward_sync_times', reward_sync_times ...
    , 'far_plane_calibration', key_file ...
    , 'far_plane_key_map', key_map ...
    , 'far_plane_padding', calibration_padding ...
    , 'far_plane_constants', calibration_constants ...
    , 'rois', bounds ...
    , 'stimulation_params', stim_params ...
    , 'date', datestr( now ) ...
    , 'plex_sync_index', plex_sync_index ...
    , 'edf_file', edf_file ...
    );
  
  if ( conf.INTERFACE.save_data )
    save( fullfile(save_p, gaze_data_file), 'gaze_data' );
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

tcp_comm.close();

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

function s = get_square_centered_on(r, sz)

cx = ((r(3) - r(1)) / 2) + r(1);
cy = ((r(4) - r(2)) / 2) + r(2);

sz2 = sz / 2;

s = [ cx - sz2, cy - sz2, cx + sz2, cy + sz2 ];

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

if ( stim_params.sync_m1_m2_params )
  if ( is_master )
    other_screen = await_rect( tcp_comm );
    other_eyes = await_rect( tcp_comm );
    other_face = await_rect( tcp_comm );
    other_mouth = await_rect( tcp_comm );
  else
    send_rect( tcp_comm, own_screen );
    send_rect( tcp_comm, own_eyes );
    send_rect( tcp_comm, own_face );
    send_rect( tcp_comm, own_mouth );
  end
else
  other_screen = zeros( 1, 4 );
  other_eyes = repmat( -1, 1, 4 );
  other_face = repmat( -1, 1, 4 );
  other_mouth = repmat( -1, 1, 4 );
end

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

function send_rect( obj, rect )

send_when_ready( obj, 'gaze', rect(1:2) );
send_when_ready( obj, 'gaze', rect(3:4) );

end

function rect = await_rect( obj )

if ( obj.bypass )
  rect = zeros( 1, 4 );
  return; 
end

recta = await_data( obj, 'gaze' );
rectb = await_data( obj, 'gaze' );

rect = [ recta, rectb ];

end