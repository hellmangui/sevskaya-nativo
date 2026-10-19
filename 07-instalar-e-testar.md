# 07 · Instalar e testar

## O que precisa estar no servidor

- RedM com **VORP** (`vorp_core` e `vorp_inventory` com suporte a dados no item, os `metadata`), **oxmysql**.
- `pantanal_nativos` e `pantanal_nativos_missoes`: o recurso base com as nossas mudanças. Ficam no servidor, **não** neste repositório.
- `Seveskaya_birds`: o recurso de aves, com o nosso `server.lua`.

## Ordem

1. **Banco.** Rodar uma vez:
   - `pantanal_nativos/nativos_itens.sql`: fogueira ritual, gaiola, viveiro e as 7 aves-item;
   - `pantanal_nativos_missoes/territory_mission.sql`: as tabelas da missão de território.
2. **Ícones** em `vorp_inventory/html/img/items/`: `fogueira_ritual.png`, mais os da falcoaria quando ficarem prontos.
3. **`server.cfg`**, nesta ordem:
   ```
   ensure Seveskaya_birds
   ensure pantanal_nativos
   ensure pantanal_nativos_missoes
   ```
4. Arquivo novo num recurso já ligado: `refresh` antes do `restart`, porque o `restart` não relê o `fxmanifest.lua`.
5. As outras tabelas (tribo, Wampum, falcoaria e as colunas novas de `seveskaya_birds`) são criadas sozinhas quando os recursos sobem.

## Preparar o mundo (staff)

1. `/nativos_settribo <seu id> Lobo`: você vira chefe de uma tribo provisória.
2. No lugar da aldeia: `/tribo_conselho` marca a fogueira do conselho.
3. Em cada ponto sagrado: `/nativos_ponto <área>`. Cole as linhas em `Config.AllowedLocations` e dê `restart`.
4. Em cada ninho: `/nativos_ninho <área> [especies]`. Cole as linhas em `Config.Falcoaria.Ninhos`.

## Roteiro de teste

Testar com **2 jogadores** de tribos diferentes, e de olho no F8 e no console.

**Domínio**
- [ ] Com o item `fogueira_ritual` perto de um ponto: o jogador agacha, e a fogueira **acende** (com fogo de verdade) e o adorno aparece atrás.
- [ ] O outro jogador, chegando, também vê a fogueira e o adorno.
- [ ] `/apagarfogueira` do rival apaga; a terra cai na aba Terras.
- [ ] Longe do ponto, ou acendendo duas vezes em 10 s, o servidor recusa.

**Painel**
- [ ] `/tribo` longe do conselho recusa; perto, abre o painel em tela cheia.
- [ ] Q e E trocam as abas; ESC fecha e devolve o controle.
- [ ] Retrato, emblema e bolsa aparecem; nome, nível, XP e cargo estão certos.
- [ ] Missões: aceitar uma; a espera aparece no losango do rodapé.
- [ ] Dons: o chefe acende e fortalece; quem não é chefe vê o botão apagado.
- [ ] Cesto: guardar e retirar um item permitido.
- [ ] Povo: chamar pelo ID; fazer outro membro chefe; expulsar.

**Wampum**
- [ ] Concluir uma missão dá Wampum (aviso e painel).
- [ ] `/nativos_darwampum <id> 3 2`, depois `/wampum`.
- [ ] Liberar a espera de uma missão: o saldo cai certo, com o troco.
- [ ] `/wampum_juntar 1` e `/wampum_soltar 1`.

**Falcoaria**
- [ ] O chefe monta o viveiro perto do conselho e os props aparecem. Longe do conselho, recusa.
- [ ] Gaiola perto do ninho: a ave aparece pousada, o jogador segura [E] e ela vai para o viveiro (ou foge).
- [ ] Aba Viveiro: alimentar até 100% (para testar rápido, baixar `IntervaloHoras` no config).
- [ ] Tirar: o item `ave_*` aparece na bolsa **com a descrição** (grau e sexo). É aqui que se confirma o `metadata`.
- [ ] Usar o item: a ave aparece e segue.
- [ ] `/aves` mostra a ave; adestrar, dar apelido (a descrição do item muda) e vender a outro jogador (o item passa de mão).
- [ ] Dar o item a outro jogador pelo inventário: no `/aves` dele, a ave aparece.
- [ ] Guardar duas aves mansas de sexos diferentes e juntar casal: aparece o ovo (para testar, baixar `HorasOvo`).
- [ ] A Botica no `/aves` aparece vazia.
- [ ] Um jogador com ave comprada antes da mudança abre o `/aves`: a ave vira item.

## Riscos conhecidos

- **Dados no item:** se o `vorp_inventory` do servidor não guardar o `metadata`, a ave-item perde o vínculo. É o primeiro teste da falcoaria.
- **Fogueira:** confirmar que o `p_campfire05x` vem aceso. Se não vier, trocar `Config.Fogueira.Base` por outra fogueira do jogo.
- **Animação:** se o `WORLD_HUMAN_CROUCH_INSPECT` não tocar, trocar em `Config.Fogueira.Cena` e em `Config.Falcoaria.Captura.Cena`.
