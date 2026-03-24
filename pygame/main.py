import pygame
import utils
pygame.init()
info = pygame.display.Info()
screenWidth = info.current_w
screenHeight = info.current_h 

print("Width:", screenWidth)
print("Height:", screenHeight)
screen = pygame.display.set_mode((screenWidth, screenHeight))
clock = pygame.time.Clock()


settings = utils.create_settings(12,1,60,60)
player1 = utils.create_player("space","a","d",[500,500],"#29C878", settings)
print("player1 X:", player1.X)


running = True
while running:
    screen.fill((0, 0, 0))  # clear screen (black)
    pygame.draw.rect(screen, player1.COLOR, (int(player1.X), int(player1.Y), 32, 32))
    pygame.display.flip()
    keys = pygame.key.get_pressed()

    player1.handle_input(keys)

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
    clock.tick(settings.TICK_SPEED)

pygame.quit()            
