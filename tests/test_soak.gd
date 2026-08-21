extends SceneTree
var f := 0
var dir := 1
var m: Node
func _initialize():
    m = load("res://Main.tscn").instantiate()
    root.add_child(m); current_scene = m
func _process(_d) -> bool:
    f += 1
    var s = current_scene
    if not is_instance_valid(s): return true
    Input.action_press("ui_select")
    if f % 90 == 0:
        dir = -dir
        Input.action_release("ui_left"); Input.action_release("ui_right")
    Input.action_press("ui_right" if dir > 0 else "ui_left")
    if s.GameOver and f % 600 == 0:
        s.get_node("HUD")._on_StartButton_pressed()   # reinicia sozinho
    if f % 4000 == 0:
        print("[f%d] score=%d inv=%d vidas=%d onda=%d GameOver=%s"
            % [f, s.TotalScore, s.TotalInvaders, s.TotalPlayerLives, s.WaveNumber, s.GameOver])
    if f >= 20000: return true
    return false
