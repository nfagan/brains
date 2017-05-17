function debug__master( address, port )

if ( nargin == 0 )
  address = '127.0.0.1';
  port = 55e3;
end

% Clear console and workspace
clc;
clear all;
close all;

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

if ( t.BytesAvailable > 0 )
  DataReceived = fread( t, 2 )
end

% Close and delete connection
fclose(t);
delete(t);