import pygame
from dataclasses import dataclass


@dataclass
class Keys:
    def __init__(self, jump, left, right):
        self.JUMP = pygame.key.key_code(jump)
        self.LEFT = pygame.key.key_code(left)
        self.RIGHT = pygame.key.key_code(right)


class Player:
    def __init__(self, color="#FFF", spawn=None, keys=None):
        self.COLOR = color
        self.SPAWN = spawn if spawn is not None else []
        
        self.KEYS = keys if keys else Keys(  # if no keys have been selected, use the standard ones
            JUMP=pygame.K_SPACE,            # could be nice to get a way to check if the loaded player is the second player
            LEFT=pygame.K_a,                # if so then use the arrow keys instead
            RIGHT=pygame.K_d
        )