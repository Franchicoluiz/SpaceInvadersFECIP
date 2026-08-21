extends TextureRect
signal DisableTopLeftCollission
signal DisableTopRightCollission
signal DisableBottomLeftCollission
signal DisableBottomRightCollission

# Gonna try and use this to create destructible sprite image
var editableImage
var imageSize = Vector2(22, 16)
var imageFormat = Image.FORMAT_RGH

var imageTexture
var image
var destroyedPixel = Color(0, 0, 0, 0)

func _ready():
    randomize()
    _reload_image()


## Carrega o PNG do barreira como Image gravavel.
## Usa load() no recurso importado (e nao Image.load(), que so funciona
## no editor e falha no jogo exportado, onde o PNG cru nao existe).
func _load_barrier_image() -> Image:
    var img: Image = load("res://Art/Barrier.png").get_image()
    img.decompress()
    img.convert(Image.FORMAT_RGBA8)
    return img

#func _process(delta):
#    # Called every frame. Delta is time since last frame.
#    # Update game logic here.
#    pass
    
## Desliga o colisor de um quadrante quando existe nele um canal vertical
## inteiramente destruido: e exatamente a condicao em que um tiro deveria passar.
## A barreira tem 4 CollisionShape2D (os quadrantes) e a imagem tem 22x16, entao
## cada quadrante cobre 11x8 pixels.
func _disable_collision_checks() -> void:
    var largura: int = image.get_width()
    var altura: int = image.get_height()
    var meio_x: int = largura / 2
    var meio_y: int = altura / 2
    if _tem_canal_vertical(0, meio_x, 0, meio_y):
        emit_signal("DisableTopLeftCollission")
    if _tem_canal_vertical(meio_x, largura, 0, meio_y):
        emit_signal("DisableTopRightCollission")
    if _tem_canal_vertical(0, meio_x, meio_y, altura):
        emit_signal("DisableBottomLeftCollission")
    if _tem_canal_vertical(meio_x, largura, meio_y, altura):
        emit_signal("DisableBottomRightCollission")


## Existe alguma coluna x em [x0, x1) totalmente vazada entre y0 e y1?
func _tem_canal_vertical(x0: int, x1: int, y0: int, y1: int) -> bool:
    for x in range(x0, x1):
        var vazada := true
        for y in range(y0, y1):
            if image.get_pixel(x, y).a > 0.0:
                vazada = false
                break
        if vazada:
            return true
    return false


func _blast_barrier(LaserCoords, BarrierCoords, BlastDirection):
    print("Laser coords: ", str(LaserCoords))
    print("Barrier coords: ", str(BarrierCoords))
    BarrierCoords.x = BarrierCoords.x - 55
    BarrierCoords.y = BarrierCoords.y - 40
    var SpriteXLocation
    var SpriteYLocation
    if (BlastDirection == "down"):
        # Actual coordinates of the laser bolt's strike point
        var LaserBoltStrikeCoordX = LaserCoords.x
        var LaserBoltStrikeCoordY = 28 + LaserCoords.y
        var Xdifference
        var Ydifference
        # Difference between the strike point and the Barriers origin 
        if LaserBoltStrikeCoordX >= BarrierCoords.x:
             Xdifference = LaserBoltStrikeCoordX - BarrierCoords.x
        else:
             Xdifference = 0 
        if LaserBoltStrikeCoordY >= BarrierCoords.y:
             Ydifference = LaserBoltStrikeCoordY - BarrierCoords.y
        else:
             Ydifference = 0
        
        # Now figure out where we are in the sprite
        var ActualBarrierWidth = 110 # pixels on the screen
        var ActualBarrierHeight = 80 # pixels on the screen  
        if Xdifference == 0:
            SpriteXLocation = 0
        else:
            SpriteXLocation = (Xdifference / ActualBarrierWidth) * 22 # (truncate?)
        if Ydifference == 0:
            SpriteYLocation = 0
        else:
            SpriteYLocation = (Ydifference / ActualBarrierHeight) * 16 # (truncate?)
        SpriteYLocation = 0 # TODO delete the above code to do with calculating the Y coord, as ir will always be 0
    else:
        var LaserBoltStrikeCoordX = LaserCoords.x
        var LaserBoltStrikeCoordY = LaserCoords.y
        var Xdifference
        var Ydifference
        # Difference between the strike point and the Barriers origin 
        if LaserBoltStrikeCoordX > BarrierCoords.x:
             Xdifference = LaserBoltStrikeCoordX - BarrierCoords.x
        else:
             Xdifference = 0   
        if LaserBoltStrikeCoordY > (BarrierCoords.y + 80): # pixels have been increased by a factor of 5
             Ydifference = LaserBoltStrikeCoordY - (BarrierCoords.y + 80)
        else:
             Ydifference = 0
        
        # Now figure out where we are in the sprite
        var ActualBarrierWidth = 110
        var ActualBarrierHeight = 80  
        if Xdifference > 0:
            SpriteXLocation = (Xdifference / ActualBarrierWidth) * 21 # (truncate?)
        else:
            SpriteXLocation = 0
        if Ydifference > 0:
            SpriteYLocation = Ydifference / ActualBarrierHeight * 15 # (truncate?)
        else:
            SpriteYLocation = 15
        SpriteYLocation = 15 # TODO delete the above code to do with calculating the Y coord, as ir will always be 15
    
    _write_pixel(SpriteXLocation, SpriteYLocation, BlastDirection)
        
func _write_pixel(SpriteXLocation, SpriteYLocation, BlastDirection):
    # As contas de coordenada acima usam constantes aproximadas (55/40/110/80)
    # e podem cair fora da imagem 22x16 quando o tiro acerta perto das bordas
    # da barreira. No build do editor isso so gera erro no log; no build
    # exportado o Godot nao checa limites e o processo morre com segfault.
    # Por isso tudo aqui e limitado a imagem antes de tocar em qualquer pixel.
    var largura: int = image.get_width()
    var altura: int = image.get_height()
    var x := clampi(int(SpriteXLocation), 0, largura - 1)
    var y := clampi(int(SpriteYLocation), 0, altura - 1)

    var pixelColour = image.get_pixel(x, y)

    var passo: int = 1 if BlastDirection == "down" else -1
    var limite: int = (altura - 1) if BlastDirection == "down" else 0

    # anda ate achar um pixel ainda intacto
    while y != limite and pixelColour == destroyedPixel:
        y += passo
        pixelColour = image.get_pixel(x, y)

    # recua o inicio da linha para alargar a cratera
    if x - 2 >= 0:
        x -= 2
    elif x - 1 >= 0:
        x -= 1

    var pixelsToDestroy := 5
    var TotalRowsToDestroy := 5
    while TotalRowsToDestroy > 0:
        for pixel in pixelsToDestroy:
            var px := int(round(x + pixel))
            # descarta o que cai fora em vez de grudar na borda: limitar aqui
            # empilharia pixels apagados na coluna da ponta
            if px < 0 or px >= largura or y < 0 or y >= altura:
                continue
            # o tiro do jogador abre cratera cheia; o do invasor, irregular
            if BlastDirection == "down" and randi() % 11 + 1 >= 8:
                continue
            image.set_pixel(px, y, Color(0.0, 0.0, 0.0, 0.0))
        y += passo
        TotalRowsToDestroy -= 1

    _write_image_back()
    _disable_collision_checks()

func _write_image_back():
    imageTexture = ImageTexture.create_from_image(image)
    $BarrierSprite.texture = imageTexture
    
func _reload_image():
    image = _load_barrier_image()
    imageTexture = ImageTexture.create_from_image(image)
    $BarrierSprite.texture = imageTexture



