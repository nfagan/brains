function reward_listener()

%   REWARD_LISTENER -- Trigger reward upon key press.

conf = brains.config.load();
comm = brains.arduino.get_serial_comm();
comm.start();

reward_key_timer = NaN;

try
  
  fprintf( '\n Listening ... ' );
  
  while ( true )
    [key_pressed, ~, key_code] = KbCheck();
    if ( key_pressed )
      % - Quit if stop_key is pressed
      if ( key_code(conf.INTERFACE.stop_key) ), break; end;
      if ( key_code(conf.INTERFACE.rwd_key) )
        if ( isnan(reward_key_timer) )
          should_reward = true;
        else
          should_reward = toc( reward_key_timer ) > conf.REWARDS.main/1e3;
        end
        if ( should_reward )
          comm.reward( 1, conf.REWARDS.key_press );
          reward_key_timer = tic;
        end
      end
    end
  end
  cleanup( comm );
catch err
  cleanup( comm );
  throw( err );
end

fprintf( 'Done.\n\n' );

end

function cleanup(comm)

comm.close();
brains.arduino.close_ports();

end