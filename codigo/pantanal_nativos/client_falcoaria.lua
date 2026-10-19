--------------------------------------------------------------------------------
-- FALCOARIA DOS NATIVOS (16/10/2026) - cliente
-- Desenha o cenário dos viveiros (props locais, como as fogueiras) e roda a captura no ninho:
-- a ave aparece pousada só para quem tenta, o jogador agacha e segura [E]. Quem decide é o servidor.
--------------------------------------------------------------------------------

local F = Config.Falcoaria
local viveiros = {}      -- lista vinda do servidor
local criados = {}       -- [gang_id] = { props }

local function Carregar(nome)
    local h = GetHashKey(nome)
    if not IsModelInCdimage(h) then return nil end
    RequestModel(h)
    local limite = GetGameTimer() + 5000
    while not HasModelLoaded(h) and GetGameTimer() < limite do Wait(10) end
    return HasModelLoaded(h) and h or nil
end

local function ApagarViveiro(id)
    for _, p in ipairs(criados[id] or {}) do if DoesEntityExist(p) then DeleteEntity(p) end end
    criados[id] = nil
end

local function MontarViveiro(v)
    local props = {}
    local rad = math.rad(v.heading or 0.0)
    local cs, sn = math.cos(rad), math.sin(rad)
    for _, d in ipairs(F.Viveiro.Props) do
        local h = Carregar(d.modelo)
        if h then
            -- gira o deslocamento pela direção do viveiro
            local x = v.x + d.x * cs - d.y * sn
            local y = v.y + d.x * sn + d.y * cs
            local o = CreateObject(h, x, y, v.z + (d.z or 0.0), false, false, false)
            SetEntityHeading(o, (v.heading or 0.0) + (d.h or 0.0))
            PlaceObjectOnGroundProperly(o)
            FreezeEntityPosition(o, true)
            props[#props + 1] = o
            SetModelAsNoLongerNeeded(h)
        end
    end
    criados[v.gang_id] = props
end

RegisterNetEvent("pantanal_nativos:falcoaria:viveiros", function(lista)
    for id in pairs(criados) do ApagarViveiro(id) end
    viveiros = lista or {}
end)

CreateThread(function()
    Wait(3000)
    TriggerServerEvent("pantanal_nativos:falcoaria:pedirViveiros")
    while true do
        local pos = GetEntityCoords(PlayerPedId())
        for _, v in ipairs(viveiros) do
            local d = #(pos - vector3(v.x, v.y, v.z))
            if d <= F.Viveiro.DistVer and not criados[v.gang_id] then
                MontarViveiro(v)
            elseif d > F.Viveiro.DistVer + 20.0 and criados[v.gang_id] then
                ApagarViveiro(v.gang_id)
            end
        end
        Wait(3000)
    end
end)

AddEventHandler("onResourceStop", function(r)
    if r ~= GetCurrentResourceName() then return end
    for id in pairs(criados) do ApagarViveiro(id) end
end)

--------------------------------------------------------------------------------
-- captura
--------------------------------------------------------------------------------
local aveNoNinho = nil
local capturando = false
local TECLA_E = 0xCEFD9220

local function Texto(x, y, txt)
    SetTextScale(0.42, 0.42)
    SetTextColor(231, 220, 195, 255)
    SetTextCentre(true)
    DisplayText(CreateVarString(10, "LITERAL_STRING", txt), x, y)
end

RegisterNetEvent("pantanal_nativos:falcoaria:capturar", function(d)
    if capturando then return end
    capturando = true
    local ped = PlayerPedId()

    -- a ave pousada no ninho (só neste cliente)
    local h = Carregar(d.modelo)
    if h then
        aveNoNinho = CreatePed(h, d.x, d.y, d.z + 0.3, math.random(0, 359) + 0.0, false, false, false, false)
        Citizen.InvokeNative(0x283978A15512B2FE, aveNoNinho, true) -- roupa aleatória (sem isso o ped some)
        PlaceEntityOnGroundProperly(aveNoNinho)
        SetBlockingOfNonTemporaryEvents(aveNoNinho, true)
        FreezeEntityPosition(aveNoNinho, true)
        SetModelAsNoLongerNeeded(h)
    end

    TaskTurnPedToFaceCoord(ped, d.x, d.y, d.z, 800)
    Wait(800)
    TaskStartScenarioInPlace(ped, GetHashKey(F.Captura.Cena), -1, true, false, false, false)

    -- minijogo: segurar [E] até encher, sem soltar
    local inicio, cheio, soltou, comecou = nil, 0, false, false
    local limite = GetGameTimer() + d.tempo + 8000
    while GetGameTimer() < limite do
        Wait(0)
        DrawRect(0.5, 0.88, 0.22, 0.018, 0, 0, 0, 170)
        DrawRect(0.5 - 0.11 + 0.11 * cheio, 0.88, 0.22 * cheio, 0.012, 185, 140, 210, 230)
        Texto(0.5, 0.83, comecou and ("Segure [E]: a " .. d.nome .. " não pode perceber") or ("Segure [E] para prender a " .. d.nome))
        if IsControlPressed(0, TECLA_E) then
            if not comecou then comecou = true inicio = GetGameTimer() end
            cheio = math.min(1.0, (GetGameTimer() - inicio) / d.tempo)
            if cheio >= 1.0 then break end
        elseif comecou then
            soltou = true
            break
        end
    end
    ClearPedTasks(ped)
    TriggerServerEvent("pantanal_nativos:falcoaria:fimCaptura", comecou and not soltou and cheio >= 1.0)
end)

RegisterNetEvent("pantanal_nativos:falcoaria:resultado", function(pegou)
    local ave = aveNoNinho
    aveNoNinho = nil
    capturando = false
    if not ave or not DoesEntityExist(ave) then return end
    if pegou then
        DeleteEntity(ave)
        -- a gaiola na mão por uns segundos
        local ped = PlayerPedId()
        local h = Carregar("p_birdcage01x")
        if h then
            local g = CreateObject(h, GetEntityCoords(ped), true, true, false)
            AttachEntityToEntity(g, ped, GetPedBoneIndex(ped, 4126), 0.5, 0.0, -0.4, 0.22, -50.0, 0.0, true, true, false, false, 2, true)
            SetTimeout(5000, function() if DoesEntityExist(g) then DeleteEntity(g) end end)
        end
    else
        FreezeEntityPosition(ave, false)
        local p = GetEntityCoords(ave)
        TaskFlyToCoord(ave, 1.0, p.x + math.random(-60, 60), p.y + math.random(-60, 60), p.z + 40.0, 1, 1)
        SetTimeout(8000, function() if DoesEntityExist(ave) then DeleteEntity(ave) end end)
    end
end)

AddEventHandler("onResourceStop", function(r)
    if r == GetCurrentResourceName() and aveNoNinho and DoesEntityExist(aveNoNinho) then DeleteEntity(aveNoNinho) end
end)
