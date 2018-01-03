function await_char( comm, c, msg, timeout )

if ( nargin < 3 )
  msg = sprintf( 'Failed to receive character "%s".', c );
end

if ( nargin < 4 )
  timeout = 5;
end

ack_timer = tic();

while ( comm.BytesAvailable == 0 )
  if ( toc(ack_timer) > timeout )
    error( 'Receipt of "%s" timed-out.', c );
  end
end

assert( isequal(fread(comm, comm.BytesAvailable, 'char'), c), msg );

end