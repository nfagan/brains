function debug__master( address, port )

if ( nargin == 0 )
  address = '127.0.0.1';
  port = 55e3;
end

% Configuration and connection
t = tcpip( address, port );

% Open socket and wait before sending data
fopen(t);
pause(0.2);

% Send data every 500ms
for i=0:10    
    DataToSend=[i;i]
    fwrite(t,DataToSend);
%     pause(0.5);
end

start_await = tic;
success = true;

while ( t.BytesAvailable == 0 )
  if ( toc(start_await) > 5 )
    success = false;
    break;
  end
end
if ( success )
  DataReceived = fread( t, 2 );
  disp( DataReceived );
else
  fprintf( '\n Unsuccessful' );
end

% Close and delete connection
fclose(t);
delete(t);