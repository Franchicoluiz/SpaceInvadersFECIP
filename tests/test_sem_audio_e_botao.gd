extends SceneTree

# Verifica (1) que nao sobrou audio nenhum e (2) o botao START de verdade:
# aparece, ignora clique fora da sua area e reinicia o jogo quando clicado.
#
# Notas de harness:
#  - o loop nao roda travado em 60fps, entao a espera e por tempo real, nao frames
#  - show_game_over() espera 5s (MessageTimer) antes de exibir o botao
#  - cliques vao por root.push_input(): Input.parse_input_event() nao entrega
#    evento de mouse a GUI quando a janela nao tem foco do sistema

var t := 0.0
var etapa := 0
var inicial: Node
var ok := []
var falhas := []
var centro := Vector2.ZERO
var fora := Vector2.ZERO

func _initialize():
    inicial = load("res://Main.tscn").instantiate()
    root.add_child(inicial)
    current_scene = inicial

func check(n, c):
    if c: ok.append(n)
    else: falhas.append(n)

func acha_audio(n: Node, achados: Array) -> void:
    if n is AudioStreamPlayer or n is AudioStreamPlayer2D or n is AudioStreamPlayer3D:
        achados.append(str(n.get_path()))
    for c in n.get_children():
        acha_audio(c, achados)

func clica(p: Vector2) -> void:
    for pressionado in [true, false]:
        var ev := InputEventMouseButton.new()
        ev.button_index = MOUSE_BUTTON_LEFT
        ev.position = p
        ev.global_position = p
        ev.pressed = pressionado
        root.push_input(ev)

func _process(d) -> bool:
    t += d
    var m = current_scene
    if not is_instance_valid(m): return true

    if etapa == 0 and t > 0.3:
        etapa = 1
        var achados := []
        acha_audio(m, achados)
        print(">> nos de audio na arvore: %d %s" % [achados.size(), achados])
        check("nenhum no de audio na cena", achados.is_empty())
        check("engine sobe sem default_bus_layout", AudioServer.get_bus_count() >= 1)
        m._on_Player_hit(); m._on_Player_hit(); m._on_Player_hit()

    elif etapa == 1 and t > 6.5:
        etapa = 2
        var b: Button = m.get_node("HUD/StartButton")
        var r = b.get_global_rect()
        print(">> t=%.1fs botao visivel=%s rect=%s" % [t, b.visible, r])
        check("botao START aparece apos os 5s da mensagem", b.visible)
        centro = r.get_center()
        fora = Vector2(r.position.x - 120, r.get_center().y)   # a esquerda do botao
        print(">> clicando FORA do botao, em %s" % fora)
        clica(fora)

    elif etapa == 2 and t > 7.5:
        etapa = 3
        var mudou = (m != inicial)
        print(">> apos clique fora: cena recarregada=%s (esperado false)" % mudou)
        check("clique fora do botao nao faz nada", not mudou and m.GameOver)
        print(">> clicando DENTRO do botao, em %s" % centro)
        clica(centro)

    elif etapa == 3 and t > 9.0:
        etapa = 4
        var mudou = (m != inicial)
        print(">> apos clique dentro: cena recarregada=%s vidas=%d invasores=%d GameOver=%s"
            % [mudou, m.TotalPlayerLives, m.TotalInvaders, m.GameOver])
        check("clique dentro do botao reinicia o jogo",
              mudou and m.TotalPlayerLives == 3 and m.TotalInvaders == 55 and not m.GameOver)
        print("")
        print("===== RESULTADO =====")
        for x in ok: print("  PASSOU: ", x)
        for x in falhas: print("  FALHOU: ", x)
        print("total: %d passou, %d falhou" % [ok.size(), falhas.size()])
        return true
    return false
