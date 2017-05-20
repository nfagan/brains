function save( opts )

savepath = fileparts( which('brains.config.save') );
filename = fullfile( savepath, 'config.mat' );

if ( nargin == 0 )
  INTERFACE = struct();
  INTERFACE.save_data = false;
  INTERFACE.use_eyelink = false;
  INTERFACE.use_arduino = false;
  INTERFACE.require_synch = false;
  INTERFACE.is_master_arduino = true;
  INTERFACE.is_master_monkey = true;
  opts = struct();
  opts.INTERFACE = INTERFACE;
end

save( filename, 'opts' );

end