function auto_flush()

%   AUTO_FLUSH -- Flush according to the length of time defined in the
%     config file.

conf = brains.config.load();

n_milliseconds = conf.REWARDS.flush;
n_solenoids = 2;

brains.arduino.flush( 1:n_solenoids, n_milliseconds );

end