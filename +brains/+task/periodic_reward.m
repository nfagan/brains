function periodic_reward(total_time, reward_period, reward_amount, reward_channels)

%   PERIODIC_REWARD -- Deliver reward every x ms.
%
%     IN:
%       - `reward_period` (double) -- Inter-reward interval, in ms.
%       - `reward_amount` (double) -- Reward-sie, in ms.

if ( nargin < 2 )
  reward_channels = 1;
end

conf = brains.config.load();

reward_key_timer = NaN;
reward_period_timer = NaN;

sync_pulse_map = brains.arduino.get_sync_pulse_map();

try
  
  tracker = EyeTracker( conf.IO.edf_file, conf.IO.edf_folder, 0 );
%   tracker.bypass = ~conf.INTERFACE.use_eyelink;
  tracker.bypass = true;
  tracker.init();
  tracker.start_recording();  
  
  use_arduino = conf.INTERFACE.use_arduino;
  
  comm = brains.arduino.get_serial_comm();
  comm.bypass = ~use_arduino;
  comm.start();
  
  task_timer = tic();
  
  comm.sync_pulse( sync_pulse_map.start );
  
  if ( use_arduino )
    brains.util.increment_start_pulse_count();
  end
  
  while ( true )
    if ( toc(task_timer) > total_time ), break; end
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
          comm.reward( 1, conf.REWARDS.key_press );
          comm.reward( 2, conf.REWARDS.key_press );
          reward_key_timer = tic;
        end
      end
    end
    if ( isnan(reward_period_timer) || toc(reward_period_timer) > reward_period/1e3 )
      comm.sync_pulse( sync_pulse_map.reward );
      for j = 1:numel(reward_channels)
        comm.reward( reward_channels(j), reward_amount );
      end
      reward_period_timer = tic;
    end
  end
  local_cleanup( comm, tracker, conf );
catch err
  local_cleanup( comm, tracker, conf );
  throw( err );
end


end

function local_cleanup(comm, tracker, conf)

% comm.close();
brains.arduino.close_ports();

if ( conf.INTERFACE.save_data )
  tracker.shutdown();
else
  tracker.stop_recording();
end

end