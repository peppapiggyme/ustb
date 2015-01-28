clear all;
close all;

%% Pixel-based image reconstruction
x_vector=linspace(-2e-3,2e-3,200);      % x vector
z_vector=linspace(38e-3,42e-3,200);   % z vector
[x z]=meshgrid(x_vector,z_vector);      % matrix of the reconstruction locations
recons=struct('x',x,'z',z);             % reconstruction structure         

%% Beam definition
transmit=struct('FN',1.75,'apodization',E.apodization_type.boxcar,'steer_angle',0*pi/180);
receive=struct('FN',1.75,'apodization',E.apodization_type.boxcar,'steer_angle',0*pi/180);
beam=struct('transmit',transmit,'receive',receive);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% image reconstruction 

% STA RF
load('./struct/ps_stai_rf.mat');
s=sta('Point scatterer (sta) RF',...
       E.signal_format.RF,...
       ps_stai.c0,...
       ps_stai.time.',...
       ps_stai.data,...
       ps_stai.geom);
[im,sig]=s.image_reconstruction(beam,recons,E.implementation.simple_matlab);   
[im,sig]=s.image_reconstruction(beam,recons,E.implementation.mex);


% STA IQ
load('./struct/ps_stai_iq.mat');
s=sta('Point scatterer (sta) IQ',...
       E.signal_format.IQ,...
       ps_stai.c0,...
       ps_stai.time.',...
       ps_stai.data,...
       ps_stai.geom,...
       ps_stai.modulation_frequency);
[im,sig]=s.image_reconstruction(beam,recons,E.implementation.simple_matlab);   
[im,sig]=s.image_reconstruction(beam,recons,E.implementation.mex);   

% CPW RF
load('./struct/ps_cpwi_rf.mat');
s=cpw('Point scatterer (cpw) RF',...
       E.signal_format.RF,...
       ps_cpwi.c0,...
       ps_cpwi.alpha,...
       ps_cpwi.time.',...
       ps_cpwi.data,...
       ps_cpwi.geom);
[im,sig]=s.image_reconstruction(beam,recons,E.implementation.simple_matlab);   
[im,sig]=s.image_reconstruction(beam,recons,E.implementation.mex);   

% CPW IQ
load('./struct/ps_cpwi_iq.mat');
s=cpw('Point scatterer (cpw) RF',...
       E.signal_format.IQ,...
       ps_cpwi.c0,...
       ps_cpwi.alpha,...
       ps_cpwi.time.',...
       ps_cpwi.data,...
       ps_cpwi.geom,...
       ps_cpwi.modulation_frequency);
[im,sig]=s.image_reconstruction(beam,recons,E.implementation.simple_matlab);   
[im,sig]=s.image_reconstruction(beam,recons,E.implementation.mex);   

% VS RF
load('./struct/ps_vsi_rf.mat');
s=vs('Point scatterer (vs) RF',...
       E.signal_format.RF,...
       ps_vsi.c0,...
       ps_vsi.vgeom,...
       ps_vsi.time.',...
       ps_vsi.data,...
       ps_vsi.geom);
[im,sig]=s.image_reconstruction(beam,recons,E.implementation.simple_matlab);   
[im,sig]=s.image_reconstruction(beam,recons,E.implementation.mex);   


% VS IQ
load('./struct/ps_vsi_iq.mat');
s=vs('Point scatterer (vs) IQ',...
       E.signal_format.IQ,...
       ps_vsi.c0,...
       ps_vsi.vgeom,...
       ps_vsi.time.',...
       ps_vsi.data,...
       ps_vsi.geom,...
       ps_vsi.modulation_frequency);
[im,sig]=s.image_reconstruction(beam,recons,E.implementation.simple_matlab);   
[im,sig]=s.image_reconstruction(beam,recons,E.implementation.mex);   

