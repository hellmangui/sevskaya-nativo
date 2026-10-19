// Conselho da Tribo (pantanal_nativos), 16/10/2026.
// Mesma tela do grimório do Sobrenatural; as funções são as do domínio (missões, terras,
// dons, cesto, povo, bolsa, Wampum). Só desenha e pede: quem confere tudo é o servidor.
(function () {
    const $ = (id) => document.getElementById(id);
    const raiz = $('grimorio');
    const palco = $('palco');
    const ABAS = ['conselho', 'missoes', 'terras', 'dons', 'cesto', 'viveiro', 'povo'];

    // símbolo de cada missão e de cada dom (o resto do painel lê do servidor)
    const SIMBOLO_MISSAO = { daily_1: 'boi', daily_2: 'poste', daily_3: 'carroca', special_1: 'totem', special_2: 'canoa', special_3: 'punho' };
    const SIMBOLO_DOM = { pickpocket: 'mao', npc_allies: 'arco', territory: 'olho', resistance: 'escudo' };
    const ORDEM_DONS = ['pickpocket', 'npc_allies', 'territory', 'resistance'];
    const CARGO = { leader: 'Chefe', member: 'Guerreiro' };

    let dados = null;          // gangData do servidor
    let cfg = {};              // config que o ui.lua manda (dons, recompensas, textos)
    let aba = 'conselho';
    const sel = { missoes: null, terras: null, dons: null, cesto: null, viveiro: null, povo: null };
    let missaoAtiva = null;    // missão aceita nesta abertura
    let travaAceitar = false;
    let escolhaTerra = null;   // lista de terras da missão de Dominação (quando aberta)
    let terraEscolhida = null;
    let cesto = [], bolsa = [];
    let viveiro = null;        // dados do viveiro (falcoaria), pedidos ao abrir a aba

    // ===================== utilidades =====================
    function recurso() { return (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'pantanal_nativos'; }
    function pedir(nome, corpo) {
        return fetch('https://' + recurso() + '/' + nome, {
            method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(corpo || {}),
        }).catch(function () {});
    }
    function el(tag, classe, texto) {
        const e = document.createElement(tag);
        if (classe) e.className = classe;
        if (texto !== undefined) e.textContent = texto;
        return e;
    }
    function simbolo(e, id) { Simbolos.desenhar(e, id); }
    function slug(t) { return String(t || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, ''); }
    function dinheiro(v) { return '$' + Number(v || 0).toLocaleString('pt-BR'); }
    function tempo(min) {
        min = Math.max(0, Math.round(Number(min) || 0));
        const h = Math.floor(min / 60), m = min % 60;
        return h > 0 ? (h + 'h' + (m ? String(m).padStart(2, '0') : '')) : (m + 'min');
    }
    function souChefe() { return dados && dados.rank === 'leader'; }
    function wampum() { return (dados && dados.wampum) || { branco: 0, roxo: 0, valor: 0, valorRoxo: cfg.valorRoxo || 2 }; }
    function infoTribo() {
        const t = cfg.tribos || {};
        const nome = dados ? dados.name : '';
        return Object.assign({}, t.Padrao || {}, t[nome] || {});
    }
    // imagem opcional: carrega se existir, senão chama reserva()
    function imagem(src, ok, reserva) {
        const i = new Image();
        i.onload = function () { ok(src); };
        i.onerror = function () { if (reserva) reserva(); };
        i.src = src;
    }
    let avisoTempo = null;
    function aviso(txt) {
        const a = $('gAviso');
        a.textContent = txt;
        a.classList.add('visivel');
        clearTimeout(avisoTempo);
        avisoTempo = setTimeout(function () { a.classList.remove('visivel'); }, 3200);
    }

    // ===================== escala do palco =====================
    function escalar() {
        const s = Math.min(window.innerWidth / 1920, window.innerHeight / 1080);
        palco.style.transform = 'scale(' + s + ') translate(-50%, -50%)';
        palco.style.setProperty('--s', s);
        palco.classList.toggle('tela-pequena', s < 0.85);
    }
    window.addEventListener('resize', escalar);
    escalar();

    // ===================== abas =====================
    function mostrarAba(nova) {
        aba = nova;
        document.querySelectorAll('.abas button').forEach(function (b) { b.classList.toggle('ativa', b.dataset.aba === aba); });
        document.querySelectorAll('.conteudo section').forEach(function (s) { s.classList.toggle('ativa', s.dataset.pagina === aba); });
        if (aba === 'cesto') { pedir('openStorage'); pedir('getPlayerInventory'); }
        if (aba === 'viveiro') pedir('viveiroDados');
        desenharAba();
    }
    document.querySelectorAll('.abas button').forEach(function (b) {
        b.addEventListener('click', function () { mostrarAba(b.dataset.aba); });
    });

    // ===================== números derivados =====================
    function terrasMedia() {
        const t = (dados && dados.territories) || {};
        const v = Object.values(t);
        if (!v.length) return 0;
        return Math.round(v.reduce(function (a, b) { return a + (Number(b) || 0); }, 0) / v.length);
    }
    function pontosDaArea(area) {
        return ((dados && dados.allowedLocations) || []).filter(function (l) { return l.area === area; }).length;
    }
    function domAtivo(id) {
        const b = ((dados && dados.buffs) || []).find(function (x) { return x.id === id; });
        if (!b || !b.level) return null;
        const resta = b.expiration ? (Number(b.expiration) - Date.now()) : 0;
        return { level: b.level, ativo: resta > 0, restaMin: Math.max(0, Math.floor(resta / 60000)) };
    }
    function missoes() { return (dados && dados.missions) || []; }
    function estadoMissao(m) {
        if (missaoAtiva === m.id || m.active) return 'ativa';
        if (m.completed && m.inCooldown) return 'espera';
        if (m.completed) return 'feita';
        return 'livre';
    }

    // ===================== ficha e conselho =====================
    function desenharFicha() {
        if (!dados) return;
        const info = infoTribo();
        const w = wampum();
        const pct = dados.xpProximo > 0 ? Math.min(100, (dados.xp / dados.xpProximo) * 100) : 0;
        const xpTxt = dados.xpProximo > 0 ? ((dados.xp || 0) + ' / ' + dados.xpProximo + ' XP') : '';
        const online = (dados.members || []).filter(function (m) { return m.online; }).length;
        const povo = (dados.members || []).length;

        $('gNome').textContent = dados.name || '';
        $('gTitulo').textContent = info.titulo || '';
        $('gNivel').textContent = dados.level || 1;
        $('gCargo').textContent = CARGO[dados.rank] || dados.rank || '';
        $('gXpBarra').style.width = pct + '%';
        $('gXp').textContent = xpTxt;
        $('gBranco').textContent = w.branco || 0;
        $('gRoxo').textContent = w.roxo || 0;
        $('gBolsa').textContent = dinheiro(dados.money);
        $('gTerras').textContent = terrasMedia() + '%';
        $('gPovo').textContent = online + ' / ' + povo;

        // retrato da tribo (fundo_<tribo>.jpg, senão fundo_tribo.jpg)
        const s = slug(dados.name);
        imagem('img/fundo_' + s + '.jpg', function (src) { $('gFundo').style.backgroundImage = 'url(' + src + ')'; }, function () {
            imagem('img/fundo_tribo.jpg', function (src) { $('gFundo').style.backgroundImage = 'url(' + src + ')'; }, function () { $('gFundo').style.backgroundImage = ''; });
        });

        // conselho
        $('cNome').textContent = dados.name || '';
        $('cTitulo').textContent = info.titulo || '';
        $('cLore').textContent = info.lore || '';
        $('cTerras').textContent = terrasMedia() + '%';
        $('cPovo').textContent = online + ' / ' + povo;
        $('cDons').textContent = ORDEM_DONS.filter(function (id) { const d = domAtivo(id); return d && d.ativo; }).length;
        $('cMissoes').textContent = missoes().filter(function (m) { return estadoMissao(m) === 'livre'; }).length;
        $('cNivel').textContent = dados.level || 1;
        $('cXpBarra').style.width = pct + '%';
        $('cXp').textContent = xpTxt;
        const emb = $('cEmblema');
        imagem('img/emblema_' + s + '.png', function (src) { emb.style.backgroundImage = 'url(' + src + ')'; }, function () {
            emb.style.backgroundImage = 'url(img/emblema_padrao.svg)';
        });
        document.querySelectorAll('[data-simbolo]').forEach(function (i) { if (!i.firstChild) simbolo(i, i.dataset.simbolo); });
        desenharSelos();
    }

    // ===================== rodapé: as 6 missões =====================
    function desenharSelos() {
        const caixa = $('rSelos');
        caixa.innerHTML = '';
        missoes().slice(0, 6).forEach(function (m, i) {
            const est = estadoMissao(m);
            const s = el('div', 'selo-rodape' + (est === 'livre' || est === 'ativa' ? ' cheio' : ''));
            s.tabIndex = 0;
            s.title = m.title + (est === 'espera' ? ' · volta em ' + tempo(m.cooldownRemaining) : '');
            const l = el('div', 'losango-selo');
            const d = el('i', 'dentro');
            simbolo(d, SIMBOLO_MISSAO[m.id] || 'trilha');
            l.appendChild(d);
            s.appendChild(l);
            s.appendChild(el('i', 'n', est === 'espera' ? tempo(m.cooldownRemaining) : String(i + 1)));
            s.addEventListener('click', function () { sel.missoes = m.id; escolhaTerra = null; mostrarAba('missoes'); });
            caixa.appendChild(s);
        });
    }

    // ===================== carta genérica =====================
    function carta(opc) {
        const c = el('div', 'carta' + (opc.classe ? ' ' + opc.classe : '') + (opc.sel ? ' sel' : ''));
        c.tabIndex = 0;
        const l = el('div', 'losango-selo');
        if (opc.pct !== undefined) {
            l.appendChild(el('span', 'pct', opc.pct + '%'));
        } else {
            const d = el('i', 'dentro');
            simbolo(d, opc.simbolo);
            l.appendChild(d);
        }
        c.appendChild(l);
        c.appendChild(el('b', '', opc.nome));
        if (opc.sub) c.appendChild(el('small', opc.subClasse || '', opc.sub));
        if (opc.barra !== undefined) {
            const b = el('div', 'barra'); const f = el('div'); f.style.width = opc.barra + '%'; b.appendChild(f); c.appendChild(b);
        }
        c.addEventListener('click', opc.ao);
        c.addEventListener('keydown', function (e) { if (e.key === 'Enter') opc.ao(); });
        return c;
    }
    function grupo(caixa, titulo) { caixa.appendChild(el('div', 'grupo-titulo', titulo)); const g = el('div', 'cartas'); caixa.appendChild(g); return g; }

    // ===================== MISSÕES =====================
    function desenharMissoes() {
        const caixa = $('mLista');
        caixa.innerHTML = '';
        if (escolhaTerra) {
            $('mTituloLista').textContent = 'Escolha a Terra';
            $('mSubLista').textContent = 'Dominação · a tribo vai tomar a terra escolhida';
            const g = grupo(caixa, 'Terras em disputa');
            escolhaTerra.forEach(function (t) {
                const dono = t.owner && t.owner !== 'none' ? t.owner : null;
                g.appendChild(carta({
                    simbolo: 'totem', nome: t.name, sel: terraEscolhida === t.name,
                    classe: t.canAttack ? '' : 'trancada',
                    sub: !t.canAttack ? 'Sua tribo' : (dono ? 'De ' + dono : 'Livre'), subClasse: t.canAttack && !dono ? 'livre' : '',
                    ao: function () { if (!t.canAttack) return aviso('Esta terra já é da sua tribo.'); terraEscolhida = t.name; desenharAba(); },
                }));
            });
            return;
        }
        $('mTituloLista').textContent = 'Trilhas do Dia';
        $('mSubLista').textContent = 'Escolha a trilha · a espera de cada uma vale para a tribo inteira';
        const lista = missoes();
        if (!lista.length) { caixa.appendChild(el('div', 'vazio-texto', 'Nenhuma trilha aberta agora.')); return; }
        [['Diárias', false], ['Especiais', true]].forEach(function (par) {
            const doGrupo = lista.filter(function (m) { return !!m.isSpecial === par[1]; });
            if (!doGrupo.length) return;
            const g = grupo(caixa, par[0]);
            doGrupo.forEach(function (m) {
                const est = estadoMissao(m);
                if (!sel.missoes) sel.missoes = m.id;
                g.appendChild(carta({
                    simbolo: SIMBOLO_MISSAO[m.id] || 'trilha', nome: m.title, sel: sel.missoes === m.id,
                    classe: est === 'livre' || est === 'ativa' ? '' : 'apagada',
                    sub: est === 'livre' ? 'Livre' : est === 'ativa' ? 'Em curso' : est === 'espera' ? 'Volta em ' + tempo(m.cooldownRemaining) : 'Feita',
                    subClasse: est === 'livre' || est === 'ativa' ? 'livre' : 'espera',
                    ao: function () { sel.missoes = m.id; desenharAba(); },
                }));
            });
        });
    }
    function painelMissao() {
        if (escolhaTerra) {
            const t = escolhaTerra.find(function (x) { return x.name === terraEscolhida; });
            return {
                rotulo: 'Dominação · escolha a terra', nome: t ? t.name : 'Escolha a terra', ilustracao: 'img/missao_special_1.jpg', simbolo: 'totem',
                descricao: t ? (t.owner && t.owner !== 'none' ? 'Hoje esta terra é de ' + t.owner + '. A tribo vai tomá-la à força.' : 'Ninguém guarda esta terra. Acendam a fogueira antes que outro acenda.') : 'Escolha no centro a terra que a tribo vai tomar.',
                botao: { texto: 'Partir', ativo: !!t && !travaAceitar, ao: function () { aceitarMissao('special_1', { territoryName: t.name }); } },
                botao2: { texto: 'Voltar', ativo: true, ao: function () { escolhaTerra = null; terraEscolhida = null; desenharAba(); } },
            };
        }
        const m = missoes().find(function (x) { return x.id === sel.missoes; });
        if (!m) return { rotulo: 'Missões', nome: 'Trilhas do dia', simbolo: 'trilha', descricao: 'Escolha uma trilha no centro.' };
        const est = estadoMissao(m);
        const premio = (cfg.wampumRecompensas || {})[m.id] || {};
        const espera = ((cfg.cooldowns || {})[m.id] || {}).minutes;
        const numeros = [];
        if (premio.branco) numeros.push({ conta: 'branca', valor: '+' + premio.branco, rotulo: 'Branco' });
        if (premio.roxo) numeros.push({ conta: 'roxa', valor: '+' + premio.roxo, rotulo: 'Roxo' });
        if (espera) numeros.push({ simbolo: 'tempo', valor: tempo(espera), rotulo: 'Espera' });
        if (m.minMembers) numeros.push({ simbolo: 'pessoas', valor: m.minMembers, rotulo: 'Mínimo' });
        const p = {
            rotulo: (m.isSpecial ? 'Missão especial' : 'Missão diária') + ' · ' + ({ livre: 'livre', ativa: 'em curso', espera: 'em espera', feita: 'feita' })[est],
            nome: m.title, ilustracao: 'img/missao_' + m.id + '.jpg', simbolo: SIMBOLO_MISSAO[m.id] || 'trilha',
            descricao: (m.description || '') + (m.reward ? '\n\nRecompensa: ' + m.reward : ''), numeros: numeros,
        };
        if (est === 'livre') {
            p.botao = { texto: m.id === 'special_1' ? 'Escolher terra' : 'Aceitar', ativo: !travaAceitar && !missaoAtiva, ao: function () {
                if (m.id === 'special_1') { terraEscolhida = null; pedir('getDominationTerritories'); aviso('Os batedores contam as terras...'); return; }
                aceitarMissao(m.id);
            } };
            if (missaoAtiva) p.motivo = 'A tribo já está numa trilha.';
        } else if (est === 'espera') {
            const custo = m.cooldownSkipCost;
            if (custo != null) {
                const w = wampum();
                p.botao = { texto: 'Liberar · ' + custo + ' Wampum', ativo: (w.valor || 0) >= custo, ao: function () {
                    pedir('skipMissionCooldown', { missionId: m.id });
                    aviso('Os anciões contam o seu wampum...');
                } };
                p.motivo = (w.valor || 0) >= custo
                    ? 'Volta sozinha em ' + tempo(m.cooldownRemaining) + '. Um roxo vale ' + (w.valorRoxo || 2) + ' brancos.'
                    : 'Você tem ' + (w.valor || 0) + ' de Wampum. Volta em ' + tempo(m.cooldownRemaining) + '.';
            } else {
                p.motivo = 'Volta em ' + tempo(m.cooldownRemaining) + '.';
            }
        } else if (est === 'ativa') {
            p.motivo = 'A tribo está nesta trilha agora.'; p.motivoBom = true;
        } else {
            p.motivo = 'Feita hoje.';
        }
        return p;
    }
    function aceitarMissao(id, params) {
        if (travaAceitar || missaoAtiva) return;
        travaAceitar = true;
        missaoAtiva = id;
        escolhaTerra = null; terraEscolhida = null;
        pedir('acceptMission', params ? { missionId: id, params: params } : { missionId: id })
            .finally(function () { setTimeout(function () { travaAceitar = false; }, 2000); });
        desenharTudo();
    }

    // ===================== TERRAS =====================
    function desenharTerras() {
        const caixa = $('tLista');
        caixa.innerHTML = '';
        const t = (dados && dados.territories) || {};
        const areas = Object.keys(t);
        $('tSub').textContent = areas.length ? 'Controle médio da tribo: ' + terrasMedia() + '%' : 'Acenda a fogueira ritual para tomar a terra';
        if (!areas.length) { caixa.appendChild(el('div', 'vazio-texto', 'Os anciões ainda não marcaram pontos sagrados.')); return; }
        const g = grupo(caixa, 'Áreas');
        areas.forEach(function (a) {
            if (!sel.terras) sel.terras = a;
            const pct = Number(t[a]) || 0;
            const total = pontosDaArea(a);
            g.appendChild(carta({
                pct: pct, nome: a, sel: sel.terras === a, classe: pct > 0 ? '' : 'apagada', barra: pct,
                sub: Math.round((pct / 100) * total) + ' de ' + total + ' fogueiras',
                ao: function () { sel.terras = a; desenharAba(); },
            }));
        });
    }
    function painelTerra() {
        const t = (dados && dados.territories) || {};
        const a = sel.terras;
        if (!a || t[a] === undefined) return { rotulo: 'Terras', nome: 'Pontos sagrados', simbolo: 'terra', descricao: 'Use a fogueira ritual num ponto sagrado para marcar a terra. Rival pode apagar.' };
        const pct = Number(t[a]) || 0, total = pontosDaArea(a), nossas = Math.round((pct / 100) * total);
        return {
            rotulo: 'Terra · ' + (pct >= 100 ? 'toda da tribo' : pct > 0 ? 'em disputa' : 'sem fogueira'),
            nome: a, ilustracao: 'img/terra_' + slug(a) + '.jpg', simbolo: 'terra',
            descricao: pct >= 100 ? 'Todas as fogueiras desta terra são da tribo. Guardem para que ninguém apague.'
                : 'Faltam ' + (total - nossas) + ' fogueira(s) para a terra ser toda da tribo. Use a fogueira ritual nos pontos sagrados.',
            numeros: [
                { simbolo: 'terra', valor: pct + '%', rotulo: 'Controle' },
                { simbolo: 'fogo', valor: nossas + '/' + total, rotulo: 'Fogueiras' },
                { simbolo: 'totem', valor: total - nossas, rotulo: 'Livres ou rivais' },
            ],
        };
    }

    // ===================== DONS =====================
    function cfgDom(id) { return ((cfg.buffs || {})[id]) || null; }
    function nivelMaxDom(c) {
        const custos = Object.keys((c && c.costs) || {}).map(Number).filter(function (n) { return n > 0; });
        return Math.min(c && c.maxLevel ? c.maxLevel : 1, custos.length ? Math.max.apply(null, custos) : 1);
    }
    function desenharDons() {
        const caixa = $('dLista');
        caixa.innerHTML = '';
        const g = grupo(caixa, 'Oferendas');
        ORDEM_DONS.forEach(function (id) {
            const c = cfgDom(id);
            if (!c) return;
            if (!sel.dons) sel.dons = id;
            const d = domAtivo(id);
            const req = (c.requirements && c.requirements.minLevel) || 1;
            const trancado = (dados.level || 1) < req;
            g.appendChild(carta({
                simbolo: SIMBOLO_DOM[id] || 'fogo', nome: c.name, sel: sel.dons === id,
                classe: trancado ? 'trancada' : (d && d.ativo ? '' : 'apagada'),
                sub: trancado ? 'Nível ' + req : (d && d.ativo ? 'Aceso · ' + tempo(d.restaMin) : 'Apagado'),
                subClasse: d && d.ativo ? 'livre' : '',
                ao: function () { sel.dons = id; desenharAba(); },
            }));
        });
    }
    function painelDom() {
        const id = sel.dons, c = cfgDom(id);
        if (!c) return { rotulo: 'Dons', nome: 'Dons da tribo', simbolo: 'fogo', descricao: '' };
        const d = domAtivo(id);
        const max = nivelMaxDom(c);
        const req = (c.requirements && c.requirements.minLevel) || 1;
        const nivelAtual = d && d.ativo ? d.level : 0;
        const proximo = d && d.ativo ? Math.min(nivelAtual + 1, max) : 1;
        const custo = (c.costs || {})[proximo] || {};
        const p = {
            rotulo: 'Dom · ' + (d && d.ativo ? 'aceso' : 'apagado'), nome: c.name,
            ilustracao: 'img/dom_' + id + '.jpg', simbolo: SIMBOLO_DOM[id] || 'fogo', descricao: c.description || '',
            numeros: [
                { simbolo: 'estrela', valor: nivelAtual + '/' + max, rotulo: 'Nível' },
                { simbolo: 'moeda', valor: dinheiro(custo.money), rotulo: 'Custo' },
                { simbolo: 'tempo', valor: (custo.duration || 0) + 'h', rotulo: 'Dura' },
            ],
        };
        if ((dados.level || 1) < req) {
            p.botao = { texto: 'Acender', ativo: false }; p.motivo = 'A tribo precisa do nível ' + req + '.';
        } else if (!souChefe()) {
            p.botao = { texto: d && d.ativo ? 'Fortalecer' : 'Acender', ativo: false }; p.motivo = 'Só o chefe acende os dons.';
        } else if (d && d.ativo) {
            const noMax = nivelAtual >= max;
            p.botao = { texto: noMax ? 'No máximo' : 'Fortalecer', ativo: !noMax, ao: function () {
                pedir('pantanal_nativos:upgradeBuff', { buff: id, level: nivelAtual + 1 }); aviso('Oferenda levada ao fogo...');
            } };
            p.motivo = 'Aceso por mais ' + tempo(d.restaMin) + '.'; p.motivoBom = true;
        } else {
            p.botao = { texto: 'Acender', ativo: true, ao: function () {
                pedir('purchaseBuff', { buffId: id, level: 1, duration: custo.duration || 1 }); aviso('Oferenda levada ao fogo...');
            } };
            p.motivo = 'Paga com a bolsa da tribo.';
        }
        return p;
    }

    // ===================== CESTO =====================
    function imgItem(e, item) {
        const i = el('img');
        i.alt = '';
        i.src = item.image || ('images/items/' + item.name + '.png');
        i.onerror = function () {
            if (!i.dataset.reserva) { i.dataset.reserva = '1'; i.src = 'nui://vorp_inventory/html/img/items/' + item.name + '.png'; }
            else i.style.visibility = 'hidden';
        };
        e.appendChild(i);
        return i;
    }
    function espacos(caixa, itens, origem) {
        caixa.innerHTML = '';
        const total = Math.max(16, Math.ceil(itens.length / 8) * 8);
        for (let k = 0; k < total; k++) {
            const item = itens[k];
            const e = el('div', 'espaco' + (item ? '' : ' vazio'));
            if (item) {
                e.tabIndex = 0;
                if (sel.cesto && sel.cesto.origem === origem && sel.cesto.name === item.name) e.classList.add('sel');
                imgItem(e, item);
                e.appendChild(el('span', 'qtd', String(item.count)));
                e.title = item.label || item.name;
                e.addEventListener('click', function () { sel.cesto = { origem: origem, name: item.name }; $('pCampoValor').value = 1; desenharAba(); });
            }
            caixa.appendChild(e);
        }
    }
    function desenharCesto() {
        espacos($('eCesto'), cesto, 'cesto');
        espacos($('eBolsa'), bolsa, 'bolsa');
    }
    function painelCesto() {
        const s = sel.cesto;
        const lista = s ? (s.origem === 'cesto' ? cesto : bolsa) : [];
        const item = s ? lista.find(function (x) { return x.name === s.name; }) : null;
        if (!item) return { rotulo: 'Cesto', nome: 'Cesto da tribo', simbolo: 'cesto', descricao: 'Escolha um item. Só entram no cesto os itens que os anciões aceitam.' };
        const doCesto = s.origem === 'cesto';
        return {
            rotulo: doCesto ? 'No cesto da tribo' : 'Na sua bolsa', nome: item.label || item.name, itemImg: item,
            descricao: doCesto ? 'Quanto você vai tirar do cesto?' : 'Quanto você vai guardar no cesto?',
            numeros: [{ simbolo: 'cesto', valor: item.count, rotulo: 'Quantidade' }],
            campo: { rotulo: 'Quantos', max: item.count },
            botao: { texto: doCesto ? 'Retirar' : 'Guardar', ativo: true, ao: function () {
                const n = Math.floor(Number($('pCampoValor').value) || 0);
                if (n <= 0 || n > item.count) return aviso('Quantidade inválida.');
                pedir(doCesto ? 'withdrawItem' : 'depositItem', { itemName: item.name, amount: n }).then(function () {
                    pedir('getPlayerInventory'); pedir('openStorage');
                });
                aviso(doCesto ? 'Tirando do cesto...' : 'Guardando no cesto...');
            } },
        };
    }

    // ===================== POVO =====================
    function desenharPovo() {
        const caixa = $('pLista');
        caixa.innerHTML = '';
        const membros = (dados && dados.members) || [];
        const on = membros.filter(function (m) { return m.online; }).length;
        $('pSubLista').textContent = membros.length + ' na tribo · ' + on + ' perto do fogo agora';
        const chamar = el('div', 'linha chamar' + (sel.povo === '+chamar' ? ' sel' : ''));
        chamar.tabIndex = 0;
        const ic = el('i'); simbolo(ic, 'chamar'); chamar.appendChild(ic);
        chamar.appendChild(el('span', '', 'Chamar alguém para a tribo'));
        chamar.addEventListener('click', function () { sel.povo = '+chamar'; $('pCampoValor').value = ''; desenharAba(); });
        caixa.appendChild(chamar);
        membros.slice().sort(function (a, b) { return (b.rank === 'leader') - (a.rank === 'leader') || (b.online - a.online); }).forEach(function (m) {
            const chave = m.identifier + ':' + m.charid;
            const l = el('div', 'linha' + (sel.povo === chave ? ' sel' : ''));
            l.tabIndex = 0;
            l.appendChild(el('i', 'ponto' + (m.online ? ' on' : '')));
            const i = el('i'); simbolo(i, m.rank === 'leader' ? 'chefe' : 'pessoa'); l.appendChild(i);
            l.appendChild(el('span', '', m.name));
            l.appendChild(el('small', '', CARGO[m.rank] || m.rank));
            l.addEventListener('click', function () { sel.povo = chave; desenharAba(); });
            caixa.appendChild(l);
        });
    }
    function painelPovo() {
        if (!sel.povo || sel.povo === '+chamar') {
            return {
                rotulo: 'Povo · chamar', nome: 'Chamar à tribo', simbolo: 'chamar',
                descricao: 'Digite o número da pessoa (o ID dela no servidor). Ela precisa estar por perto e aceitar.',
                campo: { rotulo: 'ID' },
                botao: { texto: 'Chamar', ativo: souChefe(), ao: function () {
                    const id = Math.floor(Number($('pCampoValor').value) || 0);
                    if (id <= 0) return aviso('Digite o ID da pessoa.');
                    pedir('inviteMember', { playerId: id }); aviso('O chamado foi feito.'); $('pCampoValor').value = '';
                } },
                motivo: souChefe() ? '' : 'Só o chefe chama gente nova.',
            };
        }
        const m = ((dados && dados.members) || []).find(function (x) { return (x.identifier + ':' + x.charid) === sel.povo; });
        if (!m) { sel.povo = null; return painelPovo(); }
        const p = {
            rotulo: 'Povo · ' + (m.online ? 'perto do fogo' : 'longe'), nome: m.name, simbolo: m.rank === 'leader' ? 'chefe' : 'pessoa',
            descricao: (CARGO[m.rank] || m.rank) + ' da tribo ' + (dados.name || '') + '.',
            numeros: [{ simbolo: m.rank === 'leader' ? 'chefe' : 'pessoa', valor: CARGO[m.rank] || m.rank, rotulo: 'Cargo' }].concat(m.online && m.fonte ? [{ simbolo: 'estrela', valor: m.fonte, rotulo: 'ID agora' }] : []),
        };
        if (!souChefe()) { p.motivo = 'Só o chefe muda o povo.'; return p; }
        if (m.rank === 'leader') { p.motivo = 'É o chefe.'; return p; }
        if (!m.online || !m.fonte) { p.motivo = 'Precisa estar no servidor para mudar o cargo ou sair.'; }
        p.botao = { texto: 'Fazer chefe', ativo: !!(m.online && m.fonte), ao: function () { pedir('manageMember', { playerId: m.fonte, action: 'promover' }); aviso('O conselho ouviu.'); } };
        p.botao2 = { texto: 'Expulsar', ativo: !!(m.online && m.fonte), ao: function () { pedir('manageMember', { playerId: m.fonte, action: 'remover' }); aviso('O conselho ouviu.'); } };
        return p;
    }

    // ===================== VIVEIRO (falcoaria) =====================
    const ESTADO_AVE = { selvagem: 'Selvagem', manso: 'Mansa', ovo: 'Ovo', filhote: 'Filhote' };
    function segs(s) { return tempo(Math.ceil((Number(s) || 0) / 60)); }
    function sexo(a) { return a.sexo === 'F' ? 'fêmea' : 'macho'; }
    function desenharViveiro() {
        const caixa = $('vLista');
        caixa.innerHTML = '';
        const v = viveiro;
        if (!v) { $('vSub').textContent = 'Contando as aves...'; return; }
        if (v.semTribo) { $('vSub').textContent = ''; return; }
        if (!v.existe) {
            $('vSub').textContent = 'A tribo ainda não montou o viveiro';
            caixa.appendChild(el('div', 'vazio-texto', 'O chefe usa o Viveiro da Tribo perto da fogueira do conselho. Depois, use a Gaiola de Falcoeiro num ninho para prender a primeira ave.'));
            return;
        }
        $('vSub').textContent = v.aves.length + ' de ' + v.max + ' aves · capturas hoje ' + v.capturasHoje + '/' + v.capturasMax + ' · ovos da semana ' + v.ovosSemana + '/' + v.ovosMax;
        const g = grupo(caixa, 'No viveiro');
        if (!v.aves.length) g.appendChild(el('div', 'vazio-texto', 'Nenhuma ave ainda.'));
        v.aves.forEach(function (a) {
            const chave = 'v:' + a.id;
            if (!sel.viveiro) sel.viveiro = chave;
            const sub = a.estado === 'ovo' ? 'Choca em ' + segs(a.prontoEm) : (ESTADO_AVE[a.estado] || a.estado) + ' · ' + sexo(a);
            g.appendChild(carta({
                simbolo: a.estado === 'ovo' ? 'ovo' : 'ave', nome: a.nome, sel: sel.viveiro === chave,
                classe: a.estado === 'manso' ? '' : 'apagada', sub: sub, subClasse: a.estado === 'manso' ? 'livre' : '',
                barra: a.estado === 'ovo' ? undefined : a.mansidao,
                ao: function () { sel.viveiro = chave; desenharAba(); },
            }));
        });
        if (v.noBolso && v.noBolso.length) {
            const b = grupo(caixa, 'Na sua bolsa');
            v.noBolso.forEach(function (a) {
                const chave = 'b:' + a.itemId;
                b.appendChild(carta({
                    simbolo: 'ave', nome: a.nome, sel: sel.viveiro === chave, sub: 'Grau ' + (a.grau || 1) + ' · ' + sexo(a),
                    ao: function () { sel.viveiro = chave; desenharAba(); },
                }));
            });
        }
    }
    function acaoViveiro(acao, id, txt) { pedir('viveiroAcao', { acao: acao, id: id }); aviso(txt); }
    function painelViveiro() {
        const v = viveiro;
        const base = { rotulo: 'Viveiro', nome: 'Viveiro da tribo', simbolo: 'ninho', ilustracao: 'img/viveiro.jpg',
            descricao: 'Prenda aves nos ninhos com a Gaiola de Falcoeiro, amanse no viveiro e tire quando estiver mansa: ela vira item e pode ser vendida a qualquer um.' };
        if (!v || !v.existe || !sel.viveiro) return base;
        const longe = !v.perto ? 'Você precisa estar no viveiro da tribo.' : '';
        if (sel.viveiro.indexOf('b:') === 0) {
            const itemId = Number(sel.viveiro.slice(2));
            const a = (v.noBolso || []).find(function (x) { return x.itemId === itemId; });
            if (!a) { sel.viveiro = null; return base; }
            return {
                rotulo: 'Na sua bolsa · grau ' + (a.grau || 1), nome: a.apelido && a.apelido !== '(no name)' ? a.apelido : a.nome,
                simbolo: 'ave', ilustracao: 'img/ave_' + slug(a.nome) + '.jpg',
                descricao: 'Guardada no viveiro, a ave pode formar casal para criar. Ela continua sua: tire de volta quando quiser.',
                numeros: [{ simbolo: 'estrela', valor: a.grau || 1, rotulo: 'Grau' }, { simbolo: 'ave', valor: a.sexo === 'F' ? 'Fêmea' : 'Macho', rotulo: 'Sexo' }],
                botao: { texto: 'Guardar', ativo: v.perto && v.aves.length < v.max, ao: function () { acaoViveiro('guardar', itemId, 'Levando a ave ao viveiro...'); } },
                motivo: longe || (v.aves.length >= v.max ? 'O viveiro está cheio.' : ''),
            };
        }
        const id = Number(sel.viveiro.slice(2));
        const a = v.aves.find(function (x) { return x.id === id; });
        if (!a) { sel.viveiro = null; return base; }
        const p = {
            rotulo: (ESTADO_AVE[a.estado] || a.estado) + ' · ' + sexo(a) + (a.minha ? ' · sua' : ''),
            nome: a.nome, simbolo: a.estado === 'ovo' ? 'ovo' : 'ave',
            ilustracao: a.estado === 'ovo' ? 'img/ovo.jpg' : 'img/ave_' + a.especie + '.jpg',
            numeros: [],
        };
        if (a.estado === 'ovo') {
            p.descricao = 'O ovo está sendo chocado. Quando abrir, o filhote já nasce meio manso.';
            p.numeros.push({ simbolo: 'tempo', valor: segs(a.prontoEm), rotulo: 'Choca em' });
            p.motivo = 'Espere o ovo abrir.';
            return p;
        }
        p.numeros.push({ simbolo: 'ave', valor: a.mansidao + '%', rotulo: 'Mansidão' });
        p.numeros.push({ simbolo: 'tempo', valor: a.comerEm > 0 ? segs(a.comerEm) : 'Agora', rotulo: 'Comer' });
        if (a.estado === 'manso') {
            p.numeros.push({ simbolo: 'ovo', valor: a.descansoEm > 0 ? segs(a.descansoEm) : 'Pronta', rotulo: 'Cria' });
            p.descricao = 'Mansa. Tire do viveiro para virar item, ou junte com outra mansa do outro sexo para botar ovo.';
            p.botao = { texto: 'Tirar', ativo: v.perto && a.podeTirar, ao: function () { acaoViveiro('tirar', a.id, 'Tirando a ave do viveiro...'); } };
            p.botao2 = { texto: 'Juntar casal', ativo: v.perto && a.descansoEm <= 0 && v.ovosSemana < v.ovosMax, ao: function () { acaoViveiro('casal', a.id, 'Procurando o par...'); } };
            p.motivo = longe || (!a.podeTirar ? 'Só quem pegou esta ave (ou o chefe) a tira.' : '');
        } else {
            p.descricao = a.estado === 'filhote' ? 'Filhote. Alimente até ficar mansa.' : 'Selvagem. Alimente com a comida certa até ficar mansa. Cada refeição amansa um pouco.';
            p.botao = { texto: 'Alimentar', ativo: v.perto && a.comerEm <= 0 && a.temComida, ao: function () { acaoViveiro('alimentar', a.id, 'Dando de comer...'); } };
            p.botao2 = { texto: 'Soltar', ativo: v.perto && (a.minha || v.chefe), ao: function () { acaoViveiro('soltar', a.id, 'Abrindo a gaiola...'); } };
            p.motivo = longe || (!a.temComida ? 'Você não tem a comida desta ave.' : (a.comerEm > 0 ? 'De papo cheio.' : ''));
        }
        return p;
    }

    // ===================== CONSELHO (painel) =====================
    function painelConselho() {
        const w = wampum();
        const p = {
            rotulo: 'Bolsa da tribo', nome: dinheiro(dados && dados.money), simbolo: 'wampum', ilustracao: 'img/conselho.jpg',
            descricao: 'O que a tribo junta fica aqui. Só o chefe tira.\n\nO wampum é seu: ' + (w.branco || 0) + ' branco e ' + (w.roxo || 0) + ' roxo (um roxo vale ' + (w.valorRoxo || 2) + ' brancos).',
            numeros: [
                { conta: 'branca', valor: w.branco || 0, rotulo: 'Branco' },
                { conta: 'roxa', valor: w.roxo || 0, rotulo: 'Roxo' },
                { simbolo: 'wampum', valor: w.valor || 0, rotulo: 'Valor' },
            ],
            campo: { rotulo: 'Valor $' },
            botao: { texto: 'Sacar', ativo: souChefe(), ao: function () {
                const v = Math.floor(Number($('pCampoValor').value) || 0);
                if (v <= 0) return aviso('Digite quanto sacar.');
                pedir('withdrawGangMoney', { amount: v }); aviso('Pedindo ao conselho...'); $('pCampoValor').value = '';
            } },
            motivo: souChefe() ? '' : 'Só o chefe saca da bolsa.',
        };
        return p;
    }

    // ===================== painel da direita =====================
    function desenharPainel() {
        if (!dados) return;
        const p = ({ conselho: painelConselho, missoes: painelMissao, terras: painelTerra, dons: painelDom, cesto: painelCesto, viveiro: painelViveiro, povo: painelPovo })[aba]();
        $('pRotulo').textContent = p.rotulo || '';
        $('pNome').textContent = p.nome || '';
        $('pDescricao').textContent = p.descricao || '';

        const ilu = $('pIlustracao');
        ilu.innerHTML = '';
        function grande() { ilu.innerHTML = ''; const g = el('i', 'grande'); simbolo(g, p.simbolo || 'fogo'); ilu.appendChild(g); }
        if (p.itemImg) {
            imgItem(ilu, p.itemImg).className = 'item';
        } else if (p.ilustracao) {
            grande();
            const alvo = p.ilustracao;
            imagem(alvo, function (src) { if ($('pNome').textContent === (p.nome || '')) { ilu.innerHTML = ''; const i = el('img'); i.src = src; ilu.appendChild(i); } });
        } else {
            grande();
        }

        const nums = $('pNumeros');
        nums.innerHTML = '';
        (p.numeros || []).forEach(function (n) {
            const d = el('div');
            const i = el('i');
            if (n.conta) i.appendChild(el('span', 'conta ' + n.conta)); else simbolo(i, n.simbolo);
            d.appendChild(i);
            d.appendChild(el('b', '', String(n.valor)));
            d.appendChild(el('span', '', n.rotulo));
            nums.appendChild(d);
        });

        const campo = $('pCampo');
        campo.classList.toggle('visivel', !!p.campo);
        if (p.campo) {
            $('pCampoRotulo').textContent = p.campo.rotulo;
            const v = $('pCampoValor');
            if (p.campo.max) v.max = p.campo.max; else v.removeAttribute('max');
        }

        botao($('pBotao'), p.botao);
        botao($('pBotao2'), p.botao2);
        const mot = $('pMotivo');
        mot.textContent = p.motivo || '';
        mot.classList.toggle('bom', !!p.motivoBom);
    }
    function botao(b, def) {
        b.hidden = !def;
        if (!def) { b.onclick = null; return; }
        b.querySelector('span').textContent = def.texto;
        b.disabled = !def.ativo;
        b.onclick = def.ativo && def.ao ? def.ao : null;
    }

    function desenharAba() {
        if (!dados) return;
        if (aba === 'missoes') desenharMissoes();
        else if (aba === 'terras') desenharTerras();
        else if (aba === 'dons') desenharDons();
        else if (aba === 'cesto') desenharCesto();
        else if (aba === 'viveiro') desenharViveiro();
        else if (aba === 'povo') desenharPovo();
        desenharPainel();
    }
    function desenharTudo() { if (!dados) return; desenharFicha(); desenharAba(); }

    // ===================== abrir e fechar =====================
    function abrir() { raiz.classList.remove('escondido'); escalar(); mostrarAba(aba); }
    function fechar() {
        raiz.classList.add('escondido');
        escolhaTerra = null; terraEscolhida = null;
        pedir('closeUI');
    }
    $('rVoltar').addEventListener('click', fechar);
    document.addEventListener('keydown', function (e) {
        if (raiz.classList.contains('escondido')) return;
        if (e.key === 'Escape') { e.preventDefault(); fechar(); return; }
        if (document.activeElement && document.activeElement.tagName === 'INPUT') return;
        const k = e.key.toLowerCase();
        if (k === 'q' || k === 'e') {
            const i = ABAS.indexOf(aba);
            mostrarAba(ABAS[(i + (k === 'e' ? 1 : ABAS.length - 1)) % ABAS.length]);
        }
    });

    // ===================== mensagens do jogo =====================
    function novosDados(g) {
        if (!g) return;
        dados = Object.assign({}, dados || {}, g);
        desenharTudo();
    }
    window.addEventListener('message', function (ev) {
        const d = ev.data || {};
        switch (d.type) {
            case 'showUI':
                if (d.config) cfg = d.config;
                else if (d.buffsConfig) cfg.buffs = d.buffsConfig;
                if (d.gangData) dados = d.gangData;
                missaoAtiva = null;
                abrir();
                desenharTudo();
                break;
            case 'hideUI':
                raiz.classList.add('escondido');
                break;
            case 'updateUI':
            case 'pantanal_nativos:updateGangData':
                novosDados(d.gangData);
                break;
            case 'pantanal_nativos:gang:updateGangData':
                if (d.gangData && dados) { if (d.gangData.money !== undefined) dados.money = d.gangData.money; desenharTudo(); }
                break;
            case 'pantanal_nativos:gang:updateMoney':
                if (dados) { dados.money = Number(d.data) || 0; desenharTudo(); }
                break;
            case 'updateTerritories':
                if (dados && d.territories) { dados.territories = d.territories; desenharTudo(); }
                break;
            case 'updateMissions':
                if (dados && d.missions) { dados.missions = d.missions; desenharTudo(); }
                break;
            case 'updateBuffs':
                if (dados && d.buffs) { dados.buffs = d.buffs; desenharTudo(); }
                break;
            case 'updateStorage':
                cesto = d.items || []; if (aba === 'cesto') desenharAba();
                break;
            case 'updatePlayerInventory':
                bolsa = d.items || []; if (aba === 'cesto') desenharAba();
                break;
            case 'updateWampum':
                if (dados && d.wampum) { dados.wampum = d.wampum; desenharTudo(); }
                break;
            case 'updateViveiro':
                viveiro = d.viveiro || null; if (aba === 'viveiro') desenharAba();
                break;
            case 'resetActiveMission':
                missaoAtiva = null; desenharTudo();
                break;
            case 'showTerritorySelector':
                escolhaTerra = d.territories || [];
                terraEscolhida = null;
                aba !== 'missoes' ? mostrarAba('missoes') : desenharAba();
                break;
        }
    });

    // relógio: as esperas das missões e dos dons andam com o painel aberto
    setInterval(function () {
        if (!dados || raiz.classList.contains('escondido')) return;
        missoes().forEach(function (m) { if (m.inCooldown && m.cooldownRemaining > 0) m.cooldownRemaining = Math.max(0, m.cooldownRemaining - 1); });
        desenharTudo();
    }, 60000);
})();
