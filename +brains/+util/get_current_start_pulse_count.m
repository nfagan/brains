function c = get_current_start_pulse_count(varargin)

%   GET_CURRENT_START_PULSE_COUNT -- Get a count of the number of
%     start-pulses that have been sent to plexon on this recording day.
%
%     IN:
%       - `p` (char) |OPTIONAL| -- Path to the folder housing a
%         "start_counts.mat" file.
%     OUT:
%       - `c` (double)

try
  counts = brains.util.load_start_pulse_count_file( varargin{:} );
catch err
  warning( err.message );
  c = 0;
  return
end

c = counts.next_start_pulse - 1;

end