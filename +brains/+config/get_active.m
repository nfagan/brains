function active = get_active()

%   GET_ACTIVE -- Get the name of the active config.mat file

direc = fileparts( which(sprintf('brains.config.%s', mfilename)) );
filename = fullfile( direc, 'active.mat' );

if ( exist(filename, 'file') == 0 )
  active = 'config.mat';
  brains.config.set_active( active );
  return
end

try
  active = load( filename );
  active = active.( char(fieldnames(active)) );
  shared_utils.assertions.assert__isa( active, 'char', 'the active filename.' );
catch err
  fprintf( ['\n WARNING: Parsing of the active.mat file failed. Using' ...
    , ' `config.mat` as the active filename.'] );
  active = 'config.mat';
  brains.config.set_active( active );
end

end