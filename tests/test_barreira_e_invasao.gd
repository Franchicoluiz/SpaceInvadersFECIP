extends SceneTree

var f := 0
var main: Node
var falhas := []
var ok := []
var earth_fired := false
var pixels_antes := -1

func _initialize():
    main = load("res://Main.tscn").instantiate()
    root.add_child(main)
    current_scene = main

func check(nome, cond):
    if cond: ok.append(nome)
    else: falhas.append(nome)

func conta_pixels_opacos(barreira) -> int:
    var img = barreira.get_node("TextureRect").image
    var n := 0
    for y in img.get_height():
        for x in img.get_width():
            if img.get_pixel(x, y).a > 0.0: n += 1
    return n

func _process(_d) -> bool:
    f += 1
    if not is_instance_valid(main): return true

    # --- TESTE: destruicao de barreira realmente apaga pixels ---
    if f == 30:
        var b = main.get_node("Barrier1")
        pixels_antes = conta_pixels_opacos(b)
        print(">> barreira: %d pixels opacos antes" % pixels_antes)
        # dispara um blast no centro da barreira, vindo de baixo
        b.blast_away_pixels(Vector2(b.position.x, b.position.y), "up")
    if f == 40:
        var depois = conta_pixels_opacos(main.get_node("Barrier1"))
        print(">> barreira: %d pixels opacos depois (delta %d)" % [depois, depois - pixels_antes])
        check("blast na barreira apaga pixels", depois < pixels_antes)

    # --- TESTE: invasor VIVO descendo alem da tela ainda causa Game Over ---
    if f == 60:
        var inv = null
        for c in main.get_children():
            if c.has_signal("enteringEarth"):
                inv = c; break
        inv.enteringEarth.connect(func(): earth_fired = true)
        print(">> empurrando invasor vivo (Alive=%s) para y=850, tela=768" % inv.Alive)
        inv.position.y = 850
    if f == 80:
        print(">> enteringEarth disparou = %s | GameOver = %s" % [earth_fired, main.GameOver])
        check("invasor vivo abaixo da tela dispara enteringEarth", earth_fired)
        check("isso leva a Game Over", main.GameOver == true)

    if f == 120:
        print("")
        print("===== RESULTADO =====")
        for t in ok: print("  PASSOU: ", t)
        for t in falhas: print("  FALHOU: ", t)
        print("total: %d passou, %d falhou" % [ok.size(), falhas.size()])
        return true
    return false
