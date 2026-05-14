import pygame
import utils
import settings as settings_module
pygame.init()
game_settings = settings_module.Settings(
    jump_height=10, gravity=0.7, speed=4,
    time=60, tick_speed=60,
    tile_size=32, map_width=40, map_height=10,
    block_erase_mode=False, erase_time=0,
    asset_background="pygame/assets/lucas/background.png", asset_solid="pygame/assets/lucas/solid.png", asset_win="pygame/assets/win.png", asset_lose="pygame/assets/lucas/spike.png",
    asset_player1="pygame/assets/lucas/gogo.png", asset_player2="pygame/assets/lucas/salem.png"
)
mapList = [
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,
    0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
    1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
    3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
]
player1 = utils.create_player("up","left","right",[32,32],(255,80,80),game_settings,1)
player2 = utils.create_player("w","a","d",[32,32],(80,255,80),game_settings,2)

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
