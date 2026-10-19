-- Servidor deste recurso (nao vinha no pacote). Usa VORP direto (o cliente nao tem selecao
-- de framework) e oxmysql (o pacote pedia @mysql-async, que este servidor nao tem instalado).
--
-- 16/10/2026 (pantanal_nativos): A AVE AGORA E UM ITEM. Quem carrega o item (ave_<especie>,
-- com metadata.aveId) e o dono: dar, trocar e revender e passar o item. A linha no banco guarda
-- grau, xp, apelido e plumagem. A Botica fica fechada (Config.BoticaAberta): ave nova so nasce
-- na falcoaria dos nativos (pantanal_nativos), pelos exports la embaixo.
-- Ave comprada antes desta mudanca vira item sozinha na primeira vez que o dono abre o /aves.
local Core = exports.vorp_core:GetCore()
local resourceName = GetCurrentResourceName()

local PendingOffers = {}   -- [targetSrc] = { sellerId=, birdId=, price= }
local TrainingSessions = {} -- [src] = { birdId=, startedAt= }

local function charOf(src)
    local user = Core.getUser(src)
    local c = user and user.getUsedCharacter
    if not c or not c.charIdentifier then return nil end
    return c
end

local function tip(src, text)
    TriggerClientEvent('vorp:TipRight', src, tostring(text), 4000)
end

-- ===================== nivel/xp =====================
local function maxXpForLevel(level) return level * 100 end

-- ===================== catalogo (preco/imagem/categoria a partir do config, nao do banco) =====================
local function findConfigBird(category, name)
    local list = Config.Birds[category]
    if not list then return nil end
    for _, entry in ipairs(list) do
        if entry.name == name then return entry end
    end
end

local function rowToClient(row)
    local cfg = findConfigBird(row.category, row.name) or {}
    return {
        id = row.id,
        name = row.name,
        type = row.category,
        level = row.level,
        xp = row.xp .. ' / ' .. maxXpForLevel(row.level),
        nickname = row.nickname,
        outfit = row.outfit,
        price = cfg.price or 0,
        image = cfg.image or '',
    }
end

CreateThread(function()
    local ok, err = pcall(function()
        MySQL.query.await([[CREATE TABLE IF NOT EXISTS seveskaya_birds (
            id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(64) NOT NULL,
            charidentifier INT NOT NULL,
            category VARCHAR(32) NOT NULL,
            name VARCHAR(64) NOT NULL,
            nickname VARCHAR(64) NOT NULL DEFAULT '(no name)',
            outfit INT NOT NULL DEFAULT 0,
            level INT NOT NULL DEFAULT 1,
            xp INT NOT NULL DEFAULT 0,
            last_trained BIGINT NOT NULL DEFAULT 0,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX (identifier, charidentifier)
        )]])
        -- ave como item (16/10/2026)
        MySQL.query.await("ALTER TABLE seveskaya_birds ADD COLUMN IF NOT EXISTS sexo CHAR(1) NOT NULL DEFAULT 'M'")
        MySQL.query.await("ALTER TABLE seveskaya_birds ADD COLUMN IF NOT EXISTS origem VARCHAR(10) NOT NULL DEFAULT 'botica'")
        MySQL.query.await("ALTER TABLE seveskaya_birds ADD COLUMN IF NOT EXISTS item_dado TINYINT NOT NULL DEFAULT 0")
    end)
    if not ok then print('[Seveskaya_birds] FALHA ao criar a tabela: ' .. tostring(err)) end
    print('[Seveskaya_birds] servidor pronto.')
end)

-- ===================== AVE COMO ITEM =====================
local ITEM_DA_AVE, E_ITEM_DE_AVE = {}, {}
for nome, item in pairs(Config.AveItem or {}) do
    ITEM_DA_AVE[nome] = item
    E_ITEM_DE_AVE[item] = true
end
local function Inv() return exports.vorp_inventory end

-- [aveId] = item do inventario (com .id e .metadata)
local function itensDeAve(src)
    local r = {}
    local ok, lista = pcall(function() return Inv():getUserInventoryItems(src) end)
    if not ok or type(lista) ~= 'table' then return r end
    for _, it in pairs(lista) do
        local meta = type(it.metadata) == 'table' and it.metadata or nil
        if it.name and E_ITEM_DE_AVE[it.name] and meta and tonumber(meta.aveId) then
            r[tonumber(meta.aveId)] = it
        end
    end
    return r
end
local function possui(src, birdId) return itensDeAve(src)[tonumber(birdId) or -1] end

local function descricaoDe(row)
    local partes = { 'Grau ' .. (row.level or 1), (row.sexo == 'F') and 'fêmea' or 'macho' }
    if row.nickname and row.nickname ~= '(no name)' and row.nickname ~= '(sem nome)' then table.insert(partes, 1, row.nickname) end
    return table.concat(partes, ' · ')
end
local function metaDe(row)
    return { aveId = row.id, sexo = row.sexo or 'M', grau = row.level or 1, description = descricaoDe(row) }
end
local function darItem(src, row)
    local item = ITEM_DA_AVE[row.name]
    if not item then return false end
    if not Inv():canCarryItem(src, item, 1) then return false end
    return Inv():addItem(src, item, 1, metaDe(row)) and true or false
end
-- mantem a descricao do item (grau, apelido) em dia
local function atualizarItem(src, row)
    local it = possui(src, row.id)
    if it then pcall(function() Inv():setItemMetadata(src, it.id, metaDe(row), 1) end) end
end
local function tornarDono(src, birdId)
    local c = charOf(src)
    if c then
        MySQL.update.await('UPDATE seveskaya_birds SET identifier = ?, charidentifier = ? WHERE id = ?',
            { c.identifier, c.charIdentifier, birdId })
    end
end
local function linha(birdId)
    return MySQL.single.await('SELECT * FROM seveskaya_birds WHERE id = ?', { tonumber(birdId) or -1 })
end

local function loadBirds(src, cb)
    local c = charOf(src)
    if not c then cb({}); return end

    -- aves de antes do item (compradas na Botica): viram item uma vez, se couber na bolsa
    local antigas = MySQL.query.await('SELECT * FROM seveskaya_birds WHERE identifier = ? AND charidentifier = ? AND item_dado = 0',
        { c.identifier, c.charIdentifier }) or {}
    for _, row in ipairs(antigas) do
        if darItem(src, row) then
            MySQL.update.await('UPDATE seveskaya_birds SET item_dado = 1 WHERE id = ?', { row.id })
        end
    end

    local ids = {}
    for id in pairs(itensDeAve(src)) do ids[#ids + 1] = id end
    if #ids == 0 then cb({}); return end
    local marcas = string.rep('?,', #ids):sub(1, -2)
    local rows = MySQL.query.await('SELECT * FROM seveskaya_birds WHERE id IN (' .. marcas .. ')', ids) or {}
    local list = {}
    for _, row in ipairs(rows) do list[#list + 1] = rowToClient(row) end
    cb(list)
end

local function recarregar(src)
    loadBirds(src, function(list)
        TriggerClientEvent('dodi_birds:receivePlayerBirds', src, list)
        TriggerClientEvent('dodi_birds:receiveBirdData', src, list)
    end)
end

RegisterNetEvent('dodi_birds:fetchPlayerBirds', function()
    local src = source
    loadBirds(src, function(list) TriggerClientEvent('dodi_birds:receivePlayerBirds', src, list) end)
end)

RegisterNetEvent('dodi_birds:fetchBirdData', function()
    local src = source
    loadBirds(src, function(list) TriggerClientEvent('dodi_birds:receiveBirdData', src, list) end)
end)

-- usar o item chama a ave
CreateThread(function()
    Wait(2000)
    for item in pairs(E_ITEM_DE_AVE) do
        Inv():registerUsableItem(item, function(data)
            local src = data.source
            local meta = data.item and data.item.metadata or {}
            local row = linha(meta.aveId)
            if not row then return tip(src, Config.Locale.birdNotFound) end
            tornarDono(src, row.id)
            pcall(function() Inv():closeInventory(src) end)
            TriggerClientEvent('dodi_birds:spawnBird', src, rowToClient(row))
        end, resourceName)
    end
end)

-- ===================== comprar (Botica) =====================
RegisterNetEvent('dodi_birds:saveBird', function(bird)
    local src = source
    local c = charOf(src)
    if not c or type(bird) ~= 'table' then return end
    if not Config.BoticaAberta then
        tip(src, Config.Locale.boticaFechada or 'A Botica de Aves está fechada.')
        return
    end
    local cfg = findConfigBird(bird.type, bird.name)
    if not cfg then tip(src, Config.Locale.birdNotFound); return end

    if (c.money or 0) < cfg.price then
        tip(src, Config.Locale.insufficientMoney)
        return
    end
    local item = ITEM_DA_AVE[bird.name]
    if not item or not Inv():canCarryItem(src, item, 1) then
        tip(src, string.format(Config.Locale.errorMessage, 'não cabe na bolsa'))
        return
    end
    c.removeCurrency(0, cfg.price)

    local outfit = tonumber(bird.outfit) or 0
    local id = MySQL.insert.await(
        'INSERT INTO seveskaya_birds (identifier, charidentifier, category, name, nickname, outfit, item_dado) VALUES (?, ?, ?, ?, ?, ?, 1)',
        { c.identifier, c.charIdentifier, bird.type, bird.name, '(sem nome)', outfit })
    darItem(src, linha(id))

    tip(src, string.format(Config.Locale.birdBoughtSuccess, cfg.price))
    recarregar(src)
end)

-- Atualiza so o outfit (nunca nivel/xp, que so o servidor calcula)
RegisterNetEvent('dodi_birds:updateBird', function(bird)
    local src = source
    if type(bird) ~= 'table' or not bird.id or not possui(src, bird.id) then return end
    local outfit = tonumber(bird.outfit)
    if not outfit then return end
    MySQL.update.await('UPDATE seveskaya_birds SET outfit = ? WHERE id = ?', { outfit, tonumber(bird.id) })
    loadBirds(src, function(list) TriggerClientEvent('dodi_birds:receivePlayerBirds', src, list) end)
end)

RegisterNetEvent('dodi_birds:updateBirdName', function(birdId, nickname)
    local src = source
    if not possui(src, birdId) then return end
    nickname = tostring(nickname or '(sem nome)'):sub(1, 60):gsub('%z', '')
    MySQL.update.await('UPDATE seveskaya_birds SET nickname = ? WHERE id = ?', { nickname, tonumber(birdId) })
    local row = linha(birdId)
    if row then atualizarItem(src, row) end
    loadBirds(src, function(list) TriggerClientEvent('dodi_birds:receivePlayerBirds', src, list) end)
end)

-- ===================== soltar (o "vender de volta" do pacote) =====================
RegisterNetEvent('dodi_birds:sellBirdToSystem', function(birdId)
    local src = source
    local c = charOf(src)
    if not c then return end
    local it = possui(src, birdId)
    local row = it and linha(birdId)
    if not row then tip(src, Config.Locale.birdNotFoundOrNotYours); return end
    if not Inv():subItemById(src, it.id) then tip(src, Config.Locale.birdSoldFail); return end

    local cfg = findConfigBird(row.category, row.name) or {}
    local refund = math.floor((cfg.price or 0) * (Config.SellBackPercentage or 0) / 100)
    MySQL.update.await('DELETE FROM seveskaya_birds WHERE id = ?', { row.id })

    if refund > 0 then
        c.addCurrency(0, refund)
        tip(src, string.format(Config.Locale.birdSoldSuccess, refund))
    else
        tip(src, Config.Locale.birdSoldFlewAway) -- SellBackPercentage = 0: e soltar, nao vender
    end
    TriggerClientEvent('dodi_birds:checkAndRemoveBird', src, row.id)
    recarregar(src)
end)

-- ===================== negociar com outro jogador (o item passa de mão) =====================
RegisterNetEvent('dodi_birds:offerBirdToPlayer', function(targetId, birdId, price)
    local src = source
    local c = charOf(src)
    targetId, birdId, price = tonumber(targetId), tonumber(birdId), tonumber(price)
    if not c or not targetId or not birdId or not price or price <= 0 then return end
    if targetId == src or not GetPlayerName(targetId) then
        tip(src, Config.Locale.targetPlayerNotFound)
        return
    end
    if not possui(src, birdId) then tip(src, Config.Locale.birdNotFoundOrNotYours); return end

    PendingOffers[targetId] = { sellerId = src, birdId = birdId, price = price }
    local row = linha(birdId)
    TriggerClientEvent('dodi_birds:receiveBirdOffer', targetId, src, birdId, row and rowToClient(row), price)
    tip(src, Config.Locale.offerSent)
end)

RegisterNetEvent('dodi_birds:acceptBirdOffer', function(sellerId, birdId, price)
    local src = source
    local c = charOf(src)
    sellerId, birdId, price = tonumber(sellerId), tonumber(birdId), tonumber(price)
    local offer = PendingOffers[src]
    if not c or not offer or offer.sellerId ~= sellerId or offer.birdId ~= birdId or offer.price ~= price then
        tip(src, Config.Locale.invalidOfferData)
        return
    end

    -- so consome a oferta quando a compra realmente da certo; sem dinheiro, o comprador pode tentar de novo
    if (c.money or 0) < price then
        tip(src, Config.Locale.buyerNoMoney)
        TriggerClientEvent('vorp:TipRight', sellerId, Config.Locale.buyerNoMoney, 4000)
        return
    end
    local sellerChar = charOf(sellerId)
    if not sellerChar then tip(src, Config.Locale.sellerNotFound); return end

    local it = possui(sellerId, birdId)
    local row = it and linha(birdId)
    if not row then tip(src, Config.Locale.birdNotFoundOrNotOwned); return end
    if not Inv():canCarryItem(src, ITEM_DA_AVE[row.name] or '', 1) then
        tip(src, string.format(Config.Locale.errorMessage, 'não cabe na sua bolsa'))
        return
    end
    PendingOffers[src] = nil

    -- o item sai do vendedor e entra no comprador; só então o dinheiro passa
    if not Inv():subItemById(sellerId, it.id) then tip(src, Config.Locale.transferFailed); return end
    if not darItem(src, row) then
        darItem(sellerId, row)
        tip(src, Config.Locale.transferFailed)
        return
    end
    c.removeCurrency(0, price)
    sellerChar.addCurrency(0, price)
    tornarDono(src, row.id)

    tip(src, string.format(Config.Locale.birdBoughtSuccess, price))
    TriggerClientEvent('vorp:TipRight', sellerId, string.format(Config.Locale.birdSoldSuccess, price), 4000)
    TriggerClientEvent('dodi_birds:checkAndRemoveBird', sellerId, row.id)
    recarregar(src)
    recarregar(sellerId)
end)

RegisterNetEvent('dodi_birds:declineBirdOffer', function(sellerId)
    local src = source
    sellerId = tonumber(sellerId)
    local offer = PendingOffers[src]
    PendingOffers[src] = nil
    if offer and offer.sellerId == sellerId then
        tip(sellerId, Config.Locale.yourOfferDeclined)
    end
end)

-- ===================== treino (o cliente decide o ganho, o servidor confere e trava os limites) ===
RegisterNetEvent('dodi_birds:startTrainingSession', function(birdId)
    local src = source
    birdId = tonumber(birdId)
    if not birdId or TrainingSessions[src] or not possui(src, birdId) then return end

    local row = MySQL.single.await('SELECT id, last_trained FROM seveskaya_birds WHERE id = ?', { birdId })
    if not row then return end

    local now = os.time() * 1000
    if now - (row.last_trained or 0) < Config.TrainingCooldownMs then
        TriggerClientEvent('dodi_birds:trainingNotification', src, '', 'cooldown')
        return
    end

    TrainingSessions[src] = { birdId = birdId, startedAt = now }
end)

RegisterNetEvent('dodi_birds:gainXP', function(birdId, amount)
    local src = source
    birdId, amount = tonumber(birdId), tonumber(amount)
    local session = TrainingSessions[src]
    if not session or session.birdId ~= birdId or not amount then return end
    amount = math.max(1, math.min(amount, Config.MaxXpPerTraining))

    local row = MySQL.single.await('SELECT * FROM seveskaya_birds WHERE id = ?', { birdId })
    if not row then return end

    local level, xp = row.level, row.xp + amount
    local leveled = false
    while xp >= maxXpForLevel(level) do
        xp = xp - maxXpForLevel(level)
        level = level + 1
        leveled = true
    end
    MySQL.update.await('UPDATE seveskaya_birds SET level = ?, xp = ? WHERE id = ?', { level, xp, birdId })

    TriggerClientEvent('dodi_birds:xpNotification', src, 'adestramento', amount)
    if leveled then
        TriggerClientEvent('dodi_birds:levelUpNotification', src, 'Sua ave', level)
        row.level = level
        atualizarItem(src, row)
    end
end)

RegisterNetEvent('dodi_birds:giveItem', function(itemName, count)
    local src = source
    local session = TrainingSessions[src]
    if not session or type(itemName) ~= 'string' then return end
    count = math.max(1, math.min(tonumber(count) or 1, 5))

    -- so aceita itens que estejam configurados como recompensa em alguma zona de treino
    local label
    for _, zone in ipairs(Config.TrainingZones) do
        for _, bonus in pairs(zone.bonuses or {}) do
            for _, reward in ipairs(bonus.itemRewards or {}) do
                if reward.name == itemName then label = reward.label; break end
            end
        end
    end
    if not label then return end

    if Inv():canCarryItem(src, itemName, count) then
        Inv():addItem(src, itemName, count)
        TriggerClientEvent('dodi_birds:itemNotification', src, label)
    end
end)

RegisterNetEvent('dodi_birds:endTrainingSession', function()
    local src = source
    local session = TrainingSessions[src]
    TrainingSessions[src] = nil
    if not session then return end
    MySQL.update.await('UPDATE seveskaya_birds SET last_trained = ? WHERE id = ?', { os.time() * 1000, session.birdId })
    TriggerClientEvent('dodi_birds:trainingNotification', src, '', 'complete')
end)

AddEventHandler('playerDropped', function()
    local src = source
    TrainingSessions[src] = nil
    PendingOffers[src] = nil
end)

-- ===================== EXPORTS para a falcoaria dos nativos (pantanal_nativos) =====================
-- Ave nova: cria a linha e entrega o item. Devolve o aveId, ou nil se não coube na bolsa.
exports('CriarAveItem', function(src, dados)
    local c = charOf(src)
    if not c or type(dados) ~= 'table' or not ITEM_DA_AVE[dados.nome] then return nil end
    if not Inv():canCarryItem(src, ITEM_DA_AVE[dados.nome], 1) then return nil end
    local id = MySQL.insert.await(
        'INSERT INTO seveskaya_birds (identifier, charidentifier, category, name, nickname, outfit, sexo, origem, item_dado) VALUES (?, ?, ?, ?, ?, 0, ?, ?, 1)',
        { c.identifier, c.charIdentifier, dados.categoria, dados.nome, '(sem nome)', dados.sexo == 'F' and 'F' or 'M', tostring(dados.origem or 'captura'):sub(1, 10) })
    if not id then return nil end
    if not darItem(src, linha(id)) then
        MySQL.update.await('DELETE FROM seveskaya_birds WHERE id = ?', { id })
        return nil
    end
    return id
end)

-- Tira a ave-item da bolsa (para o viveiro). Devolve { aveId, nome, sexo, apelido } ou nil.
exports('RecolherAveItem', function(src, itemId)
    itemId = tonumber(itemId)
    for aveId, it in pairs(itensDeAve(src)) do
        if it.id == itemId then
            local row = linha(aveId)
            if not row then return nil end
            if not Inv():subItemById(src, it.id) then return nil end
            TriggerClientEvent('dodi_birds:checkAndRemoveBird', src, aveId)
            return { aveId = aveId, nome = row.name, sexo = row.sexo, apelido = row.nickname }
        end
    end
    return nil
end)

-- Devolve à bolsa uma ave que já existe (saindo do viveiro).
exports('DevolverAveItem', function(src, aveId)
    local row = linha(aveId)
    if not row or not darItem(src, row) then return false end
    tornarDono(src, row.id)
    return true
end)

-- Aves-item que a pessoa carrega: { itemId, aveId, nome, apelido, grau, sexo }
exports('AvesNoInventario', function(src)
    local r = {}
    for aveId, it in pairs(itensDeAve(src)) do
        local row = linha(aveId)
        if row then
            r[#r + 1] = { itemId = it.id, aveId = aveId, nome = row.name, apelido = row.nickname, grau = row.level, sexo = row.sexo }
        end
    end
    return r
end)

-- A ave foi solta de vez (some do banco).
exports('SoltarAve', function(aveId)
    MySQL.update.await('DELETE FROM seveskaya_birds WHERE id = ?', { tonumber(aveId) or -1 })
    return true
end)
