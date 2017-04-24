classdef stack < postprocess.postprocess
    
    methods
        function out_dataset = go(h,in_dataset)
            %STACK Stacks scanlines together to produce an image
            
            assert(isa(in_dataset(1).scan,'uff.linear_scan')||isa(in_dataset(1).scan,'uff.sector_scan'),'Stack only works with LINEAR_SCAN and SECTOR_SCAN');
            
            out_dataset=in_dataset(1);
            wb=waitbar(0,'Stacking');
            
            switch class(in_dataset(1).scan)
                case 'uff.linear_scan'
                    x_axis=in_dataset(1).scan.x(1);
                    z_axis=in_dataset(1).scan.z;
                    
                    for n=2:length(in_dataset)
                        waitbar(n/length(in_dataset),wb);
                        
                        x_axis(n)=in_dataset(n).scan.x(1);
                        out_dataset.data(:,n,:)=in_dataset(n).data;
                    end
                    out_dataset.scan=uff.linear_scan(x_axis.',z_axis);
                case 'uff.sector_scan'
                    azimuth_axis=in_dataset(1).scan.azimuth_axis(1);
                    depth_axis=in_dataset(1).scan.depth_axis;
                    
                    for n=2:length(in_dataset)
                        waitbar(n/length(in_dataset),wb);
                        
                        azimuth_axis(n)=in_dataset(n).scan.azimuth_axis(1);
                        out_dataset.data(:,n,:)=in_dataset(n).data;
                    end
                    out_dataset.scan=uff.sector_scan(azimuth_axis.',depth_axis);
            end
            close(wb); 
        end
    end
end