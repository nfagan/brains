function free_viewing(task_time, reward_period, reward_amount, key_file, key_map, bounds, stim_params)

%   PERIODIC_REWARD -- Deliver reward every x ms.
%
%     IN:
%       - `reward_period` (double) -- Inter-reward interval, in ms.
%       - `reward_amount` (double) -- Reward-sie, in ms.

conf = brains.config.load();

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

try
  
  tracker = EyeTracker( edf_file, save_p, 0 );
  tracker_exists = true;
  tracker.bypass = ~conf.INTERFACE.use_eyelink;
  tracker.init();
  
  tcp_comm = brains.server.get_tcp_comm();
  tcp_comm.bypass = ~conf.INTERFACE.require_synch;
  tcp_comm.start();
  
  stim_comm = init_stim_comm( conf, tcp_comm, stim_params, bounds );
  
  task_timer = tic();
  
  tracker.send_message( 'SYNCH' );
  fprintf( '\n Sync!' );
  comm.sync_pulse( sync_pulse_map.start );
  
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
      structfun( @(x) brains.util.el_draw_rect(x, 3), bounds );
      brains.util.draw_far_plane_rois( key_file, 20, 1, tracker.bypass );
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
    , 'edf_file', edf_file ...
    );
  save( fullfile(save_p, gaze_data_file), 'gaze_data' );
  
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

function stim_comm = init_stim_comm(conf, tcp_comm, stim_params, bounds)

is_master = conf.INTERFACE.is_master_arduino;

own_screen = conf.CALIBRATION.cal_rect;
own_eyes = bounds.eyes;
own_face = bounds.face;
own_mouth = bounds.mouth;

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

send_bounds( stim_comm, 'm1', 'screen', own_screen );
send_bounds( stim_comm, 'm2', 'screen', other_screen );

send_bounds( stim_comm, 'm1', 'eyes', own_eyes );
send_bounds( stim_comm, 'm2', 'eyes', other_eyes );

send_bounds( stim_comm, 'm1', 'face', own_face);
send_bounds( stim_comm, 'm2', 'face', other_face );

send_bounds( stim_comm, 'm1', 'mouth', own_mouth );
send_bounds( stim_comm, 'm2', 'mouth', other_mouth );

send_stim_param( stim_comm, 'all', 'probability', stim_params.probability );
send_stim_param( stim_comm, 'all', 'frequency', stim_params.frequency );
send_stim_param( stim_comm, 'all', 'stim_stop_start', 0 );

active_rois = stim_params.active_rois;

if ( ~iscell(active_rois) ), active_rois = { active_rois }; end

send_stim_param( stim_comm, 'all', 'protocol', stim_params.protocol );

cellfun( @(x) send_stim_param(stim_comm, x, 'stim_stop_start', 1), active_rois );

end

function local_cleanup(comm, tracker, conf, stim_comm)

brains.arduino.close_ports();

if ( ~isempty(tracker) )
  tracker.shutdown();
end

if ( ~isempty(stim_comm) )
  fclose( stim_comm );
end

end

function send_rect( obj, rect )

send_when_ready( obj, rect(1:2) );
send_when_ready( obj, rect(3:4) );

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