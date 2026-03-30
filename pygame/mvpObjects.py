import pygame
from player import Player, Keys
from settings import Settings

# Create custom keys
# the current valid_keys should work with the documentation of pygame.key.key_code -- else key.pyi has the anwsers
jump = "space" #example
left = "a"     #example
right = "d"    #example
custom_keys = Keys(JUMP=jump, LEFT=left, RIGHT=right)


# Create player with all custom parameters
player = Player(
    color="#000000",      # Custom color (black) (Hexcode string)
    spawn=[200, 300],       # Custom spawn position [x, y]
    keys=custom_keys        # Custom key bindings
)
#Create the settings/game constants with custom parameters
settings = Settings(
    jumpHeight = 1,         #Custom jump height (float)
    gravity = 1,            #Custom gravity const (float)
    time = 60,              #Custom time count (int)
    tickSpeed = 60          #Custom tickspeed (FPS) - (float)
)