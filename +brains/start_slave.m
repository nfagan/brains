function start_slave()

% if ( nargin == 0 )
%   opts.INTERFACE = struct( 'is_master_monkey', false, 'is_master_arduino', false );
% end
% 
% brains.task.start( opts );

config = brains.config.load();
config.INTERFACE.is_master_monkey = false;
config.INTERFACE.is_master_arduino = false;
brains.config.save( config );
brains.task.start();

end