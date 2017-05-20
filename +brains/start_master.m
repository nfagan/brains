function start_master(opts)

if ( nargin == 0 )
  opts = struct( 'is_master_monkey', true, 'is_master_arduino', true );
end

brains.task.start( opts );

end