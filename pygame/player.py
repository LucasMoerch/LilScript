import pygame
from dataclasses import dataclass


@dataclass
class Keys:
    def __init__(self, jump, left, right):
        self.JUMP = pygame.key.key_code(jump)
        self.LEFT = pygame.key.key_code(left)
        self.RIGHT = pygame.key.key_code(right)


class Player:
    def __init__(self, color="#FFF", spawn=None, keys=None, settings=None):
        self.COLOR = color
        self.SPAWN = spawn if spawn is not None else [100,100]
        self.X:int = spawn[0] if spawn is not None else 100
        self.Y:float = spawn[1] if spawn is not None else 100
        self.SPEED = 4
        self.SETTINGS = settings
        self.GROUND_Y = self.Y
        self.velocity_y = 0
        self.KEYS = keys if keys else Keys(  # if no keys have been selected, use the standard ones
            jump="space",                  # could be nice to get a way to check if the loaded player is the second player
            left="a",                      # if so then use the arrow keys instead
            right="d"
        )
    
    def handle_input(self, keys):
        dx = 0

        if keys[self.KEYS.RIGHT]:
            dx += self.SPEED
        if keys[self.KEYS.LEFT]:
            dx -= self.SPEED

        if keys[self.KEYS.JUMP] and self.on_ground():#ground needs to be switched out once it can collide with a block
            jump_height = self.SETTINGS.JUMP_HEIGHT if self.SETTINGS else self.SPEED * 2
            self.velocity_y = -jump_height

        self.move(dx, self.velocity_y)
        self.apply_gravity()

    def on_ground(self):
        return self.Y >= self.GROUND_Y

    def apply_gravity(self):
        gravity = self.SETTINGS.GRAVITY if self.SETTINGS else 1
        self.velocity_y += gravity

    def move(self, dx, dy):
        self.X += dx
        self.Y += dy

        if self.Y >= self.GROUND_Y:
            self.Y = self.GROUND_Y
            self.velocity_y = 0
