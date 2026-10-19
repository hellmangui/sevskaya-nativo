--------------------------------------------------------------------------------
-- FALCOARIA DOS NATIVOS (16/10/2026) - servidor
-- Ninho -> viveiro da tribo -> amansar -> item. Casal -> ovo -> filhote.
-- Tudo é conferido aqui: tribo, distância (posição vista pelo servidor), item, tetos.
-- A ave-item (criar, recolher, devolver) é do recurso de aves: Config.Falcoaria.RecursoAves.
--------------------------------------------------------------------------------

local VorpCore = {}
TriggerEvent("getCore", function(core) VorpCore = core end)

local F = Config.Falcoaria
local AVES = function() return exports[F.RecursoAves] end

local function Personagem(src)
    local u = VorpCore.getUser and VorpCore.getUser(src)
    return u and u.getUsedCharacter or nil
end
local function Avisar(src, texto, ok)
    TriggerClientEvent("vorp:NotifyLeft", src, "FALCOARIA", texto, "generic_textures", ok and "tick" or "menu_icon_alert", 5000, ok and "COLOR_GREEN" or "COLOR_RED")
end
local function Agora() return os.time() end
local function Dist(c, x, y, z)
    local dx, dy, dz = c.x - x, c.y - y, c.z - z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function Posicao(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local ok, h = pcall(GetEntityHeading, ped)
    return GetEntityCoords(ped), ok and h or 0.0
end
local function Tribo(src)
    local c = Personagem(src)
    if not c then return nil end
    local t = GetPlayerGangInfo(c.identifier, c.charIdentifier)
    return t, c
end
local function EspeciePorNome(nome)
    for k, e in pairs(F.Especies) do if e.nome == nome then return k, e end end
end

--------------------------------------------------------------------------------
-- tabelas
--------------------------------------------------------------------------------
CreateThread(function()
    Wait(1500)
    exports.oxmysql:executeSync([[
        CREATE TABLE IF NOT EXISTS nativos_viveiros (
            gang_id   INT NOT NULL PRIMARY KEY,
            x FLOAT NOT NULL, y FLOAT NOT NULL, z FLOAT NOT NULL,
            heading   FLOAT NOT NULL DEFAULT 0,
            criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )]])
    exports.oxmysql:executeSync([[
        CREATE TABLE IF NOT EXISTS nativos_viveiro_aves (
            id             INT AUTO_INCREMENT PRIMARY KEY,
            gang_id        INT NOT NULL,
            especie        VARCHAR(20) NOT NULL,
            sexo           CHAR(1) NOT NULL DEFAULT 'M',
            estado         VARCHAR(10) NOT NULL DEFAULT 'selvagem',
            mansidao       INT NOT NULL DEFAULT 0,
            ultima_comida  INT NOT NULL DEFAULT 0,
            pronto_em      INT NOT NULL DEFAULT 0,
            descanso_ate   INT NOT NULL DEFAULT 0,
            dono_identifier VARCHAR(64) NOT NULL,
            dono_charid    INT NOT NULL,
            ave_id         INT NULL,
            origem         VARCHAR(10) NOT NULL DEFAULT 'captura',
            criado_em      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX (gang_id)
        )]])
    exports.oxmysql:executeSync([[
        CREATE TABLE IF NOT EXISTS nativos_falcoaria_log (
            id INT AUTO_INCREMENT PRIMARY KEY,
            gang_id INT NOT NULL,
            identifier VARCHAR(64) NOT NULL,
            charid INT NOT NULL,
            acao VARCHAR(16) NOT NULL,
            especie VARCHAR(20) NULL,
            criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX (gang_id, acao), INDEX (identifier, charid, acao)
        )]])
    EnviarViveiros(-1)
end)

local function Log(gangId, c, acao, especie)
    exports.oxmysql:execute("INSERT INTO nativos_falcoaria_log (gang_id, identifier, charid, acao, especie) VALUES (?, ?, ?, ?, ?)",
        { gangId, c.identifier, c.charIdentifier, acao, especie })
end

--------------------------------------------------------------------------------
-- viveiros (props no mundo)
--------------------------------------------------------------------------------
local function Viveiro(gangId)
    local r = exports.oxmysql:executeSync("SELECT * FROM nativos_viveiros WHERE gang_id = ? LIMIT 1", { gangId })
    return r and r[1]
end

function EnviarViveiros(alvo)
    local r = exports.oxmysql:executeSync("SELECT gang_id, x, y, z, heading FROM nativos_viveiros") or {}
    TriggerClientEvent("pantanal_nativos:falcoaria:viveiros", alvo, r)
end

RegisterNetEvent("pantanal_nativos:falcoaria:pedirViveiros", function()
    EnviarViveiros(source)
end)

local function LocalConselho(gangId)
    local r = exports.oxmysql:executeSync("SELECT x, y, z FROM nativos_menu_locations WHERE gang_id = ? LIMIT 1", { gangId })
    return r and r[1]
end

-- montar o viveiro: só o chefe, perto da fogueira do conselho. Montar de novo muda de lugar.
CreateThread(function()
    Wait(2500)
    exports.vorp_inventory:registerUsableItem(F.Viveiro.Item, function(data)
        local src = data.source
        local t, c = Tribo(src)
        if not t then return Avisar(src, "Só quem é de uma tribo monta viveiro.") end
        if t.rank ~= "leader" then return Avisar(src, "Só o chefe monta o viveiro da tribo.") end
        local pos, head = Posicao(src)
        if not pos then return end
        local cons = LocalConselho(t.id)
        if not cons then return Avisar(src, "A tribo precisa marcar a fogueira do conselho antes (/tribo_conselho).") end
        if Dist(pos, cons.x, cons.y, cons.z) > F.Viveiro.DistConselho then
            return Avisar(src, ("O viveiro precisa ficar a até %d m da fogueira do conselho."):format(math.floor(F.Viveiro.DistConselho)))
        end
        exports.oxmysql:executeSync([[
            INSERT INTO nativos_viveiros (gang_id, x, y, z, heading) VALUES (?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE x = VALUES(x), y = VALUES(y), z = VALUES(z), heading = VALUES(heading)
        ]], { t.id, pos.x, pos.y, pos.z - 1.0, head or 0.0 })
        Log(t.id, c, "viveiro", nil)
        Avisar(src, "O viveiro da tribo foi montado aqui.", true)
        EnviarViveiros(-1)
    end, GetCurrentResourceName())
end)

--------------------------------------------------------------------------------
-- aves do viveiro
--------------------------------------------------------------------------------
local function ChocarOvos(gangId)
    exports.oxmysql:executeSync([[
        UPDATE nativos_viveiro_aves SET estado = 'filhote', mansidao = ?
        WHERE gang_id = ? AND estado = 'ovo' AND pronto_em <= ?
    ]], { F.Cria.MansidaoFilhote, gangId, Agora() })
end
local function AvesDaTribo(gangId)
    ChocarOvos(gangId)
    return exports.oxmysql:executeSync("SELECT * FROM nativos_viveiro_aves WHERE gang_id = ? ORDER BY id", { gangId }) or {}
end
local function AveDaTribo(gangId, aveId)
    local r = exports.oxmysql:executeSync("SELECT * FROM nativos_viveiro_aves WHERE id = ? AND gang_id = ? LIMIT 1", { tonumber(aveId) or 0, gangId })
    return r and r[1]
end
local function Lotacao(gangId)
    local r = exports.oxmysql:executeSync("SELECT COUNT(*) AS n FROM nativos_viveiro_aves WHERE gang_id = ?", { gangId })
    return r and r[1] and tonumber(r[1].n) or 0
end
local function Contar(sql, args)
    local r = exports.oxmysql:executeSync(sql, args)
    return r and r[1] and tonumber(r[1].n) or 0
end
local function CapturasHoje(c)
    return Contar("SELECT COUNT(*) AS n FROM nativos_falcoaria_log WHERE identifier = ? AND charid = ? AND acao = 'captura' AND DATE(criado_em) = CURDATE()",
        { c.identifier, c.charIdentifier })
end
local function OvosSemana(gangId)
    return Contar("SELECT COUNT(*) AS n FROM nativos_falcoaria_log WHERE gang_id = ? AND acao = 'ovo' AND criado_em >= NOW() - INTERVAL 7 DAY", { gangId })
end
local function PertoDoViveiro(src, gangId)
    local v = Viveiro(gangId)
    if not v then return false, "A tribo ainda não montou o viveiro." end
    local pos = Posicao(src)
    if not pos or Dist(pos, v.x, v.y, v.z) > F.Viveiro.DistUsar then return false, "Você precisa estar no viveiro da tribo." end
    return true
end
local function TemItem(src, nome)
    return (exports.vorp_inventory:getItemCount(src, nil, nome) or 0) > 0
end

-- o que o painel mostra
local function DadosDoViveiro(src)
    local t, c = Tribo(src)
    if not t then return { semTribo = true } end
    local v = Viveiro(t.id)
    local agora = Agora()
    local pos = Posicao(src)
    local perto = v and pos and Dist(pos, v.x, v.y, v.z) <= F.Viveiro.DistUsar or false
    local chefe = t.rank == "leader"
    local aves, comida = {}, {}
    for _, a in ipairs(AvesDaTribo(t.id)) do
        local e = F.Especies[a.especie] or {}
        if comida[a.especie] == nil then
            comida[a.especie] = false
            for _, item in ipairs(e.comida or {}) do if TemItem(src, item) then comida[a.especie] = true break end end
        end
        local minha = a.dono_identifier == c.identifier and tonumber(a.dono_charid) == tonumber(c.charIdentifier)
        aves[#aves + 1] = {
            id = a.id, especie = a.especie, nome = e.nome or a.especie, sexo = a.sexo, estado = a.estado,
            mansidao = a.mansidao, origem = a.origem, minha = minha,
            comerEm = math.max(0, (a.ultima_comida + F.Amansar.IntervaloHoras * 3600) - agora),
            prontoEm = math.max(0, a.pronto_em - agora),
            descansoEm = math.max(0, a.descanso_ate - agora),
            temComida = comida[a.especie],
            podeTirar = a.estado == "manso" and (minha or chefe or not F.TirarSoDono),
        }
    end
    local noBolso = {}
    local ok, lista = pcall(function() return AVES():AvesNoInventario(src) end)
    if ok and lista then noBolso = lista end
    return {
        existe = v ~= nil, perto = perto, chefe = chefe,
        aves = aves, max = F.Viveiro.MaxAves,
        capturasHoje = CapturasHoje(c), capturasMax = F.Captura.PorDia,
        ovosSemana = OvosSemana(t.id), ovosMax = F.Cria.PorSemana,
        noBolso = noBolso,
    }
end
local function Atualizar(src)
    TriggerClientEvent("pantanal_nativos:falcoaria:dados", src, DadosDoViveiro(src))
end
RegisterNetEvent("pantanal_nativos:falcoaria:pedirDados", function() Atualizar(source) end)

-- alimentar: amansa a selvagem/o filhote; a mansa pode soltar pena
RegisterNetEvent("pantanal_nativos:falcoaria:alimentar", function(aveId)
    local src = source
    local t, c = Tribo(src)
    if not t then return end
    local ok, motivo = PertoDoViveiro(src, t.id)
    if not ok then return Avisar(src, motivo) end
    local a = AveDaTribo(t.id, aveId)
    if not a or a.estado == "ovo" then return end
    local agora = Agora()
    if agora < a.ultima_comida + F.Amansar.IntervaloHoras * 3600 then
        return Avisar(src, "Esta ave ainda está de papo cheio.")
    end
    local e = F.Especies[a.especie]
    local usado
    for _, item in ipairs(e.comida) do
        if TemItem(src, item) then usado = item break end
    end
    if not usado then return Avisar(src, "Você não tem a comida certa para esta ave.") end
    exports.vorp_inventory:subItem(src, usado, 1)

    local era = a.estado
    local mans = a.mansidao
    local estado = a.estado
    if estado ~= "manso" then
        mans = math.min(100, mans + F.Amansar.PorComida)
        if mans >= 100 then estado = "manso" end
    end
    exports.oxmysql:executeSync("UPDATE nativos_viveiro_aves SET mansidao = ?, estado = ?, ultima_comida = ? WHERE id = ?",
        { mans, estado, agora, a.id })

    if era == "manso" and math.random(100) <= F.Amansar.ChancePena and e.pena then
        if exports.vorp_inventory:canCarryItem(src, e.pena, 1) then
            exports.vorp_inventory:addItem(src, e.pena, 1)
            Avisar(src, ("A %s soltou uma pena."):format(e.nome), true)
        end
    elseif estado == "manso" and era ~= "manso" then
        Avisar(src, ("A %s está mansa. Já pode sair do viveiro."):format(e.nome), true)
    else
        Avisar(src, ("A %s comeu. Mansidão %d%%."):format(e.nome, mans), true)
    end
    Atualizar(src)
end)

-- tirar do viveiro: vira item no inventário
RegisterNetEvent("pantanal_nativos:falcoaria:tirar", function(aveId)
    local src = source
    local t, c = Tribo(src)
    if not t then return end
    local ok, motivo = PertoDoViveiro(src, t.id)
    if not ok then return Avisar(src, motivo) end
    local a = AveDaTribo(t.id, aveId)
    if not a or a.estado ~= "manso" then return Avisar(src, "Só ave mansa sai do viveiro.") end
    local minha = a.dono_identifier == c.identifier and tonumber(a.dono_charid) == tonumber(c.charIdentifier)
    if F.TirarSoDono and not minha and t.rank ~= "leader" then return Avisar(src, "Só quem pegou esta ave (ou o chefe) a tira do viveiro.") end
    local e = F.Especies[a.especie]
    if not exports.vorp_inventory:canCarryItem(src, e.item, 1) then return Avisar(src, "Você não tem lugar na bolsa.") end

    -- apaga primeiro (ninguém tira a mesma ave duas vezes); se o item falhar, devolve a linha
    local apagou = exports.oxmysql:executeSync("DELETE FROM nativos_viveiro_aves WHERE id = ? AND estado = 'manso'", { a.id })
    local n = type(apagou) == "table" and (apagou.affectedRows or 0) or (tonumber(apagou) or 0)
    if n < 1 then return end

    local certo
    if a.ave_id then
        certo = AVES():DevolverAveItem(src, a.ave_id)
    else
        certo = AVES():CriarAveItem(src, { nome = e.nome, categoria = e.categoria, item = e.item, sexo = a.sexo, origem = a.origem }) ~= nil
    end
    if not certo then
        exports.oxmysql:executeSync([[INSERT INTO nativos_viveiro_aves (id, gang_id, especie, sexo, estado, mansidao, ultima_comida, pronto_em,
            descanso_ate, dono_identifier, dono_charid, ave_id, origem) VALUES (?, ?, ?, ?, 'manso', ?, ?, ?, ?, ?, ?, ?, ?)]],
            { a.id, a.gang_id, a.especie, a.sexo, a.mansidao, a.ultima_comida, a.pronto_em, a.descanso_ate, a.dono_identifier, a.dono_charid, a.ave_id, a.origem })
        return Avisar(src, "Não deu para tirar a ave agora.")
    end
    Log(t.id, c, "tirar", a.especie)
    Avisar(src, ("A %s saiu do viveiro com você."):format(e.nome), true)
    Atualizar(src)
end)

-- guardar no viveiro uma ave-item (para criar casal)
RegisterNetEvent("pantanal_nativos:falcoaria:guardar", function(itemId)
    local src = source
    local t, c = Tribo(src)
    if not t then return end
    local ok, motivo = PertoDoViveiro(src, t.id)
    if not ok then return Avisar(src, motivo) end
    if Lotacao(t.id) >= F.Viveiro.MaxAves then return Avisar(src, "O viveiro está cheio.") end
    local dados = AVES():RecolherAveItem(src, tonumber(itemId))
    if not dados then return Avisar(src, "Essa ave não está com você.") end
    local esp = EspeciePorNome(dados.nome)
    if not esp then
        AVES():DevolverAveItem(src, dados.aveId)
        return Avisar(src, "Essa ave não fica no viveiro dos nativos.")
    end
    exports.oxmysql:executeSync([[INSERT INTO nativos_viveiro_aves (gang_id, especie, sexo, estado, mansidao, dono_identifier, dono_charid, ave_id, origem)
        VALUES (?, ?, ?, 'manso', 100, ?, ?, ?, 'guardada')]], { t.id, esp, dados.sexo or "M", c.identifier, c.charIdentifier, dados.aveId })
    Log(t.id, c, "guardar", esp)
    Avisar(src, ("A %s ficou no viveiro."):format(dados.nome), true)
    Atualizar(src)
end)

-- juntar casal: a ave escolhida e um par manso do outro sexo, mesma espécie
RegisterNetEvent("pantanal_nativos:falcoaria:casal", function(aveId)
    local src = source
    local t, c = Tribo(src)
    if not t then return end
    local ok, motivo = PertoDoViveiro(src, t.id)
    if not ok then return Avisar(src, motivo) end
    local a = AveDaTribo(t.id, aveId)
    local agora = Agora()
    if not a or a.estado ~= "manso" then return Avisar(src, "Só aves mansas formam casal.") end
    if a.descanso_ate > agora then return Avisar(src, "Esta ave ainda está descansando da última cria.") end
    if OvosSemana(t.id) >= F.Cria.PorSemana then return Avisar(src, "A tribo já teve todos os ovos desta semana.") end
    if Lotacao(t.id) >= F.Viveiro.MaxAves then return Avisar(src, "Não cabe mais um ovo no viveiro.") end
    local par = exports.oxmysql:executeSync([[
        SELECT id FROM nativos_viveiro_aves
        WHERE gang_id = ? AND especie = ? AND sexo <> ? AND estado = 'manso' AND descanso_ate <= ? AND id <> ?
        LIMIT 1]], { t.id, a.especie, a.sexo, agora, a.id })
    par = par and par[1]
    local e = F.Especies[a.especie]
    if not par then return Avisar(src, ("Falta no viveiro um(a) %s mansa do outro sexo e descansada."):format(e.nome)) end

    local descanso = agora + F.Cria.DescansoCasal * 3600
    exports.oxmysql:executeSync("UPDATE nativos_viveiro_aves SET descanso_ate = ? WHERE id IN (?, ?)", { descanso, a.id, par.id })
    exports.oxmysql:executeSync([[INSERT INTO nativos_viveiro_aves (gang_id, especie, sexo, estado, mansidao, pronto_em, dono_identifier, dono_charid, origem)
        VALUES (?, ?, ?, 'ovo', 0, ?, ?, ?, 'cria')]],
        { t.id, a.especie, math.random(2) == 1 and "M" or "F", agora + F.Cria.HorasOvo * 3600, c.identifier, c.charIdentifier })
    Log(t.id, c, "ovo", a.especie)
    Avisar(src, ("O casal de %s botou um ovo. Choca em %dh."):format(e.nome, F.Cria.HorasOvo), true)
    Atualizar(src)
end)

-- soltar no mato (some de vez)
RegisterNetEvent("pantanal_nativos:falcoaria:soltar", function(aveId)
    local src = source
    local t, c = Tribo(src)
    if not t then return end
    local ok, motivo = PertoDoViveiro(src, t.id)
    if not ok then return Avisar(src, motivo) end
    local a = AveDaTribo(t.id, aveId)
    if not a then return end
    local minha = a.dono_identifier == c.identifier and tonumber(a.dono_charid) == tonumber(c.charIdentifier)
    if not minha and t.rank ~= "leader" then return Avisar(src, "Só quem pegou esta ave (ou o chefe) a solta.") end
    exports.oxmysql:executeSync("DELETE FROM nativos_viveiro_aves WHERE id = ?", { a.id })
    if a.ave_id then pcall(function() AVES():SoltarAve(a.ave_id) end) end
    Log(t.id, c, "soltar", a.especie)
    Avisar(src, "A ave voltou para a mata.", true)
    Atualizar(src)
end)

--------------------------------------------------------------------------------
-- captura nos ninhos
--------------------------------------------------------------------------------
local descansoNinho = {}   -- [indice] = os.time() da última tentativa
local pendente = {}        -- [src] = { ninho, especie, sucesso, expira }

local function NinhoPerto(pos)
    local melhor, idx, d0
    for i, n in ipairs(F.Ninhos) do
        local d = Dist(pos, n.x, n.y, n.z)
        if d <= F.Captura.DistNinho and (not d0 or d < d0) then melhor, idx, d0 = n, i, d end
    end
    return melhor, idx
end

local function SortearEspecie(ninho, domina)
    local lista, total = {}, 0
    local permitidas = ninho.especies
    for k, e in pairs(F.Especies) do
        local entra = true
        if permitidas then
            entra = false
            for _, p in ipairs(permitidas) do if p == k then entra = true break end end
        end
        if entra and e.rara and not domina then entra = false end
        if entra then total = total + e.peso; lista[#lista + 1] = { k, total } end
    end
    if total <= 0 then return nil end
    local r = math.random() * total
    for _, par in ipairs(lista) do if r <= par[2] then return par[1] end end
    return lista[#lista][1]
end

CreateThread(function()
    Wait(2500)
    exports.vorp_inventory:registerUsableItem(F.Captura.Item, function(data)
        local src = data.source
        if pendente[src] then return end
        local t, c = Tribo(src)
        if not t then return Avisar(src, "Só os nativos sabem prender ave de ninho.") end
        if not Viveiro(t.id) then return Avisar(src, "A tribo precisa de um viveiro para guardar a ave.") end
        if Lotacao(t.id) >= F.Viveiro.MaxAves then return Avisar(src, "O viveiro da tribo está cheio.") end
        if CapturasHoje(c) >= F.Captura.PorDia then return Avisar(src, "Você já prendeu aves que bastem hoje.") end
        local pos = Posicao(src)
        if not pos then return end
        local ninho, idx = NinhoPerto(pos)
        if not ninho then return Avisar(src, "Não há ninho aqui perto.") end
        local ultimo = descansoNinho[idx]
        if ultimo and Agora() - ultimo < F.Captura.DescansoNinho * 60 then
            return Avisar(src, "Este ninho está vazio por ora. Volte mais tarde.")
        end

        local dominio = 0
        if ninho.area then
            local terras = CalculateTerritoryDomination(t.id) or {}
            dominio = tonumber(terras[ninho.area]) or 0
        end
        local domina = dominio >= F.Captura.DominioMinimo
        local especie = SortearEspecie(ninho, domina)
        if not especie then return Avisar(src, "Nenhuma ave pousou neste ninho.") end
        local e = F.Especies[especie]
        local chance = e.chance + (domina and F.Captura.BonusDominio or 0)

        descansoNinho[idx] = Agora()
        pendente[src] = { ninho = idx, especie = especie, sucesso = math.random(100) <= chance, expira = Agora() + 30 }
        TriggerClientEvent("pantanal_nativos:falcoaria:capturar", src, {
            x = ninho.x, y = ninho.y, z = ninho.z, modelo = e.modelo, nome = e.nome, tempo = F.Captura.TempoSegurar,
        })
    end, GetCurrentResourceName())
end)

RegisterNetEvent("pantanal_nativos:falcoaria:fimCaptura", function(segurou)
    local src = source
    local p = pendente[src]
    pendente[src] = nil
    if not p or Agora() > p.expira then return end
    local t, c = Tribo(src)
    if not t then return end
    local e = F.Especies[p.especie]
    local pegou = segurou == true and p.sucesso
    if pegou then
        if not exports.vorp_inventory:subItem(src, F.Captura.Item, 1) then pegou = false end
    end
    if not pegou then
        TriggerClientEvent("pantanal_nativos:falcoaria:resultado", src, false)
        return Avisar(src, ("A %s escapou."):format(e.nome))
    end
    exports.oxmysql:executeSync([[INSERT INTO nativos_viveiro_aves (gang_id, especie, sexo, estado, mansidao, dono_identifier, dono_charid, origem)
        VALUES (?, ?, ?, 'selvagem', 0, ?, ?, 'captura')]], { t.id, p.especie, math.random(2) == 1 and "M" or "F", c.identifier, c.charIdentifier })
    Log(t.id, c, "captura", p.especie)
    if AddGangXP then pcall(AddGangXP, t.id, 10) end
    TriggerClientEvent("pantanal_nativos:falcoaria:resultado", src, true)
    Avisar(src, ("Você prendeu um(a) %s. Ela foi para o viveiro da tribo."):format(e.nome), true)
end)

AddEventHandler("playerDropped", function() pendente[source] = nil end)

--------------------------------------------------------------------------------
-- staff: /nativos_ninho <área> [especie especie ...]
--------------------------------------------------------------------------------
RegisterCommand("nativos_ninho", function(source, args)
    local src = source
    if src == 0 then return end
    local c = Personagem(src)
    if not c or not Config.StaffGroups or not Config.StaffGroups[c.group] then
        return TriggerClientEvent("chatMessage", src, "SISTEMA", { 255, 0, 0 }, "Você não tem permissão para usar este comando!")
    end
    local area = args[1] or "Área"
    local esp = {}
    for i = 2, #args do if F.Especies[args[i]] then esp[#esp + 1] = '"' .. args[i] .. '"' end end
    local pos = Posicao(src)
    if not pos then return end
    local linha = ('{ x = %.3f, y = %.3f, z = %.3f, area = "%s"%s },'):format(pos.x, pos.y, pos.z - 1.0, area,
        #esp > 0 and (", especies = { " .. table.concat(esp, ", ") .. " }") or "")
    print("^3[pantanal_nativos] ninho: " .. linha .. "^0")
    TriggerClientEvent("chat:addMessage", src, { args = { "NINHO", linha } })
end, false)
