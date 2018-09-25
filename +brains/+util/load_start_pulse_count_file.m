function c = load_start_pulse_count_file(p)

if ( nargin < 1 || isempty(p) )
  p = fullfile( brains.util.get_latest_data_dir_path(), 'plex_sync' );
end

filename = fullfile( p, 'start_counts.mat' );

assert( exist(filename, 'file') == 2 ...
  , 'The plexon start counts file "%s" has not yet been defined.', filename );

c = load( filename );
c = c.(char(fieldnames(c)));

end