# Documentação técnica

Registro do port de **Godot 3.0 → Godot 4.7.1**: o que foi convertido, cada bug
encontrado, como foi diagnosticado e como foi verificado.

Nada aqui é necessário para jogar — para isso, veja o [README](README.md).
Este documento é para quem for mexer no código.

O projeto de origem é o [Godot-Space-Invaders de
Chuck5ta](https://github.com/Chuck5ta/Godot-Space-Invaders) (2018, Godot 3.0).

## Índice

- [Ambiente de desenvolvimento](#ambiente-de-desenvolvimento)
- [O que foi alterado na conversão](#o-que-foi-alterado-na-conversão)
- [Verificação](#verificação)
- [Bugs de jogabilidade corrigidos (2ª rodada)](#bugs-de-jogabilidade-corrigidos-2ª-rodada)
- [Como os bugs foram verificados](#como-os-bugs-foram-verificados)
- [Bugs encontrados na 3ª rodada (busca ativa)](#bugs-encontrados-na-3ª-rodada-busca-ativa)
- [Suíte de testes](#suíte-de-testes)
- [Áudio removido](#áudio-removido)
- [Áreas que estavam sem verificação, agora cobertas](#áreas-que-estavam-sem-verificação-agora-cobertas)
- [Crash ao atirar nas barreiras (segfault)](#crash-ao-atirar-nas-barreiras-segfault)
- [Correções da 4ª rodada](#correções-da-4ª-rodada)
- [Estado atual dos testes](#estado-atual-dos-testes)
- [O que continua sem verificação](#o-que-continua-sem-verificação)

## Ambiente de desenvolvimento

Testado com **Godot 4.7.1**. Os comandos abaixo usam `godot` como o executável
do engine; ajuste para o caminho da sua instalação.

Abrir no editor:

```
godot --path .
```

Rodar o jogo sem abrir o editor:

```
godot --path .
```

Gerar o executável (precisa dos *export templates* instalados):

```
godot --headless --path . --export-release "Windows Desktop" build/SpaceInvaders.exe
```

Rodar uma suíte de testes (**precisa de janela** — veja a ressalva em
[Suíte de testes](#suíte-de-testes)):

```
godot --path . --script res://tests/test_wave_e_mothership.gd
```

## O que foi alterado na conversão

Além do que o conversor automático (`--convert-3to4`) fez, estas correções
foram necessárias à mão:

1. **`project.godot`** — o arquivo original era `config_version=3` (Godot 3.0) e o
   conversor não o atualiza. Reescrito para `config_version=5`. A resolução foi
   fixada em 1024x768: o original só declarava `height=768` e herdava a largura
   padrão 1024 do Godot 3 — o Godot 4 usa 1152, o que deformaria o jogo, já que
   o `Player.gd` limita a posição pelo tamanho da viewport.

2. **`TextureRect.gd` (barreiras destrutíveis)** — era o único bug que quebrava
   *especificamente o build exportado*. O código fazia
   `Image.load("res://Art/Barrier.png")` em tempo de execução; no `.exe` o PNG
   cru não existe (vira `.ctex` importado), então as barreiras falhariam apenas
   no aplicativo, nunca no editor. Trocado por `load(...).get_image()`, com
   `decompress()` + `convert(FORMAT_RGBA8)` para manter a imagem gravável pelo
   `set_pixel()`. Também atualizadas as APIs `image.create()` e
   `imageTexture.create_from_image()`, que viraram estáticas no Godot 4.

3. **Colisões (12 ocorrências em 5 arquivos)** — `$CollisionShape2D.disabled = X`
   dentro de handlers de `area_entered` gera erro no Godot 4
   ("Can't change this state while flushing queries"). Convertido para
   `set_deferred("disabled", X)`.

4. **`Invader1.gd`** — `AnimatedSprite2D.frames` foi renomeado para
   `sprite_frames` no Godot 4.

5. **`Sounds/shoot.wav`** — o arquivo **não existe** no repositório original
   (só sobrou o `.import` órfão), e o `Main.tscn` o referenciava, impedindo a
   cena principal de carregar. Substituído por `Sounds/FireLaserBolt.wav`, que
   existe, é o som de tiro do mesmo pacote de assets e não era usado em lugar
   nenhum.

6. **`default_env.tres`** — Environment 3D em formato Godot 3, sem uso em um
   jogo 2D. Removido.

## Verificação

O build exportado foi executado por 1200 frames em modo headless com **zero
erros**, exercitando o caminho de código das barreiras (o ponto de falha do
item 2). Também roda em janela: o Vulkan não está disponível nesta máquina e o
Godot cai automaticamente para Direct3D 12 — isso é um aviso, não uma falha.

Testes automatizados de jogabilidade não foram feitos: o modo headless não
processa entrada, então movimento, tiro e colisão com o jogador precisam de
conferência manual.

## Bugs de jogabilidade corrigidos (2ª rodada)

O jogo compilava e rodava sem erros no log, mas era **injogável**. Três bugs
silenciosos, todos encontrados injetando input em execução e medindo o estado:

7. **Invasores invencíveis** (o mais grave) — as cenas `Invader1/2/3.tscn` tinham
   `collision_mask = 0` na Area2D raiz. No Godot 3, quando uma área detectava
   outra, **ambas** recebiam `area_entered`; no Godot 4 a detecção é
   unidirecional, cada área só enxerga o que a própria máscara cobre. Resultado:
   o tiro registrava a colisão, mas o invasor nunca era notificado e nunca
   morria. Medido: 3600 frames de tiro contínuo com score 0 e 55 invasores
   intactos. Corrigido para `collision_mask = 1`.

8. **Game Over a cada abate** — `Invader1.gd` emitia `enteringEarth` (que encerra
   o jogo) no `screen_exited` do `VisibleOnScreenNotifier2D`. Mas o `hide()` de
   um invasor recém-abatido também dispara `screen_exited`. Evidência: invasor
   morto em y=368, numa tela de 768px, emitindo "chegou na Terra" 31 frames
   depois. Adicionadas as guardas `Alive` e `position.y >= altura da tela`.

9. **Textos a 16px** — os blocos `[sub_resource type="FontFile"]` eram
   `DynamicFont` do Godot 3 renomeados pela metade: no Godot 4 `FontFile` não
   tem `size` nem `font_data`, então todo texto caía para o default de 16px em
   vez de 64/32. Substituídos por referência direta ao `.ttf` mais
   `theme_override_font_sizes/font_size`.

10. **Nave saindo pela borda** — `clamp(position.x, 0, screensize.x)` limitava o
    *centro* do sprite, deixando ~28px da nave fora da tela nos dois extremos.
    Passa a limitar pela borda. Esta é a única mudança de comportamento em
    relação ao original — as outras restauram o que o jogo fazia no Godot 3.

## Como os bugs foram verificados

Rodando o jogo com um script `SceneTree` que injeta input via `Input.action_press()`
e mede o estado quadro a quadro. Resultado final, varrendo a tela e atirando:

```
[f1000] score=340 inv=29 vidas=2 GameOver=false
[f2000] score=660 inv=14 vidas=1 GameOver=false
[f3000] score=800 inv=8  vidas=0 GameOver=true
```

Score sobe, invasores caem, vidas decrementam e o Game Over dispara em 0 vidas.

**Atenção ao testar em headless:** `VisibleOnScreenNotifier2D` não dispara sem
renderização, então o tiro nunca "sai da tela" e trava o `LaserBoltExists`. Isso
é artefato do modo headless, não bug — em janela funciona. Testes de
jogabilidade precisam rodar com janela.

## Bugs encontrados na 3ª rodada (busca ativa)

Com o jogo já jogável, uma varredura dos caminhos ainda não exercitados achou mais
dois bugs, ambos da **mesma raiz** e ambos herdados do original:

11. **Fileira 4 nunca se movia** — 11 dos 55 invasores ficavam congelados desde o
    início da partida, sempre. `Invader1.gd` zerava `Attack` dentro de
    `_on_VisibilityNotifier2D_screen_entered()`. No Godot 4 esse sinal dispara
    *depois* dos timers de entrada das fileiras. Como o timer da fileira 4 é o mais
    rápido (0.1s, contra 0.3–0.9s das outras), ele ativava a fileira e o sinal
    desligava logo em seguida. As fileiras 0–3 disparavam depois do sinal e
    escapavam.

12. **Onda 2 completamente travada** — depois de limpar a primeira onda, os 55
    invasores ficavam parados, sem se mover nem atirar: jogo impossível de
    continuar. Mesma causa (o `show()` do reset dispara `screen_entered`, que
    zerava o `Attack` que o reset acabara de ligar), agravada pelo `_new_game()`
    não reiniciar os timers de entrada das fileiras.

    Correções: removido o `Attack = false` do `screen_entered` (ele já nasce
    `false` na declaração; quem liga são os timers e `_reset_invader_scene()`), e
    `_new_game()` passou a chamar `_set_off_invaders()`.

Antes/depois da ativação por fileira, no boot normal:

```
antes:  L0=11/11 L1=11/11 L2=11/11 L3=11/11 L4=0/11    <- fileira 4 morta
depois: L0=11/11 L1=11/11 L2=11/11 L3=11/11 L4=11/11
```

## Suíte de testes

Em `tests/`. Rodam com o jogo de verdade (janela), injetando input via
`Input.action_press()` e medindo o estado quadro a quadro:

| Arquivo | Cobre |
|---|---|
| `test_wave_e_mothership.gd` | limpar a onda, mothership, botão NEXT WAVE, reposição de invasores/barreiras, teto de 2 lasers inimigos |
| `test_barreira_e_invasao.gd` | destruição de pixels da barreira; invasor vivo abaixo da tela causando Game Over |
| `test_onda2_e_vidas.gd` | movimento dos invasores na onda 2; decremento de vidas 3→0 |
| `test_reinicio.gd` | Game Over → START → `reload_current_scene()` e estado zerado |
| `test_sem_audio_e_botao.gd` | ausência de nós de áudio; botão START: aparece, ignora clique fora e reinicia o jogo |
| `test_morte_barreira_invencibilidade.gd` | tiro bloqueado durante a morte; quadrante perfurado deixa de bloquear; invencibilidade de 2s |
| `test_ativacao_fileiras.gd` | ativação escalonada das 5 fileiras (diagnóstico) |
| `test_barreira_limites.gd` | 656 blasts nas bordas das barreiras, checando estouro de índice |
| `test_soak.gd` | 20.000 frames com reinício automático |

Resultado atual (ver contagem final mais abaixo): **todas as asserções passando**, e o soak de 20.000 frames
(~5,5 min de jogo, com várias mortes e reinícios) sem um único erro de script.

Auditorias estáticas feitas junto: os 55 handlers `_on_InvaderXY_hit` têm índices
e pontuação corretos (30 no topo, 20/20 no meio, 10/10 na base), e os 55 nós de
invasor têm as conexões `hit` e `enteringEarth` ligadas aos métodos certos.

## Áudio removido

O jogo agora é totalmente silencioso. Removidos:

- **9 nós `AudioStreamPlayer` e 2 `AudioStreamPlayer2D`** em 5 cenas
  (`ExplosionSound`, `LaserBoltSound`, `InvaderMovementSound1-4`, `FlyingSound`)
- **os 11 `ext_resource` de áudio** e a pasta `Sounds/` inteira
- `default_bus_layout.tres`
- todas as chamadas `.play()` / `.stop()` nos scripts
- os timers `InvaderSoundTimer` / `InvaderSoundSpeed` e os handlers da marchinha
  de quatro notas, que existiam só para o áudio e não influenciavam o jogo

Isso eliminou de quebra um **vazamento de memória**: `_wait()` criava um nó
`Timer` a cada chamada e nunca o liberava. Como o `InvaderSoundTimer` se repetia
e acelerava (`wait_time / 1.1` a cada ciclo), o vazamento crescia sem parar
durante a partida.

O executável continua com ~105 MB: os `.wav` eram pequenos perto do runtime do
Godot, que domina o tamanho.

## Áreas que estavam sem verificação, agora cobertas

- **Área clicável do botão START**: validada com clique real de mouse. Um clique
  120px à esquerda do botão não faz nada; no centro, reinicia o jogo (vidas de
  volta a 3, 55 invasores, `GameOver` limpo).
- **Áudio**: em vez de testar que os sons tocam, o teste varre a árvore de nós e
  exige **zero** players de áudio, confirmando a remoção.

Duas armadilhas de harness descobertas aqui, anotadas nos testes:

1. `Input.parse_input_event()` **não** entrega clique à GUI quando a janela não
   tem foco do sistema. Para clique é preciso `root.push_input()`. Movimento de
   mouse (hover) funciona pelos dois caminhos.
2. O loop do `SceneTree` de teste não roda travado em 60fps (chega a ~195fps),
   então contar frames não serve de relógio; as esperas precisam acumular
   `delta`. Foi isso que fez o botão parecer que nunca aparecia — na verdade
   `show_game_over()` espera 5s reais no `MessageTimer` antes de exibi-lo.

## Crash ao atirar nas barreiras (segfault)

**Sintoma:** o jogo fechava sozinho ao acertar os blocos verdes.

**Causa:** em `TextureRect.gd`, as contas que convertem a posição do tiro em
coordenada de pixel usam constantes aproximadas (55/40/110/80/21/15) e não
tinham nenhum teto. Um tiro perto das bordas da barreira produzia índices fora
da imagem 22x16 — chegavam a **28** de largura, e o Y podia ficar negativo
quando o laço de busca já havia levado a linha até 0.

**Por que passou por todos os testes anteriores:** o build do editor checa os
limites e apenas registra `Index p_x = 28 is out of bounds` no log, seguindo em
frente. O template de release não faz essa checagem, e o acesso inválido derruba
o processo. Reproduzido no `.exe`:

```
Laser bolt has hit the target!
Laser coords: (604.9042, 592.823)
Barrier coords: (631.667, 639.97)
Segmentation fault    exit code 139
```

**Correção:** `_write_pixel()` foi reescrita. Toda coordenada é convertida para
inteiro e limitada à imagem antes de qualquer `get_pixel`/`set_pixel`, e as
escritas que caem fora são descartadas em vez de grampeadas na borda (grampear
empilharia pixels apagados na coluna da ponta, deformando a cratera). Os dois
sentidos de tiro passaram a compartilhar o mesmo laço, com passo `+1`/`-1`.

**Verificação:** 656 blasts varrendo X de −150 a +260 em relação à barreira, nos
dois sentidos e em 4 alturas, com **zero** estouros de limite
(`tests/test_barreira_limites.gd`). No build exportado, 3 partidas com 187, 118
e 47 impactos em barreira e um soak de 15.000 frames com 119 impactos — todos
saindo com **exit 0**.

### Lição para os próximos testes

Testar só no build do editor não basta: ele mascara erros de índice que são
fatais no `.exe` entregue. Bugs de acesso a pixel/array precisam de uma rodada
no build exportado.

## Correções da 4ª rodada

Três problemas relatados durante o uso, todos confirmados e corrigidos.

### Era possível atirar enquanto morto

`Main.gd` decidia se podia atirar pelo seu próprio `PlayerAlive`, que só virava
`false` quando as vidas chegavam a zero. Morrendo com vidas restantes, a
variável continuava `true` e o jogo aceitava tiro durante a explosão e o
renascimento.

O estado autoritativo é o do próprio jogador, então a checagem passou a ser
`if ($Player.PlayerAlive)`.

### Barreira perfurada continuava bloqueando o tiro

Cada barreira tem 4 `CollisionShape2D`, um por quadrante. O `TextureRect.gd` já
declarava os sinais `DisableTopLeftCollission`, `DisableTopRightCollission`,
`DisableBottomLeftCollission` e `DisableBottomRightCollission` e tinha uma
função para emiti-los — **mas as chamadas estavam comentadas e os sinais nunca
foram conectados a nada**. O recurso existia no código e nunca chegou a
funcionar.

`_disable_collision_checks()` foi reescrita: em vez de checar uma única linha
horizontal (a heurística original), ela procura por um **canal vertical
totalmente vazado** no quadrante — que é exatamente a condição em que um tiro
consegue atravessar. `Barrier1.gd` passou a conectar os quatro sinais e a
religar os quadrantes em `_reenable_barrier()`, para a barreira voltar inteira
na onda seguinte.

Com a cratera de 5x5 pixels de cada tiro numa imagem de 22x16, são necessários
cerca de 2 tiros no mesmo ponto para abrir passagem por um quadrante.

### Spawn kill

Não havia nenhuma proteção no renascimento: o jogador podia reaparecer
exatamente sob um laser já em curso e morrer no mesmo instante.

`Player.gd` ganhou **2 segundos de invencibilidade** ao renascer
(`INVENCIBILIDADE_SEGUNDOS`), com um `Timer` criado em `_ready()`. Durante a
janela o `CollisionShape2D` fica desligado e a nave pisca, para o estado ficar
visível. `_on_Player_area_entered()` também retorna cedo se `Invencivel` estiver
ativo.

Coberto por `tests/test_morte_barreira_invencibilidade.gd` (10 asserções),
incluindo a expiração da invencibilidade e o religamento do colisor.

## Estado atual dos testes

**40 asserções, todas passando**, distribuídas em 6 suítes:

| Suíte | Asserções |
|---|---|
| `test_wave_e_mothership.gd` | 10 |
| `test_morte_barreira_invencibilidade.gd` | 10 |
| `test_onda2_e_vidas.gd` | 6 |
| `test_reinicio.gd` | 6 |
| `test_sem_audio_e_botao.gd` | 5 |
| `test_barreira_e_invasao.gd` | 3 |

Mais três scripts sem asserções, de diagnóstico e carga:
`test_ativacao_fileiras.gd`, `test_barreira_limites.gd` (656 blasts, zero
estouros de índice) e `test_soak.gd` (20.000 frames com reinício automático,
sem erros de script).

No build exportado: partidas de 5.000 frames com ~50 impactos em barreira e 3
mortes cada, todas saindo com `exit 0`.

## O que continua sem verificação

- Nenhum teste cobre a **aparência** do jogo: eles leem estado e posições, não
  pixels na tela. Sprites trocados ou desalinhados passariam despercebidos.
- `Area2D.gd` é código morto (não anexado a nenhuma cena) e contém chamadas
  inválidas (`getName()` / `getname()`). Deixado como está por não afetar nada.
- O aviso `resources still in use at exit` ao fechar é ruído normal do Godot ao
  sair via `--quit-after`, não um erro de jogo.
