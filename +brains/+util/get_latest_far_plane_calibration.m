function key = get_latest_far_plane_calibration(p)

if ( nargin < 1 )
  p = fullfile( brains.util.get_latest_data_dir_path(), 'calibration' );
end

try
  shared_utils.assertions.assert__valid_path( p );
catch err
  error( 'The calibration directory ''%s'' does not exist.', p );
end

mats = shared_utils.io.dirnames( p, '.mat' );

if ( isempty(mats) )
  error( 'No calibration files found in ''%s''.', p );
end

mat_ns = cellfun( @(x) x(numel('far_plane_calibration')+1:end), mats, 'un', false );

if ( numel(mats) ~= 1 )
  ns = zeros( size(mat_ns) );

  for i = 1:numel(ns)
    ns(i) = str2double( mat_ns{i}(1:end-4) );
  end

  [~, I] = sort( ns );

  file = mats{I(end)};
else
  file = mats{1};
end

key = load( fullfile(p, file) );
key = key.(char(fieldnames(key)));

end