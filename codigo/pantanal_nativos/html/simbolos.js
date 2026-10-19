// Símbolos de traço do Conselho da Tribo (mesmo desenho dos sigilos do Sobrenatural:
// quadro de 64x64, traço fino, sem preenchimento). Simbolos.desenhar(el, id) põe o SVG dentro de el.
(function () {
    const S = {
        fogo:     '<path d="M32 6c4 10 14 15 12 28-1 9-7 16-12 16s-13-6-13-16c0-9 7-12 9-20 2 6 4 8 6 9-1-6-2-11-2-17Z"/><path d="M32 50c-4 0-6-3-6-6 0-4 4-6 6-11 2 5 6 7 6 11 0 3-2 6-6 6Z"/><path d="M14 58l36-6 M14 52l36 6"/>',
        boi:      '<path d="M8 16c4 7 11 10 18 10h12c7 0 14-3 18-10 M22 26c-3 9-2 19 4 25 3 3 9 3 12 0 6-6 7-16 4-25 M27 45c2 2 8 2 10 0"/><circle cx="26" cy="35" r="1.5"/><circle cx="38" cy="35" r="1.5"/>',
        poste:    '<path d="M32 6v52 M16 14h32 M19 23h26 M16 14v5 M48 14v5 M19 23v5 M45 23v5 M24 58h16 M8 30c8-4 16-6 24-7 M56 30c-8-4-16-6-24-7"/>',
        carroca:  '<path d="M8 28h36v14H8Z M44 32h7l5 10H44 M12 28l4-9h20l4 9"/><circle cx="18" cy="48" r="6"/><circle cx="42" cy="48" r="6"/><path d="M18 48h.01 M42 48h.01"/>',
        totem:    '<path d="M22 6h20v15H22Z M19 21h26v15H19Z M22 36h20v22H22Z M12 25h7 M45 25h7 M27 47h10 M25 29h14 M18 58h28"/><circle cx="28" cy="13" r="2"/><circle cx="36" cy="13" r="2"/>',
        canoa:    '<path d="M4 38c8 11 48 11 56 0Z M14 38l6-12 M50 38l-6-12 M38 12v27 M38 12 22 26h16 M30 50l-6 8 M34 50l6 8"/>',
        punho:    '<path d="M18 32v-9a4 4 0 0 1 8 0v5 M26 26v-9a4 4 0 0 1 8 0v9 M34 26v-7a4 4 0 0 1 8 0v8 M42 28v-2a4 4 0 0 1 8 0v12c0 10-7 18-17 18h-3c-8 0-12-6-12-14v-8a4 4 0 0 1 8 0v4"/>',
        mao:      '<path d="M20 36V18a3 3 0 0 1 6 0v12 M26 28V14a3 3 0 0 1 6 0v14 M32 28V16a3 3 0 0 1 6 0v14 M38 30v-8a3 3 0 0 1 6 0v16c0 10-6 18-15 18-6 0-10-3-13-8l-6-10a3 3 0 0 1 5-3l5 5"/><circle cx="50" cy="10" r="5"/>',
        arco:     '<path d="M20 6c15 8 22 17 22 26S35 50 20 58 M20 6v52 M8 32h48 M48 26l8 6-8 6 M10 28l-4 4 4 4"/>',
        olho:     '<path d="M5 32c8-12 17-18 27-18s19 6 27 18c-8 12-17 18-27 18S13 44 5 32Z"/><circle cx="32" cy="32" r="8"/><circle cx="32" cy="32" r="2"/>',
        escudo:   '<path d="M32 6l20 8v16c0 14-10 24-20 28-10-4-20-14-20-28V14Z M32 16v32 M20 28h24 M24 20l8 8 8-8"/>',
        cesto:    '<path d="M10 26h44l-6 28H16Z M18 26c0-10 6-16 14-16s14 6 14 16 M13 36h38 M15 46h34 M25 26l2 28 M39 26l-2 28"/>',
        pessoa:   '<circle cx="32" cy="18" r="8"/><path d="M14 56c0-12 8-20 18-20s18 8 18 20"/>',
        chamar:   '<circle cx="28" cy="20" r="8"/><path d="M10 56c0-12 8-20 18-20 5 0 9 2 12 5 M50 34v16 M42 42h16"/>',
        chefe:    '<circle cx="32" cy="26" r="8"/><path d="M14 58c0-12 8-20 18-20s18 8 18 20 M20 14l4-8 4 6 4-8 4 8 4-6 4 8"/>',
        wampum:   '<path d="M4 32h56"/><ellipse cx="10" cy="32" rx="4" ry="6"/><ellipse cx="21" cy="32" rx="4" ry="6"/><ellipse cx="32" cy="32" rx="4" ry="6"/><ellipse cx="43" cy="32" rx="4" ry="6"/><ellipse cx="54" cy="32" rx="4" ry="6"/>',
        moeda:    '<circle cx="32" cy="32" r="22"/><path d="M32 18v28 M39 24c-2-2-4-3-7-3-4 0-7 2-7 5 0 8 14 4 14 12 0 3-3 6-7 6-3 0-6-1-8-3"/>',
        tempo:    '<path d="M18 8h28 M18 56h28 M21 8c0 12 11 16 11 24S21 44 21 56 M43 8c0 12-11 16-11 24s11 12 11 24 M26 50h12"/>',
        estrela:  '<path d="M32 7l7 15 16 2-12 11 3 16-14-8-14 8 3-16-12-11 16-2Z"/>',
        terra:    '<path d="M4 54l18-28 10 14 9-11 19 25Z M22 26l4-6 4 6"/><path d="M44 12c-3 0-5 2-5 5 M48 8h.01"/>',
        trilha:   '<path d="M14 58c4-10 18-10 18-20S16 30 18 20 34 8 46 6"/><path d="M42 4l6 2-2 6"/><circle cx="14" cy="58" r="2"/>',
        pessoas:  '<circle cx="22" cy="20" r="7"/><circle cx="44" cy="22" r="6"/><path d="M6 54c0-11 7-18 16-18s16 7 16 18 M38 36c8 0 16 6 16 16"/>',
        ave:      '<path d="M6 30c8-2 14 0 18 4 4-10 12-16 24-16l10-4-4 8c0 14-10 24-26 24-8 0-14-4-18-10 M24 34c2 6 6 10 12 12 M46 22h.01 M16 50l-4 8 M28 52l-2 6"/>',
        ovo:      '<path d="M32 8c-10 0-18 16-18 28 0 11 8 20 18 20s18-9 18-20C50 24 42 8 32 8Z M24 34l4-4 4 4 4-4 4 4"/>',
        ninho:    '<path d="M8 38c4 10 14 16 24 16s20-6 24-16 M8 38h48 M12 44h40 M18 50h28"/><ellipse cx="26" cy="32" rx="5" ry="6"/><ellipse cx="38" cy="32" rx="5" ry="6"/>',
        cadeado:  '<rect x="16" y="28" width="32" height="26" rx="2"/><path d="M22 28v-8a10 10 0 0 1 20 0v8 M32 38v8"/>',
    };
    function desenhar(el, id) {
        if (!el) return;
        const corpo = S[id] || S.fogo;
        el.innerHTML = '<svg class="simbolo" viewBox="0 0 64 64">' + corpo + '</svg>';
    }
    window.Simbolos = { desenhar: desenhar, tem: function (id) { return !!S[id]; } };
})();
