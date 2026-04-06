import pygame
from player import Player, Keys
from settings import Settings
from block import Block
from level import mapList
# Create custom keys
# the current valid_keys should work with the documentation of pygame.key.key_code -- else key.pyi has the anwsers

def create_player(jumpInput, leftInput, rightInput, spawnInput, colorInput, settingsInput):

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


def create_settings(jumpHeightInput, gravityInput, speedInput, timeInput, tickSpeedInput):
    #create custom settings
    settings = Settings(
        jumpHeight = jumpHeightInput,     #Custom jump height (float)
        gravity = gravityInput,           #Custom gravity const (float)
        speed = speedInput,               #Custom speed const (float)
        time = timeInput,                 #Custom time count (int)
        tickSpeed = tickSpeedInput        #Custom tickspeed (FPS) - (float)
    )
    return settings

def create_block (xInput,yInput, blockTypeInput):
    block = Block(
        x = xInput,
        y = yInput,
        blockType = blockTypeInput
    )
    return block
def create_level(settings):

    i = 0
    mapWidth = 20
    yCoordinate = 1
    xCoordinate = 1
    blockList = []
    #Need to write an fail scenario if the map reaches more than 20 lines
    while i < len(mapList):
        temp_block = create_block(xCoordinate*settings.TILE_SIZE, yCoordinate*settings.TILE_SIZE,mapList[i])
        blockList.append(temp_block)
        #Line switching logic
        if (i+1) % mapWidth  == 0:
    
            yCoordinate += 1
            xCoordinate = 0
            
        xCoordinate += 1
        i += 1
    return blockList

