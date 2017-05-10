%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  EyeTrackExample.m
%
%  Fake task to demonstrate use of scripts
%
%  Global Variables:
%    Owned:
%      bQuit - An exposed variable to allow other scripts to declare the end of
%        the task.
%       cFlag - This frame's flag character
%    External:
%
%  Required Functions:
%    Init
%    SerialInit
%    RegisterUpdate
%    Looper
%    SendMessage
%    SerialCleanup
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function EyeCal
    %These properties can be used to set the Arduino into Reflective mode and Paired Mode
    %%Reflective Mode has the Arduino reflect messages back to the sender.
%     bReflective = false;
    %%Paired Mode has the Arduino initiate communication with another Arduino.
%     bPaired = false;
    %Initiate the Serial Device and pass along the Property values.
%     SerialInit(bReflective,bPaired);
    
    try
        EYECALWin();
    catch err
      throw( err );
        return;
    end
%     SerialCleanup();
end