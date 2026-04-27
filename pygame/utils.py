import pygame
from player import Player, Keys
from block import Block

# Create custom keys
# the current valid_keys should work with the documentation of pygame.key.key_code -- else key.pyi has the anwsers
def create_player(jumpInput, leftInput, rightInput, spawnInput, colorInput, settingsInput, playerNumber):
    #Create custom keybinds
    custom_keys = Keys(jump=jumpInput, left=leftInput, right=rightInput)
    # Create player with all custom parameters
    player = Player(
        color=colorInput,               # Custom color (black) (Hexcode string)
        spawn=spawnInput,               # Custom spawn position [x, y]
        keys=custom_keys,               # Custom key bindings
        settings=settingsInput,
        player_nr=playerNumber
    )
    return player

def create_block(x, y, block_type, settings=None):
    return Block(
        x=x,
        y=y,
        blockType=block_type,
        settings=settings
    )

def create_level(settings, map_list):
    blockList = []
    for i, tile in enumerate(map_list):
        x = (i % settings.map_width) * settings.tile_size
        y = (i // settings.map_width) * settings.tile_size
        # pass settings so block can read asset paths
        blockList.append(create_block(x, y, tile, settings))
    return blockList
