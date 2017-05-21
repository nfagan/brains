function loaded = load()

%   LOAD -- Load the config file.
%
%     The file will be created based on the defaults in
%     brains.config.create if it does not exist.
%
%     OUT:
%       - `loaded` (struct) -- Loaded config file.

savepath = fileparts( which('brains.config.load') );
filename = fullfile( savepath, 'config.mat' );
if ( exist(filename, 'file') ~= 2 )
  brains.config.create();
end

loaded = load( filename );
loaded = loaded.(char(fieldnames(loaded)));

end