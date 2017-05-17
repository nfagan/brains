function debug__slave( address, port )


if ( nargin == 0 )
  address = '127.0.0.1';
  port = 55e3;
end

%% TCP/IP Receiver

% Configuration and connection
disp ('Receiver started');
t=tcpip( address, port, 'NetworkRole','server');

% Wait for connection
disp('Waiting for connection');
fopen(t);
disp('Connection OK');

% Read data from the socket
for i=0:10
    DataReceived=fread(t,2)
end

fwrite( t, [1;2] );

end