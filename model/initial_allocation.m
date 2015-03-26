function initial_allocation

    STATION_NUM = 329;
    BIKE_NUM = 3116;
            
    P = ones(24, STATION_NUM, STATION_NUM);
    TRANSITIONS_FILENAME = 'july-2013.matrix';
    for hour = 0:23
        range = [hour * STATION_NUM, 0, (hour + 1) * STATION_NUM - 1, STATION_NUM - 1];
        P(hour + 1, :, :) = dlmread(TRANSITIONS_FILENAME, '', range);
    end
    
    best_error = 999999999;
    
    for outer_iter = 1:5
        
        NUM_PARALLEL_ITERS = 100;

        best_errors = zeros(NUM_PARALLEL_ITERS, 1);
        best_es = zeros(NUM_PARALLEL_ITERS, 24, STATION_NUM);

        %parpool

        parfor iter = 1:NUM_PARALLEL_ITERS
            e = zeros(24, STATION_NUM);
            e_optimal = rand(24, STATION_NUM);

            for t = 1:24
                e_optimal(t, :, :) = e_optimal(t, :, :) / sum(e_optimal(t, :, :)) * BIKE_NUM;
            end

            total_error = 0;

            for t = 1:24
                for current_station = 1:STATION_NUM
                    for other_station = 1:STATION_NUM
                        enter = e_optimal(t, other_station) * P(t, other_station, current_station);
                        exit = e_optimal(t, current_station) * P(t, current_station, other_station);

                        e(t+1, current_station) = e_optimal(t, current_station) + enter - exit;

                        next_time = mod(t, 24) + 1;

                        error = e(next_time, current_station) - e_optimal(next_time, current_station);
                        total_error = total_error + abs(error);
                    end
                end
            end

            best_errors(iter) = total_error
            best_es(iter, :, :) = e_optimal;
            %iter
        end

        best_found = max(best_errors);
        if best_found < best_error
            ix = find(best_errors == best_found);
            best_e = squeeze(best_es(ix, :, :));
            size(best_e)
            dlmwrite('optimal-allocations.matrix', best_e, 'delimiter','\t');
            best_error = best_found
            disp 'Found local opt'
        end
    end
end
