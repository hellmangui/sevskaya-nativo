--------------------------------------------------------------------------------
-- WAMPUM (16/10/2026)
-- Moeda dos nativos, por personagem, guardada no banco (como a Moeda Cigana da
-- máfia, que era um saldo só). Aqui são duas contas:
--   Wampum Branco (conta de concha branca)
--   Wampum Roxo   (conta de concha roxa, vale Config.Wampum.ValorRoxo brancos)
-- Preços e recompensas são dados em VALOR (em brancos). Ao pagar, gasta primeiro
-- os brancos e depois os roxos; se um roxo passar do preço, o troco volta em branco.
--------------------------------------------------------------------------------

local VorpCore = {}

TriggerEvent("getCore", function(core)
    VorpCore = core
end)

local createWampumTable = [[
    CREATE TABLE IF NOT EXISTS nativos_wampum (
        identifier     VARCHAR(50) NOT NULL,
        charidentifier INT         NOT NULL,
        branco         INT         NOT NULL DEFAULT 0,
        roxo           INT         NOT NULL DEFAULT 0,
        updated_at     DATETIME    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (identifier, charidentifier)
    )
]]

CreateThread(function()
    Wait(1000)
    exports.oxmysql:executeSync(createWampumTable)
end)

local function ValorRoxo()
    return (Config.Wampum and Config.Wampum.ValorRoxo) or 2
end

local function Personagem(source)
    local User = VorpCore.getUser and VorpCore.getUser(source)
    if not User then return nil end
    return User.getUsedCharacter
end

local function Afetadas(result)
    if type(result) == "number" then return result end
    if type(result) == "table" then return tonumber(result.affectedRows) or 0 end
    return 0
end

-- Devolve branco, roxo
function GetWampum(source)
    local Character = Personagem(source)
    if not Character then return 0, 0 end

    local result = exports.oxmysql:executeSync([[
        SELECT branco, roxo FROM nativos_wampum
        WHERE identifier = ? AND charidentifier = ?
        LIMIT 1
    ]], {Character.identifier, Character.charIdentifier})

    if result and result[1] then
        return tonumber(result[1].branco) or 0, tonumber(result[1].roxo) or 0
    end
    return 0, 0
end

-- Valor total em brancos
function GetWampumValor(source)
    local branco, roxo = GetWampum(source)
    return branco + roxo * ValorRoxo()
end

-- Saldo no formato que o painel usa
function WampumParaUI(source)
    local branco, roxo = GetWampum(source)
    return { branco = branco, roxo = roxo, valor = branco + roxo * ValorRoxo(), valorRoxo = ValorRoxo() }
end

-- Soma (ou devolve) contas. Aceita negativos só para estorno de PagarWampum.
function AddWampum(source, branco, roxo)
    branco = math.floor(tonumber(branco) or 0)
    roxo   = math.floor(tonumber(roxo) or 0)
    if branco == 0 and roxo == 0 then return false end
    local Character = Personagem(source)
    if not Character then return false end

    local result = exports.oxmysql:executeSync([[
        INSERT INTO nativos_wampum (identifier, charidentifier, branco, roxo)
        VALUES (?, ?, GREATEST(?, 0), GREATEST(?, 0))
        ON DUPLICATE KEY UPDATE
            branco = GREATEST(branco + ?, 0),
            roxo   = GREATEST(roxo + ?, 0),
            updated_at = NOW()
    ]], {Character.identifier, Character.charIdentifier, branco, roxo, branco, roxo})

    if Afetadas(result) > 0 then
        print("^2[WAMPUM] " .. branco .. " branco / " .. roxo .. " roxo -> jogador " .. source
            .. " (" .. tostring(Character.identifier) .. ")^0")
        return true
    end
    return false
end

-- Paga um valor (em brancos). Devolve ok, gastoBranco, gastoRoxo.
-- gastoBranco pode ser negativo quando houve troco. Para estornar:
-- AddWampum(source, gastoBranco, gastoRoxo).
-- O UPDATE só passa se o saldo não mudou desde a leitura (sem saldo negativo, sem gasto duplo).
function PagarWampum(source, valor)
    valor = math.floor(tonumber(valor) or 0)
    if valor <= 0 then return false, 0, 0 end
    local Character = Personagem(source)
    if not Character then return false, 0, 0 end

    local vr = ValorRoxo()
    for _ = 1, 3 do
        local branco, roxo = GetWampum(source)
        if branco + roxo * vr < valor then return false, 0, 0 end

        local gastoBranco = math.min(branco, valor)
        local falta       = valor - gastoBranco
        local gastoRoxo   = math.ceil(falta / vr)
        local troco       = gastoRoxo * vr - falta
        gastoBranco       = gastoBranco - troco

        local result = exports.oxmysql:executeSync([[
            UPDATE nativos_wampum
            SET branco = branco - ?, roxo = roxo - ?, updated_at = NOW()
            WHERE identifier = ? AND charidentifier = ? AND branco = ? AND roxo = ?
        ]], {gastoBranco, gastoRoxo, Character.identifier, Character.charIdentifier, branco, roxo})

        if Afetadas(result) > 0 then
            return true, gastoBranco, gastoRoxo
        end
        Wait(50) -- saldo mudou no meio: lê de novo
    end
    return false, 0, 0
end

exports('GetWampum',      GetWampum)
exports('GetWampumValor', GetWampumValor)
exports('AddWampum',      AddWampum)
exports('PagarWampum',    PagarWampum)

local function AtualizarPainel(source)
    TriggerClientEvent('pantanal_nativos:gang:updateWampum', source, WampumParaUI(source))
end
_G.AtualizarPainelWampum = AtualizarPainel

local function Avisar(source, titulo, texto, ok)
    TriggerClientEvent("vorp:NotifyLeft", source, titulo, texto,
        "generic_textures", ok and "tick" or "menu_icon_alert", 5000, ok and "COLOR_GREEN" or "COLOR_RED")
end

--------------------------------------------------------------------------------
-- Comandos do jogador
--   /wampum           mostra o saldo
--   /wampum_juntar N  troca N roxos novos por N*ValorRoxo brancos (enfiar o cordão)
--   /wampum_soltar N  desfaz N roxos em brancos
--------------------------------------------------------------------------------
RegisterCommand('wampum', function(source)
    if source == 0 then return end
    local branco, roxo = GetWampum(source)
    Avisar(source, "WAMPUM",
        string.format("Branco: %d · Roxo: %d (valor: %d)", branco, roxo, branco + roxo * ValorRoxo()), true)
end, false)

local function Trocar(source, args, juntar)
    if source == 0 then return end
    local Character = Personagem(source)
    if not Character then return end
    local n  = math.floor(tonumber(args[1]) or 1)
    if n <= 0 or n > 1000 then n = 1 end
    local vr = ValorRoxo()

    local result
    if juntar then
        result = exports.oxmysql:executeSync([[
            UPDATE nativos_wampum SET branco = branco - ?, roxo = roxo + ?, updated_at = NOW()
            WHERE identifier = ? AND charidentifier = ? AND branco >= ?
        ]], {n * vr, n, Character.identifier, Character.charIdentifier, n * vr})
    else
        result = exports.oxmysql:executeSync([[
            UPDATE nativos_wampum SET branco = branco + ?, roxo = roxo - ?, updated_at = NOW()
            WHERE identifier = ? AND charidentifier = ? AND roxo >= ?
        ]], {n * vr, n, Character.identifier, Character.charIdentifier, n})
    end

    if Afetadas(result) > 0 then
        if juntar then
            Avisar(source, "WAMPUM", string.format("Você enfiou %d contas brancas em %d roxa(s).", n * vr, n), true)
        else
            Avisar(source, "WAMPUM", string.format("Você soltou %d roxa(s) em %d contas brancas.", n, n * vr), true)
        end
        AtualizarPainel(source)
    else
        Avisar(source, "WAMPUM", "Você não tem contas que bastem para essa troca.", false)
    end
end

RegisterCommand('wampum_juntar', function(source, args) Trocar(source, args, true) end, false)
RegisterCommand('wampum_soltar', function(source, args) Trocar(source, args, false) end, false)

--------------------------------------------------------------------------------
-- Staff: /nativos_darwampum [id] [branco] [roxo]
-- Valores negativos tiram (sem deixar saldo negativo).
--------------------------------------------------------------------------------
RegisterCommand('nativos_darwampum', function(source, args)
    local _source = source
    if _source ~= 0 then
        local Character = Personagem(_source)
        if not Character then return end
        if not Config.StaffGroups or not Config.StaffGroups[Character.group] then
            TriggerClientEvent("chatMessage", _source, "SISTEMA", {255, 0, 0},
                "Você não tem permissão para usar este comando.")
            return
        end
    end

    local function Responder(msg, cor)
        if _source == 0 then print(msg) else TriggerClientEvent("chatMessage", _source, "SISTEMA", cor, msg) end
    end

    local targetId = tonumber(args[1])
    local branco   = math.floor(tonumber(args[2]) or 0)
    local roxo     = math.floor(tonumber(args[3]) or 0)
    if not targetId or (branco == 0 and roxo == 0) then
        Responder("Uso: /nativos_darwampum [id] [branco] [roxo]", {255, 255, 0})
        return
    end
    if not Personagem(targetId) then
        Responder("Jogador ID " .. targetId .. " não encontrado.", {255, 0, 0})
        return
    end

    if AddWampum(targetId, branco, roxo) then
        local b, r = GetWampum(targetId)
        AtualizarPainel(targetId)
        Responder(string.format("[WAMPUM] %d branco / %d roxo -> ID %d (saldo: %d branco, %d roxo)",
            branco, roxo, targetId, b, r), {0, 255, 0})
        Avisar(targetId, "WAMPUM", string.format("Os anciões mudaram seu Wampum: %+d branco, %+d roxo.", branco, roxo), true)
        print("^2[WAMPUM ADMIN] ID " .. tostring(_source) .. " deu " .. branco .. "b/" .. roxo .. "r para ID " .. targetId .. "^0")
    else
        Responder("Erro ao mudar o Wampum. Veja o console.", {255, 0, 0})
    end
end, false)
