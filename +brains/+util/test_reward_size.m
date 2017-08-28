brains.arduino.close_ports();

comm = brains.arduino.get_serial_comm();
comm.start();

iterations = 10;
rwd_size = 800;
rwd_timer = NaN;
i = 0;

while ( i < iterations )
  
  if ( isnan(rwd_timer) )
    should_reward = true;
    rwd_timer = tic;
  else
    should_reward = toc( rwd_timer ) > rwd_size/1e3;
  end
  
  if ( should_reward )
    comm.reward( 1, rwd_size );
    comm.update();
    i = i + 1;
    rwd_timer = tic;
  end
  
end

clear comm;
brains.arduino.close_ports();