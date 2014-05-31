function[output_pop] = crossing(pop, list_size, pop_size, mutation_rate, crossing_rate)

    output_pop = pop;
    
    for n = 1:crossing_rate
            
        parent1 = randi(pop_size);
        parent2 = randi(pop_size);
        gen_1 = zeros(list_size,1);
        gen_2 = zeros(list_size,1);
        cut = randi(list_size);
        
        for i=1:cut
                
            gen_1(i,1) = pop(parent1,i);
            gen_2(i,1) = pop(parent2,i);
            
        end
                
        aux_1 = 1;
        aux_2 = 1;
        i = cut + 1;
            
        while i <= list_size
            
            while((aux_2 < i) && (pop(parent2,aux_1) ~= gen_1(aux_2,1)))
                aux_2 = aux_2 + 1;
            end
            
            if(aux_2 == i)
                gen_1(i,1) = pop(parent2,aux_1);
                i = i + 1;
                aux_2 = 1;
            else
                aux_1 = aux_1 + 1;
                aux_2 = 1;
            end
            
        end
        
        aux_1 = 1;
        aux_2 = 1;
        i = cut + 1;
        
        while i <= list_size
            
            while((aux_2 < i) && (pop(parent1,aux_1) ~= gen_2(aux_2,1)))
                aux_2 = aux_2 + 1;
            end
            
            if(aux_2 == i)
                gen_2(i,1) = pop(parent1,aux_1);
                i = i + 1;
                aux_2 = 1;
            else
                aux_1 = aux_1 + 1;
                aux_2 = 1;
            end
            
        end
        
        for l=1:list_size
            output_pop(pop_size + mutation_rate + 2*n-1, l) = gen_1(l,1);
            output_pop(pop_size + mutation_rate + 2*n,   l) = gen_2(l,1);
        end
    end
end