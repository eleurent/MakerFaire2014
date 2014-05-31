function [pop] = initialisation(point_list, list_size, pop_size, pop_size_max, dista)

    pop = zeros(pop_size_max, list_size+1);
    
   % for i=1:list_size
   %     gen = new_gen_greedy(i, list_size, point_list, dista);
   %     for j=1:list_size
   %         pop(i,j) = gen(j);
   %     end
   % end
    
    for i=1:pop_size
        gen = new_gen_alea(list_size);
        for j=1:list_size
            pop(i,j) = gen(j,1);
        end
    end
    
end
