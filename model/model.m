function model
   
    % Keep track of how many people's preferred start or end station could
    % not be accomodated
    unhappy_customers = 0;
    
    alpha = 0.2;
    
    STATION_NUM = 329;
    
    % Current locations of bikes and capacities at each station
    % FIXME: we should read the capacities in from the data files on the website.
    bikes = 20 * ones(STATION_NUM);
    capacities = 40 * ones(STATION_NUM);
    
    % Transitions holds the transition matrix for each hour, for each pair
    % of stations.
    % For example, transitions(0, 10, 50) is the probability of going to
    % station 50 from station 10 at hour 0.
    transitions = ones(24, STATION_NUM, STATION_NUM);
    TRANSITIONS_FILENAME = 'july-2013.matrix';
    for hour = 0:23
        range = [hour * STATION_NUM, 0, (hour + 1) * STATION_NUM - 1, STATION_NUM - 1];
        transitions(hour + 1, :, :) = dlmread(TRANSITIONS_FILENAME, '', range);
    end
    
    % Starts holds the distribution of start stations, for each hour
    % For example, starts(5, 60) is the probability of a trip during hour 5
    % starting at station 60.
    starts = ones(24, STATION_NUM);
    START_FILENAME = 'july-2013-start.matrix';
    for hour = 0:23
        range = [hour * STATION_NUM, 0, (hour + 1) * STATION_NUM - 1, 0];
        starts(hour + 1, :) = dlmread(START_FILENAME, '', range);
    end
    
    % Trip counts hold the distribution for number of trips per hour.
    % For example, counts(5) = [Mean, Variance] for number of trips in hour 5
    TRIPCOUNTS_FILENAME = 'july-2013-tripcounts.matrix';
    range = [0, 0, 23, 1];
    counts = dlmread(TRIPCOUNTS_FILENAME, '', range);

    %{
    figure
    axis([0, 8, 0, max(capacities)])
    axis manual
    set(gca,'XTickLabel',labels)
    hold on
    bar([ bikes; unhappy_customers; 0 ])
    %}
    
    % Compute the number of trips that take place during a tick in this
    % hour.  Note that a tick is 10 minutes, so divide by 6.
    function trips = trips_per_tick(hour)
        trips = floor(normrnd(counts(hour + 1, 1) * alpha, counts(hour + 1, 2)^.5) / 6);
    end

    % Compute the cost of moving some number of bikes
    function cost = cost_to_move(bikes)
        % Picked a random function here.  Need to think about this.
        cost = (5 * bikes + 7) / 100;
    end

    % Simulate a single trip that take place in a given hour
    function [] = simulate_trip(hour)
        
        % Generate a random number 0 to 1, and find the starting station
        % such that the number fulls in that station's range in the
        % cumulative probability function
        trip = rand();
        for startStation = 1:STATION_NUM
            if trip < starts(hour + 1, startStation)
                break
            else
                trip = trip - starts(hour + 1, startStation);
            end
        end
        
        % Make sure we have a bike at the user's desired start station
        if bikes(startStation) <= 0
            strcat('start station ', int2str(startStation),' is empty')
            unhappy_customers = unhappy_customers + 1;
            return
        end

        % Generate a random number 0 to 1, and find the ending station
        % such that the number fulls in that station's range in the
        % cumulative probability function
        trip = rand();
        for endStation = 1:STATION_NUM
            if trip < transitions(hour + 1, startStation, endStation)
                break
            else
                trip = trip - transitions(hour + 1, startStation, endStation);
            end
        end

        % Make sure we have a bike at the user's desired end station
        if bikes(endStation) >= capacities(endStation)
           strcat('end station ', int2str(endStation),' is full')
           unhappy_customers = unhappy_customers + 1;
           return
        end

        % FIXME: Trips here are assumed to be instantaneous, but maybe they
        % should take some time for the bike to be available again
        
        % Move the bike
        bikes(startStation) = bikes(startStation) - 1;
        bikes(endStation) = bikes(endStation) + 1;
    end

    % Simplest heuristic to perform rebalancing -
    % move 1 bike from biggest station to smallest
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

    % Simulate a full day's worth of time ticks
    totalCost = 0;
    for i = 1:143
        hour = floor(i / 6);
        tripCount = trips_per_tick(hour);
        % Simulate each trip that occurred this time tick.
        for j = 1:tripCount
            simulate_trip(hour);
        end

        % Simulate any rebalancing that occurred this time tick.
        %totalCost = totalCost + simplest_rebalance();
        %totalCost = totalCost + balanced_rebalance();

        % Redraw graph
        %{
        hold off
        clf
        axis([0, 8, 0, max(capacities)])
        axis manual
        set(gca,'XTickLabel',labels)
        hold on
        bar([ bikes; unhappy_customers; totalCost ])
        pause(0.01)
        %}
        
    end

    bikes;
    unhappy_customers
    totalCost
end
