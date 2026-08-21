extends SceneTree
# Regressao do segfault: tiro nas bordas da barreira estourava os limites da
# imagem 22x16. No editor isso so loga erro; no build exportado derruba o
# processo. Varre X bem alem da largura da barreira, nas duas direcoes.
var t := 0.0
var m: Node
var feito := false
func _initialize():
    m = load("res://Main.tscn").instantiate()
    root.add_child(m); current_scene = m
func _process(d) -> bool:
    t += d
    if feito or t < 0.5: return false
    feito = true
    var n := 0
    for nome in ["Barrier1", "Barrier4"]:
        var b = m.get_node(nome)
        for dx in range(-150, 260, 10):
            for dy in [-40, 0, 40, 120]:
                for dir in ["up", "down"]:
                    b.blast_away_pixels(Vector2(b.position.x + dx, b.position.y + dy), dir)
                    n += 1
    print("RESULTADO: %d blasts executados" % n)
    return true
