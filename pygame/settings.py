class Settings:
    def __init__(self, jumpHeight = 1,gravity = 1, speed = 5, time = 60, tickSpeed = 60,):
        self.JUMP_HEIGHT: float = jumpHeight
        self.GRAVITY: float = gravity
        self.SPEED: float = speed
        self.TIME: int = time #Time in seconds
        self.TICK_SPEED: float = tickSpeed #FPS
