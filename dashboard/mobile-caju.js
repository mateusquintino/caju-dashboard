/* ══════════════════════════════════════════════════════════════
   CAJU · PATCH MOBILE (comportamento) — formato "app" (protótipo Caju Mobile)
   Referencie com <script src="mobile-caju.js" defer></script> antes de </body>.
   Não altera nada acima de 768px.
   ══════════════════════════════════════════════════════════════ */
(function(){
  'use strict';
  var MQ = '(max-width:768px)';
  var isMobile = function(){ return window.matchMedia(MQ).matches; };
  var $  = function(s,r){ return (r||document).querySelector(s); };
  var $$ = function(s,r){ return Array.prototype.slice.call((r||document).querySelectorAll(s)); };

  /* ---------- ícones da barra inferior ---------- */
  var I = {
    home:'<path d="M3 10.5 12 3l9 7.5"/><path d="M5 10v10h14V10"/>',
    saldo:'<rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/>',
    mov:'<path d="M8 3 4 7l4 4"/><path d="M4 7h16"/><path d="m16 21 4-4-4-4"/><path d="M20 17H4"/>',
    comp:'<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="8" y1="13" x2="16" y2="13"/><line x1="8" y1="17" x2="16" y2="17"/>',
    mais:'<line x1="4" y1="7" x2="20" y2="7"/><line x1="4" y1="12" x2="20" y2="12"/><line x1="4" y1="17" x2="20" y2="17"/>'
  };
  /* 4 destinos + Mais (data-p = data-p das .tab do site; __home/__mais são especiais) */
  var NAV = [
    {p:'__home', lbl:'Início',    ico:I.home},
    {p:'dashboard', lbl:'Saldo',  ico:I.saldo},
    {p:'movimentacoes', lbl:'Movim.', ico:I.mov},
    {p:'comprovantes', lbl:'Comprov.', ico:I.comp},
    {p:'__mais', lbl:'Mais',      ico:I.mais}
  ];

  /* título/subtítulo do header por página (fallback = rótulo da aba) */
  var SUB = { home:'Grupo Cajupar', dashboard:'Visão geral das contas' };

  /* ---------- 1. viewport + safe-area + theme-color ---------- */
  function fixViewport(){
    var m = $('meta[name="viewport"]');
    if(!m){ m = document.createElement('meta'); m.name='viewport'; document.head.appendChild(m); }
    m.setAttribute('content','width=device-width,initial-scale=1,viewport-fit=cover');
    var tc = $('meta[name="theme-color"]');
    if(!tc){ tc=document.createElement('meta'); tc.name='theme-color'; document.head.appendChild(tc); }
    var upd = function(){
      tc.setAttribute('content', document.documentElement.getAttribute('data-theme')==='light' ? '#ECEAE5' : '#141414');
    };
    upd();
    new MutationObserver(upd).observe(document.documentElement,{attributes:true,attributeFilter:['data-theme']});
  }

  /* ---------- helpers de página ---------- */
  function currentPageId(){
    var on = $('.page.on'); return on ? (on.id||'').replace('page-','') : '';
  }
  function tabFor(p){ return $('.hdr .tab[data-p="'+p+'"]'); }
  function tabLabel(p){ var t = tabFor(p); var l = t && t.querySelector('.tlbl'); return l ? l.textContent.trim() : ''; }
  function goPage(p){
    closeSheets();
    if(p==='__home'){ if(window.irHome) window.irHome(); }
    else if(window.irPara){ window.irPara(p); }
    else { var t=tabFor(p); if(t) t.click(); }
    window.scrollTo(0,0);
    syncNav(); updateTop();
  }

  /* ---------- 2. header (chrome) ---------- */
  var topEl, badgeEl, themeIcoEl, ttlB, ttlS;
  function logoSVG(){
    var src = $('.hdr .logo .logo-mini') || $('.hdr .logo svg');
    if(src){
      var c = src.cloneNode(true); c.removeAttribute('class'); c.setAttribute('style','width:27px;height:27px;display:block');
      /* ids de gradiente únicos: o original vive numa sidebar display:none e não pinta o clone */
      var ids = Array.prototype.map.call(c.querySelectorAll('[id]'), function(n){ return n.id; });
      if(ids.length){
        var html = c.innerHTML;
        ids.forEach(function(id){
          var esc = id.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
          html = html.replace(new RegExp('id="'+esc+'"','g'),'id="cj-'+id+'"')
                     .replace(new RegExp('url\\(#'+esc+'\\)','g'),'url(#cj-'+id+')')
                     .replace(new RegExp('href="#'+esc+'"','g'),'href="#cj-'+id+'"');
        });
        c.innerHTML = html;
      }
      return c;
    }
    var span = document.createElement('span');
    span.style.cssText='width:26px;height:26px;border-radius:8px;background:linear-gradient(135deg,var(--or1),var(--or2));display:block';
    return span;
  }
  function buildTop(){
    if(topEl) return;
    topEl = document.createElement('div');
    topEl.className='cj-top';
    var inn = document.createElement('div'); inn.className='cj-top-in';

    var logo = document.createElement('button'); logo.type='button'; logo.className='cj-logo'; logo.title='Início';
    logo.appendChild(logoSVG());
    logo.addEventListener('click', function(){ goPage('__home'); });

    var ttl = document.createElement('div'); ttl.className='cj-ttl';
    ttlB = document.createElement('b'); ttlS = document.createElement('span');
    ttl.appendChild(ttlB); ttl.appendChild(ttlS);

    var bell = document.createElement('button'); bell.type='button'; bell.className='cj-ic cj-bell'; bell.title='Notificações';
    bell.innerHTML = '<svg viewBox="0 0 24 24"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>';
    badgeEl = document.createElement('span'); badgeEl.className='cj-badge'; badgeEl.style.display='none';
    bell.appendChild(badgeEl);
    bell.addEventListener('mousedown', function(e){ e.stopPropagation(); }, true);
    bell.addEventListener('click', function(e){ e.preventDefault(); if(window.toggleNotif) window.toggleNotif(); });

    var th = document.createElement('button'); th.type='button'; th.className='cj-ic cj-theme'; th.title='Tema';
    themeIcoEl = document.createElement('span'); themeIcoEl.textContent='☀'; th.appendChild(themeIcoEl);
    th.addEventListener('click', function(){ var b=$('#tglBtn'); if(b) b.click(); setTimeout(updateThemeIco,30); });

    inn.appendChild(logo); inn.appendChild(ttl); inn.appendChild(bell); inn.appendChild(th);
    topEl.appendChild(inn);
    document.body.appendChild(topEl);

    updateTop(); updateThemeIco(); updateBadge();
    // reflete tema e badge do site
    new MutationObserver(updateThemeIco).observe(document.documentElement,{attributes:true,attributeFilter:['data-theme']});
    var nb = $('#notifBadge');
    if(nb) new MutationObserver(updateBadge).observe(nb,{attributes:true,childList:true,characterData:true,subtree:true});
  }
  function updateTop(){
    if(!ttlB) return;
    var pid = currentPageId();
    ttlB.textContent = pid==='home' ? 'Caju Financeiro' : (tabLabel(pid) || 'Caju');
    ttlS.textContent = (SUB[pid]!==undefined ? SUB[pid] : '');
    ttlS.style.display = ttlS.textContent ? 'block' : 'none';
  }
  function updateThemeIco(){
    if(!themeIcoEl) return;
    themeIcoEl.textContent = document.documentElement.getAttribute('data-theme')==='light' ? '☽' : '☀';
  }
  function updateBadge(){
    if(!badgeEl) return;
    var nb = $('#notifBadge');
    var vis = nb && nb.style.display!=='none' && (nb.textContent||'').trim() && (nb.textContent||'').trim()!=='0';
    badgeEl.style.display = vis ? 'grid' : 'none';
    if(vis) badgeEl.textContent = nb.textContent.trim();
  }

  /* ---------- 3. barra inferior (nvb) ---------- */
  var nav;
  function buildNav(){
    if($('.mnav')) { nav = $('.mnav'); return; }
    nav = document.createElement('nav'); nav.className='mnav';
    NAV.forEach(function(it){
      var b = document.createElement('button'); b.type='button'; b.dataset.target = it.p;
      b.innerHTML = '<svg viewBox="0 0 24 24">'+it.ico+'</svg>'+it.lbl;
      b.addEventListener('click', function(){
        if(it.p==='__mais'){ openMais(); return; }
        goPage(it.p);
      });
      nav.appendChild(b);
    });
    document.body.appendChild(nav);
    syncNav();
  }
  function syncNav(){
    if(!nav) return;
    var id = currentPageId(); if(id==='home') id='__home';
    Array.prototype.forEach.call(nav.children, function(b){ b.classList.toggle('on', b.dataset.target===id); });
  }

  /* ---------- 4. backdrop + bottom sheets ---------- */
  var bdEl;
  function bdrop(){
    if(!bdEl){
      bdEl = document.createElement('div'); bdEl.className='cj-bdrop';
      bdEl.addEventListener('click', closeAll);
      document.body.appendChild(bdEl);
    }
    return bdEl;
  }
  function refreshBdrop(){
    var np = $('#notifPanel');
    var open = $('.cj-sheet.on') || (np && np.classList.contains('on'));
    bdrop().classList.toggle('on', !!open);
    document.body.style.overflow = open ? 'hidden' : '';
  }
  function openSheet(el){
    $$('.cj-sheet.on').forEach(function(s){ if(s!==el) s.classList.remove('on'); });
    el.classList.add('on'); refreshBdrop();
  }
  function closeSheets(){ $$('.cj-sheet.on').forEach(function(s){ s.classList.remove('on'); }); refreshBdrop(); }
  function closeAll(){ closeSheets(); if(window.toggleNotif) window.toggleNotif(false); refreshBdrop(); }

  function newSheet(cls){
    var s = document.createElement('div'); s.className='cj-sheet '+cls;
    var grab = document.createElement('div'); grab.className='cj-grab'; s.appendChild(grab);
    var hd = document.createElement('div'); hd.className='cj-sheet-hd';
    var b = document.createElement('b'); var x = document.createElement('button'); x.type='button'; x.className='cj-sheet-x'; x.innerHTML='✕';
    x.addEventListener('click', closeSheets);
    hd.appendChild(b); hd.appendChild(x); s.appendChild(hd);
    document.body.appendChild(s);
    return { sheet:s, title:b };
  }

  /* ---------- 4a. sheet "Mais" (todos os módulos) ---------- */
  var maisSheet, maisBox;
  function openMais(){
    if(!maisSheet){
      var o = newSheet('sh-mais'); maisSheet=o.sheet; o.title.textContent='Todos os módulos';
      maisBox = document.createElement('div'); maisBox.className='cj-mods'; maisSheet.appendChild(maisBox);
    }
    maisBox.textContent='';
    $$('.hdr .tab[data-p]').forEach(function(tab){
      var p = tab.getAttribute('data-p');
      if(!p) return;
      if((tab.style.display||'').indexOf('none')>-1) return;      /* aba oculta (ex.: Usuários até logar admin) */
      var lbl = tab.querySelector('.tlbl'); lbl = lbl ? lbl.textContent.trim() : p;
      var ico = tab.querySelector('.tico svg');
      var b = document.createElement('button'); b.type='button'; b.className='cj-mod';
      var ic = document.createElement('span'); ic.className='cj-mod-ic';
      if(ico){ var c=ico.cloneNode(true); c.removeAttribute('style'); ic.appendChild(c); }
      var t = document.createElement('span'); t.className='cj-mod-t'; t.textContent=lbl;
      var ch = document.createElement('span'); ch.className='cj-mod-chev'; ch.textContent='›';
      b.appendChild(ic); b.appendChild(t); b.appendChild(ch);
      b.addEventListener('click', function(){ goPage(p); });
      maisBox.appendChild(b);
    });
    openSheet(maisSheet);
  }

  /* ---------- 5. filtros: chips no topo + sheet ---------- */
  var FILT_ICO = '<svg viewBox="0 0 24 24"><path d="M4 6h16M7 12h10M10 18h4"/></svg>';
  function chipsOf(bar){
    var out=[]; var sels=$$('select', bar);
    sels.forEach(function(s){ var o=s.options[s.selectedIndex]; if(o && o.text) out.push(o.text.trim()); });
    if(!out.length){
      var ins=$$('input', bar).filter(function(i){ return i.value; });
      if(ins.length) out.push(ins.map(function(i){return i.value;}).join(' – '));
    }
    return out.length ? out : ['Filtros'];
  }
  function buildFiltros(){
    if(!isMobile()) return;
    $$('.page.on .pbar, .page.on .mov-filters').forEach(function(bar){
      if(bar.dataset.cjFilt) { updateTrigger(bar); return; }
      bar.dataset.cjFilt='1';
      var o = newSheet('sh-filt'); var sheet=o.sheet; o.title.textContent='Filtros';
      var trig = document.createElement('button'); trig.type='button'; trig.className='cj-filtbar';
      trig.innerHTML = '<span class="cj-filtbar-chips"></span><span class="cj-filtbar-ic">'+FILT_ICO+'</span>';
      bar.parentNode.insertBefore(trig, bar);
      sheet.appendChild(bar);                                   /* move os controles reais p/ dentro do sheet */
      var apply = document.createElement('button'); apply.type='button'; apply.className='cj-apply'; apply.textContent='Aplicar';
      apply.addEventListener('click', closeSheets);
      sheet.appendChild(apply);
      trig._bar = bar; trig._sheet = sheet;
      trig.addEventListener('click', function(){ openSheet(sheet); });
      bar.addEventListener('change', function(){ updateTrigger(bar); setTimeout(cardifyAll, 350); });
      bar._trigger = trig;
      updateTrigger(bar);
    });
  }
  function updateTrigger(bar){
    var trig = bar._trigger; if(!trig) return;
    var box = trig.querySelector('.cj-filtbar-chips'); if(!box) return;
    box.textContent='';
    chipsOf(bar).forEach(function(txt,i){
      var c=document.createElement('span'); c.className='cj-chip'+(i===0?' on':''); c.textContent=txt; box.appendChild(c);
    });
  }

  /* ---------- 6. tabelas → cards ---------- */
  var MONEY = /^[+\-⇄]?\s*(R\$)?\s*[\d.,]+%?$/;
  function headers(tbl){ return $$('thead th', tbl).map(function(th){ return (th.textContent||'').trim(); }); }

  function parseBR(s){
    s=(s||'').trim(); if(!s||s==='—'||s==='-') return 0;
    var neg = s.indexOf('-')>-1;
    var t = s.replace(/[^\d.,]/g,'').replace(/\./g,'').replace(',','.');
    var n = parseFloat(t); if(isNaN(n)) n=0;
    return neg ? -n : n;
  }
  function fmtBR(n){
    try{ return new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'}).format(n); }
    catch(e){ return 'R$ '+(n||0).toFixed(2); }
  }
  function mrow(lbl, val, col, strong){
    var r=document.createElement('div'); r.className='m-row';
    var s=document.createElement('span'); s.textContent=lbl;
    var b=document.createElement('b'); b.textContent=val;
    if(col) b.style.color=col; if(strong) b.style.fontWeight='700';
    r.appendChild(s); r.appendChild(b); return r;
  }
  /* Detalhe por Conta (tbody#tBody): agrupa as contas por unidade (Empresa) num único card */
  function cardifyMarca(tbl, wrap){
    var hd = headers(tbl);
    var rows = $$('tbody tr', tbl).filter(function(tr){
      return tr.children.length>=9 && !tr.querySelector('.ecel') && !tr.classList.contains('skr') && !tr.classList.contains('skr');
    });
    var box = wrap.nextElementSibling;
    if(!box || !box.classList.contains('m-cards')){
      box=document.createElement('div'); box.className='m-cards';
      wrap.parentNode.insertBefore(box, wrap.nextSibling);
    }
    // lê tudo ANTES de esconder a tabela (getComputedStyle é mais confiável visível)
    var groups={}, order=[];
    var MC=[3,4,5,6,7,8];                                  // colunas de dinheiro
    rows.forEach(function(tr){
      var td=tr.children;
      var uni=(td[0].textContent||'').trim()||'—';      // Empresa = unidade
      if(!groups[uni]){
        var chip=td[1].querySelector('.bmarca')||td[1];
        groups[uni]={cor:getComputedStyle(chip).color, marca:(td[1].textContent||'').trim(), contas:[], sums:{}};
        order.push(uni);
      }
      var g=groups[uni];
      var stg=td[8].querySelector('strong')||td[8];
      g.contas.push({ banco:(td[2].textContent||'').trim(),
                      saldo:(td[8].textContent||'').trim(), cor:getComputedStyle(stg).color });
      MC.forEach(function(i){ g.sums[i]=(g.sums[i]||0)+parseBR(td[i].textContent); });
    });

    box.textContent=''; wrap.classList.add('m-carded');
    if(!order.length){
      var e=document.createElement('div'); e.className='m-cards-empty';
      e.textContent='Nenhuma conta para os filtros selecionados.'; box.appendChild(e); return;
    }
    order.forEach(function(uni){
      var g=groups[uni];
      var d=document.createElement('details'); d.className='m-card';
      var sum=document.createElement('summary');
      var main=document.createElement('span'); main.className='m-card-main';
      var t=document.createElement('span'); t.className='m-card-t';
      t.style.display='flex'; t.style.alignItems='center'; t.style.gap='7px';
      var dot=document.createElement('span');
      dot.style.cssText='width:9px;height:9px;border-radius:50%;flex:none;background:'+(g.cor||'var(--or1)');
      t.appendChild(dot); t.appendChild(document.createTextNode(uni));
      var s2=document.createElement('span'); s2.className='m-card-s';
      s2.textContent=(g.marca?g.marca+' · ':'')+g.contas.length+' '+(g.contas.length===1?'conta':'contas');
      main.appendChild(t); main.appendChild(s2); sum.appendChild(main);
      var v=document.createElement('span'); v.className='m-card-v'; v.textContent=fmtBR(g.sums[8]);
      v.style.color = g.sums[8]>=0 ? '#10B981' : '#EF4444'; sum.appendChild(v);
      var cv=document.createElement('span'); cv.className='m-card-cv'; cv.textContent='›'; sum.appendChild(cv);
      d.appendChild(sum);
      var body=document.createElement('div'); body.className='m-card-body';
      // contas da unidade (por banco)
      g.contas.forEach(function(c){
        body.appendChild(mrow(c.banco||'Conta', c.saldo, c.cor));
      });
      // totais da marca
      var sep=document.createElement('div');
      sep.style.cssText='border-top:1px solid var(--bd);margin-top:3px;padding-top:7px;display:flex;flex-direction:column;gap:7px';
      [3,4,5,6,7].forEach(function(i){ if(hd[i]) sep.appendChild(mrow(hd[i], fmtBR(g.sums[i]))); });
      sep.appendChild(mrow(hd[8]||'Saldo Atual', fmtBR(g.sums[8]), g.sums[8]>=0?'#10B981':'#EF4444', true));
      body.appendChild(sep);
      d.appendChild(body); box.appendChild(d);
    });
  }

  function cardify(tbl){
    var wrap = tbl.closest('.twrap') || tbl.parentElement; if(!wrap) return;
    var tb0 = tbl.querySelector('tbody');
    if(tb0 && tb0.id==='tBody' && !tbl.querySelector('tbody input, tbody select, tbody textarea')){
      return cardifyMarca(tbl, wrap);        // Detalhe por Conta → um card por marca/loja
    }
    var rows = $$('tbody tr', tbl);
    if(tbl.querySelector('tbody input, tbody select, tbody textarea')){
      wrap.classList.remove('m-carded');
      var old0 = wrap.nextElementSibling;
      if(old0 && old0.classList.contains('m-cards')) old0.remove();
      return;
    }
    var hd = headers(tbl);
    var box = wrap.nextElementSibling;
    if(!box || !box.classList.contains('m-cards')){
      box = document.createElement('div'); box.className='m-cards';
      wrap.parentNode.insertBefore(box, wrap.nextSibling);
    }
    box.textContent=''; wrap.classList.add('m-carded');
    if(!rows.length){
      var e = document.createElement('div'); e.className='m-cards-empty';
      e.textContent = 'Nenhum registro para os filtros selecionados.'; box.appendChild(e); return;
    }
    rows.forEach(function(tr){
      var tds = $$('td', tr); if(!tds.length) return;
      var vals = tds.map(function(td){ return (td.textContent||'').trim(); });
      var ti=0; for(var i=0;i<vals.length;i++){ if(vals[i] && !MONEY.test(vals[i])){ ti=i; break; } }
      var vi=-1; for(var j=vals.length-1;j>=0;j--){ if(vals[j] && MONEY.test(vals[j])){ vi=j; break; } }
      var si=-1; for(var k=ti+1;k<vals.length;k++){ if(k!==vi && vals[k] && !MONEY.test(vals[k])){ si=k; break; } }
      var d = document.createElement('details'); d.className='m-card';
      var sum = document.createElement('summary');
      var main = document.createElement('span'); main.className='m-card-main';
      var t = document.createElement('span'); t.className='m-card-t'; t.textContent = vals[ti]||'—'; main.appendChild(t);
      if(si>-1){ var s2=document.createElement('span'); s2.className='m-card-s'; s2.textContent = vals[si]; main.appendChild(s2); }
      sum.appendChild(main);
      if(vi>-1){ var v=document.createElement('span'); v.className='m-card-v'; v.textContent=vals[vi];
        var c = tds[vi] && getComputedStyle(tds[vi]).color; if(c) v.style.color=c; sum.appendChild(v); }
      var cv=document.createElement('span'); cv.className='m-card-cv'; cv.textContent='›'; sum.appendChild(cv);
      d.appendChild(sum);
      var body = document.createElement('div'); body.className='m-card-body'; var extra=0;
      vals.forEach(function(val, idx){
        if(idx===ti||idx===vi||idx===si) return;
        if(!val && !tds[idx].querySelector('button,a')) return;
        var r = document.createElement('div'); r.className='m-row';
        var lb = document.createElement('span'); lb.textContent = hd[idx]||('Coluna '+(idx+1));
        var vb = document.createElement('b');
        var act = tds[idx].querySelector('button,a');
        if(act){ vb.appendChild(act.cloneNode(true)); } else { vb.textContent = val; }
        var cc = getComputedStyle(tds[idx]).color; if(cc) vb.style.color = cc;
        r.appendChild(lb); r.appendChild(vb); body.appendChild(r); extra++;
      });
      if(si>-1 && hd[si]){
        var r2=document.createElement('div'); r2.className='m-row';
        var l2=document.createElement('span'); l2.textContent=hd[si];
        var b2=document.createElement('b'); b2.textContent=vals[si];
        r2.appendChild(l2); r2.appendChild(b2); body.insertBefore(r2, body.firstChild); extra++;
      }
      if(extra){ d.appendChild(body); } else { cv.style.display='none'; }
      box.appendChild(d);
    });
  }
  function cardifyAll(){ if(!isMobile()) return; $$('.page.on table.dtbl').forEach(cardify); }
  function undoCards(){
    $$('.m-cards').forEach(function(b){ b.remove(); });
    $$('.m-carded').forEach(function(w){ w.classList.remove('m-carded'); });
  }

  /* ---------- 7. avisos "faça no desktop" ---------- */
  function desktopOnly(){
    if(!isMobile()) return;
    var imp = $('#page-importar .imp-zones');
    if(imp && !(imp.previousElementSibling && imp.previousElementSibling.classList && imp.previousElementSibling.classList.contains('m-desktop-only'))){
      var d = document.createElement('div'); d.className='m-desktop-only';
      d.innerHTML = '<b>Importação de OFX é melhor no desktop</b>Escolher arquivos e certificados não funciona bem no celular. Aqui você acompanha o histórico das importações.';
      imp.parentNode.insertBefore(d, imp);
      imp.style.display='none';
    }
  }

  /* ---------- 8. PWA ---------- */
  function pwa(){
    if(!$('link[rel="manifest"]')){
      var l=document.createElement('link'); l.rel='manifest'; l.href='manifest.webmanifest'; document.head.appendChild(l);
    }
    var am=document.createElement('meta'); am.name='apple-mobile-web-app-capable'; am.content='yes'; document.head.appendChild(am);
    var as=document.createElement('meta'); as.name='apple-mobile-web-app-status-bar-style'; as.content='black-translucent'; document.head.appendChild(as);
    if(!$('link[rel="apple-touch-icon"]')){
      var ai=document.createElement('link'); ai.rel='apple-touch-icon'; ai.href='assets/apple-touch-icon.png'; document.head.appendChild(ai);
    }
    if('serviceWorker' in navigator){
      window.addEventListener('load', function(){ navigator.serviceWorker.register('sw.js').catch(function(){}); });
    }
    var prompt=null;
    window.addEventListener('beforeinstallprompt', function(e){
      e.preventDefault(); prompt=e;
      if(!isMobile() || localStorage.getItem('cj_pwa_off')==='1') return;
      var bar=document.createElement('div'); bar.className='m-pwa';
      bar.innerHTML='<div class="m-pwa-txt"><b>Instalar o Caju</b>Acesse pelo ícone, sem a barra do navegador.</div>'
        +'<button type="button" class="m-pwa-x">Depois</button><button type="button" class="m-pwa-go">Instalar</button>';
      document.body.appendChild(bar);
      bar.querySelector('.m-pwa-x').onclick=function(){ localStorage.setItem('cj_pwa_off','1'); bar.remove(); };
      bar.querySelector('.m-pwa-go').onclick=function(){ bar.remove(); if(prompt) prompt.prompt(); };
    });
  }

  /* ---------- 8b. Saldo: esconder o que não está no protótipo ---------- */
  /* protótipo da tela Saldo = filtros + KPIs + "Saldo por marca" + "Detalhe por conta".
     Os gráficos Receitas×Despesas e Empilhado (Santander×Itaú) somem no mobile. */
  function trimSaldo(){
    if(!isMobile()) return;
    ['chartRxD','chartEmpilhado'].forEach(function(id){
      var cv = document.getElementById(id); if(!cv) return;
      var card = cv.closest('.kcard'); if(!card) return;
      card.classList.add('cj-hide-mobile');
      var prev = card.previousElementSibling;
      if(prev && prev.classList && prev.classList.contains('shdr')) prev.classList.add('cj-hide-mobile');
    });
  }

  /* ---------- 9. observadores ---------- */
  function run(){
    if(isMobile()){ buildTop(); buildNav(); trimSaldo(); cardifyAll(); buildFiltros(); desktopOnly(); }
    syncNav(); updateTop(); refreshBdrop();
  }
  function observe(){
    var deb; var kick = function(){ clearTimeout(deb); deb=setTimeout(run, 120); };
    $$('.page').forEach(function(p){ new MutationObserver(kick).observe(p,{attributes:true,attributeFilter:['class']}); });
    var main = $('.main') || document.body;
    new MutationObserver(function(muts){
      for(var i=0;i<muts.length;i++){ var t=muts[i].target;
        if(t.closest && (t.closest('.m-cards')||t.closest('.cj-sheet')||t.closest('.cj-top')||t.closest('.mnav'))) return; }
      kick();
    }).observe(main,{childList:true,subtree:true});
    var np = $('#notifPanel');
    if(np) new MutationObserver(function(){ refreshBdrop(); updateBadge(); }).observe(np,{attributes:true,attributeFilter:['class']});
    window.matchMedia(MQ).addEventListener('change', function(e){
      if(e.matches){ run(); }
      else { undoCards(); closeAll(); }
    });
    run();
  }

  /* o site chama toggleMenu() (hambúrguer) e toggleMenu(false) ao trocar de aba */
  window.toggleMenu = function(open){
    if(open===false){ closeSheets(); return; }
    if(open===true){ openMais(); return; }
    if($('.cj-sheet.on')) closeSheets(); else openMais();
  };

  function init(){ fixViewport(); pwa(); observe(); }
  if(document.readyState==='loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
