import pygame
from player import Player, Keys
from settings import Settings
# Create custom keys
# the current valid_keys should work with the documentation of pygame.key.key_code -- else key.pyi has the anwsers

def create_player(jumpInput, leftInput, rightInput, spawnInput, colorInput, settingsInput=None):

    #Create custom keybinds
    custom_keys = Keys(jump=jumpInput, left=leftInput, right=rightInput)
    # Create player with all custom parameters
    player = Player(
        color= colorInput,               # Custom color (black) (Hexcode string)
        spawn= spawnInput,               # Custom spawn position [x, y]
        keys= custom_keys,               # Custom key bindings
        settings= settingsInput
    )
    return player


def create_settings(jumpHeightInput, gravityInput, timeInput, tickSpeedInput):
    #create custom settings
    settings = Settings(
        jumpHeight = jumpHeightInput,     #Custom jump height (float)
        gravity = gravityInput,           #Custom gravity const (float)
        time = timeInput,                 #Custom time count (int)
        tickSpeed = tickSpeedInput        #Custom tickspeed (FPS) - (float)
    )
    return settings

