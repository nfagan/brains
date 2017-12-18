function free_viewing(task_time, reward_period, reward_amount, dist_file, roi_file, key_file, other_monk)

%   PERIODIC_REWARD -- Deliver reward every x ms.
%
%     IN:
%       - `reward_period` (double) -- Inter-reward interval, in ms.
%       - `reward_amount` (double) -- Reward-sie, in ms.

conf = brains.config.load();

if ( ~conf.INTERFACE.allow_overwrite && conf.INTERFACE.save_data )
  brains.util.assert__file_does_not_exist( fullfile(conf.IO.edf_folder, conf.IO.edf_file) );
end

screen_constants = brains_analysis.gaze.util.get_screen_constants();
first_invocation = true;

edf_sample_rate = 1e3;

if ( ~isinf(task_time) )
  gaze_data = nan( 3, task_time * edf_sample_rate );
else
  gaze_data = nan( 3, 1 );
end

gaze_sync_times = nan( 10e3, 2 );

gaze_stp = 1;
gaze_sync_stp = 1;

comm = brains.arduino.get_serial_comm();
comm.bypass = ~conf.INTERFACE.use_arduino;
comm.start();

reward_key_timer = NaN;
reward_period_timer = NaN;

edf_sync_interval = 1;
tcp_sync_interval = 1;

try
  
  tracker = EyeTracker( conf.IO.edf_file, conf.IO.edf_folder, 0 );
  tracker.bypass = ~conf.INTERFACE.use_eyelink;
  tracker.init();
  
  tcp_comm = brains.server.get_tcp_comm();
  tcp_comm.bypass = ~conf.INTERFACE.require_synch;
  tcp_comm.start();
  
  tracker.send_message( 'SYNCH' );
  fprintf( '\n Sync!' );
%   comm.sync_pulse( 1 );
  
  task_timer = tic();
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
        comm.reward( 1, reward_amount );
      end
      reward_period_timer = tic;
    end
    
    if ( first_invocation )
      brains.util.draw_far_plane_rois( key_file, 20, 1, tracker.bypass );
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
      next_edf_pulse_time = toc( task_timer ) + edf_sync_interval;
    end
    
    if ( ~isempty(tracker.coordinates) )
      gaze_data(1:2, gaze_stp) = tracker.coordinates;
      gaze_data(3, gaze_stp) = toc( task_timer );
      gaze_stp = gaze_stp + 1;
    end
  end
  disp( gaze_stp );
  
  if ( conf.INTERFACE.save_data )
    save_p = fullfile( conf.IO.repo_folder, 'brains', 'data', datestr(now, 'mmddyy') );
    if ( exist(save_p, 'dir') ~= 7 ), mkdir(save_p); end
    mats = shared_utils.io.dirnames( save_p, '.mat' );
    next_id = numel( mats ) + 1;
    gaze_data_file = sprintf( 'position_%d.mat', next_id );
    gaze_data = struct( 'position', gaze_data, 'sync_times', gaze_sync_times );
    save( fullfile(save_p, gaze_data_file), 'gaze_data' );
  end
  
  local_cleanup( comm, tracker, conf );
catch err
  local_cleanup( comm, tracker, conf );
  throw( err );
end

tcp_comm.close();


end

function local_cleanup(comm, tracker, conf)

comm.close();
brains.arduino.close_ports();

if ( conf.INTERFACE.save_data && ~isempty(tracker) )
  tracker.shutdown();
else
  tracker.stop_recording();
end

end