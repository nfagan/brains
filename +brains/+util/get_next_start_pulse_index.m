function c = get_next_start_pulse_index(varargin)

%   GET_NEXT_START_PULSE_INDEX -- Get the index of the next start pulse
%     that will be sent to plexon.
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
  c = 1;
  return
end

c = counts.next_start_pulse;

end