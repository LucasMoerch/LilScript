import pygame
class Block:
    def __init__(self, x, y, blockType):
        self.X: int = x
        self.Y: int = y
        self.COLOR = 0
        self.BLOCKTYPE = 0 

        self.setup(blockType)

    def setup(self,blockType):
        if blockType == 1:
             self.BLOCKTYPE = "solid"
             self.COLOR = "#CD11D3"
        elif blockType == 2:
            self.BLOCKTYPE = "win"
            self.COLOR = "#11d314"
        elif blockType == 3:
            self.BLOCKTYPE = "lose"
            self.COLOR = "#d31111"

             

    def draw_block(self, screen):
        if self.BLOCKTYPE in ("solid", "win", "lose"):
             pygame.draw.rect(screen, self.COLOR, (self.X, self.Y, 32, 32))



    