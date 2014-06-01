function[gen] = ga_new_gen_alea(list_size)

    gen = (1:list_size)';
    
    for i=0:10*list_size
        alea = randi(list_size-3);
        alea = alea + 3;
        aux = gen(alea,1);
        gen(alea,1) = gen(2,1);
        gen(2,1) = aux;
    end 
    
end