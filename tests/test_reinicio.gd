extends SceneTree

var f := 0
var inicial: Node
var ok := []
var falhas := []

func _initialize():
    inicial = load("res://Main.tscn").instantiate()
    root.add_child(inicial)
    current_scene = inicial

func check(n, c):
    if c: ok.append(n)
    else: falhas.append(n)

func cena() -> Node:
    return current_scene if is_instance_valid(current_scene) else null

func _process(_d) -> bool:
    f += 1
    var m = cena()
    if m == null:
        if f > 5:
            print("!! current_scene invalida no frame %d" % f)
            return true
        return false

    if f == 30:
        print(">> matando o jogador 3x (vidas=%d)" % m.TotalPlayerLives)
        m._on_Player_hit(); m._on_Player_hit(); m._on_Player_hit()
    if f == 50:
        check("GameOver apos 3 mortes", m.GameOver == true)
        print(">> START com GameOver=true -> reload_current_scene()")
        m.get_node("HUD")._on_StartButton_pressed()

    if f == 200:
        var reiniciou = (m != inicial)
        print(">> cena recarregada = %s" % reiniciou)
        print(">> estado: vidas=%d score=%d invasores=%d onda=%d GameOver=%s"
            % [m.TotalPlayerLives, m.TotalScore, m.TotalInvaders, m.WaveNumber, m.GameOver])
        check("cena foi recarregada", reiniciou)
        check("vidas voltam a 3", m.TotalPlayerLives == 3)
        check("invasores voltam a 55", m.TotalInvaders == 55)
        check("GameOver limpo", m.GameOver == false)
        var atacando := 0
        for c in m.get_children():
            if c.has_signal("enteringEarth") and c.Attack: atacando += 1
        print(">> invasores ativos apos reinicio = %d" % atacando)
        check("invasores ativos apos reinicio", atacando == 55)

    if f == 260:
        print("")
        print("===== RESULTADO =====")
        for t in ok: print("  PASSOU: ", t)
        for t in falhas: print("  FALHOU: ", t)
        print("total: %d passou, %d falhou" % [ok.size(), falhas.size()])
        return true
    return false
