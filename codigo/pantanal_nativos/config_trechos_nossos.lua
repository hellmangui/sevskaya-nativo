-- Trechos do config.lua do pantanal_nativos que são nossos (16/10/2026).
-- O resto do config.lua vem do recurso base (Dodiban, gang system) e não está neste repositório.

-- FOGUEIRA RITUAL (16/10/2026): no lugar do grafite da máfia, a tribo acende uma fogueira no ponto.
-- O que aparece no chão: a fogueira (Base, igual para todas) + o adorno da tribo (coluna graffiti_model
-- da tabela nativos_gangs; é o 2º argumento de /nativos_criartribo). Os dois são props do próprio jogo.
Config.Fogueira = {
    Base            = "p_campfire05x",          -- fogueira acesa (o medicalman conta como fonte de calor)
    DistanciaAdorno = 0.9,                      -- m atrás da fogueira onde fica o adorno da tribo
    Cena            = "WORLD_HUMAN_CROUCH_INSPECT", -- o jogador agacha para acender e para apagar
    TempoAcender    = 12000,                    -- ms
    TempoApagar     = 8000,                     -- ms
    RivalApaga      = true,                     -- true: rival (e qualquer um) apaga a fogueira com /apagarfogueira
}

-- Adornos sugeridos (props do RDR2) para o /nativos_criartribo:
--   p_skullpost02x (estaca com crânio)   p_skullelk01x (crânio de alce)   p_skullram01x (crânio de carneiro)
--   p_skullcattle02x (crânio de boi)     p_disdreamcatcherwind01x (apanhador de sonhos)

-- PONTOS SAGRADOS: onde a tribo pode acender a fogueira (1 fogueira por ponto).
-- Começa VAZIO: os pontos da tribo eram em Saint Denis e no pântano. Para marcar um ponto novo, a staff
-- fica no lugar, de frente para onde a fogueira deve olhar, e usa /nativos_ponto <área>: a linha pronta
-- sai no F8 e no console do servidor; é só colar aqui.
Config.AllowedLocations = {
    -- {x = 0.0, y = 0.0, z = 0.0, heading = 0.0, area = "Nome da Área"},
}

-- WAMPUM (16/10/2026): moeda dos nativos, por personagem (server_wampum.lua)
-- Duas contas: Branco e Roxo. Um Roxo vale ValorRoxo brancos (na história, a concha roxa valia o dobro).
-- Jogador: /wampum (saldo), /wampum_juntar N (brancos -> roxo), /wampum_soltar N (roxo -> brancos)
-- Staff:   /nativos_darwampum [id] [branco] [roxo]
Config.Wampum = {
    ValorRoxo = 2,
}

-- Preço em Wampum (VALOR em brancos) para liberar a espera de cada missão (por tribo).
-- Paga com brancos primeiro, depois roxos (com troco em branco). enabled = false desliga.
Config.WampumPularEspera = {
    enabled = true,
    costs = {
        daily_1   = 2,   -- Bois
        daily_2   = 2,   -- Postes
        daily_3   = 3,   -- Carroça
        special_1 = 5,   -- Dominação
        special_2 = 4,   -- Piratas
        special_3 = 3,   -- Extorsão
    }
}

-- Wampum ganho por personagem ao concluir cada missão
Config.WampumRecompensas = {
    daily_1   = { branco = 1, roxo = 0 },   -- Bois
    daily_2   = { branco = 1, roxo = 0 },   -- Postes
    daily_3   = { branco = 2, roxo = 0 },   -- Carroça
    special_1 = { branco = 1, roxo = 2 },   -- Dominação
    special_2 = { branco = 1, roxo = 1 },   -- Piratas
    special_3 = { branco = 2, roxo = 0 },   -- Extorsão
}

-- TRIBOS PROVISÓRIAS (16/10/2026): o dono vai mandar a lista certa.
-- Entram sozinhas no banco ao subir o recurso (INSERT IGNORE: não duplica nem apaga as que já existem).
-- Nome sem espaço (os comandos de staff leem uma palavra só). adorno = prop do jogo ao lado da fogueira.
-- Trocar a lista aqui NÃO renomeia tribo já criada: para renomear, mudar no banco (nativos_gangs).
Config.TribosProvisorias = {
    { nome = "Lobo",  adorno = "p_skullpost02x" },
    { nome = "Urso",  adorno = "p_skullelk01x" },
    { nome = "Garca", adorno = "p_disdreamcatcherwind01x" },
    { nome = "Corvo", adorno = "p_skullram01x" },
}

-- Textos de cada tribo no painel (aba Conselho). Chave = nome da tribo no banco.
-- titulo: linha embaixo do nome; lore: o parágrafo do conselho. Tribo fora da lista usa o Padrao.
-- Imagens (opcionais) em html/img/: fundo_<nome>.jpg (retrato da esquerda) e emblema_<nome>.png.
-- <nome> em minúsculas e sem acento, ex. "Garca" -> fundo_garca.jpg
Config.TribosInfo = {
    Padrao = {
        titulo = "Confederação Kohani",
        lore   = "O interior do Pantanal nunca pertenceu aos impérios. A fogueira acesa diz de quem é a terra, e o wampum guarda a palavra dada.",
    },
    Lobo  = { titulo = "Clã do Lobo",  lore = "Caçam juntos e não deixam ninguém para trás. Onde o Lobo acende a fogueira, a estrada fecha." },
    Urso  = { titulo = "Clã do Urso",  lore = "Guardiões das ervas e da cura Mbaraeté. Lentos para a guerra, impossíveis de derrubar." },
    Garca = { titulo = "Clã da Garça", lore = "Gente das águas e das canoas. Conhecem cada braço de rio que o colono ainda não mapeou." },
    Corvo = { titulo = "Clã do Corvo", lore = "Olhos da confederação. Sabem o que se diz nas cidades antes que o xerife saiba." },
}
