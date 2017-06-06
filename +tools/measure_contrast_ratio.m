function [CR] = measure_contrast_ratio(sta_image,image,xc_nonecho,zc_nonecho,r_nonecho,r_speckle_inner,r_speckle_outer,f_filename)
%% Non echo Cyst contrast

xc_speckle = xc_nonecho;
zc_speckle = zc_nonecho;

% Create masks to mask out the ROI of the cyst and the background.
for p = 1:length(sta_image.scan.z_axis)
    positions(p,:,1) = sta_image.scan.x_axis;
end

for p = 1:length(sta_image.scan.x_axis)
    positions(:,p,2) = sta_image.scan.z_axis;
end


points = ((positions(:,:,1)-xc_nonecho*10^-3).^2) + (positions(:,:,2)-zc_nonecho*10^-3).^2;
idx_cyst = (points < (r_nonecho*10^-3)^2);                     %ROI inside cyst
idx_speckle_outer =  (((positions(:,:,1)-xc_speckle*10^-3).^2) + (positions(:,:,2)-zc_speckle*10^-3).^2 < (r_speckle_outer*10^-3)^2); %ROI speckle
idx_speckle_inner =  (((positions(:,:,1)-xc_speckle*10^-3).^2) + (positions(:,:,2)-zc_speckle*10^-3).^2 < (r_speckle_inner*10^-3)^2); %ROI speckle
idx_speckle_outer(idx_speckle_inner) = 0;% & idx_speckle_inner;
idx_speckle = idx_speckle_outer;

%%

f1 = figure(1111);clf;
set(f1,'Position',[100,100,300,300]);
imagesc(sta_image.scan.x_axis*1e3,sta_image.scan.z_axis*1e3,image.all{1});
colormap gray; caxis([-60 0]); axis image; xlabel('x [mm]');ylabel('z [mm]');
title('Image indicating regions used to measure contrast');
axi = gca;
viscircles(axi,[xc_nonecho,zc_nonecho],r_nonecho,'EdgeColor','r');
viscircles(axi,[xc_nonecho,zc_nonecho],r_speckle_inner,'EdgeColor','y');
viscircles(axi,[xc_nonecho,zc_nonecho],r_speckle_outer,'EdgeColor','y');

if nargin == 8
    saveas(f1,f_filename,'eps2c');
end

for i = 1:length(image.all)
    CR(i) = abs(mean(image.all{i}(idx_cyst))-mean(image.all{i}(idx_speckle)));
end

end

