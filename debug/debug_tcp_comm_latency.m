clear all; clc;

is_client = false;

N = 1e3;
latencies = zeros( 1, N );
start = [];

latency_thresholds = [1, 2, 3, 5, 10, 20];

tcp_comm = [];

address = 'localhost';
port = 55e3;

if ( is_client )
  tcp_comm = brains.server.Client( address, port );
else
  tcp_comm = brains.server.Server( address, port );
end

tcp_comm.start();

if ( is_client )
  for i = 1:N
    start = tic;
    tcp_comm.send_when_ready( 'gaze', [10, 10] );
    latencies(i) = toc( start );
  end
else
  while ( true )
    tcp_comm.update();
    if ( ~isnan(tcp_comm.DATA.choice) ), break; end
  end
end

if ( is_client )
  perc = @(x) (sum(x) / numel(x)) * 100;
  
  tcp_comm.send_when_ready( 'choice', 0 );
  latencies = latencies * 1e3;

  fprintf( '\nAverage round-trip-latency: %0.4f', mean(latencies) );
  fprintf( '\nStd dev round-trip-latency: %0.4f', std(latencies) );
  fprintf( '\nMax     round-trip-latency: %0.4f', max(latencies) );
  fprintf( '\nMin     round-trip-latency: %0.4f', min(latencies) );
  for i = 1:numel(latency_thresholds)
    thresh = latency_thresholds(i);
    fprintf( '\nPercent less than %0.1f: %0.3f', thresh, perc(latencies < thresh) );
  end
  fprintf( '\n\n' );
end
