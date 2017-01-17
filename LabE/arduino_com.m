% Programmed by: Mathias Beckius
% Modified by: Daniel Nordahl
%
% This class defines a "communication object", to be used for communication
% with a Arduino Due. 
%
% This implementation is based upon code from:
% "Analog and Digital Input and Output Server for MATLAB",
% by Giampiero Campa,
% Copyright 2013 The MathWorks, Inc

classdef arduino_com < handle
    
    properties (SetAccess=private,GetAccess=private)
        aser        %Serial Connection
        response    %response (incoming character)
    end
    
    properties (Hidden=true)
        chks = false;  % Checks serial connection before every operation
        chkp = true;   % Checks parameters before every operation
    end
    
    methods
        
        %constructor, establishes an connection with the Arduino Due
        function a=arduino_com(comPort)
            %check number of arguments, only one argument accepted (COM port)
            if (nargin ~= 1)
                error('Wrong number of arguments!');
            end
            
            %check port
            if (~ischar(comPort))
                error('The input argument must be a string, e.g. ''COM8'' ');
            end   
            
            %check if we are already connected
            if (isa(a.aser,'serial') && isvalid(a.aser) && strcmpi(get(a.aser,'Status'),'open'))
                disp(['It looks like a board is already connected to port ' comPort ]);
                disp('Delete the object to force disconnection');
                disp('before attempting a connection to a different port.');
                return;
            end
            
            %check whether serial port is currently used by MATLAB
            if (~isempty(instrfind({'Port'},{comPort})))
                disp(['The port ' comPort ' is already used by MATLAB']);
                disp(['If you are sure that the board is connected to ' comPort]);
                disp('then delete the object, execute:');
                disp(['  delete(instrfind({''Port''},{''' comPort '''}))']);
                disp('to delete the port, disconnect the cable, reconnect it,');
                disp('and then create a new arduino object');
                error(['Port ' comPort ' already used by MATLAB']);
            end 
            
            %define serial object
            a.aser=serial(comPort,'BaudRate',115200);
            
            %open port
            try
                fopen(a.aser);
            catch ME
                disp(ME.message);
                delete(a);
                error(['Could not open port: ' comPort]);
            end
                
            %it takes several seconds before any operation could be attempted
            fprintf(1,'Attempting connection .');
            for i=1:12,
                pause(1);
                fprintf(1,'.');
            end
            fprintf(1,'\n');
                
            %flush serial buffer before sending anything
            flush(a);
                
            %send enquiry (ENQ)
            fwrite(a.aser,[5],'uchar');
            %expect answer
            a.response=fscanf(a.aser,'%s');
            %exit if there was no answer
            if isempty(a.response)
                delete(a);
                error('Connection unsuccessful, no response!');
            end
            
            %check returned value
            if (sum(double(a.response)) == 6) %Acknowledgement (ACK) ?
                disp('Connection successful!');
            else
                delete(a);
                error('Connection unsuccessful, didn''t receive acknowledgement!');
            end
            
            %set a.aser tag
            a.aser.Tag='ok';            
        end % arduino
        
        %destructor, deletes the object
        %use delete(a) or a.delete to delete the arduino object
        function delete(a)
            %if it is a serial, valid and open then close it
            if (isa(a.aser,'serial') && isvalid(a.aser) && strcmpi(get(a.aser,'Status'),'open'))
                fclose(a.aser);
            end
            %if it's an object delete it
            if (isobject(a.aser))
                delete(a.aser);
            end
        end % delete
        
        % disp, displays the object
        function disp(a)
            % disp(a) or a.disp, displays the arduino object properties
            % The first and only argument is the arduino object, there is no
            % output, but the basic information and properties of the arduino
            % object are displayed on the screen.
            % This function is called when just the name of the arduino object
            % is typed on the command line, followed by enter. The command
            % str=evalc('a.disp'), (or str=evalc('a')), can be used to capture
            % the output in the string 'str'.
            if isvalid(a),
                if isa(a.aser,'serial') && isvalid(a.aser),
                    disp(['Connected to ' a.aser.port ' port']);
                    disp(' ');
                else
                    disp('Connected to an invalid serial port');
                    disp('Please delete this object');
                    disp(' ');
                end
            else
                disp('Invalid object!');
                disp('Please clear the object and instantiate another one!');
                disp(' ');
            end
        end
        
        % serial, returns the serial port
        function str=serial(a)
            % serial(a) (or a.serial), returns the name of the serial port
            % The first and only argument is the arduino object, the output
            % is a string containing the name of the serial port to which
            % the arduino board is connected (e.g. 'COM9', 'DEMO', or
            % '/dev/ttyS101'). The string 'Invalid' is returned if
            % the serial port is invalid
            if isvalid(a.aser),
                str=a.aser.port;
            else
                str='Invalid';
            end
            
        end  % serial
        
        % flush, clears the pc's serial port buffer
        function val=flush(a)
            % val=flush(a) (or val=a.flush) reads all the bytes available 
            % (if any) in the computer's serial port buffer, therefore 
            % clearing said buffer.
            % The first and only argument is the arduino object, the 
            % output is a vector of bytes that were still in the buffer.
            % The value '-1' is returned if the buffer was already empty.
            val=-1;
            if a.aser.BytesAvailable>0,
                val=fread(a.aser,a.aser.BytesAvailable);
            end
        end  % flush
        
        %%PLACE FUNCTIONS HERE!!!
        
        function pinMode(a,pin,str)
            %Set pin as output or input on when calling this function pin
            %number and direction is needed as arguments.
            %Example: 
            %a.pinMode(11,'OUTPUT'); Sets pin 11 on Arduino Due as output
            %a.pinMode(25,'INPUT'); Sets pin 25 on Arduino Due as input
            
            %check arguments
            if(nargin<3)
                error('Wrong number of arguments, this function should have two arguments pin and direction.');
            end
            
            %check pin
            if( pin >= 0 && pin <= 53)
                %valid
            else
                error('Not a vaild pin, valid pins are 0 to 53.')
            end
            
            if(lower(str(1)) == 'o' || lower(str(1)) == 'i' )
                %valid
            else
                error('Pin must be defined as INPUT or OUTPUT.');
            end
            
            if(lower(str(1)) == 'o')
                dir = 1;
            else
                dir = 0;
            end
            
            fwrite(a.aser,[86 pin dir+10],'uchar');
            
        end
        
        function digitalWrite(a,pin,level)
            %Set pin level, make sure pin in set as output before calling 
            %this function
            %Example: 
            %a.digitalWrite(11,1) Set logic level on pin 11 as high
            %a.digitalWrite(11,0) Set logic level on pin 11 as low
            
            %check arguments
            if(nargin~=3)
                error('Wrong number of arguments, this function should have two arguments pin and level.');
            end
            
            %check pin
            if( pin >= 0 && pin <= 53)
                %valid
            else
                error('Not a vaild pin, valid pins are 0 to 53.')
            end
            
            %validate arguments
            if(level == 1 || level == 0)
                %valid
            else
                error('Invalid level argument, level should be 1 or 0.');
            end
            
            fwrite(a.aser,[87 pin level+10],'uchar');
            
            
        end
        
        function [val]=digitalRead(a,pin)
            % Reads and return the status of a pin. Prior to 
            % calling this function pin must be set as input.
            % Example:
            % val=a.digitalRead(4); Reads pin 4 on the Arduino Due
            
             %check arguments
            if(nargin~=2)
                error('Wrong number of arguments, this function should have two arguments pin and level.');
            end
            
             %check pin
            if( pin >= 0 && pin <= 53)
                %valid
            else
                error('Not a valid pin, valid pins are 0 to 53.')
            end
            
            fwrite(a.aser,[88 pin],'uchar');
            
            val = fscanf(a.aser,'%d');
        end
        
        function analogWrite(a,val,pin)
            % Set the pwm duty cycle and thus the speed of the motor
            % pin argument is currenlty not used because the pwm output
            % is locked to the DAC1 pin.
            
            if(nargin~=3)
                error('Wrong number of arguments, this function should have one argument pwm duty cycle');
            end
            
            %check pwm duty cycle
            if( val < 0 || val > 255)
                error('Invalid duty cycle. Pwm resolution is 8-bits. Set duty between 0-255');
            end
            if strcmp(pin,'DAC1');
                fwrite(a.aser,[89 val],'uchar');
            elseif strcmp(pin,'DAC0');
                fwrite(a.aser,[91 val],'uchar');
            end
        end
        
        function [value] = analogRead(a,pin)
            % Reads value on analog pin, pins avalible are A0,A1,A2
            % Example:
            % analog = a.analogRead('A=0');
            
            %check arguments
            if(nargin~=2)
                error('Wrong number of arguments, this function should have one argument analog pin');
            end
            
            pin = lower(pin);
          
            if strcmp(pin,'a0')
                channel = 7;
            elseif strcmp(pin,'a1')
                channel = 6;
            elseif strcmp(pin,'a2')
                channel = 5;
            else
                error('wrong pin avalible pins are A0,A1 or A2');
            end
                    
                    
            
            fwrite(a.aser,[90 channel],'uchar');
            
            value = fscanf(a.aser,'%d');
           
        end
        
    end % methods
    
    methods (Static) % static methods
        
        function errstr=checknum(num,description,allowed)
            
            % errstr=arduino.checknum(num,description,allowed); Checks numeric argument.
            % This function checks the first argument, num, described in the string
            % given as a second argument, to make sure that it is real, scalar,
            % and that it is equal to one of the entries of the vector of allowed
            % values given as a third argument. If the check is successful then the
            % returned argument is empty, otherwise it is a string specifying
            % the type of error.
            
            % initialize error string
            errstr=[];
            
            % check num for type
            if ~isnumeric(num),
                errstr=['The ' description ' must be numeric'];
                return
            end
            
            % check num for size
            if numel(num)~=1,
                errstr=['The ' description ' must be a scalar'];
                return
            end
            
            % check num for realness
            if ~isreal(num),
                errstr=['The ' description ' must be a real value'];
                return
            end
            
            % check num against allowed values
            if ~any(allowed==num),
                
                % form right error string
                if numel(allowed)==1,
                    errstr=['Unallowed value for ' description ', the value must be exactly ' num2str(allowed(1))];
                elseif numel(allowed)==2,
                    errstr=['Unallowed value for ' description ', the value must be either ' num2str(allowed(1)) ' or ' num2str(allowed(2))];
                elseif max(diff(allowed))==1,
                    errstr=['Unallowed value for ' description ', the value must be an integer going from ' num2str(allowed(1)) ' to ' num2str(allowed(end))];
                else
                    errstr=['Unallowed value for ' description ', the value must be one of the following: ' mat2str(allowed)];
                end
                
            end
            
        end % checknum
        
        function errstr=checkstr(str,description,allowed)
            
            % errstr=arduino.checkstr(str,description,allowed); Checks string argument.
            % This function checks the first argument, str, described in the string
            % given as a second argument, to make sure that it is a string, and that
            % its first character is equal to one of the entries in the cell of
            % allowed characters given as a third argument. If the check is successful
            % then the returned argument is empty, otherwise it is a string specifying
            % the type of error.
            
            % initialize error string
            errstr=[];
            
            % check string for type
            if ~ischar(str),
                errstr=['The ' description ' argument must be a string'];
                return
            end
            
            % check string for size
            if numel(str)<1,
                errstr=['The ' description ' argument cannot be empty'];
                return
            end
            
            % check str against allowed values
            if ~any(strcmpi(str,allowed)),
                
                % make sure this is a hozizontal vector
                allowed=allowed(:)';
                
                % add a comma at the end of each value
                for i=1:length(allowed)-1,
                    allowed{i}=['''' allowed{i} ''', '];
                end
                
                % form error string
                errstr=['Unallowed value for ' description ', the value must be either: ' allowed{1:end-1} 'or ''' allowed{end} ''''];
                return
            end
            
        end % checkstr
        
        function errstr=checkser(ser,chk)
            
            % errstr=arduino.checkser(ser,chk); Checks serial connection argument.
            % This function checks the first argument, ser, to make sure that either:
            % 1) it is a valid serial connection (if the second argument is 'valid')
            % 3) it is open (if the second argument is 'open')
            % If the check is successful then the returned argument is empty,
            % otherwise it is a string specifying the type of error.
            
            % initialize error string
            errstr=[];
            
            % check serial connection
            switch lower(chk),
                
                case 'valid',
                    
                    % make sure is valid
                    if ~isvalid(ser),
                        disp('Serial connection invalid, please recreate the object to reconnect to a serial port.');
                        errstr='Serial connection invalid';
                        return
                    end
                    
                case 'open',
                    
                    % check openness
                    if ~strcmpi(get(ser,'Status'),'open'),
                        disp('Serial connection not opened, please recreate the object to reconnect to a serial port.');
                        errstr='Serial connection not opened';
                        return
                    end
                    
                    
                otherwise
                    
                    % complain
                    error('second argument must be either ''valid'' or ''open''');
                    
            end
            
        end % chackser
        
    end % static methods
    
end % class def