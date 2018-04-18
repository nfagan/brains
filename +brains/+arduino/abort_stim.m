function abort_stim(stim_comm)

%   ABORT_STIM -- Ensure that stimulation cannot occurr.

try
  brains.arduino.calino.send_stim_param( stim_comm, 'all', 'stim_stop_start', 0 );
catch err
  warning( err.message );
end

end