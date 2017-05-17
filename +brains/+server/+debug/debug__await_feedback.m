function debug__await_feedback( is_server, address, port )

if ( is_server )
  t=tcpip( address, port, 'NetworkRole', 'server' );
  fopen(t);
else
  % Configuration and connection
  t = tcpip( address, port );

  % Open socket and wait before sending data
  fopen(t);
  pause(0.2);
end

ready = true;
timeout = 10;
timer_id = tic;

if ( ~is_server )  
  while ( true )
    if ( ready )
      fwrite(t, [1, 65] );
      ready = false;
    else
      ready = check_if_ready( t );
    end
    if ( toc(timer_id) > timeout )
      break;
    end
  end
else
  while ( true )
    if ( ready )
      received = fread(t, 2);
      disp( received );
      fwrite(t, 65);
      ready = false;
    else
      ready = check_if_ready( t );
    end
    if ( toc(timer_id) > timeout )
      break;
    end
  end
end

end

function ready = check_if_ready( t )

ready = false;
if ( t.BytesAvailable <= 0 ), return; end;
received = fread( t, 1 );
if ( char(received) == 'A' )
  fprintf( '\n Success' );
  ready = true;
end

end