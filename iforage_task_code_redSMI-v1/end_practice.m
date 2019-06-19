function [] = end_practice(window, screenYpixels)
%%% displays instructions for the end of practice

Screen('TextStyle', window, 1);
Screen('TextSize', window, 20);
instructions = ...
    sprintf(['Well done! \n'...
    'From now on, the animals will be hiding in 2\n'...
    'different worlds.\n\n'...
    'They have different favourite hiding places in the different worlds\n\n'...
    'It will help you complete your task if you learn where they like to hide.\n\n'...
    'Press any key to start the task. Good luck!']);
DrawFormattedText(window, instructions,'Center', screenYpixels*.3, [255 255 255]);
Screen('Flip', window);
end