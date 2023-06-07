    C_SS_mean_01 = sparse(AveSpatKer_Rec(C_SS_Pixel_Us,N_HC,...
        N_HCOutX,N_HCOutY,NPixX,NPixY,0,1));

    C_SS_mean_10 = sparse(AveSpatKer_Rec(C_SS_Pixel_Us,N_HC,...
        N_HCOutX,N_HCOutY,NPixX,NPixY,1,0));

    C_SS_Diff = C_SS_mean_01 - C_SS_mean_10;

figure;
axis tight manual;
filename = 'SS_Ker_diff_animation.mp4';
writerObj = VideoWriter(filename, 'MPEG-4');
writerObj.FrameRate = 2; % Set the frame rate (optional)
open(writerObj);


% Generate a sequence of plots
for ii = 1:50
    % Generate plot data
        ShowField_Rec(abs(C_SS_Diff(1760+ii,:)'),1:3200,N_HCOutX*NPixX,N_HCOutY*NPixY)
        title(sprintf('%d',ii))
    % Capture the current plot frame
    frame = getframe(gcf);
    im = frame2im(frame);
    
     % Write the frame to the video
    writeVideo(writerObj, im);
end

% Close the video writer
close(writerObj);
