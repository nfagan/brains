function periodic_reward(reward_period, reward_amount)

%   PERIODIC_REWARD -- Deliver reward every x ms.
%
%     IN:
%       - `reward_period` (double) -- Inter-reward interval, in ms.
%       - `reward_amount` (double) -- Reward-sie, in ms.

conf = brains.config.load();
comm = brains.arduino.get_serial_comm();
comm.start();

reward_key_timer = NaN;
reward_period_timer = NaN;

try
  
  tracker = EyeTracker( conf.IO.edf_file, conf.IO.edf_folder, 0 );
  tracker.bypass = ~conf.INTERFACE.use_eyelink;
  tracker.init();
  tracker.start_recording();  
  
  while ( true )
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
      comm.reward( 1, reward_amount );
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

comm.close();
brains.arduino.close_ports();

if ( conf.INTERFACE.save_data )
  tracker.shutdown();
else
  tracker.stop_recording();
end

end