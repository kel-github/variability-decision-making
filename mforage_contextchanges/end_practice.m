function [] = end_practice(window, screenYpixels)
%%% displays instructions for the end of practice

Screen('TextStyle', window, 1);
Screen('TextSize', window, 20);
instructions = ...
    sprintf(['Well done! \n\n'...
    'From now on, the animals will be hiding in two different\n'...
    'coloured houses.\n\n'...
    'You can tell which house you are in by the colour of the border\n'...
    'The animals will be hiding in different rooms, depending on which house they are in.\n\n'...
    'You must learn these hiding places to complete the task.\n\n'...
    'Your task is to learn to find the animal within 4 moves.\n ' ...
    'You are doing the task correctly when you find the animal in 4 moves or less.\n'...
    'You will hear some tones when you have done the task well.\n'...
    'The number of tones relates to the number of moves you took to find the animal.\n'...
    'The more tones you hear, the better you did.\n'...
    '1 move = 4 tones - you aced it!\n'...
    '2 moves = 3 tones\n'...
    '3 moves = 2 tones\n'...
    '4 moves = 1 tone\n\n'...
    'No tones will play if you take more than 4 moves to find the animals :( \n\n'...
    'Remember to try and find the animal within 4 moves on every trial.\n'...
    'At first, this will be tough but will become easy once you learn their hiding places.\n\n'... 
    'Press any key to start the task. Good luck!']);
    DrawFormattedText(window, instructions,'Center', screenYpixels*.3, [0 0 255]);
    Screen('Flip', window);
end