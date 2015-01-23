function model
    P = [.4, .1, .3, .1, .1;
         .1, .1, .5, .1, .2;
         .2, .3, .3, .1, .1;
         .2, .2, .2, .2, .2;
         .2, .3, .1, .1, .3];

    bikes = [15; 15; 15; 15; 15];
    capacities = [30; 30; 30; 30; 30];


    % Returns an integer
    function trips = trips_per_tick()
        % Assumes a random distribution 0 to 10, fix this
        trips = round(rand() * 10);
    end


    % Simulate 1000 time ticks
    for i = 0:1000
        tripCount = trips_per_tick();
        % Simulate each trip that occurred this time tick.
        for j = 1:tripCount
            startStation = floor(rand() * 5) + 1;
            if bikes(startStation) <= 0
                strcat('start station ', int2str(startStation),' is empty')
                continue
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
               continue 
            end

            % FIXME: Trips here are assumed to be instantaneous, but maybe they
            % should take some time for the bike to be available again
            bikes(startStation) = bikes(startStation) - 1;
            bikes(endStation) = bikes(endStation) + 1;
        end
    end

    bikes
end