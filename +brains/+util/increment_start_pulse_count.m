function increment_start_pulse_count(p)

%   INCREMENT_START_PULSE_COUNT -- Increment the current count of
%     start-pulses sent to Plexon.
%
%     IN:
%       - `p` (char) |OPTIONAL| -- Path in which to save the counts file.

if ( nargin < 1 || isempty(p) )
  p = fullfile( brains.util.get_latest_data_dir_path(), 'plex_sync' );
end

filename = fullfile( p, 'start_counts.mat' );

counts = struct();

if ( exist(filename, 'file') ~= 2 )
  counts.next_start_pulse = 1;
else
  counts = load( filename );
  counts = counts.(char(fieldnames(counts)));
  counts.next_start_pulse = counts.next_start_pulse + 1;
end

if ( exist(p, 'dir') ~= 7 ), mkdir( p ); end

save( filename, 'counts' );

end