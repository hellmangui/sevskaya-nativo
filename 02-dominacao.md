# 02 · Domínio da tribo

O `pantanal_nativos` é o sistema de gangues da máfia (`pantanal_mafia`, base Dodiban) clonado para os nativos. A mecânica é a mesma; mudaram os nomes, a marca de território, a moeda, os aliados e o painel. Os dois recursos rodam juntos sem se misturar.

| Na máfia | Nos nativos |
| --- | --- |
| gangue / família | tribo |
| grafite na parede, com a lata de tinta | fogueira ritual no chão, com o item `fogueira_ritual` |
| modelo de grafite de cada gangue | adorno da tribo ao lado da fogueira |
| pontos em Saint Denis e no pântano | pontos sagrados, que começam vazios |
| Moeda Cigana | Wampum branco e roxo |
| NPC aliado de gangue do jogo | guerreiro Wapiti com arco |
| tabelas `mafia_*`, eventos `pantanal_mafia:*` | tabelas `nativos_*`, eventos `pantanal_nativos:*` |

## Tribos e povo

- A staff cria a tribo com `/nativos_criartribo <nome> <adorno>`. O adorno é um prop do jogo, por exemplo `p_skullpost02x`.
- As tribos de `Config.TribosProvisorias` entram sozinhas no banco quando o recurso sobe (`INSERT IGNORE`).
- `/nativos_settribo <id> <tribo>` põe um jogador como **chefe** da tribo.
- O chefe chama gente nova pelo ID na aba Povo. Pela mesma aba, faz outro membro chefe ou o expulsa, clicando no nome (precisa que a pessoa esteja no servidor).
- Os cargos são `leader` (Chefe) e `member` (Guerreiro).

## A fogueira ritual

1. O jogador usa o item `fogueira_ritual`. O "detector" liga e mostra os pontos sagrados perto dele.
2. A até 2,5 m de um ponto, o jogador se agacha (`WORLD_HUMAN_CROUCH_INSPECT`) por 12 s, e a fogueira vai aparecendo.
3. No chão ficam a fogueira acesa (`p_campfire05x`) e o **adorno da tribo** atrás dela, a 0,9 m.
4. O servidor só grava se for um ponto do `Config.AllowedLocations`, se o jogador estiver perto dele (pela posição que o **servidor** vê) e se tiver passado 10 s da última fogueira dele.
5. Acender por cima da fogueira de outra tribo toma o ponto.
6. `/apagarfogueira` apaga a fogueira mais perto (até 4 m). Com `Config.Fogueira.RivalApaga = true`, qualquer um apaga; com `false`, só a própria tribo e o admin.

Os props são **locais**: cada cliente cria os seus quando chega a 110 m e apaga a 120 m, como era o grafite.

## Pontos sagrados e terras

- Os pontos ficam em `Config.AllowedLocations` (`x, y, z, heading, area`). A lista começa **vazia**.
- Para marcar um ponto, a staff fica no lugar, de frente para onde a fogueira deve olhar, e usa `/nativos_ponto <área>`. O ponto fica 1,5 m à frente, no chão, e a linha pronta sai no F8 e no console do servidor.
- O controle de uma área é o número de fogueiras da tribo dividido pelo número de pontos da área.

## Conselho

- O chefe marca a **fogueira do conselho** com `/tribo_conselho` (uma por tribo; mudar de lugar espera 60 min).
- `/tribo` abre o painel, só perto da fogueira do conselho.

## Missões

São 3 diárias e 3 especiais, cada uma com espera de **3 h para a tribo inteira**. Ainda são as da máfia, com outro nome: Bois, Postes, Carroça, Dominação, Piratas e Extorsão (no recurso `pantanal_nativos_missoes`). As missões próprias dos nativos estão no [PLANO.md](PLANO.md).

Concluir uma missão dá 100 de XP à tribo e Wampum ao jogador. A espera pode ser liberada pagando Wampum (ver [03-wampum.md](03-wampum.md)).

## Nível da tribo

- O XP para passar do nível *n* é `1000 × n`.
- Missão concluída dá 100 de XP; roubo do Tributo da Mata dá 50; captura de ave dá 10.

## Dons (buffs)

Só o chefe acende, e o custo sai da **bolsa da tribo**.

| Dom | Id | O que faz | Nível mínimo da tribo |
| --- | --- | --- | --- |
| Tributo da Mata | `pickpocket` | quem atravessa a terra da tribo pode ter a bolsa batida (até o nível 5) | 1 |
| Guerreiros da Tribo | `npc_allies` | até 3 guerreiros Wapiti com arco acompanham cada membro na terra dominada | 5 |
| Olhos dos Batedores | `territory` | mostra no mapa todos os pontos sagrados | 5 |
| Força dos Ancestrais | `resistance` | mais vida e fôlego para a tribo na terra dominada | 10 |

Os guerreiros usam `a_m_m_wapwarriors_01`, com uma roupa sorteada e depois a variação aleatória do jogo (sem ela o ped nasce invisível). A troca é feita por tribo em `Config.GangNPCModels`.

## Cesto e bolsa

- O **cesto** guarda só os itens permitidos em `Config.ItemsData`. Qualquer membro guarda e retira.
- A **bolsa da tribo** recebe o dinheiro (dos roubos do Tributo da Mata, por exemplo). Só o chefe saca.

## Comandos

| Quem | Comando | O que faz |
| --- | --- | --- |
| Membro | `/tribo` | abre o painel perto da fogueira do conselho |
| Chefe | `/tribo_conselho` | marca a fogueira do conselho |
| Qualquer um | `/apagarfogueira` | apaga a fogueira mais perto |
| Staff | `/nativos_criartribo nome adorno` | cria uma tribo |
| Staff | `/nativos_settribo id tribo` | põe o jogador como chefe |
| Staff | `/nativos_vertribo`, `/nativos_listartribos`, `/nativos_checkplayer` | consultas |
| Staff | `/nativos_ponto área` | marca um ponto sagrado |

## Tabelas

O recurso cria as tabelas sozinho ao subir:

| Tabela | Guarda |
| --- | --- |
| `nativos_gangs` | tribos: nome, adorno (`graffiti_model`), bolsa (`money`) |
| `nativos_members` | membros e cargo |
| `nativos_locations` | fogueiras acesas: ponto, área, tribo |
| `nativos_menu_locations` | fogueira do conselho de cada tribo |
| `nativos_storage` | cesto |
| `nativos_completed_missions` | missões feitas e a espera |
| `nativos_gang_levels` | nível e XP da tribo |
| `nativos_gang_buffs` | dons acesos e quando acabam |
| `nativos_wampum` | Wampum de cada personagem ([03-wampum.md](03-wampum.md)) |
| `nativos_viveiros`, `nativos_viveiro_aves`, `nativos_falcoaria_log` | falcoaria ([04-falcoaria.md](04-falcoaria.md)) |

As tabelas da missão de território (`nativos_territory_missions` e `nativos_territory_mission_logs`) vêm do `pantanal_nativos_missoes/territory_mission.sql`, que o dono roda no banco.
