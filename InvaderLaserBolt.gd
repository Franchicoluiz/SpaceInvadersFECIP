extends Area2D

signal hit(area, LaserPosition)
signal hiding

@export var SPEED: int  # how fast the player will move (pixels/sec)

var LaserBoltMoving = false
# Used for resetting the invader
var StartPositionX = 0;
var StartPositionY = 0;

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
    hide()

func _process(delta):
    # move the laser bolt up the screen
    if (LaserBoltMoving):
        position.y += SPEED 

func _disable_laserbolt(): 
    print("Disable laser")
    LaserBoltMoving = false
    hide()
    $AnimatedSprite2D.stop()
    $CollisionShape2D.set_deferred("disabled", true) # stop it from destroying anything else

func _on_VisibilityNotifier2D_screen_exited():
    # stop the laser bolt moving 
    _disable_laserbolt()
    emit_signal("hiding")
        
func _reset_laserbolt(): 
    print("Activate Invader!")
    show()   
    $AnimatedSprite2D.play() 
    $AnimatedSprite2D.show()
    LaserBoltMoving = true
    $CollisionShape2D.set_deferred("disabled", false) 


func _on_InvaderLaserBolt_area_entered(area):
    print("Invader laser hit something!")
    LaserBoltMoving = false
    $AnimatedSprite2D.stop()
    $AnimatedSprite2D.visible = false
    hide()
    emit_signal("hit", area, position)
    _disable_laserbolt()
    
    
    
    
    
    
    
