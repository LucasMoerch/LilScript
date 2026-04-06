import pygame
from dataclasses import dataclass


@dataclass
class Keys:
    def __init__(self, jump, left, right):
        self.JUMP = pygame.key.key_code(jump)
        self.LEFT = pygame.key.key_code(left)
        self.RIGHT = pygame.key.key_code(right)


class Player:
    def __init__(self, color="#FFFFFF", spawn=[100,100], keys=None,settings=None):
        self.COLOR = color
        self.SPAWN = spawn 
        self.SETTINGS = settings
        self.SIZE = self.SETTINGS.TILE_SIZE if self.SETTINGS else 32
        self.rect = pygame.Rect(spawn[0], spawn[1], self.SIZE, self.SIZE)
        self.x = float(spawn[0])
        self.y = float(spawn[1])
        self.grounded = True
        self.velocity_y = 0.0
        self.KEYS = keys if keys else Keys(  # if no keys have been selected, use the standard ones
            jump="space",                  # could be nice to get a way to check if the loaded player is the second player
            left="a",                      # if so then use the arrow keys instead
            right="d"
        )
    
    def handle_input(self, keysPressed, blockList):
        dx = 0.0
        speed = self.SETTINGS.SPEED if self.SETTINGS else 1
        #if moving right set delta x to the amount of pixels the player moved to the right
        if keysPressed[self.KEYS.RIGHT]:
            dx += speed 
        #if moving left set delta x to the amount of pixels the player moved to the left
        if keysPressed[self.KEYS.LEFT]:
            dx -= speed 
        #if the player is grounded and performs a jump give delta y in terms of a velocity to mimic gravity
        if keysPressed[self.KEYS.JUMP] and self.grounded == True:
            jump_height = self.SETTINGS.JUMP_HEIGHT if self.SETTINGS else speed * 2
            self.velocity_y = -jump_height

        self.move(dx, self.velocity_y, blockList)
        self.apply_gravity()


    def apply_gravity(self):

        gravity = self.SETTINGS.GRAVITY if self.SETTINGS else 1
        self.velocity_y += gravity 

    def move(self, dx, dy, blockList):
        self.grounded = False

        self.x += dx
        self.rect.x = int(self.x)
        for block in blockList:
            if block.BLOCKTYPE != "solid":
                continue
            if self.rect.colliderect(block.rect):
                #if the the player was moving right snap the player out to the left of the block
                if dx > 0:
                    self.rect.right = block.rect.left
                #if the the player was moving left snap the player out to the right of the block
                elif dx < 0:
                    self.rect.left = block.rect.right
                self.x = float(self.rect.x)

        self.y += dy
        self.rect.y = int(self.y)
        for block in blockList:
            if block.BLOCKTYPE != "solid":
                continue
            if self.rect.colliderect(block.rect):
                #if the the player was moving down snap the player out to the on top of the block and give status grounded
                #grounded allows the player to perfom a jump again
                if dy > 0:
                    self.rect.bottom = block.rect.top
                    self.grounded = True
                #if the the player was moving up snap the player out on the bottom of the block
                elif dy < 0:
                    self.rect.top = block.rect.bottom
                self.y = float(self.rect.y)
                #once done falling set velocity to 0
                self.velocity_y = 0


    def draw(self, screen):
        pygame.draw.rect(screen, self.COLOR, self.rect)
