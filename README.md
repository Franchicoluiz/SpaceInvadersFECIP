# Space Invaders — Godot 4

Recriação do clássico de 1978, feita em **Godot 4**.

Port do [projeto original de Chuck5ta](https://github.com/Chuck5ta/Godot-Space-Invaders)
(Godot 3.0, 2018), com os bugs corrigidos.

## Jogar

1. Baixe **[SpaceInvaders-Windows.zip](https://github.com/Franchicoluiz/SpaceInvadersFECIP/raw/main/SpaceInvaders-Windows.zip)** (36 MB)
2. Extraia o arquivo
3. Dê dois cliques em `SpaceInvaders.exe`

Não precisa instalar nada — nem o Godot. O executável é autocontido e roda em
qualquer Windows 64 bits.

## Controles

| Tecla | Ação |
|---|---|
| ← → | Mover a nave |
| Espaço | Atirar |

Destrua os invasores antes que eles cheguem à Terra. Você tem 3 vidas. Os
blocos verdes são barreiras: protegem você, mas vão sendo destruídos pelos
tiros — dos dois lados.

Pontuação por fileira: **30** pontos na de cima, **20** nas duas do meio, **10**
nas duas de baixo. A nave-mãe vermelha, que cruza o topo da tela, vale **100**.

## Se o Windows bloquear

Na primeira execução pode aparecer *"O Windows protegeu o computador"*. Isso
acontece com qualquer programa sem assinatura digital baixado da internet, e
não indica problema com o arquivo.

Clique em **Mais informações** e depois em **Executar assim mesmo**.

## Para desenvolvedores

O código-fonte está neste repositório. Como abrir no editor, gerar o
executável, rodar os testes e todo o histórico do port — cada bug encontrado,
o diagnóstico e a verificação — estão na
**[documentação técnica](DOCUMENTACAO.md)**.

> **Por que o jogo está zipado no repositório?**
> O runtime do Godot ocupa 104 MB e o GitHub recusa arquivos acima de 100 MB.
> Comprimido, cai para 36 MB e cabe. O zip contém só o `SpaceInvaders.exe` e um
> `LEIAME.txt`.
