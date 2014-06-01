function[output_pop] = ga_mutation(input_pop, list_size, pop_size, mutation_rate)
        
        output_pop = input_pop;
        
        for k=1:mutation_rate
            
            ind = randi(pop_size);
            
            for l=1:list_size
                output_pop(pop_size + k, l) = output_pop(ind, l);
            end
            
            a = randi(list_size - 1) + 1;
            b = randi(list_size - 1) + 1;
            mini = min(a,b);
            maxi = max(a,b);

            for i=2:(maxi-mini)/2
                temp = output_pop(pop_size + k, mini + i);
                output_pop(pop_size + k, mini + i) = output_pop(pop_size + k, maxi - i);
                output_pop(pop_size + k, maxi - i) = temp;
            end   
        end
end