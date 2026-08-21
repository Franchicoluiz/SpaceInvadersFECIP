extends SceneTree
var f := 0
var m: Node
func _initialize():
    m = load("res://Main.tscn").instantiate()
    root.add_child(m); current_scene = m
func _process(_d) -> bool:
    f += 1
    if f in [30, 60, 120, 240, 400]:
        var por_linha = {0:0, 1:0, 2:0, 3:0, 4:0}
        var total = {0:0, 1:0, 2:0, 3:0, 4:0}
        for c in m.get_children():
            if not c.has_signal("enteringEarth"): continue
            var linha = int(str(c.name).substr(7, 1))
            total[linha] += 1
            if c.Attack: por_linha[linha] += 1
        print("[f%d] ativos por fileira: L0=%d/%d L1=%d/%d L2=%d/%d L3=%d/%d L4=%d/%d"
            % [f, por_linha[0],total[0], por_linha[1],total[1], por_linha[2],total[2],
               por_linha[3],total[3], por_linha[4],total[4]])
    if f >= 400: return true
    return false
