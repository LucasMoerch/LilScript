import pygame
class Block:
    def __init__(self, x, y, blockType):
        self.rect = pygame.Rect(x, y, 32, 32)
        self.x: int = x
        self.y: int = y
        self.color = 0
        self.block_type = 0

        self.setup(blockType)

    def setup(self,blockType):
        if blockType == 1:
             self.block_type = "solid"
             self.color = "#CD11D3"
        elif blockType == 2:
            self.block_type = "win"
            self.color = "#11d314"
        elif blockType == 3:
            self.block_type = "lose"
            self.color = "#d31111"



    def draw_block(self, screen):
        if self.block_type in ("solid", "win", "lose"):
             pygame.draw.rect(screen, self.color, (self.rect.x, self.rect.y, 32, 32))
