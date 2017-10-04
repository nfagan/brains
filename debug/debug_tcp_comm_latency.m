%%  test tcp_comm latency

clear all; clc;

N = 5e3;
slatencies = zeros( 1, N );
rlatencies = zeros( 1, N );
start = [];

rstp = 1;
received_timer = NaN;

latency_thresholds = [1, 2, 3, 5, 10, 15, 20];

tcp_comm = brains.server.get_tcp_comm();

is_server = isa( tcp_comm, 'brains.server.Server' );

tcp_comm.start();

if ( is_server )
  for i = 1:N
    start = tic;
    tcp_comm.send_when_ready( 'gaze', [10, 10] );
    slatencies(i) = toc( start );
  end
else
  while ( true )
    tcp_comm.update();
    gaze = tcp_comm.consume( 'gaze' );
    if ( ~any(isnan(gaze)) )
      if ( isnan(received_timer) )
        received_timer = tic;
      else
        rlatencies(rstp) = toc( received_timer );
        received_timer = tic;
        rstp = rstp + 1;
      end
    end
    if ( ~isnan(tcp_comm.DATA.choice) ), break; end
  end
end

perc = @(x) (sum(x) / numel(x)) * 100;

if ( is_server )  
  tcp_comm.send_when_ready( 'choice', 0 );
  slatencies = slatencies * 1e3;

  fprintf( '\nAverage round-trip-latency: %0.4f', mean(slatencies) );
  fprintf( '\nStd dev round-trip-latency: %0.4f', std(slatencies) );
  fprintf( '\nMax     round-trip-latency: %0.4f', max(slatencies) );
  fprintf( '\nMin     round-trip-latency: %0.4f', min(slatencies) );
  for i = 1:numel(latency_thresholds)
    thresh = latency_thresholds(i);
    fprintf( '\nPercent less than %0.1f: %0.3f', thresh, perc(slatencies < thresh) );
  end
  fprintf( '\n\n' );
else
  rlatencies = rlatencies(1:rstp-1) * 1e3;

  fprintf( '\nAverage round-trip-latency: %0.4f', mean(rlatencies) );
  fprintf( '\nStd dev round-trip-latency: %0.4f', std(rlatencies) );
  fprintf( '\nMax     round-trip-latency: %0.4f', max(rlatencies) );
  fprintf( '\nMin     round-trip-latency: %0.4f', min(rlatencies) );
  for i = 1:numel(latency_thresholds)
    thresh = latency_thresholds(i);
    fprintf( '\nPercent less than %0.1f: %0.3f', thresh, perc(rlatencies < thresh) );
  end
  fprintf( '\n\n' );  
end

tcp_comm.close();
