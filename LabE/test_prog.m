function test_prog(a)
pause on

while(1)
    a.pinMode(5,'output');
    a.digitalWrite(5,1);
    pause(0.1);
    a.digitalWrite(5,0);
    pause(0.1);
end

end