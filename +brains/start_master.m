function start_master()
% 
% if ( nargin == 0 )
%   opts.INTERFACE = struct( 'is_master_monkey', true, 'is_master_arduino', true );
% end
% 
% brains.task.start( opts );

config = brains.config.load();
config.STRUCTURE.is_master_monkey = true;
config.INTERFACE.is_master_arduino = true;
brains.config.save( config );
brains.task.start();

end