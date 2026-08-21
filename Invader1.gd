extends Area2D

signal hit
signal enteringEarth
var SPEED = 0.4
var MovementRight = true #Invader will move right when initially spawned
var MovementDown = false
# used to allow for the difference between the travel distance of the first move to the right compared with all subsequent moves
var InitialMove = true # Invaders first movement to the far right
var MaxDistanceToTravel = 80 # max distance to move left and right
var DistanceTravelled = 0 # Distance travelled so far in pixels
var DistanceToMoveDown = 10 #25 #move 50 pixels down the screen
var Attack = false # to prevent movement before the game starts 
var Alive = true # falso do abate ate o proximo reset (ver _on_VisibilityNotifier2D_screen_exited)
var AnimationSpeed = 1
# Used for resetting the invader
var StartPositionX = 0;
var StartPositionY = 0;

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
    # store position
    StartPositionX = position.x
    StartPositionY = position.y
    $AnimatedSprite2D.get_sprite_frames().set_animation_speed("animate", 1)
    
func _process(delta):
    if (!Attack):
        return
    #move the Invader
    if (MovementDown):
        position.y += DistanceToMoveDown      
        MovementDown = false 
    elif (MovementRight):
        position.x += SPEED
        DistanceTravelled += SPEED 
    else: # move left
        position.x -= SPEED
        DistanceTravelled += SPEED 
    if (DistanceTravelled >= MaxDistanceToTravel):
        if (InitialMove):
            InitialMove = false
            MaxDistanceToTravel = 160
        #time to go down the screen
        MovementDown = true
        DistanceTravelled = 0
        MovementRight = !MovementRight
        #increase movement speed
        SPEED += 0.01
        AnimationSpeed += SPEED
        $AnimatedSprite2D.sprite_frames.set_animation_speed("animate", AnimationSpeed)

func _on_ExplosionTimer_timeout():
    # Hide the scene
    hide()
    #queue_free()
    $ExplosionTimer.stop()

func _on_VisibilityNotifier2D_screen_entered():
    # NAO zerar Attack aqui. No Godot 4 este sinal dispara depois dos timers de
    # entrada das fileiras, entao ele desligava fileiras ja ativadas: a fileira 4
    # (timer de 0.1s, o mais rapido) nunca chegava a se mover, e apos um reset de
    # onda todas as 55 ficavam congeladas. Attack ja nasce false na declaracao;
    # quem liga sao os Line*InvaderStartTimer e _reset_invader_scene().
    $AnimatedSprite2D.play()

# Called when game is over in order to hide any remaining invaders
func _disable_invader():
    Alive = false
    Attack = false
    $CollisionShape2D.set_deferred("disabled", true) # should not be needed, but just in case
    $AnimatedSprite2D.hide()

func _on_VisibilityNotifier2D_screen_exited():
    # Game over so quando um invasor VIVO desce alem da base da tela.
    # O hide() de um invasor abatido tambem dispara screen_exited; sem estas
    # guardas, cada abate emitia enteringEarth e encerrava o jogo na hora.
    if (!Alive):
        return
    if (position.y < get_viewport_rect().size.y):
        return
    emit_signal("enteringEarth")
    
# Run at the start of a new level
func _reset_invader_scene():
    show()
    $AnimatedSprite2D.show()
    $AnimatedSprite2D.visible = true 
    $Explosion.visible = false 
    position.x = StartPositionX
    position.y = StartPositionY
    $AnimatedSprite2D.play()
    $CollisionShape2D.set_deferred("disabled", false)
    Alive = true
    Attack = true
    InitialMove = true 
    AnimationSpeed = 1
    DistanceToMoveDown += 1 # increses every wave

func _on_Invader_area_entered(area):
    Alive = false
    $CollisionShape2D.set_deferred("disabled", true)
    print("Invader has been hit!!")
    # hide animation    
    $AnimatedSprite2D.stop()
    $AnimatedSprite2D.visible = false  
    $Explosion.visible = true    
    $ExplosionTimer.start()
    emit_signal("hit")
