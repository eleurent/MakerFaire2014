function[output_pop] = sort_paths(pop, list_size, pop_size_max, dista, angle, speed_straight, speed_rotation)
    
    for i=1:pop_size_max
        val = 0;
        for j=1:(list_size-2)
            val = val + speed_straight * dista(pop(i,j), pop(i,j+1)) + speed_rotation * angle(pop(i,j), pop(i,j+1),pop(i,j+2));
        end
        val = val + speed_straight * dista(pop(i,list_size-1),pop(i,list_size));
        pop(i, list_size + 1) = val;
    end;
    
    output_pop = sortrows(pop, list_size+1);
    
end