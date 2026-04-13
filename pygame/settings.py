from dataclasses import dataclass

@dataclass
class Settings:
    jump_height: float = 1
    gravity: float = 1
    speed: float = 5
    time: int = 60
    tick_speed: float = 60
    tile_size: int = 32
    map_width: int = 20
    map_height: int = 20
