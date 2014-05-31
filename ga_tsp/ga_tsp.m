function [optimal_path, comput_time] = ga_tsp(point_list_input, pop_size, mutation_rate, crossing_rate, iter_number, speed_straight, speed_rotation)
    
    list_size = size(point_list_input,1);
    point_list = zeros((list_size+1)*2,1);
    point_list(1,1) = 50;
    point_list(2,1) = 50;
    value = zeros(iter_number,1);

    for i=2:list_size+1
        point_list(2*i-1,1) = point_list_input(i-1,1);
        point_list(2*i  ,1) = point_list_input(i-1,2);
    end
    
    list_size = list_size + 1;
    for j=1:2*list_size
        point_list(j)
    end
    
    value
    
    dista = compute_distance_matrix(point_list,list_size);
    dista
    angle = compute_angle_matrix(point_list,list_size);
    pop_size_max = pop_size + mutation_rate + 2*crossing_rate;
    pop = initialisation(point_list, list_size, pop_size, pop_size_max, dista);
       
    % Genetic Algorithm Loop
    
    for i=1:iter_number
        
        pop = mutation  (pop, list_size, pop_size, mutation_rate);
        pop = crossing  (pop, list_size, pop_size, mutation_rate, crossing_rate);
        pop = sort_paths(pop, list_size, pop_size_max, dista, angle, speed_straight, speed_rotation);
        value(i,1) = pop(1,list_size + 1);
    end
    
    optimal_path = zeros(list_size, 1);
    for i=1:list_size
        optimal_path(i,1) = pop(1,i)-1;
    end
    
    comput_time = 0;
    plot(value);
end

    
    
