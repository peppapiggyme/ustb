function [sig] = ir_simple_matlab(h,r)
%IR_SIMPLE_MATLAB    Image reconstruction implementation with simple matlab code
%
%   Syntax:
%   beamformed_signal = ir_simple_matlab(h,recons)
%       recons              RECONSTRUCTION class containing the specification of the reconstruction
%       beamformed_signal   Matrix containig the beamformed raw data 
%
%   See also RECONSTRUCTION

%   authors: Alfonso Rodriguez-Molares (alfonsom@ntnu.no)
%   $Date: 2015/01/28 $

    %% formats
    switch(h.format)
        case E.signal_format.RF 
            w0=0;
        case E.signal_format.AS
            w0=0;
        case E.signal_format.IQ
            w0=2*pi*h.modulation_frequency;
        otherwise
            error('Unknown signal format!');
    end
    
    %% beamforming
    sig=zeros(r.scan.pixels,h.frames);
    wb=waitbar(0,'CPW Beamforming');
    for f=1:h.frames
        for na=1:h.firings
            waitbar(((f-1)*h.firings+na)/h.firings/h.frames);
            Da=r.scan.z*cos(h.angle(na))+r.scan.x*sin(h.angle(na));
            for nrx=1:h.channels
                RF=sqrt((h.geom(nrx,1)-r.scan.x).^2+(h.geom(nrx,3)-r.scan.z).^2);
                delay=(Da+RF)/h.c0;
                phase_shift=exp(1i.*w0*delay); 
                sig(:,f)=sig(:,f)+phase_shift.*h.transmit_apodization(:,na).*h.receive_apodization(:,nrx).*interp1(h.time,h.data(:,nrx,na,f),delay,'linear',0);
            end
        end
    end
    close(wb);
    
end

