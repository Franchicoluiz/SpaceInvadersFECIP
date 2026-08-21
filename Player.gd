extends Area2D

signal hit
@export var SPEED: int  # how fast the player will move (pixels/sec)
var screensize  # size of the game window
var PlayerAlive = true
# Used for resetting the Plaer
var StartPositionX = 0;
var StartPositionY = 0;
# Meia largura visivel da nave, para o clamp nao deixar metade dela sair da tela
var HalfWidth = 0.0
# Janela sem colisao logo apos renascer, para nao morrer no instante do spawn
const INVENCIBILIDADE_SEGUNDOS = 2.0
var Invencivel = false
var _timer_invencibilidade: Timer

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
    # store position
    StartPositionX = position.x
    StartPositionY = position.y
    screensize = get_viewport_rect().size
    HalfWidth = ($PlayerSprite.texture.get_width() * $PlayerSprite.scale.x * scale.x) / 2.0
    $AnimatedSprite2D.visible = false 
    _timer_invencibilidade = Timer.new()
    _timer_invencibilidade.name = "InvincibilityTimer"
    _timer_invencibilidade.one_shot = true
    _timer_invencibilidade.wait_time = INVENCIBILIDADE_SEGUNDOS
    _timer_invencibilidade.timeout.connect(_fim_da_invencibilidade)
    add_child(_timer_invencibilidade)

func _process(delta):
    if (PlayerAlive):
        var velocity = Vector2() # the player's movement vector
        if Input.is_action_pressed("ui_right"):
            velocity.x += 1
        if Input.is_action_pressed("ui_left"):
            velocity.x -= 1
        if velocity.length() > 0:
            velocity = velocity.normalized() * SPEED
        position += velocity * delta
        # Limita pela borda da nave, nao pelo centro: com clamp(0, screensize.x)
        # metade do sprite ficava fora da tela nos dois extremos.
        position.x = clamp(position.x, HalfWidth, screensize.x - HalfWidth)
        position.y = clamp(position.y, 0, screensize.y)
        if (Invencivel):
            # pisca enquanto invencivel, para o estado ficar visivel ao jogador
            $PlayerSprite.visible = fmod(_timer_invencibilidade.time_left, 0.2) < 0.1
    
# Run at the start of a new level
func _reset_player_scene():
    show()  
    $PlayerSprite.show()
    $PlayerSprite.visible = true 
    position.x = StartPositionX
    position.y = StartPositionY
    PlayerAlive = true
    # renasce intangivel por 2s; o colisor so volta em _fim_da_invencibilidade()
    Invencivel = true
    $CollisionShape2D.set_deferred("disabled", true)
    _timer_invencibilidade.start()

func _fim_da_invencibilidade():
    Invencivel = false
    $PlayerSprite.visible = true
    $CollisionShape2D.set_deferred("disabled", false)

func _on_ExplosionTimer_timeout():
    # Hide the scene
    hide()  
    $AnimatedSprite2D.stop() 
    $AnimatedSprite2D.visible = false
    $PlayerSprite.visible = true  
    $ExplosionTimer.stop()


func _on_Player_area_entered(area):
    if (Invencivel):
        return
    print("PLAYER GUN HIT!!!!")
    if (PlayerAlive): # used to prevent double kill (2 lives lost) at the same time
        $CollisionShape2D.set_deferred("disabled", true)
        PlayerAlive = false
        # hide animation  
        $PlayerSprite.visible = false 
        $AnimatedSprite2D.visible = true    
        $AnimatedSprite2D.play()  
        $ExplosionTimer.start()
        await $ExplosionTimer.timeout
        emit_signal("hit") 
