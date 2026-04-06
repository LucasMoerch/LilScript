import pygame
import utils
import block
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
spawnInput = [150,100]
colorInput = "#2961C8"
colorInput2 = "#31DAC020"
colorInput3 = "#551ACA1F"

print("Width:", screenWidth)
print("Height:", screenHeight)
screen = pygame.display.set_mode((screenWidth, screenHeight))
clock = pygame.time.Clock()

#Creates the settings
settings= utils.create_settings(jumpHeightInput,gravityInput,speedInput,timeInput,tickSpeedInput)
#creates the blocklist, uses the settings to acess the tile size
blockList = utils.create_level(settings)
#creates 1 player
player1 = utils.create_player(jumpInput,leftInput,rightInput,spawnInput,colorInput, settings)
print("player1 X:", player1.rect.x)
testRect = pygame.Rect(500,500,32,32)


running = True
while running:
    screen.fill((255, 255, 255)) #clear screen make it white
    #draws in the blocks
    for block in blockList:
        block.draw_block(screen)
    player1.draw(screen)

    if player1.rect.colliderect(testRect):
        pygame.draw.rect(screen, colorInput2,testRect)
    else:
        pygame.draw.rect(screen, colorInput3,testRect)
    

    pygame.display.flip()



    keysPressed = pygame.key.get_pressed()

    player1.handle_input(keysPressed, blockList)
    
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

pygame.quit()            
