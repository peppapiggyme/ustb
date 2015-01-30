classdef reconstruction < handle
%RECONSTRUCTION   Reconstruction definition
%
%   See also BEAM, SCAN
    properties  (SetAccess = public)
        name=''                     % String containing the name of the reconstruction
        creation_date=''            % String containing the date the reconstruction was created
        transmit_beam=beam()        % BEAM class defining transmit beam
        receive_beam=beam()         % BEAM class defining receive beam            
        scan=linear_scan()          % SCAN class defining the scan area
        format=E.signal_format.RF   % format of the signal
        data                        % matrix containing the reconstructed raw signal
        envelope                    % matrix containing the envelope of the reconstructed signal
        frames                      % Number of frames in the reconstruction
        central_frequency           % central frequency [Hz]
        bandwidth                   % central frequency [Hz]
    end
    
    %% constructor
    methods (Access = public)
        function h = reconstruction(name)
            %RECONSTRUCTION    Constructor of the RECONSTRUCTION class.
            %
            %   Syntax:
            %   RECONSTRUCTION(name) 
            %       name                    Name of the reconstruction
            %
            %   See also BEAM, LINEAR_SCAN
            if exist('name') 
                h.name=name;
            end
            t_now=now;
            h.creation_date=[date sprintf('-%d-%d-%d',hour(t_now),minute(t_now),round(second(t_now)))];
        end
    end
   
    %% calculate apodization
    methods (Access = public)
        function [apo]= calculate_apodization(h,beam,x0)
            %CALCULATE_APODIZATION    Calculates apodization for a given set of elements
            %
            %   Syntax:
            %   calculate_apodization(beam, elements_x_coordinate)
            %       BEAM                    Class specifying the beam
            %       elements_x_coordinate   Vector with the x coordinates of the elements
            %
            %   See also BEAM, LINEAR_SCAN
            
            % checking format
            assert(size(x0,1)==h.scan.pixels, 'The element position vector must be a column vector!');
            
            % we take the number of apodization values from x0
            number_elements=size(x0,2);
            
            % apodization computation 
            if beam.apodization==E.apodization_type.none
                apo=ones(h.scan.pixels,number_elements);
            else
                apo=zeros(h.scan.pixels,number_elements);
                Aperture=h.scan.z./beam.f_number;
                for n=1:number_elements
                    xd=abs(x0(:,n)-h.scan.x+h.scan.z*tan(beam.steer_angle));
                    switch(beam.apodization)
                        case E.apodization_type.boxcar
                            apo(:,n)=double(xd<Aperture/2); 
                        case E.apodization_type.hanning
                            apo(:,n)=double(xd<Aperture/2).*(0.5 + 0.5*cos(2*pi*xd./Aperture)); 
                        case E.apodization_type.tukey25
                            roll=0.25;
                            apo(:,n)=(xd<(Aperture/2*(1-roll))) + (xd>(Aperture/2*(1-roll))).*(xd<(Aperture/2)).*0.5.*(1+cos(2*pi/roll*(xd/Aperture-roll/2-1/2)));                               
                        case E.apodization_type.tukey50
                            roll=0.5;
                            apo(:,n)=(xd<(Aperture/2*(1-roll))) + (xd>(Aperture/2*(1-roll))).*(xd<(Aperture/2)).*0.5.*(1+cos(2*pi/roll*(xd/Aperture-roll/2-1/2)));                               
                        case E.apodization_type.tukey80
                            roll=0.8;
                            apo(:,n)=(xd<(Aperture/2*(1-roll))) + (xd>(Aperture/2*(1-roll))).*(xd<(Aperture/2)).*0.5.*(1+cos(2*pi/roll*(xd/Aperture-roll/2-1/2)));                               
                        otherwise
                            error('Unknown apodization type!');
                    end
                end
            end
            
            % implementation of edge smoothing
            if(beam.smoothing)
                n0=1:(beam.smoothing+1);                                  
                mask=(n0/(beam.smoothing+1)).^(1./beam.smoothing_order);
                for nn=n0(1):n0(end) % <--- have to think how to vectorise this
                    apo(:,nn)=apo(:,nn).*mask(nn);
                    apo(:,end-nn+1)=apo(:,end-nn+1).*mask(nn);
                end
            end
        end
    end
    
    %% presentation methods
    methods (Access = public)    
        function im=calculate_envelope(h)
            %CALCULATE_ENVELOPE    Calculates the envelope of the beamformed signal
            %
            %   Syntax:
            %   envelope_signal=calculate_envelope(data)
            %       envelope_signal         Matrix with the envelope with the same dimensions of data
            %
            %   See also RECONSTRUCTION
            
            switch(h.format)
                case E.signal_format.RF
                    dz=mean(diff(h.scan.z_axis));   % spatial step in the beam direction
                    Fs=1540/2/dz;                   % effective sampling frequency (Hz)
                    maximum_frequency=h.central_frequency+h.bandwidth;
                    ratio=Fs/maximum_frequency;
                    
                    im=zeros(size(h.data));
                    
                    if(ratio<4)
                        warning(sprintf('The spatial sampling in the beam direction does not allow to compute the Hilbert transform on pixel data. Displayed envelopes will be innacurate. To solve this issue please consider: working with demodulated signal (IQ), or increasing the sampling resolution in the beam direction by a factor of %0.2f',4/ratio));
                        for f=1:h.frames
                            super_axis=linspace(h.scan.z_axis(1),h.scan.z_axis(end),8/ratio*length(h.scan.z_axis));
                            im(:,:,f)=abs(interp1(super_axis,hilbert(interp1(h.scan.z_axis,h.data(:,:,f),super_axis)),h.scan.z_axis));
                        end                        
                    else
                        for f=1:h.frames
                            im(:,:,f)=abs(hilbert(h.data(:,:,f)));
                        end
                    end
                    
                case E.signal_format.IQ
                    im=abs(h.data);
                otherwise
                    error('Unknown signal format!');
            end
        end
        
        function im=show(h,dynamic_range)
            %SHOW    Plots the envelope of the beamformed data and returns a copy of the image
            %
            %   Syntax:
            %   image=show(dynamic_range)
            %       image           Matrix with the envelope of the normalised bemformed signal on dB
            %       dynamic_range   Desired dynamic range of the displayed images
            %
            %   See also RECONSTRUCTION
       
            if ~exist('dynamic_range') dynamic_range=60; end
            
            % computing envelope
            if isempty(h.envelope) h.envelope=h.calculate_envelope(); end
            
            % Ploting image reconstruction
            im=20*log10(h.envelope./max(h.envelope(:)));
            figure; set(gca,'fontsize',16); 
            for f=1:h.frames
                pcolor(h.scan.x_matrix*1e3,h.scan.z_matrix*1e3,im(:,:,f)); shading flat; colormap gray; caxis([-dynamic_range 0]); colorbar;
                axis equal manual;
                xlabel('x [mm]');
                ylabel('z [mm]');
                set(gca,'YDir','reverse');
                set(gca,'fontsize',16);
                axis([min(h.scan.x_axis) max(h.scan.x_axis) min(h.scan.z_axis) max(h.scan.z_axis)]*1e3);
                title(sprintf('%s (%s)',char(h.name),char(h.format))); 
                drawnow;
                pause(0.05);
            end
        end
        
        function write_video(h,filename,dynamic_range,figure_size)
            %MAKE_VIDEO    Creates and stores a video with the beamformeddataset
            %
            %   Syntax:
            %   write_video(filename,dynamic_range)
            %       filename        Path and name where the video will be written
            %       dynamic_range   Desired dynamic range of the displayed images
            %
            %   See also RECONSTRUCTION
       
            if ~exist('dynamic_range') dynamic_range=60; end
            if ~exist('figure_size') figure_size=[500 500]; end
            
            
            %% making a video -> envelope
            writerObj = VideoWriter(filename);
            open(writerObj);
            
            % computing envelope
            if isempty(h.envelope) h.envelope=h.calculate_envelope(); end
            
            im=20*log10(h.envelope./max(h.envelope(:)));
            figure; set(gca,'fontsize',16); 
            for f=1:h.frames
                pcolor(h.scan.x_matrix*1e3,h.scan.z_matrix*1e3,im(:,:,f)); shading flat; colormap gray; caxis([-dynamic_range 0]);colorbar; hold on;
                axis equal manual;
                xlabel('x [mm]');
                ylabel('z [mm]');
                set(gca,'YDir','reverse');
                set(gca,'fontsize',16);
                axis([min(h.scan.x_axis) max(h.scan.x_axis) min(h.scan.z_axis) max(h.scan.z_axis)]*1e3);
                title(sprintf('Frame %d',f)); 
                set(gcf,'Position',[200   100   figure_size(1) figure_size(2)]);
                drawnow;

                frame = getframe(gcf,[0 0 figure_size(1) figure_size(2)]);
                writeVideo(writerObj,frame);

                hold off;
            end

            close(writerObj);
            
        end
    end

    %% Set methods
    methods
        function set.data(h,input_data)
            % check that the data format matches the specification
            assert(size(input_data,1)==h.scan.pixels, 'The number of rows in the data does not match the scan specification!');
            h.frames=size(input_data,2);
            
            % reshape beamformed image
            h.data=reshape(input_data,[length(h.scan.z_axis) length(h.scan.x_axis) h.frames]);
            h.envelope=[];
        end
    end

end

