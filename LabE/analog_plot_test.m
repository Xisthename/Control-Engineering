function analog_plot_test(a,N,dT)
    t = zeros(1,N);
    h = zeros(1,N);
    ok = 0;
    for i=1:N 
        start = cputime;
        if ok < 0
            i;
            disp('Varning samplingstiden är för kort!');
        end
        [h(i)] = a.analogRead('A1');
        t(i) = i;
        plot(t,h);
        elapsed = cputime-start;
        ok = dT-elapsed;
        pause(ok);
    end
end