function debug__slave()

%% TCP/IP Receiver

% Clear console and workspace
close all;
clear all;
clc;

% Configuration and connection
disp ('Receiver started');
t=tcpip('127.0.0.1', 55e3,'NetworkRole','server');

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