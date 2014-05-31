function [point_list_output] = ga_tsp(point_list_input)
    
    pop_size = 300;
    mutation_rate = 300;
    crossing_rate = 300;
    iter_number = 300;
    speed_straight = 1;
    
    list_size = size(point_list_input,1);
    point_list = zeros((list_size+1)*2,1);
    point_list(1,1) = 50;
    point_list(2,1) = 50;

    for i=2:list_size+1
        point_list(2*i-1,1) = point_list_input(i-1,1);
        point_list(2*i  ,1) = point_list_input(i-1,2);
    end
    
    list_size = list_size + 1;
        
    dista = compute_distance_matrix(point_list,list_size);
    pop_size_max = pop_size + mutation_rate + 2*crossing_rate;
    pop = initialisation(point_list, list_size, pop_size, pop_size_max, dista);
       
    % Genetic Algorithm Loop
    
    for i=1:iter_number
        
        pop = mutation  (pop, list_size, pop_size, mutation_rate);
        pop = crossing  (pop, list_size, pop_size, mutation_rate, crossing_rate);
        pop = sort_paths(pop, list_size, pop_size_max, dista, speed_straight);

    end
    
    optimal_path = zeros(list_size, 1);
    for i=1:list_size
        optimal_path(i,1) = pop(1,i)-1;
    end
    
    point_list_output = point_list_input;
    for i=1:list_size-1
        point_list_output(i,1) = point_list_input(optimal_path(i+1));
    end
end

    
    
