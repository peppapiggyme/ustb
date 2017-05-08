% Example of beamformer definition using Synthetic Transmit Aperture 
% simulation with USTB built-in Fresnel simulator

%   authors: Alfonso Rodriguez-Molares (alfonso.r.molares@ntnu.no)
%   $Date: 2017/03/11$

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
N=128;                      % number of waves
seq=uff.wave();
for n=1:N 
    seq(n)=uff.wave();
    seq(n).probe=prb;
    seq(n).source.xyz=[prb.x(n) prb.y(n) prb.z(n)];
    
    seq(n).apodization.window=uff.window.sta;
    seq(n).apodization.apex=seq(n).source;
    
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
sca=uff.linear_scan(linspace(-2e-3,2e-3,200).', linspace(39e-3,41e-3,100).');
sca.plot(fig_handle,'Scenario');    % show mesh
 
%% PARENT BEAMFORMER
bmf_parent=beamformer();
% input
bmf_parent.channel_data=channel_data;
bmf_parent.scan=sca;
bmf_parent.receive_apodization.window=uff.window.tukey50;
bmf_parent.receive_apodization.f_number=1.7;
bmf_parent.receive_apodization.apex.distance=Inf;
bmf_parent.transmit_apodization.window=uff.window.tukey50;
bmf_parent.transmit_apodization.f_number=1.7;
bmf_parent.transmit_apodization.apex.distance=Inf;

% beamforming
b_data_parent=bmf_parent.go({process.das_matlab() process.coherent_compounding()});

% show
b_data_parent.plot();

%% CHILD BEAMFORMER WITH STANDALONE CODE
bmf_child=beamformer.das_cc_standalone();
% input
bmf_child.channel_data=channel_data;
bmf_child.scan=sca;
bmf_child.receive_apodization.window=uff.window.tukey50;
bmf_child.receive_apodization.f_number=1.7;
bmf_child.receive_apodization.apex.distance=Inf;
bmf_child.transmit_apodization.window=uff.window.tukey50;
bmf_child.transmit_apodization.f_number=1.7;
bmf_child.transmit_apodization.apex.distance=Inf;

% beamforming
b_data_child=bmf_child.go();

% show
b_data_child.plot();

%% CHILD BEAMFORMER WITH PROCESSES
bmf_child=beamformer.das_cc_processes();
% input
bmf_child.channel_data=channel_data;
bmf_child.scan=sca;
bmf_child.receive_apodization.window=uff.window.tukey50;
bmf_child.receive_apodization.f_number=1.7;
bmf_child.receive_apodization.apex.distance=Inf;
bmf_child.transmit_apodization.window=uff.window.tukey50;
bmf_child.transmit_apodization.f_number=1.7;
bmf_child.transmit_apodization.apex.distance=Inf;

% beamforming
b_data_child=bmf_child.go();

% show
b_data_child.plot();