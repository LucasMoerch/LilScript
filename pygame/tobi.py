import pygame
import utils
import settings as settings_module
pygame.init()
game_settings = settings_module.Settings(
    jump_height=16, gravity=1.8, speed=5,
    time=60, tick_speed=60,
    tile_size=32, map_width=50, map_height=10,
    block_erase_mode=False, erase_time=0,
    asset_background=None, asset_solid=None, asset_win=None, asset_lose=None,
    asset_player1=None, asset_player2=None
)
mapList = [
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,
    0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,1,1,0,1,0,0,0,0,0,0,0,0,0,0,
    0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,
    0,0,0,0,1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,
    0,0,0,0,0,0,0,0,1,1,0,1,0,0,0,0,0,0,1,0,
    0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,1,0,
    0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,1,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,1,3,3,3,3,3,3,3,3,3,3,
    3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
    3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,3
]
player1 = utils.create_player("up","left","right",[32,32],(255,80,80),game_settings,1)

blockList = utils.create_level(game_settings, mapList)
screen = pygame.display.set_mode((
    game_settings.map_width  * game_settings.tile_size,
    game_settings.map_height * game_settings.tile_size))
background = None
if game_settings.asset_background:
    try:
        background = pygame.image.load(game_settings.asset_background).convert_alpha()
        background = pygame.transform.scale(background, screen.get_size())
    except:
        pass
clock = pygame.time.Clock()
running = True
while running:
    if background:
        screen.blit(background, (0, 0))
    else:
        screen.fill((255,255,255))
    for b in blockList:
        b.draw_block(screen)
        b.update(game_settings)
    player1.draw(screen)
    pygame.display.flip()
    keys = pygame.key.get_pressed()
    player1.handle_input(keys, blockList)
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
    clock.tick(game_settings.tick_speed)
pygame.quit()
