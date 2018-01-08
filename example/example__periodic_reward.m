reward_period = 3000; % ms
reward_amount = 150;  % ms
total_time = 10;  % s

brains.task.periodic_reward( total_time, reward_period, reward_amount );