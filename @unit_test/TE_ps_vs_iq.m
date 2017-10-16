function ok = TE_ps_vs_iq(h)
%PS_VS_IQ Point Spread function Diverging Waves IQ test
%   Downloads data from 'http://hirse.medisin.ntnu.no/ustb/data/ps/'
%   beamforms it and compares it with previously beamformed data (USTB v1.9)

    import uff.*;
    
    % data location
    url='http://hirse.medisin.ntnu.no/ustb/data/ps/';   % if not found data will be downloaded from here
    local_path=[ustb_path() '/data/ps/'];                              % location of example data in this computer                      
    raw_data_filename='ps_vs_iq.mat';
    beamformed_data_filename='beamformed_ps_vs_iq.mat';
    
    % check if the file is available in the local path & downloads otherwise
    tools.download(raw_data_filename, url, local_path);
    tools.download(beamformed_data_filename, url, local_path);
    
    % load data
    load([local_path raw_data_filename]);    
    load([local_path beamformed_data_filename]);    
    
    % PROBE
    prb=probe();
    prb.geometry = s.geom;
    
    % SEQUENCE 
    for n=1:length(s.source)
        seq(n)=wave();
        seq(n).probe=prb;
        seq(n).sound_speed=s.c0;
        seq(n).source.xyz=s.source(n,:);
        seq(n).delay=seq(n).source.distance/s.c0;
    end
    
    % RAW DATA
    r_data=channel_data();
    r_data.probe=prb;
    r_data.sequence=seq;
    r_data.initial_time=s.time(1);
    r_data.sampling_frequency=1/(s.time(2)-s.time(1));
    r_data.modulation_frequency=s.modulation_frequency;
    r_data.sound_speed=s.c0;
    r_data.data=s.data;
    
    % BEAMFORMER
    pipe=pipeline();
    pipe.channel_data=r_data;
    pipe.receive_apodization.window = window.boxcar;
    pipe.receive_apodization.f_number = r.f_number;
    pipe.transmit_apodization.window = window.boxcar;
    pipe.transmit_apodization.f_number = r.f_number;
    pipe.scan=linear_scan('x_axis',r.x_axis,'z_axis',r.z_axis);
        
    % use matlab implementation for DAS
    das = midprocess.das();
    das.code = code.matlab;
    
    % beamforming
    b_data=pipe.go({das postprocess.coherent_compounding});
    
    % test result
    ok=(norm(b_data.data-r.data(:))/norm(r.data(:)))<h.external_tolerance;

%     figure;
%     plot(real(b_data.data)); hold on; grid on;
%     plot(real(r.data(:)),'r--'); 
%    
%     % show
%     b_data.plot([],'Result');
%     
%     % ref
%     ref_data=beamformed_data();
%     ref_data.data=r.data;
%     ref_data.scan=linear_scan(r.x_axis,r.z_axis);
%     ref_data.plot([],'Reference');
    
end

