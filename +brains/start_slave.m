function start_slave(opts)

if ( nargin == 0 )
  opts.INTERFACE = struct( 'is_master_monkey', false, 'is_master_arduino', false );
end

brains.task.start( opts );

end