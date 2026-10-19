# 08 · Passagem para o dev

## Onde está cada coisa

| Lugar | O que tem |
| --- | --- |
| servidor: `resources/.../pantanal_nativos/` | o recurso inteiro (base mais as nossas mudanças) |
| servidor: `resources/.../pantanal_nativos_missoes/` | as missões (ainda as da máfia) |
| servidor: `resources/.../Seveskaya_birds/` | o recurso de aves, com o nosso `server.lua` |
| este repositório | documentação e o código que é nosso |
| `sevskaya/sistema-sobrenatural` | o modelo do painel (grimório) e das regras de vida, dano e morte |

Arquivos do `pantanal_nativos` por papel:

| Arquivo | Papel | Nosso? |
| --- | --- | --- |
| `config.lua` | pontos, mensagens, fogueira, Wampum, tribos | trechos (`config_trechos_nossos.lua`) |
| `config_buffs.lua` | dons, nível, guerreiros | base, com nomes e modelos trocados |
| `config_falcoaria.lua` | falcoaria | sim |
| `server.lua` | tribos, fogueiras, conselho, missões, cesto, XP e o `gangData` do painel | base, com mudanças |
| `server_buffs.lua` | dons | base |
| `server_wampum.lua` | Wampum | sim |
| `server_falcoaria.lua` | falcoaria | sim |
| `client.lua` | fogueira (acender e apagar props), detector, blips | base, com a fogueira nova |
| `commands.lua` | `/apagarfogueira`, `/tribo_conselho` | base, com mudanças |
| `client_falcoaria.lua` | cenário do viveiro e captura | sim |
| `ui.lua` | ponte com o painel | base mais trechos (`ui_trechos_nossos.lua`) |
| `html/` | o painel | sim |

## Regras que não se quebram

- **O servidor decide.** Posição, distância, item, dono, saldo e tetos são conferidos no servidor. O cliente só desenha e pede.
- **Dinheiro e Wampum** saem com um UPDATE que não deixa saldo negativo. Quando a ação depois do débito falha, o estorno devolve exatamente o que saiu.
- **Tudo que dá item ou moeda é torneira:** precisa de teto (por dia ou por semana) antes de entrar.
- **Props e peds de cenário são locais** (cada cliente cria os seus). NPC de rede em massa já derrubou jogadores em outro recurso.
- **Ped criado precisa de roupa** (`0x283978A15512B2FE`, a variação aleatória), senão nasce invisível.
- **Comando restrito vai no servidor.** `RegisterCommand(..., true)` no cliente bloqueia calado.
- **`restart` não relê o `fxmanifest.lua`:** com arquivo novo, `refresh` antes.
- **Lua 5.4.** Função `local` declarada depois do handler não é vista por ele.
- **NPC não usa arma de fogo:** os guerreiros têm arco.
- **O ilegal não vaza:** nada de blip ou aviso da terra de uma tribo para quem não é dela.
- **Textos** em português antigo e simples, sem citar a staff.

## Nomes que não podem mudar sem mudar junto

- `Config.Falcoaria.Especies[...].nome` precisa ser **igual** ao `name` do `Config.Birds` e às chaves de `Config.AveItem` (recurso de aves).
- `Config.Falcoaria.RecursoAves` precisa ser o nome **da pasta** do recurso de aves no servidor.
- O nome da área dos ninhos precisa ser igual ao nome da área dos pontos sagrados, para valer o domínio.

## Como acrescentar

- **Espécie de ave:** uma linha em `Config.Falcoaria.Especies`, a entrada no `Config.Birds` e no `Config.AveItem` (recurso de aves), e o item no SQL.
- **Dom:** uma entrada em `Config.Buffs` (no recurso base), o símbolo em `SIMBOLO_DOM` e a ordem em `ORDEM_DONS` (no `tribo.js`).
- **Fonte de Wampum:** chamar `AddWampum(src, branco, roxo)` no servidor, com teto.
- **Aba no painel:** ver o fim do [05-painel.md](05-painel.md).

## Testar sem o jogo

- `luac -p` (ou o Lua 5.4) em todos os `.lua`.
- O painel em `html/_demo.html` ([05-painel.md](05-painel.md)).
