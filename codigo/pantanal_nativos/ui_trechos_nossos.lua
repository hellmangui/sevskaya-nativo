-- Trechos do ui.lua do pantanal_nativos que são nossos (16/10/2026): ponte NUI do painel novo.
-- O resto do ui.lua (abrir/fechar, missões, cesto, membros, dons) vem do recurso base.

-- O que o painel precisa do config (preços, recompensas, textos das tribos)
local function ConfigParaPainel()
    return {
        buffs             = Config.Buffs,
        wampumRecompensas = Config.WampumRecompensas,
        pularEspera       = Config.WampumPularEspera,
        cooldowns         = Config.MissionCooldowns,
        valorRoxo         = Config.Wampum and Config.Wampum.ValorRoxo or 2,
        tribos            = Config.TribosInfo,
    }
end

-- Comando principal da Tribo: abre o conselho (perto da fogueira do conselho)
RegisterCommand('tribo', function()
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('pantanal_nativos:gang:checkMenuLocation', coords.x, coords.y, coords.z)
end)

-- Callback: pular a espera da missão pagando Wampum
RegisterNUICallback('skipMissionCooldown', function(data, cb)
    if not data or not data.missionId then
        cb({success = false})
        return
    end
    TriggerServerEvent('pantanal_nativos:gang:skipMissionCooldown', data.missionId)
    cb({success = true})
end)

-- Atualiza o Wampum no painel sem recarregar tudo
RegisterNetEvent('pantanal_nativos:gang:updateWampum')
AddEventHandler('pantanal_nativos:gang:updateWampum', function(wampum)
    if display then
        SendNUIMessage({
            type   = 'updateWampum',
            wampum = wampum
        })
    end
end)

-- Viveiro da tribo (falcoaria, 16/10/2026): o painel pede os dados e as ações; o servidor confere tudo
RegisterNUICallback('viveiroDados', function(data, cb)
    TriggerServerEvent('pantanal_nativos:falcoaria:pedirDados')
    cb('ok')
end)

local ACOES_VIVEIRO = { alimentar = true, tirar = true, guardar = true, casal = true, soltar = true }
RegisterNUICallback('viveiroAcao', function(data, cb)
    if data and ACOES_VIVEIRO[data.acao] and data.id then
        TriggerServerEvent('pantanal_nativos:falcoaria:' .. data.acao, data.id)
    end
    cb('ok')
end)

RegisterNetEvent('pantanal_nativos:falcoaria:dados')
AddEventHandler('pantanal_nativos:falcoaria:dados', function(dados)
    if display then
        SendNUIMessage({ type = 'updateViveiro', viveiro = dados })
    end
end)
