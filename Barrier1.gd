extends Area2D

var Laserbolt

var image
var imageTexture
var imageSize = Vector2(22, 16)
var imageFormat = Image.FORMAT_RGH

const QUADRANTES = ["TopLeftCollission", "TopRightCollission",
                    "BottomLeftCollission", "BottomRightCollission"]

func _ready():
    # Os sinais ja existiam em TextureRect.gd mas nunca foram conectados, entao
    # a barreira continuava barrando tiro mesmo depois de perfurada.
    var tr := $TextureRect
    tr.DisableTopLeftCollission.connect(_desliga_quadrante.bind("TopLeftCollission"))
    tr.DisableTopRightCollission.connect(_desliga_quadrante.bind("TopRightCollission"))
    tr.DisableBottomLeftCollission.connect(_desliga_quadrante.bind("BottomLeftCollission"))
    tr.DisableBottomRightCollission.connect(_desliga_quadrante.bind("BottomRightCollission"))

func _desliga_quadrante(nome: String) -> void:
    get_node(nome).set_deferred("disabled", true)

#func _process(delta):
#    # Called every frame. Delta is time since last frame.
#    # Update game logic here.
#    pass

    
func blast_away_pixels(LaserCoords, BlastDirection):
    $TextureRect._blast_barrier(LaserCoords, position, BlastDirection)
    
func _reenable_barrier():    
    # required from the 2nd wave onwards
    $TextureRect._reload_image()
    for nome in QUADRANTES:
        get_node(nome).set_deferred("disabled", false)
    show() 
