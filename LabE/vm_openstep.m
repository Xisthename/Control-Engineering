function [h1,h2,t,u] = vm_openstep(a,N,dT,v)
% L�ser in stegsvaret p� vattenmodellen (niv� h1 och h2)

% DEL A: Beskrivning av de olika variablerna
% utg�ngsvariablerna (vektorer med n v�rden):
% h1: niv� (h�jd) i beh�llaren 1, ansluten till 'A0'
% h2: niv� (h�jd) i beh�llaren 2, ansluten till 'A1'
% t: tiden
% u: styrsignal till pumpen
% ing�ngsvariablerna:
% a: arduino-objekt som f�s med funktionen a = arduino_com('COMxx') 275 +
% 340
% N: antal sampling
% dT: samplingstiden i sek.
% v: v�rden f�r pumpstyrningen, ska h�llas konstant,[0..255]

% DEL B: Initialisering av in- och utg�ngar
pinMode(a,3,'output'); %Riktning som motorn ska snurra (om motorshield anv�nds)
analogRead(a,'A0'); % m�t niv�n i beh�llaren 1
analogRead(a,'A1'); % m�t niv�n i beh�llaren 2
% analoga ing�ngar f�r m�tning av vattenniv�: 'A0', 'A1'
% analog utg�ng f�r pumpstyrningen, l�st till DAC1

% DEL C: Skapa och initialisera olika variablerna f�r att kunna spara m�tresultat
% skapa vektorer f�r att spara m�tv�rden under experimentet, genom att fylla en vektor med N-nullor
h1 = zeros(1, N); %vektor med N nullor p� en (1) rad som ska fyllas med m�tningar av niv�n i vattentank 1
h2 = zeros(1, N); %vektor med N nullor p� en (1) rad som ska fyllas med m�tningar av niv�n i vattentank 2
u = v*ones(1, N); %vektor som visar b�rv�rdet v, anv�nds i online-plot
t = 1:N; %vektor f�r tiden som en numrering av tidspunkter fr�n 1 till N
ok=0; %anv�nds f�r att uppt�cka f�r korta samplingstider

% DEL D: starta stegsvarsexperimentet
  analogWrite(a,v,'DAC0'); %starta pumpen med stegsvarsv�rdet, D/A-utg�ng 'DAC0'
  
  for k=1:N %slinga kommer att k�ras N-g�ngar, varje g�ng tar exakt Ts-sekunder
    
    start = cputime; %startar en timer f�r att kunna m�ta tiden f�r en loop
    if ok <0 %testar om samplingen �r f�r kort
        k % sampling time too short!
        disp('samplingstiden �r f�r lite! �ka v�rdet f�r Ts');
        return
    end
    
    h1(k)= analogRead(a,'A0'); % m�t niv�n i beh�llaren 1
    h2(k)= analogRead(a,'A1'); % m�t niv�n i beh�llaren 2
    %online-plot
    
    plot(t,h1,'k-',t,h2,'r--',t,u,'m:');
    
    
    elapsed=cputime-start; %r�knar �tg�ngen tid i sekunder
    ok=(dT-elapsed); % sparar tidsmarginalen i ok
    
    pause(ok); %pausar resterande samplingstid

  end % -for
  
  % experimentet �r f�rdig

% DEL E: avsluta experimentet
  analogWrite(a,0,'DAC0'); % st�ng av pumpen
  % plotta en fin slutbild, 
  plot(t,h1,'k-',t,h2,'r--',t,u,'m:');
  xlabel('samples k')
  ylabel('niv�n h1, h2, steg u')
  title('�ppet stegsvar vattenmodel')
  legend('h1 ', 'h2 ', 'u ')

end

