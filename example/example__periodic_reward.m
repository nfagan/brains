reward_period = 2000; % ms
reward_amount = 100;  % ms
total_time = 5*60;  % s

%   1 -> m1;
%   2 -> m2;

rewarded_targets = 1;
% rewarded_targets = 1:2;

brains.task.periodic_reward( total_time, reward_period, reward_amount, rewarded_targets );