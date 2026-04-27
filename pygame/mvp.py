import pygame
import utils
import settings as settings_module
pygame.init()
game_settings = settings_module.Settings(
    jump_height=15, gravity=1.2, speed=4,
    time=60, tick_speed=60,
    tile_size=32, map_width=20, map_height=15
)
mapList = [
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,
    0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,1,1,1,1,1,1,0,0,0,1,1,1,1,1,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
]
player1 = utils.create_player("up","left","right",[64,64],(255,80,80),game_settings)
player2 = utils.create_player("w","a","d",[96,96],(80,255,80),game_settings)

blockList = utils.create_level(game_settings, mapList)
screen = pygame.display.set_mode((
    game_settings.map_width  * game_settings.tile_size,
    game_settings.map_height  * game_settings.tile_size))
clock = pygame.time.Clock()

running = True
while running:
    screen.fill((255,255,255))
    for b in blockList:
        b.draw_block(screen)
    player1.draw(screen)
    player2.draw(screen)
    pygame.display.flip()
    keys = pygame.key.get_pressed()
    player1.handle_input(keys, blockList)
    player2.handle_input(keys, blockList)
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
    clock.tick(game_settings.tick_speed)
pygame.quit()
