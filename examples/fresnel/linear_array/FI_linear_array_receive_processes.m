% Using receive processes with a Focused Imaging (single focal depth)
% dataset simulated with the USTB's Fresnel simulator 

%   authors: Alfonso Rodriguez-Molares (alfonso.r.molares@ntnu.no)
%   $Date: 2017/05/01$

clear all;
close all;

%% PHANTOM
pha=uff.phantom();
pha.sound_speed=1540;            % speed of sound [m/s]
pha.points=[0,  0, 40e-3, 1];    % point scatterer position [m]
fig_handle=pha.plot();             
             
%% PROBE
prb=uff.linear_array();
prb.N=128;                  % number of elements 
prb.pitch=300e-6;           % probe pitch in azimuth [m]
prb.element_width=270e-6;   % element width [m]
prb.element_height=5000e-6; % element height [m]
prb.plot(fig_handle);

%% PULSE
pul=uff.pulse();
pul.center_frequency=5.2e6;       % transducer frequency [MHz]
pul.fractional_bandwidth=0.6;     % fractional bandwidth [unitless]
pul.plot([],'2-way pulse');

%% SEQUENCE GENERATION
N=200;                      % number of focused beams
x_axis=linspace(-2e-3,2e-3,N).';
z0=40e-3;
seq=uff.wave();
for n=1:N 
    seq(n)=uff.wave();
    seq(n).probe=prb;
    seq(n).source.xyz=[x_axis(n) 0 z0];
    
    seq(n).apodization.window=uff.window.tukey50;
    seq(n).apodization.f_number=1.7;
    seq(n).apodization.apex.distance=Inf;
    seq(n).apodization.scan.xyz=seq(n).source.xyz;
    
    seq(n).sound_speed=pha.sound_speed;
    
    % show source
    fig_handle=seq(n).source.plot(fig_handle);
end

%% SIMULATOR
sim=fresnel();

% setting input data 
sim.phantom=pha;                % phantom
sim.pulse=pul;                  % transmitted pulse
sim.probe=prb;                  % probe
sim.sequence=seq;               % beam sequence
sim.sampling_frequency=41.6e6;  % sampling frequency [Hz]

% we launch the simulation
channel_data=sim.go();
 
%% SCAN
z_axis=linspace(39e-3,41e-3,100).';
sca=uff.linear_scan();
for n=1:length(x_axis)
    sca(n)=uff.linear_scan(x_axis(n),z_axis);
    sca(n).plot(fig_handle,'Scenario');    
end
 
%% BEAMFORMER
bmf=beamformer();
bmf.channel_data=channel_data;
bmf.scan=sca;
bmf.receive_apodization.window=uff.window.tukey50;
bmf.receive_apodization.f_number=1.7;
bmf.receive_apodization.apex.distance=Inf;

% beamforming
b_data=bmf.go({process.delay_matlab() process.stack()});

%% PROCESSES
% coherently compounded
cc=process.coherent_compounding();
cc.beamformed_data=b_data;
cc_data=cc.go();
cc_data.plot([],cc.name);

% incoherently compounded
ic=process.incoherent_compounding();
ic.beamformed_data=b_data;
ic_data=ic.go();
ic_data.plot([],ic.name);

% max
mv=process.max();
mv.beamformed_data=b_data;
mv_data=mv.go();
mv_data.plot([],mv.name);

% Mallart-Fink coherence factor
cf=process.coherence_factor();
cf.channel_data=bmf.channel_data;
cf.transmit_apodization=bmf.transmit_apodization;
cf.receive_apodization=bmf.receive_apodization;
cf.beamformed_data=b_data;
cf_data=cf.go();
cf.CF.plot([],'Mallart-Fink Coherence factor',60,'none'); % show the coherence factor
cf_data.plot([],cf.name);

% Camacho-Fritsch phase coherence factor
pcf=process.phase_coherence_factor();
pcf.channel_data=bmf.channel_data;
pcf.transmit_apodization=bmf.transmit_apodization;
pcf.receive_apodization=bmf.receive_apodization;
pcf.beamformed_data=b_data;
pcf_data=pcf.go();
pcf.PCF.plot([],'Camacho-Fritsch Phase coherence factor',60,'none'); % show the phase coherence factor
pcf_data.plot([],pcf.name);
