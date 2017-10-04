%%

comm = brains.arduino.get_serial_comm();
comm.start();

%   queue the sending of 3 rewards. the first happens immediately, the next
%   two happen once the previous one has completed.

comm.reward(1, 2e3);
comm.reward(1, 500);
comm.reward(1, 250);

test_dur = 5;
test_timer = tic;

while ( toc(test_timer) < test_dur )
  %   update whether the next reward is ready to send
  comm.update();
end

comm.close();