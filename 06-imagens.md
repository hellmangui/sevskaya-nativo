# 06 · Imagens

> **Já prontas (19/10/2026):** `fundo_tribo.jpg`, `emblema_lobo.png`, `conselho.jpg` e o ícone `fogueira_ritual.png`. Estão em `codigo/pantanal_nativos/html/img/` (o ícone fica no `vorp_inventory` do servidor).

# Pedido de imagens: Conselho da Tribo

16/10/2026. O painel `/tribo` já funciona **sem** nenhuma destas imagens: onde falta imagem, aparece o símbolo de traço (como no grimório antes da arte). Cada imagem que você colocar em `pantanal_nativos/html/img/` com o nome exato entra sozinha. Não precisa mexer no código.

## Direção visual

- A mesma linha do Sobrenatural: pintura realista e escura, luz de fogueira quente, noite ou fim de tarde, fundo que some no preto.
- O toque dos nativos é o roxo do wampum (conchas brancas e roxas). Use-o pouco, num detalhe.
- Nada de texto dentro das imagens.
- Os nativos são os **Kohani**, a confederação do Rei do Gelo, com a cura Mbaraeté. Gente séria e digna, sem caricatura e sem cocar de filme.
- Os nomes de arquivo vão em minúsculas e sem acento: "Garça" vira `garca`.

## 1. Retrato da esquerda (prioridade 1)

O retrato fica atrás da ficha, como o caçador na tela do Mago. O rosto precisa estar no **terço esquerdo** da imagem. Do meio para a direita, deixe escuro e vazio: o painel escurece essa parte.

| Arquivo | Tamanho | O que mostra |
| --- | --- | --- |
| `fundo_tribo.jpg` | 1920×1080 (ou 1536×1024) | o padrão de todas as tribos: um ancião Kohani de perfil, à luz de uma fogueira, com um cinto de wampum no ombro e o pântano escuro ao fundo |
| `fundo_<tribo>.jpg` | igual | um por tribo (opcional): o guerreiro ou o chefe daquela tribo. Hoje as tribos são `lobo`, `urso`, `garca` e `corvo`; quando você mandar a lista certa, valem os nomes novos |

## 2. Emblema de cada tribo (prioridade 1)

Aparece grande e redondo no centro da aba Conselho. Sem ele, o painel usa o emblema padrão: a fogueira dentro do anel de contas.

| Arquivo | Tamanho | O que mostra |
| --- | --- | --- |
| `emblema_<tribo>.png` | 512×512, PNG **com fundo transparente**, redondo | o selo da tribo: um anel de contas de wampum (brancas e roxas) em volta do animal ou do símbolo da tribo, em traço dourado sobre um disco escuro |

## 3. Ilustrações das missões (EM ESPERA)

> **16/10/2026: em espera.** As missões dos nativos ainda não foram definidas. Não criar estas imagens agora; a lista abaixo fica só como referência e muda quando as missões novas forem decididas. Sem elas, o painel mostra o símbolo de cada missão.

<!-- em espera até definir as missões dos nativos
Aparecem no painel da direita quando se escolhe a missão. Elas são quadradas e as bordas se dissolvem no escuro, como as ilustrações dos poderes.

| Arquivo | Tamanho | O que mostra |
| --- | --- | --- |
| `missao_daily_1.jpg` | 768×768 | **Bois:** guerreiros a cavalo levando o gado tomado dos colonos, de noite |
| `missao_daily_2.jpg` | 768×768 | **Postes:** um poste do telégrafo dos colonos tombando, com o fio cortado no chão |
| `missao_daily_3.jpg` | 768×768 | **Carroça:** emboscada a uma carroça na estrada de terra, com a lanterna caída |
| `missao_special_1.jpg` | 768×768 | **Dominação:** a fogueira ritual acesa num ponto sagrado, com uma estaca de crânio ao lado |
| `missao_special_2.jpg` | 768×768 | **Piratas:** canoas cercando um barco no rio, com flechas no casco |
| `missao_special_3.jpg` | 768×768 | **Extorsão:** um comerciante entregando a bolsa a um guerreiro na porta da loja |

Ainda são as missões da máfia com outro nome. Se elas forem trocadas por missões dos nativos, as ilustrações mudam junto.
-->


## 4. Ilustrações dos dons (prioridade 2)

| Arquivo | Tamanho | O que mostra |
| --- | --- | --- |
| `dom_pickpocket.jpg` | 768×768 | **Tributo da Mata:** uma mão saindo da mata e tirando a bolsa da cintura de um viajante |
| `dom_npc_allies.jpg` | 768×768 | **Guerreiros da Tribo:** três guerreiros com arco saindo da neblina |
| `dom_territory.jpg` | 768×768 | **Olhos dos Batedores:** um batedor no alto de uma pedra olhando o vale, com fogueiras distantes |
| `dom_resistance.jpg` | 768×768 | **Força dos Ancestrais:** a pintura de guerra no rosto e espíritos de ancestrais na fumaça |

## 5. Painel do Conselho e terras (prioridade 3)

| Arquivo | Tamanho | O que mostra |
| --- | --- | --- |
| `conselho.jpg` | 768×768 | cintos de wampum e uma bolsa de couro sobre uma pele, à luz do fogo (é a imagem da Bolsa da Tribo) |
| `terra_<area>.jpg` | 768×768 | opcional, uma por área dos pontos sagrados (a área é o nome que a staff dá no `/nativos_ponto`, ex. `terra_valewapiti.jpg`) |

## 6. Ícone do item (prioridade 1, vai no inventário)

| Arquivo | Onde | Tamanho | O que mostra |
| --- | --- | --- | --- |
| `fogueira_ritual.png` | `vorp_inventory/html/img/items/` | 96×96, PNG transparente | um feixe de lenha amarrado com ervas, uma pena e uma pederneira |

## 7. Falcoaria (16/10/2026)

### Ícones de item (prioridade 1, vão no inventário)
Todos em `vorp_inventory/html/img/items/`, 96×96, PNG transparente, no estilo dos ícones do RDR2.

| Arquivo | O que mostra |
| --- | --- |
| `gaiola_falcoeiro.png` | gaiola de vime com alça de couro e uma pena presa |
| `viveiro_tribo.png` | trouxa de varas, palha e uma gaiola pequena amarrada |
| `ave_aguia.png` | cabeça de águia de perfil |
| `ave_gaviao.png` | cabeça de gavião de perfil |
| `ave_garca.png` | cabeça e pescoço de garça-azul |
| `ave_pelicano.png` | cabeça de pelicano branco com o bico |
| `ave_corvo.png` | corvo pousado |
| `ave_urubu.png` | cabeça de urubu |
| `ave_arara.png` | cabeça de arara-vermelha |

### Ilustrações do painel (prioridade 2, aba Viveiro)
Todas em `pantanal_nativos/html/img/`, 768×768, JPG, no mesmo estilo da imagem da bolsa.

| Arquivo | O que mostra |
| --- | --- |
| `viveiro.jpg` | o viveiro da tribo à noite: gaiolas de vime, poleiros, ninho de palha, luz de fogueira |
| `ave_aguia.jpg` | águia pousada no braço enluvado de couro de um falcoeiro nativo |
| `ave_gaviao.jpg` | gavião num poleiro de madeira com penas de wampum amarradas |
| `ave_garca.jpg` | garça-azul em pé na água rasa do pântano ao entardecer |
| `ave_pelicano.jpg` | pelicano branco num tronco caído na beira do rio |
| `ave_corvo.jpg` | corvo numa estaca com crânio, olhando para a câmera |
| `ave_urubu.jpg` | urubu de asas abertas num galho seco |
| `ave_arara.jpg` | arara-vermelha num galho, cores fortes no meio do escuro |
| `ovo.jpg` | um ovo num ninho de palha e penas, iluminado pela fogueira |

## Resumo do que dá para ver já

- Sem nenhuma imagem: o painel inteiro funciona, com os símbolos de traço.
- Com só `fundo_tribo.jpg` e um `emblema_<tribo>.png`: a tela já fica igual à do grimório com retrato.
- O resto entra aos poucos, na ordem de prioridade.
