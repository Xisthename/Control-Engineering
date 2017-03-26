function [h1,h2,t,u,e] = vm_poln1(a,N,dT,v)
% Läser in stegsvaret på vattenmodellen (nivå h1 och h2)

% DEL A: Beskrivning av de olika variablerna
% utgångsvariablerna (vektorer med n värden):
% h1: nivå (höjd) i behållaren 1, ansluten till 'A0'
% h2: nivå (höjd) i behållaren 2, ansluten till 'A1'
% t: tiden
% u: styrsignal till pumpen
% ingångsvariablerna:
% a: arduino-objekt som fås med funktionen a = arduino_com('COMxx')
% N: antal sampling
% dT: samplingstiden i sek.
% v: värden för pumpstyrningen, ska hållas konstant,[0..255]
% kp: Man multiplicer felvärdet med kp som är en konstant

% DEL B: Initialisering av in- och utgångar
pinMode(a,3,'output'); %Riktning som motorn ska snurra (om motorshield används)
% analoga ingångar för mätning av vattennivå: 'A0', 'A1'
% analog utgång för pumpstyrningen, låst till DAC1

% DEL C: Skapa och initialisera olika variablerna för att kunna spara mätresultat
% skapa vektorer för att spara mätvärden under experimentet, genom att fylla en vektor med N-nullor
h1 = zeros(1, N); %vektor med N nullor på en (1) rad som ska fyllas med mätningar av nivån i vattentank 1
h2 = zeros(1, N); %vektor med N nullor på en (1) rad som ska fyllas med mätningar av nivån i vattentank 2
u = v*ones(1, N); %vektor som visar börvärdet v, används i online-plot
t = 1:N; %vektor för tiden som en numrering av tidspunkter från 1 till N
ok=0; %används för att upptäcka för korta samplingstider
e = zeros(1, N);
d0 = 4.855;
kr = 1.24;
% DEL D: starta stegsvarsexperimentet  

  for k=1:N %slinga kommer att köras N-gångar, varje gång tar exakt Ts-sekunder
    
    start = cputime; %startar en timer för att kunna mäta tiden för en loop
    if ok <0 %testar om samplingen är för kort
        k; % sampling time too short!
        disp('samplingstiden är för lite! Öka värdet för Ts');
        return
    end
    
    h1(k)= analogRead(a,'A0'); % mät nivån i behållaren 1
    h2(k)= analogRead(a,'A1'); % mät nivån i behållaren 2 
    y2(k) = d0 * h1(k);
    e(k) = v * kr - y2(k);
    u(k) = 1 / (1 + e(k));
    u(k) = max(0, min(255, round(u(k))));
    analogWrite(a, u(k), 'DAC0');
    
    %online-plot
    plot(t,h1,'k-',t,h2,'r--',t,u,'m:',t, e);
    
 
    elapsed=cputime-start; %räknar åtgången tid i sekunder
    ok=(dT-elapsed); % sparar tidsmarginalen i ok
    
    pause(ok); %pausar resterande samplingstid

  end % -for
  
  % experimentet är färdig

% DEL E: avsluta experimentet
  analogWrite(a,0,'DAC0'); % stäng av pumpen
  % plotta en fin slutbild, 
  plot(t,h1,'k-',t,h2,'r--',t,u,'m:',t,e);
  xlabel('samples k')
  ylabel('nivån h1, h2, steg u','t','e')
  title('öppet stegsvar vattenmodel')
  legend('h1 ', 'h2 ', 'u ', 'e')

end

