-- FALCOARIA DOS NATIVOS (16/10/2026)
-- Só nativo (membro de tribo) captura, cria e amansa ave. A ave pronta vira ITEM (ave_<especie>)
-- e aí circula livre: qualquer um usa, dá, troca ou revende. O voo, o seguir e o adestramento
-- continuam no recurso de aves (Seveskaya_birds), que é o "corpo" da ave.
--
-- Ciclo: ninho (captura com a gaiola) -> viveiro da tribo (selvagem) -> alimentar até amansar
--        -> tirar do viveiro = item. Cria: casal manso no viveiro -> ovo -> filhote -> amansar -> item.

Config.Falcoaria = {
    -- nome da pasta do recurso de aves no servidor (é quem cria a ave-item e a chama no céu)
    RecursoAves = "Seveskaya_birds",

    -- ===================== ESPÉCIES =====================
    -- chave = id interno. nome/categoria TÊM de ser iguais ao Config.Birds do recurso de aves.
    -- modelo: só para a ave aparecer pousada no ninho durante a captura.
    -- comida: itens que amansam (qualquer um da lista serve). pena: item que a ave pode soltar ao comer.
    -- peso: chance relativa de aparecer no ninho. rara = só aparece em ninho de terra dominada pela tribo.
    Especies = {
        aguia    = { modelo = "a_c_eagle_01", nome = "Águia",          categoria = "Hunting",   item = "ave_aguia",    comida = { "meat", "game", "animal_rat" }, pena = "eaglef",           peso = 2,  rara = true,  chance = 25 },
        gaviao   = { modelo = "a_c_hawk_01", nome = "Gavião",         categoria = "Hunting",   item = "ave_gaviao",   comida = { "meat", "bird", "animal_rat" }, pena = "hawkf",            peso = 3,  rara = true,  chance = 30 },
        garca    = { modelo = "a_c_heron_01", nome = "Garça",          categoria = "Fishing",   item = "ave_garca",    comida = { "fish", "fishmeat", "bait" },   pena = "kbirdf",           peso = 6,  rara = false, chance = 45 },
        pelicano = { modelo = "a_c_pelican_01", nome = "Pelicano",       categoria = "Fishing",   item = "ave_pelicano", comida = { "fish", "fishmeat" },           pena = "pelicanf",         peso = 5,  rara = false, chance = 45 },
        corvo    = { modelo = "a_c_crow_01", nome = "Corvo",          categoria = "Scavenger", item = "ave_corvo",    comida = { "stringy", "meat", "bait" },    pena = "ravenf",           peso = 8,  rara = false, chance = 60 },
        urubu    = { modelo = "a_c_vulture_01", nome = "Urubu",          categoria = "Scavenger", item = "ave_urubu",    comida = { "stringy", "meat" },            pena = "pena_ave_selvagem", peso = 8, rara = false, chance = 60 },
        arara    = { modelo = "a_c_parrot_01", nome = "Arara-vermelha", categoria = "Companion", item = "ave_arara",    comida = { "bait" },                       pena = "bparrotf",         peso = 2,  rara = true,  chance = 30 },
    },

    -- ===================== CAPTURA (NINHOS) =====================
    Captura = {
        Item          = "gaiola_falcoeiro", -- Gaiola de Falcoeiro. Gasta 1 quando a ave é presa.
                                            -- (dá para trocar pelo "cage" do servidor se nenhum outro recurso usar esse item)
        DistNinho     = 3.0,      -- m do jogador ao ninho para tentar
        TempoSegurar  = 6000,     -- ms segurando [E] no minijogo
        DescansoNinho = 45,       -- min que o ninho fica vazio depois de uma tentativa (de qualquer um)
        PorDia        = 3,        -- capturas certas por jogador por dia
        DominioMinimo = 50,       -- % da área que a tribo precisa dominar para aparecerem as raras
        BonusDominio  = 15,       -- + pontos na chance quando a tribo domina a área do ninho
        Cena          = "WORLD_HUMAN_CROUCH_INSPECT",
    },

    -- Ninhos: começa VAZIO. Staff: /nativos_ninho <área> marca um ninho onde está (a linha sai no F8 e no console).
    -- area = mesmo nome de área dos pontos sagrados (para valer o domínio da tribo).
    -- especies = quais podem aparecer (ids acima). Sem lista = todas.
    Ninhos = {
        -- { x = 0.0, y = 0.0, z = 0.0, area = "Nome da Área", especies = { "garca", "pelicano" } },
    },

    -- ===================== VIVEIRO DA TRIBO =====================
    Viveiro = {
        Item            = "viveiro_tribo",  -- o chefe usa para montar (1 por tribo; montar de novo muda de lugar)
        MaxAves         = 8,                -- aves dentro (selvagens, mansas, ovos e filhotes)
        DistConselho    = 40.0,             -- m máximo da fogueira do conselho da tribo
        DistUsar        = 40.0,             -- m do viveiro para alimentar/tirar/juntar casal
        DistVer         = 120.0,            -- m para os props aparecerem
        -- cenário com props do jogo (posição relativa ao centro e à direção do viveiro)
        Props = {
            { modelo = "p_wildanimalcage01",     x =  0.0, y =  0.0, z = 0.0, h =   0.0 },
            { modelo = "p_birdcage01x",          x =  1.8, y =  0.6, z = 0.0, h =  20.0 },
            { modelo = "p_birdcage01x",          x = -1.8, y =  0.6, z = 0.0, h = -15.0 },
            { modelo = "p_mp_shadybirdcage01x",  x =  1.6, y = -1.2, z = 0.0, h =  90.0 },
            { modelo = "p_nestfeather06x",       x = -1.4, y = -1.0, z = 0.0, h =   0.0 },
            { modelo = "p_feedtroughsml01x",     x =  0.0, y = -1.9, z = 0.0, h =   0.0 },
        },
    },

    -- ===================== AMANSAR =====================
    Amansar = {
        PorComida      = 20,   -- pontos de mansidão por refeição (100 = mansa)
        IntervaloHoras = 4,    -- tempo mínimo entre duas refeições da mesma ave
        ChancePena     = 25,   -- % de a ave soltar uma pena ao comer (só mansas)
    },

    -- ===================== CRIA =====================
    Cria = {
        HorasOvo        = 12,  -- do casal ao ovo virar filhote
        DescansoCasal   = 48,  -- h que o casal descansa depois de botar
        MansidaoFilhote = 60,  -- filhote já nasce meio manso
        PorSemana       = 4,   -- ovos por tribo por semana
    },

    -- quem pode tirar a ave pronta do viveiro: quem capturou/criou, ou o chefe
    TirarSoDono = true,
}
