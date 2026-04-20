import pygame
from dataclasses import dataclass
import block


@dataclass
class Keys:
    jump: str
    left: str
    right: str

    def __post_init__(self):
        self.jump = pygame.key.key_code(self.jump)
        self.left = pygame.key.key_code(self.left)
        self.right = pygame.key.key_code(self.right)


class Player:
    def __init__(self, color="#FFFFFF", spawn=[100,100], keys=None,settings=None, player_nr=0):
        self.color = color
        self.spawn = spawn 
        self.settings = settings
        self.size = self.settings.tile_size if self.settings else 32
        self.rect = pygame.Rect(spawn[0], spawn[1], self.size, self.size)
        self.x = float(spawn[0])
        self.y = float(spawn[1])
        self.grounded = True
        self.velocity_y = 0.0
        self.player_nr = player_nr
        self.keys = keys if keys else Keys(  # if no keys have been selected, use the standard ones
            jump="space",                  # could be nice to get a way to check if the loaded player is the second player
            left="a",                      # if so then use the arrow keys instead
            right="d"
        )
    
    def handle_input(self, keysPressed, blockList):
        dx = 0.0
        speed = self.settings.speed if self.settings else 1
        #if moving right set delta x to the amount of pixels the player moved to the right
        if keysPressed[self.keys.right]:
            dx += speed 
        #if moving left set delta x to the amount of pixels the player moved to the left
        if keysPressed[self.keys.left]:
            dx -= speed 
        #if the player is grounded and performs a jump give delta y in terms of a velocity to mimic gravity
        if keysPressed[self.keys.jump] and self.grounded == True:
            jump_height = self.settings.jump_height if self.settings else speed * 2
            self.velocity_y = -jump_height

        self.move(dx, self.velocity_y, blockList)
        self.apply_gravity()

    def apply_gravity(self):

        gravity = self.settings.gravity if self.settings else 1
        self.velocity_y += gravity 

    def move(self, dx, dy, blockList):
        self.grounded = False

        self.x += dx
        self.rect.x = int(self.x)

        for block in blockList:
            if block.block_type == "solid":

                if self.rect.colliderect(block.rect):
                    #if the the player was moving right snap the player out to the left of the block
                    if dx > 0:
                        self.rect.right = block.rect.left
                    #if the the player was moving left snap the player out to the right of the block
                    elif dx < 0:
                        self.rect.left = block.rect.right

                    self.x = float(self.rect.x)
                    if self.settings.block_erase_mode:
                        block.start_block_timer()

        self.y += dy
        self.rect.y = int(self.y)

        for block in blockList:
            if block.block_type == "solid":
        
                if self.rect.colliderect(block.rect):
                    #if the the player was moving down snap the player out to the on top of the block and give status grounded
                    #grounded allows the player to perfom a jump again
                    if dy > 0:
                        self.rect.bottom = block.rect.top
                        self.grounded = True
                        if self.settings.block_erase_mode:
                            block.start_block_timer()

                    #if the the player was moving up snap the player out on the bottom of the block
                    elif dy < 0:
                        self.rect.top = block.rect.bottom

                    self.y = float(self.rect.y)
                    #once done falling set velocity to 0
                    self.velocity_y = 0

        for block in blockList:
            if block.block_type in ("lose", "win") and self.rect.colliderect(block.rect):
                self.reset_to_spawn()
                return

        max_x = self.settings.map_width * self.settings.tile_size
        max_y = self.settings.map_height * self.settings.tile_size
        self.rect.left = max(self.rect.left, 0)
        self.rect.right = min(self.rect.right, max_x)
        self.rect.top = max(self.rect.top, 0)
        self.rect.bottom = min(self.rect.bottom, max_y)

        if self.rect.bottom >= max_y:
            self.grounded = True
            self.velocity_y = 0

        if self.rect.top <= 0 and self.velocity_y < 0:
            self.velocity_y = 0

        self.x = float(self.rect.x)
        self.y = float(self.rect.y)    

    def reset_to_spawn(self):
        self.x = float(self.spawn[0])
        self.y = float(self.spawn[1])
        self.rect.x = self.spawn[0]
        self.rect.y = self.spawn[1]
        self.velocity_y = 0.0
        self.grounded = False

    def draw(self, screen):
        try:
            img = pygame.image.load(f"pygame/assets/player{self.player_nr}.png").convert_alpha()
        except:
            pygame.draw.rect(screen, self.color, self.rect, )
            return

        if img:   
            rect = img.get_rect(topleft=(self.rect.x, self.rect.y))
            screen.blit(img, rect)
        
        
