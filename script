P = [.4, .1, .3, .1, .1;
     .1, .1, .5, .1, .2;
     .2, .3, .3, .1, .1;
     .2, .2, .2, .2, .2;
     .2, .3, .1, .1, .3];
 
bikes = [15; 15; 15; 15; 15];
capacities = [30; 30; 30; 30; 30];

for i = 0:100
    startStation = floor(rand() * 5) + 1;
    if bikes(startStation) <= 0
        v = strcat('start station ', int2str(startStation),' is empty')
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
       v = strcat('end station ', int2str(endStation),' is full')
       continue 
    end
    
    bikes(startStation) = bikes(startStation) - 1;
    bikes(endStation) = bikes(endStation) + 1;
end

bikes