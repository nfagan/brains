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
  
  COMMUNICATORS.server_address = '0.0.0.0';
  COMMUNICATORS.client_address = '172.28.141.64';
  
  opts = struct();
  opts.INTERFACE = INTERFACE;
  opts.COMMUNICATORS = COMMUNICATORS;
end

save( filename, 'opts' );

end