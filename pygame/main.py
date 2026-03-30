import pygame
import utils
from level import blockList
from block import Block
pygame.init()
info = pygame.display.Info()
#screenWidth = info.current_w
#screenHeight = info.current_h 
screenWidth = 1000 #for the mvp we chose screensize of 1000x1000 pixels
screenHeight = 1000 
#20*20 tiles

#dummy inputs
jumpHeightInput = 15
gravityInput = 1.5
speedInput = 5
timeInput = 60
tickSpeedInput = 60


jumpInput = "space"
leftInput = "a"
rightInput = "d"
spawnInput = [500,500]
colorInput = "#29C878"

print("Width:", screenWidth)
print("Height:", screenHeight)
screen = pygame.display.set_mode((screenWidth, screenHeight))
clock = pygame.time.Clock()


settings = utils.create_settings(jumpHeightInput,gravityInput,speedInput,timeInput,tickSpeedInput)

player1 = utils.create_player(jumpInput,leftInput,rightInput,spawnInput,colorInput, settings)
print("player1 X:", player1.X)


running = True
while running:
    screen.fill((255, 255, 255)) #clear screen make it white
    #draws in the blocks
    for block in blockList:
        block.draw_block(screen)
    pygame.draw.rect(screen, player1.COLOR, (int(player1.X), int(player1.Y), 32, 32))
    pygame.display.flip()
    keysPressed = pygame.key.get_pressed()

    player1.handle_input(keysPressed)
    
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

pygame.quit()            
