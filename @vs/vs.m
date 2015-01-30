classdef vs < dataset
%VS    Virtual source (vs) dataset.
%
%   See also DATASET, VS.VS

%   authors: Alfonso Rodriguez-Molares (alfonsom@ntnu.no)
%   $Date: 2015/01/29 $
    
    properties (SetAccess = public)
        source       % vector containing the angles (rad)
    end
    
    properties (SetAccess = private)
        N           % number of virtual sources in the sequence        
    end
    
    %% constructor
    methods (Access = public)        
        function h = vs(name,input_format,input_c0,input_source,input_time,input_data,input_geom,input_modulation_frequency)
            %VS    Constructor of the VS class.
            %
            %   Syntax:
            %   VS(name,format,c0,source,time,data,geom,modulation_frequency) 
            %       name                    Name of the dataset
            %       format                  Format of the signal (E.signal_format.RF, default=E.signal_format.IQ)
            %       c0                      Reference speed of sound (m/s)
            %       source                  Location of virtual sources [x, y, z] (m)
            %       time                    Time vector (s)
            %       data                    Numerical data [time_samples, channels, firings, frames]
            %       geom                    Probe geometry [x, y, z] (m)
            %       modulation_frequency    Modulation frequency (Hz) - required only for IQ format
            %
            %   See also VS, DATASET
                   
            % Call superclass constructor
            h@dataset(name); 
            
            % required data
            h.format = input_format;
            h.c0 = input_c0;
            h.time = input_time;
            h.data = input_data;
            h.geom = input_geom;
            h.source = input_source;
            
            if(h.format==E.signal_format.IQ) 
                h.modulation_frequency=input_modulation_frequency;
            end
            
            % dependent data
            h.Fs = 1/mean(diff(h.time));    % sampling frequency (Hz)
            h.F=size(h.data,4);             % short for the number of frames
            h.N = size(h.source,1);         % short for the number of firing
            h.M = size(h.geom,1);           % short for the number of channels
            h.t0= h.time(1);                % initial time (s)
        end

    end

    %% image reconstruction
    methods (Access = public)        
        function elapsed_time = image_reconstruction(h,recons,implem)
            %IMAGE_RECONSTRUCTION    Method for image reconstruction of virtual source datasets
            %
            %   Syntax:
            %   IMAGE_RECONSTRUCTION(transmit_beam,receive_beam,scan,implementation)
            %       reconstruction          Class containing the reconstruction specification
            %       implementation          Enumeration specifying the algorithm 
            %
            %   See also RECONSTRUCTION, VS
             
            % default implementation
            if ~exist('implem') implem=E.implementation.mex; end
            
            % initial time -> performance test
            tic; 
            
            % precompute transmit and receive apodization
            xT=recons.scan.x*ones(1,h.N)-(recons.scan.z*ones(1,h.N)).*(ones(recons.scan.pixels,1)*h.source(:,1).'-recons.scan.x*ones(1,h.N))./(ones(recons.scan.pixels,1)*h.source(:,3).'-recons.scan.z*ones(1,h.N)); % position of equivalent receive element -> Alfonso's equation 
            valid_apodization=(xT>h.geom(1,1))&(xT<h.geom(end,1));            % check we don't get out of the aperture
            h.tx_apodization = valid_apodization.*recons.calculate_apodization(recons.transmit_beam,xT);
            xR=ones(recons.scan.pixels,1)*(h.geom(:,1).');                    % position of receive element
            h.rx_apodization = recons.calculate_apodization(recons.receive_beam,xR);
            
            % launch selected implementation
            recons.data=h.launch_implementation(recons,implem);
            
            % copy data to reconstruction
            recons.format=h.format;
            [recons.central_frequency recons.bandwidth]=tools.estimate_frequency(h.time,h.data);
                        
            % elapsed time for performance test
            elapsed_time=toc; 
        end
    end
end

