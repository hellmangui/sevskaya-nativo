# 05 · O painel `/tribo`

O painel tem a mesma tela do grimório do Sobrenatural: um **palco fixo de 1920×1080**, escalado para qualquer tela.

| Lugar | O que mostra |
| --- | --- |
| Topo | a marca "K🔥HANI" e as abas (Q e E trocam) |
| Esquerda | nome da tribo, clã, nível, cargo de quem abriu e barra de XP, sobre o retrato. Embaixo, o **Tesouro**: Wampum branco e roxo, bolsa, terras e povo |
| Centro | o conteúdo da aba, em cartas de losango como o Índice dos Poderes |
| Direita | o detalhe do que foi escolhido: ilustração, descrição, números, campo e botões |
| Rodapé | teclas, um aviso curto e os **6 losangos das missões** (aceso = livre; apagado mostra quanto falta) |

Código: [`codigo/pantanal_nativos/html/`](codigo/pantanal_nativos/html): `index.html`, `tribo.css`, `tribo.js` e `simbolos.js` (os símbolos de traço, no mesmo desenho dos sigilos do grimório). As molduras (`img/ui/*.svg`) são as do kit do Sobrenatural, com o detalhe azul trocado por roxo.

## As abas

| Aba | O que faz | Pede ao jogo |
| --- | --- | --- |
| Conselho | emblema, lore, terras, povo, dons, nível. O chefe saca da bolsa | `withdrawGangMoney {amount}` |
| Missões | aceitar, ver a espera, liberar com Wampum, escolher a terra da Dominação | `acceptMission {missionId, params}`, `skipMissionCooldown`, `getDominationTerritories` |
| Terras | o controle de cada área em fogueiras | — |
| Dons | acender e fortalecer (só o chefe) | `purchaseBuff {buffId, level, duration}`, `pantanal_nativos:upgradeBuff {buff, level}` |
| Cesto | cesto da tribo e a bolsa da pessoa; retirar e guardar com quantidade | `openStorage`, `getPlayerInventory`, `withdrawItem`, `depositItem` |
| Viveiro | a falcoaria ([04-falcoaria.md](04-falcoaria.md)) | `viveiroDados`, `viveiroAcao {acao, id}` |
| Povo | chamar pelo ID; o chefe faz outro membro chefe ou o expulsa | `inviteMember {playerId}`, `manageMember {playerId, action}` |

## Mensagens que o painel escuta

`showUI` (com `gangData` e `config`), `hideUI`, `updateUI`, `pantanal_nativos:updateGangData`, `pantanal_nativos:gang:updateMoney`, `updateTerritories`, `updateMissions`, `updateBuffs`, `updateStorage`, `updatePlayerInventory`, `updateWampum`, `updateViveiro`, `showTerritorySelector` e `resetActiveMission`.

O `config` que vai junto com o `showUI` é montado no `ui.lua` (`ConfigParaPainel`, em [`ui_trechos_nossos.lua`](codigo/pantanal_nativos/ui_trechos_nossos.lua)): dons, recompensas de Wampum, preços para pular a espera, tempos de espera, valor do roxo e os textos de cada tribo (`Config.TribosInfo`).

Do servidor, o `gangData` traz, além do que a máfia já mandava, o `xp` e o `xpProximo` da tribo, o `rank` de quem abriu, o `wampum`, e o `fonte` (ID no servidor) de cada membro online.

## Imagens: entram sozinhas, e o painel funciona sem elas

O painel procura cada imagem em `html/img/`. Se não acha, mostra o símbolo de traço no lugar.

| Imagem | Onde aparece | Reserva |
| --- | --- | --- |
| `fundo_<tribo>.jpg`, senão `fundo_tribo.jpg` | retrato da esquerda | fundo escuro |
| `emblema_<tribo>.png` | centro da aba Conselho | `emblema_padrao.svg` (a fogueira no anel de contas) |
| `conselho.jpg` | painel da direita, aba Conselho | símbolo |
| `missao_<id>.jpg`, `dom_<id>.jpg`, `terra_<area>.jpg`, `ave_<especie>.jpg`, `ovo.jpg`, `viveiro.jpg` | painel da direita | símbolo |

O `<tribo>` e a `<area>` vão em minúsculas, sem acento e sem espaço: "Garça" vira `garca`, "Vale Wapiti" vira `valewapiti`. O pedido completo está em [06-imagens.md](06-imagens.md).

## Ver no navegador (sem o jogo)

O `html/_demo.html` abre o painel com dados de teste. Ele precisa de um servidor local:

```bash
cd codigo/pantanal_nativos/html
python -m http.server 8765
```

Depois é só abrir `http://127.0.0.1:8765/_demo.html?aba=missoes`. Valem `conselho`, `missoes`, `dominacao`, `terras`, `dons`, `cesto`, `viveiro` e `povo`. O `_demo.html` **não** vai no `fxmanifest`.

## Acrescentar uma aba

1. `index.html`: um botão em `.abas` e uma `<section data-pagina="...">` em `.conteudo`.
2. `tribo.js`: o id em `ABAS` e em `sel`, um `desenharX()` e um `painelX()`, mais a ligação nos mapas de `desenharAba` e `desenharPainel`.
3. Se a aba precisa de dados do servidor: um `RegisterNUICallback` no `ui.lua` e um `SendNUIMessage` com um `type` novo, tratado no `switch` do `tribo.js`.
