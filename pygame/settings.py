from dataclasses import dataclass
from typing import Optional

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
    block_erase_mode: bool = False
    erase_time: int = 0
    # asset paths -- None means fall back to colored rectangles
    asset_background: Optional[str] = None
    asset_solid: Optional[str] = None
    asset_win: Optional[str] = None
    asset_lose: Optional[str] = None
    asset_player1: Optional[str] = None
    asset_player2: Optional[str] = None
