function model
    P = [.4, .1, .3, .1, .1;
         .1, .1, .5, .1, .2;
         .2, .3, .3, .1, .1;
         .2, .2, .2, .2, .2;
         .2, .3, .1, .1, .3];

    bikes = [15; 15; 15; 15; 15];
    capacities = [30; 30; 30; 30; 30];
    unhappy_customers = 0;

    % Returns an integer
    function trips = trips_per_tick()
        % Assumes a random distribution 0 to 10, fix this
        trips = round(rand() * 10);
    end

    function cost = cost_to_move(bikes)
        % Picked a random function here.  Need to think about this.
        cost = 5 * bikes + 7;
    end

    function [] = simulate_trip()
        startStation = floor(rand() * 5) + 1;
        if bikes(startStation) <= 0
            strcat('start station ', int2str(startStation),' is empty')
            unhappy_customers = unhappy_customers + 1;
            return
        end

        trip = rand();

        for endStation = 1:5
            if trip < P(startStation, endStation)
                break
            else
                trip = trip - P(startStation, endStation);
            end
        end

        if bikes(endStation) >= capacities(endStation)
           strcat('end station ', int2str(endStation),' is full')
           unhappy_customers = unhappy_customers + 1;
           return 
        end

        % FIXME: Trips here are assumed to be instantaneous, but maybe they
        % should take some time for the bike to be available again
        bikes(startStation) = bikes(startStation) - 1;
        bikes(endStation) = bikes(endStation) + 1;
    end
    
    % Simplest heuristic - move 1 bike from biggest station to smallest
    function cost = simplest_rebalance()
        [~, maxIndex] = max(bikes);
        [~, minIndex] = min(bikes);
        
        bikes(minIndex) = bikes(minIndex) + 1;
        bikes(maxIndex) = bikes(maxIndex) - 1;
        
        cost = cost_to_move(1);
    end

    % Another easy heuristic - if stations have less than 25% bikes,
    % rebalance it up to 50% by moving bikes from the fullest station.
    % Similarly, if a station is more than 75% full, move bikes to the
    % emptiest station until its at 50%
    function cost = balanced_rebalance()
        [maxBikes, maxIndex] = max(bikes);
        [minBikes, minIndex] = min(bikes);
        
        bikesToMoveToMin = 0;
        bikesToMoveToMax = 0;
        
        if (minBikes < capacities(minIndex) / 4)
            bikesToMoveToMin = capacities(minIndex) / 2 - minBikes;
        end
        
        if (minBikes > 3 * capacities(minIndex) / 4)
            bikesToMoveToMax = maxBikes - capacities(minIndex) / 2;
        end
        
        bikesMoving = max(bikesToMoveToMin, bikesToMoveToMax);
        
        bikes(minIndex) = bikes(minIndex) + bikesMoving;
        bikes(maxIndex) = bikes(maxIndex) - bikesMoving;
        
        cost = cost_to_move(bikesMoving);
    end
    
    % Simulate 1000 time ticks
    totalCost = 0;
    for i = 0:1000
        tripCount = trips_per_tick();
        % Simulate each trip that occurred this time tick.
        for j = 1:tripCount
            simulate_trip();
        end
        
        % Simulate any rebalancing that occurred this time tick.
        %totalCost = totalCost + simplest_rebalance();
        totalCost = totalCost + balanced_rebalance();
    end

    bikes
    unhappy_customers
    totalCost
end