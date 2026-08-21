extends SceneTree

var f := 0
var main: Node
var phase := 0
var max_bolts_seen := 0
var falhas := []
var ok := []

func _initialize():
    main = load("res://Main.tscn").instantiate()
    root.add_child(main)
    current_scene = main

func invasores() -> Array:
    var r := []
    for c in main.get_children():
        if c.has_signal("enteringEarth"):
            r.append(c)
    return r

func check(nome, cond):
    if cond: ok.append(nome)
    else: falhas.append(nome)

func _process(_d) -> bool:
    f += 1
    if not is_instance_valid(main): return true

    # monitora o teto de laseres inimigos durante todo o teste
    max_bolts_seen = max(max_bolts_seen, main.TotalInvaderLaserbolts)

    if f == 30 and phase == 0:
        phase = 1
        print(">> FASE 1: matar todos os %d invasores" % invasores().size())
        for inv in invasores():
            inv._on_Invader_area_entered(null)

    if f == 60 and phase == 1:
        phase = 2
        print("   TotalInvaders apos abate = %d" % main.TotalInvaders)
        check("todos invasores contabilizados", main.TotalInvaders == 0)
        var score_antes = main.TotalScore
        main.get_node("Mothership")._on_Mothership_area_entered(null)
        await_frame(score_antes)

    if f == 90 and phase == 2:
        phase = 3
        check("wave_killed detectado", main.WaveKilled == true)
        check("HUD mostra botao NEXT WAVE", main.get_node("HUD/StartButton").visible)
        print("   WaveKilled=%s  botao='%s' visivel=%s" % [main.WaveKilled,
            main.get_node("HUD/StartButton").text, main.get_node("HUD/StartButton").visible])
        print(">> FASE 2: apertar START para proxima onda")
        main.get_node("HUD")._on_StartButton_pressed()

    if f == 150 and phase == 3:
        phase = 4
        print("   onda=%d invasores=%d" % [main.WaveNumber, main.TotalInvaders])
        check("onda incrementada", main.WaveNumber == 2)
        check("invasores repostos", main.TotalInvaders == 55)
        check("mothership revivida", main.MothershipAlive == true)
        check("WaveKilled resetado", main.WaveKilled == false)
        var vivos := 0
        for inv in invasores():
            if inv.visible and inv.Alive: vivos += 1
        print("   invasores visiveis e vivos apos reset = %d" % vivos)
        check("invasores reaparecem vivos", vivos == 55)
        var b = main.get_node("Barrier1")
        check("barreiras reexibidas", b.visible)

    if f == 400:
        print("   teto de laseres inimigos observado = %d (max permitido = %d)"
            % [max_bolts_seen, main.MaxInvaderLaserbolts])
        check("teto de laseres inimigos respeitado", max_bolts_seen <= main.MaxInvaderLaserbolts)
        print("")
        print("===== RESULTADO =====")
        for t in ok: print("  PASSOU: ", t)
        for t in falhas: print("  FALHOU: ", t)
        print("total: %d passou, %d falhou" % [ok.size(), falhas.size()])
        return true
    return false

func await_frame(_s): pass
