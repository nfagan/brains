function loaded = load()

savepath = fileparts( which('brains.config.load') );
filename = fullfile( savepath, 'config.mat' );
if ( exist(filename, 'file') ~= 2 )
  brains.config.save();
end

loaded = load( filename );
loaded = loaded.(char(fieldnames(loaded)));

end