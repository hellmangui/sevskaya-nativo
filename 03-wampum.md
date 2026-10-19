# 03 · Wampum

A moeda dos nativos, por **personagem**. Ela funciona como a Moeda Cigana da máfia (um saldo no banco, não um item), mas com duas contas.

| Conta | Valor |
| --- | --- |
| Wampum branco | 1 |
| Wampum roxo | `Config.Wampum.ValorRoxo` brancos (hoje 2) |

Código: [`codigo/pantanal_nativos/server_wampum.lua`](codigo/pantanal_nativos/server_wampum.lua). Configuração: [`config_trechos_nossos.lua`](codigo/pantanal_nativos/config_trechos_nossos.lua).

## Onde se ganha

Ao concluir uma missão, o personagem recebe o que está em `Config.WampumRecompensas`:

| Missão | Branco | Roxo |
| --- | --- | --- |
| Bois (`daily_1`) | 1 | 0 |
| Postes (`daily_2`) | 1 | 0 |
| Carroça (`daily_3`) | 2 | 0 |
| Dominação (`special_1`) | 1 | 2 |
| Piratas (`special_2`) | 1 | 1 |
| Extorsão (`special_3`) | 2 | 0 |

## Onde se gasta

**Liberar a espera de uma missão** (`Config.WampumPularEspera`). O preço é dado em **valor de brancos**:

| Missão | Preço |
| --- | --- |
| Bois, Postes | 2 |
| Carroça, Extorsão | 3 |
| Piratas | 4 |
| Dominação | 5 |

## Como o pagamento funciona

1. O preço é em valor de brancos.
2. Gasta primeiro os brancos e depois os roxos.
3. Se um roxo passar do preço, o **troco volta em branco**. Exemplo: com 1 branco e 2 roxos, um preço de 4 gasta 1 branco e 2 roxos e devolve 1 branco.
4. O débito é **um único UPDATE** que só passa se o saldo não mudou desde a leitura (`WHERE branco = ? AND roxo = ?`). Assim não fica saldo negativo nem gasto em dobro. Se o saldo mudou no meio, o servidor lê de novo (até 3 vezes).
5. Se a ação depois do débito falhar (por exemplo, liberar a missão), o Wampum é devolvido exatamente como saiu.

## Comandos

| Quem | Comando | O que faz |
| --- | --- | --- |
| Jogador | `/wampum` | mostra o saldo |
| Jogador | `/wampum_juntar N` | troca `N × ValorRoxo` brancos por `N` roxos (enfiar o cordão) |
| Jogador | `/wampum_soltar N` | troca `N` roxos por `N × ValorRoxo` brancos |
| Staff | `/nativos_darwampum id branco roxo` | dá ou tira (com valor negativo; nunca fica abaixo de zero) |

## No painel

- A coluna da esquerda mostra Wampum branco e Wampum roxo.
- A aba Conselho mostra o valor total.
- Na aba Missões, o botão **Liberar · N Wampum** só acende se o valor total alcançar o preço.
- O servidor manda o saldo novo pelo evento `pantanal_nativos:gang:updateWampum`.

## Exports (servidor)

```lua
local branco, roxo = exports.pantanal_nativos:GetWampum(src)
local valor = exports.pantanal_nativos:GetWampumValor(src)                  -- branco + roxo * ValorRoxo
exports.pantanal_nativos:AddWampum(src, branco, roxo)                      -- aceita negativo (sem passar de zero)
local ok, gastoB, gastoR = exports.pantanal_nativos:PagarWampum(src, valor) -- para estornar: AddWampum(src, gastoB, gastoR)
```

## Tabela

```sql
nativos_wampum (identifier, charidentifier, branco, roxo, updated_at)  -- chave: identifier + charidentifier
```

## Cuidado com a economia

Toda recompensa que dá Wampum é uma **torneira**. Antes de criar uma fonte nova, defina um teto por dia ou por semana.
