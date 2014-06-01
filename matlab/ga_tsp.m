function [point_list_output] = ga_tsp(point_list_input, pop_size, mutation_rate, crossing_rate, iter_number, speed_straight, startPos)
    point_list = [startPos;point_list_input];
    list_size = size(point_list,1);
    dista = ga_compute_distance_matrix(point_list);
    pop_size_max = pop_size + mutation_rate + 2*crossing_rate;
    pop = ga_initialisation(point_list, pop_size, pop_size_max, dista);
       
    % Genetic Algorithm Loop
    for i=1:iter_number
        pop = ga_mutation  (pop, list_size, pop_size, mutation_rate);
        pop = ga_crossing  (pop, list_size, pop_size, mutation_rate, crossing_rate);
        pop = ga_sort_paths(pop, list_size, pop_size_max, dista, speed_straight);
    end
    
    optimal_path = zeros(list_size, 1);
    for i=1:list_size
        optimal_path(i,1) = pop(1,i)-1;
    end
    
    point_list_output = point_list_input;
    for i=1:list_size-1
        point_list_output(i,:) = point_list_input(optimal_path(i+1),:);
    end
end
