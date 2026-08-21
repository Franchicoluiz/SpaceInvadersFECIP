extends SceneTree

var f := 0
var main: Node
var ok := []
var falhas := []
var pos_onda2 := {}

func _initialize():
    main = load("res://Main.tscn").instantiate()
    root.add_child(main)
    current_scene = main

func check(n, c):
    if c: ok.append(n)
    else: falhas.append(n)

func invasores() -> Array:
    var r := []
    for c in main.get_children():
        if c.has_signal("enteringEarth"): r.append(c)
    return r

func _process(_d) -> bool:
    f += 1
    if not is_instance_valid(main): return true

    # ---- onda 1 -> onda 2 ----
    if f == 30:
        for inv in invasores(): inv._on_Invader_area_entered(null)
        main.get_node("Mothership")._on_Mothership_area_entered(null)
    if f == 60:
        main.get_node("HUD")._on_StartButton_pressed()
    if f == 120:
        for inv in invasores(): pos_onda2[inv.name] = inv.position
        print(">> onda %d iniciada, gravando posicoes" % main.WaveNumber)
    if f == 220:
        var mexeram := 0
        var atacando := 0
        for inv in invasores():
            if inv.position != pos_onda2.get(inv.name): mexeram += 1
            if inv.Attack: atacando += 1
        print(">> onda 2: %d/55 invasores se moveram, %d com Attack=true" % [mexeram, atacando])
        check("invasores se movem na onda 2", mexeram > 0)
        check("invasores em Attack na onda 2", atacando == 55)

    # ---- morte do jogador -> vidas -> game over ----
    if f == 240:
        print(">> vidas antes: %d" % main.TotalPlayerLives)
        main._on_Player_hit()
    if f == 250:
        check("vida decrementa 3->2", main.TotalPlayerLives == 2)
        main._on_Player_hit()
    if f == 260:
        check("vida decrementa 2->1", main.TotalPlayerLives == 1)
        main._on_Player_hit()
    if f == 270:
        print(">> vidas depois de 3 mortes: %d  GameOver=%s" % [main.TotalPlayerLives, main.GameOver])
        check("vidas chegam a 0", main.TotalPlayerLives == 0)
        check("Game Over ao zerar vidas", main.GameOver == true)

    if f == 320:
        print("")
        print("===== RESULTADO =====")
        for t in ok: print("  PASSOU: ", t)
        for t in falhas: print("  FALHOU: ", t)
        print("total: %d passou, %d falhou" % [ok.size(), falhas.size()])
        return true
    return false
