function set_active( filename )

shared_utils.assertions.assert__isa( filename, 'char', 'the active config filename' );
dir = fileparts( which(sprintf('brains.config.%s', mfilename)) );
save( fullfile(dir, 'active.mat'), 'filename' );

end