import pygame
from player import Player, Keys
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



def create_block (xInput,yInput, blockTypeInput):
    block = Block(
        x = xInput,
        y = yInput,
        blockType = blockTypeInput
    )
    return block
def create_level(settings):

    i = 0
    yCoordinate = 0
    xCoordinate = 0
    blockList = []
    #Need to write an fail scenario if the map reaches more than 20 lines
    while i < len(mapList):
        temp_block = create_block(xCoordinate * settings.tile_size, yCoordinate * settings.tile_size, mapList[i])
        blockList.append(temp_block)
        #Line switching logic
        if (i+1) % settings.map_width  == 0:
    
            yCoordinate += 1
            xCoordinate = -1
            
        xCoordinate += 1
        i += 1
    return blockList

