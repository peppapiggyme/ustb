classdef pulse 
%pulse   Pulse definition
%
%   See also PULSE, PHANTOM

%   authors: Alfonso Rodriguez-Molares (alfonso.r.molares@ntnu.no)
%   $Date: 2016/09/01 $

    %% public properties
    properties  (Access = public)
        center_frequency           % center frequency [Hz]
        fractional_bandwidth       % fractional bandwidth [unitless]
        phase                      % initial phase [rad]
    end
    
    
    %% constructor
    methods (Access = public)
        function h=pulse(center_frequency_in,fractional_bandwidth_in,phase_in)
            %PULSE   Constructor of PULSE class
            %
            %   Syntax:
            %   h = pulse(center_frequency,fractional_bandwidth,phase)
            %         center_frequency           % center frequency [Hz]
            %         fractional_bandwidth       % fractional bandwidth [unitless]
            %         phase                      % initial phase [rad]
            %
            %   See also BEAM, PHANTOM, PROBE
                      
            % initialization
            h.center_frequency = 0;
            h.fractional_bandwidth = 0;
            h.phase = 0;
            
            if nargin>0
               h.center_frequency=center_frequency_in;
            end
            if nargin>1
               h.fractional_bandwidth=fractional_bandwidth_in;
            end
            if nargin>2
               h.phase=phase_in;
            end            
        end
    end
    
    %% plot methods
    methods
        function figure_handle=plot(h,figure_handle_in,title_in)
          t0=linspace(-2/h.center_frequency/h.fractional_bandwidth,2/h.center_frequency/h.fractional_bandwidth,256);

          % plotting pulse
          if (nargin>1) && ~isempty(figure_handle_in)
            figure_handle=figure(figure_handle_in); hold on;
          else
            figure_handle=figure(); 
            title('Pulse'); hold on;
          end
          
          plot(t0*1e6,h.signal(t0)); grid on; axis tight;
          xlabel('time [mus]');
          set(gca,'ZDir','Reverse');
          set(gca,'fontsize',14);

          if nargin>2
            title(title_in);
          end
        end
    end
    
    %% get the signal for a given time
    methods  
        function s=signal(h,time)
            % gaussian-pulsed pulse
            s=cos(2*pi*h.center_frequency*time).*exp(-2.77*(1.1364*time*h.fractional_bandwidth*h.center_frequency).^2);  
        end
    end
end