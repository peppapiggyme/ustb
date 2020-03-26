classdef progressMonitor < matlab.net.http.ProgressMonitor
    properties
        Direction matlab.net.http.MessageType
        Value uint64 % Total number of transferred bytes
        clearMsg
    end
    
    methods
        % class constructor
        function obj = progressMonitor
            obj.Interval = 1;
            obj.clearMsg = '';
        end
        
        % function that is called once transfer is complete or halted
        function done(~)
            fprintf(1, '...done!\n');
        end
    end
    
    % SET methods
    methods
        function set.Direction(obj, dir)
            obj.Direction = dir;
        end
        
        function set.Value(obj, value)
            obj.Value = value;
            obj.fprintf();
        end
    end
    
    methods
        function fprintf(obj)
            if  obj.Direction == matlab.net.http.MessageType.Response
                if isempty(obj.Max)
                    msg = sprintf('Downloaded %.1f MB', double(obj.Value)/1e6);
                else
                    msg = sprintf('Downloaded %.1f / %.1f MB', double(obj.Value)/1e6, double(obj.Max)/1e6);
                end
            else
                if isempty(obj.Max)
                    msg = sprintf('Sent %.1f MB', double(obj.Value)/1e6);
                else
                    msg = sprintf('Sent %.1f / %.1f MB', double(obj.Value)/1e6, double(obj.Max)/1e6);
                end
            end
            
            fprintf(1, strcat(obj.clearMsg, msg));
            obj.clearMsg = repmat('\b', size(msg));
        end
    end
end