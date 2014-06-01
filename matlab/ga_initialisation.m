function [pop] = ga_initialisation(point_list, pop_size, pop_size_max, dista)

    pop = zeros(pop_size_max, size(point_list,1));
    
   % for i=1:list_size
   %     gen = ga_new_gen_greedy(i, list_size, point_list, dista);
   %     for j=1:list_size
   %         pop(i,j) = gen(j);
   %     end
   % end
    
    for i=1:pop_size
        gen = ga_new_gen_alea(size(point_list,1));
        for j=1:size(point_list,1)
            pop(i,j) = gen(j,1);
        end
    end
end
