function free_viewing(task_time, reward_period, reward_amount, key_file, key_map)

%   PERIODIC_REWARD -- Deliver reward every x ms.
%
%     IN:
%       - `reward_period` (double) -- Inter-reward interval, in ms.
%       - `reward_amount` (double) -- Reward-sie, in ms.

conf = brains.config.load();

save_p = fullfile( conf.IO.repo_folder, 'brains', 'data', datestr(now, 'mmddyy') );
if ( exist(save_p, 'dir') ~= 7 ), mkdir(save_p); end

edfs = shared_utils.io.find( save_p, '.edf' );
n_edfs = numel( edfs );
edf_file = sprintf( '%s%d.edf', conf.IO.edf_file, n_edfs + 1 );

% if ( ~conf.INTERFACE.allow_overwrite && conf.INTERFACE.save_data )
  brains.util.assert__file_does_not_exist( fullfile(save_p, edf_file) );
% end

screen_constants = brains_analysis.gaze.util.get_screen_constants();
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
%       brains.util.draw_far_plane_rois( key_file, 20, 1, tracker.bypass );
%       brains.util.draw_eyelink_rois( conf, tracker, dist_file, roi_file, screen_constants, other_monk, true );
      first_invocation = false;
    else
%       brains.util.draw_eyelink_rois( conf, tracker, dist_file, roi_file, screen_constants, other_monk, false );
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
  
%   if ( conf.INTERFACE.save_data )
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
      , 'date', datestr( now ) ...
      , 'edf_file', edf_file ...
      );
    save( fullfile(save_p, gaze_data_file), 'gaze_data' );
%   end
  
  local_cleanup( comm, tracker, conf );
catch err
  if ( ~tracker_exists )
    tracker = [];
  end
  local_cleanup( comm, tracker, conf );
  throw( err );
end

tcp_comm.close();


end

function local_cleanup(comm, tracker, conf)

brains.arduino.close_ports();

% if ( conf.INTERFACE.save_data && ~isempty(tracker) )
%   tracker.shutdown();
% else
%   tracker.stop_recording();
% end

if ( ~isempty(tracker) )
  tracker.shutdown();
end

end