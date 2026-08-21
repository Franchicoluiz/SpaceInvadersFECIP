extends SceneTree
# 1) nao atirar enquanto morto  2) barreira perfurada deixa o tiro passar
# 3) 2s de invencibilidade ao renascer
# ExplosionTimer do jogador = 3s, entao a janela de "morto" vai de t+0 a t+3.

var t := 0.0
var etapa := 0
var m: Node
var ok := []
var falhas := []
var vidas_no_hit := 0

func _initialize():
    m = load("res://Main.tscn").instantiate()
    root.add_child(m); current_scene = m

func check(n, c):
    if c: ok.append(n)
    else: falhas.append(n)

func _process(d) -> bool:
    t += d
    if not is_instance_valid(m): return true
    var p = m.get_node("Player")

    # ---- BARREIRA: perfurar e conferir se o colisor do quadrante desliga ----
    if etapa == 0 and t > 0.4:
        etapa = 1
        var b = m.get_node("Barrier1")
        var q = b.get_node("BottomLeftCollission")
        print(">> quadrante inferior esquerdo desabilitado ANTES: %s" % q.disabled)
        check("quadrante comeca ativo", not q.disabled)
        # varios tiros no mesmo X, vindos de baixo, ate abrir um canal vertical
        for i in 8:
            b.blast_away_pixels(Vector2(b.position.x - 30, b.position.y), "up")

    elif etapa == 1 and t > 0.7:
        etapa = 2
        var b = m.get_node("Barrier1")
        var q = b.get_node("BottomLeftCollission")
        print(">> quadrante inferior esquerdo desabilitado DEPOIS: %s" % q.disabled)
        check("quadrante perfurado para de bloquear", q.disabled)
        # e depois de repor a barreira (nova onda) ele volta a bloquear
        b._reenable_barrier()

    elif etapa == 2 and t > 1.0:
        etapa = 3
        var q = m.get_node("Barrier1/BottomLeftCollission")
        print(">> apos _reenable_barrier: desabilitado=%s" % q.disabled)
        check("quadrante volta a bloquear na nova onda", not q.disabled)
        # ---- MORTE: matar o jogador e tentar atirar ----
        print(">> matando o jogador (vidas=%d)" % m.TotalPlayerLives)
        p._on_Player_area_entered(null)

    elif etapa == 3 and t > 1.6:
        etapa = 4
        var bolt = m.get_node("LaserBolt")
        m.LaserBoltExists = false          # zera para nao mascarar o teste
        bolt._disable_laserbolt()
        Input.action_press("ui_select")
        print(">> segurando tiro com o jogador morto (PlayerAlive=%s)" % p.PlayerAlive)

    elif etapa == 4 and t > 2.2:
        etapa = 5
        var bolt = m.get_node("LaserBolt")
        print(">> durante a morte: bolt visivel=%s LaserBoltExists=%s" % [bolt.visible, m.LaserBoltExists])
        check("nao atira enquanto morto", not bolt.visible and not m.LaserBoltExists)
        Input.action_release("ui_select")

    # renascimento acontece 3s apos a morte (t ~= 4.0)
    elif etapa == 5 and t > 4.3:
        etapa = 6
        print(">> renasceu: PlayerAlive=%s Invencivel=%s colisor_desabilitado=%s"
            % [p.PlayerAlive, p.Invencivel, p.get_node("CollisionShape2D").disabled])
        check("renasce invencivel", p.Invencivel)
        check("colisor desligado durante invencibilidade", p.get_node("CollisionShape2D").disabled)
        vidas_no_hit = m.TotalPlayerLives
        p._on_Player_area_entered(null)     # tomar tiro durante a invencibilidade

    elif etapa == 6 and t > 4.8:
        etapa = 7
        print(">> vidas antes=%d agora=%d (nao pode ter caido)" % [vidas_no_hit, m.TotalPlayerLives])
        check("tiro durante invencibilidade nao mata", m.TotalPlayerLives == vidas_no_hit and p.PlayerAlive)

    # invencibilidade comeca ~4.0 e dura 2s -> acaba ~6.0
    elif etapa == 7 and t > 6.6:
        etapa = 8
        print(">> apos 2s: Invencivel=%s colisor_desabilitado=%s"
            % [p.Invencivel, p.get_node("CollisionShape2D").disabled])
        check("invencibilidade expira", not p.Invencivel)
        check("colisor religa depois dela", not p.get_node("CollisionShape2D").disabled)
        check("nave visivel ao fim da invencibilidade", p.get_node("PlayerSprite").visible)

    elif etapa == 8 and t > 7.0:
        print("")
        print("===== RESULTADO =====")
        for x in ok: print("  PASSOU: ", x)
        for x in falhas: print("  FALHOU: ", x)
        print("total: %d passou, %d falhou" % [ok.size(), falhas.size()])
        return true
    return false
