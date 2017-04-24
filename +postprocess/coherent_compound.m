classdef coherent_compound < postprocess.postprocess
    
    methods
        function out_dataset = go(h,in_dataset)
            %COHERENT_COMPOUND Coherently compounds beamformed datasets
            
            out_dataset=in_dataset(1);
            wb=waitbar(0,'Postprocessing');
            for n=2:length(in_dataset)
                out_dataset.data=out_dataset.data+in_dataset(n).data;
            end
            close(wb);
            
        end
    end 
end
