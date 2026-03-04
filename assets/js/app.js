
    
(function(){
  const $ = (s)=>document.querySelector(s);
  const $$ = (s)=>Array.from(document.querySelectorAll(s));

  function fmtMilwaukeeTime(d){
    return new Intl.DateTimeFormat("en-US",{
      timeZone:"America/Chicago",
      hour:"numeric", minute:"2-digit", second:"2-digit",
      hour12:true
    }).format(d);
  }

  // ---------- BOOT ----------
  function runBoot(){
    const boot = $("#boot");
    if(!boot) return;
    const out = $("#bootText");
    const lines = [
      "MKEWX TERMINAL BIOS v0.4",
      "Copyright (c) 1986–2026 MKEWX SYSTEMS",
      "",
      "MEMORY TEST ......... OK",
      "VIDEO ............... AMBER",
      "NETWORK ............. ONLINE",
      "DISPATCH INDEX ....... READY",
      "RADAR SCOPE ......... READY",
      "",
      "Press any key to continue..."
    ];
    let i=0;
    out.textContent = "";
    const tick = ()=>{
      if(i < lines.length){
        out.textContent += (i===0 ? "" : "\n") + lines[i];
        i++;
        setTimeout(tick, 110);
      }else{
        setTimeout(()=>boot.classList.add("is-hidden"), 350);
      }
    };
    tick();

    const skip = ()=>{
      boot.classList.add("is-hidden");
      window.removeEventListener("keydown", skip);
      boot.removeEventListener("pointerdown", skip);
    };
    window.addEventListener("keydown", skip);
    boot.addEventListener("pointerdown", skip);
  }

  // ---------- CLOCK ----------
  function startClock(){
    const t = $("#mwkTime");
    if(!t) return;
    const step = ()=>{ t.textContent = fmtMilwaukeeTime(new Date()); };
    step();
    setInterval(step, 1000);
  }

  // ---------- TERMINAL LOG ----------
  function logLine(text){
    const log = $("#termLog");
    if(!log) return;
    const div = document.createElement("div");
    div.textContent = text;
    log.appendChild(div);
    log.scrollTop = log.scrollHeight;
  }

  // ---------- DISPATCHES ----------
  const dispatchLinks = $$("a.dispatch-link");
  dispatchLinks.forEach((a, idx)=>{ a.dataset.index = String(idx+1); });

  function loadPostFromUrl(url){
    const reader = $("#readerBox");
    if(!reader) return;
    reader.innerHTML = "<div class='reader-placeholder'>LOADING DISPATCH…</div>";

    fetch(url, { credentials: "omit" })
      .then(r => r.text())
      .then(html => {
        const doc = new DOMParser().parseFromString(html, "text/html");
        const content = doc.querySelector("#post-content");
        const title = doc.querySelector(".reader-title");
        const sub = doc.querySelector(".reader-sub");

        if(content){
          reader.innerHTML = content.innerHTML;
          const metaTitle = $("#readerTitle");
          const metaSub = $("#readerSub");
          if(metaTitle && title) metaTitle.textContent = title.textContent.trim();
          if(metaSub && sub) metaSub.textContent = sub.textContent.trim();
          return;
        }

        reader.textContent = "Could not parse dispatch content. Opening the dispatch page…";
        window.location.href = url;
      })
      .catch(() => {
        reader.textContent = "Fetch blocked or offline. Opening the dispatch page…";
        window.location.href = url;
      });
  }

  function loadDispatchByIndex(n){
    const a = dispatchLinks[n-1];
    if(!a){ logLine("ERR: No dispatch at that index."); return; }
    const url = a.getAttribute("href");
    const title = a.dataset.title || a.textContent.trim();
    const date = a.dataset.date || "";
    const cat = a.dataset.category || "";

    const metaTitle = $("#readerTitle");
    const metaSub = $("#readerSub");
    if(metaTitle) metaTitle.textContent = title;
    if(metaSub) metaSub.textContent = [date, cat].filter(Boolean).join(" • ");

    logLine(`READ ${n}: ${title}`);
    loadPostFromUrl(url);
    document.getElementById("readerPanel")?.scrollIntoView({behavior:"smooth", block:"start"});
  }

  dispatchLinks.forEach(a=>{
    a.addEventListener("click", (e)=>{
      e.preventDefault();
      loadDispatchByIndex(parseInt(a.dataset.index, 10));
    });
  });

  function listwx(){
    logLine("DISPATCH INDEX:");
    dispatchLinks.forEach(a=>{
      const n = a.dataset.index;
      const t = a.dataset.title || a.textContent.trim();
      logLine(`  ${n}. ${t}`);
    });
  }

  // ---------- CONDITIONS (KMKE) ----------
  let lastTempF = null;
  function updateConditions(){
  fetch("https://api.weather.gov/stations/KMKE/observations/latest", { headers: { Accept: "application/geo+json" } })
    .then(r=>r.json())
    .then(data=>{
      const p = data?.properties;
      if(!p) throw new Error("no properties");

      const cToF = (c)=> c==null ? null : (c*9/5+32);
      const msToMph = (ms)=> ms==null ? null : (ms*2.236936);
      const paToInHg = (pa)=> pa==null ? null : (pa*0.0002953);

      const tempF = cToF(p.temperature?.value);
      window.__MKEWX_LAST_TEMP_F = (tempF==null || Number.isNaN(tempF)) ? undefined : tempF;

      // "Feels like": prefer windChill / heatIndex if present
      const chillF = cToF(p.windChill?.value);
      const heatF  = cToF(p.heatIndex?.value);
      const feelsF = (heatF!=null && !Number.isNaN(heatF)) ? heatF : ((chillF!=null && !Number.isNaN(chillF)) ? chillF : null);

      const dewF = cToF(p.dewpoint?.value);
      const rh = p.relativeHumidity?.value;

      const windDir = p.windDirection?.value;
      const windSpd = msToMph(p.windSpeed?.value);
      const gustSpd = msToMph(p.windGust?.value);
      const windArrow = __windDirArrow(windDir);

      const visMi = (p.visibility?.value==null) ? null : (p.visibility.value/1609.344);

      const pressureIn = paToInHg(p.barometricPressure?.value);

      // Pressure tendency if available
      const tendPa = p.pressureTendency?.value;
      const tendArrow = (tendPa==null || Number.isNaN(tendPa)) ? "→" : (tendPa > 0.15 ? "↑" : (tendPa < -0.15 ? "↓" : "→"));

      const cloudPct = __cloudPctFromLayers(p.cloudLayers);

      const updated = p.timestamp ? new Date(p.timestamp) : null;
      const isNight = (p.icon||"").toLowerCase().includes("night");

      // Precip type hint (very rough)
      const txt = (p.textDescription||"");
      let precipType = null;
      const present = (p.presentWeather && p.presentWeather.length) ? (p.presentWeather[0]?.weather || "") : "";
      const presentL = present.toLowerCase();
      if(presentL.includes("snow") || txt.toLowerCase().includes("snow")) precipType = "snow";
      else if(presentL.includes("rain") || txt.toLowerCase().includes("rain") || txt.toLowerCase().includes("shower")) precipType = "rain";

      const iconArt = __pickIcon(txt, isNight, precipType);

// Headline fields for styled display
const tDisp = (tempF==null || Number.isNaN(tempF)) ? "—" : (Math.round(tempF) + "F");
const fDisp = (feelsF==null || Number.isNaN(feelsF)) ? "" : ("FEELS " + Math.round(feelsF) + "F");
const dDisp = (txt||"—").toUpperCase();
const _set = (sel, val)=>{ const el = $(sel); if(el) el.textContent = val; };
_set("#condTemp", tDisp);
_set("#condFeels", fDisp);
_set("#condDesc", dDisp);

      const fmt = (v, unit="", digits=0)=>{
        if(v==null || Number.isNaN(v)) return "—";
        return (digits ? v.toFixed(digits) : String(Math.round(v))) + unit;
      };

      const lines = [];
      if(iconArt) lines.push(`<span class="glow-strong">${iconArt.replace(/</g,"&lt;").replace(/>/g,"&gt;")}</span>`, "");
      lines.push("STATION.... KMKE");
      lines.push("UPDATED.... " + (updated ? fmtMilwaukeeTime(updated) : "—"));
      lines.push("");
      lines.push("TEMP....... " + fmt(tempF, "F") + (feelsF!=null ? ("  (FEELS " + fmt(feelsF,"F") + ")") : ""));
      lines.push(`DEWPOINT... <span class="glow-soft">${fmt(dewF,"F")}</span>   HUMIDITY... <span class="glow-soft">${fmt(rh,"%")}</span>`);
      lines.push("WIND....... " + windArrow + " " + (windDir==null? "—" : Math.round(windDir)) + "°  " + fmt(windSpd, " mph") + (gustSpd!=null && !Number.isNaN(gustSpd) ? ("  G " + fmt(gustSpd, " mph")) : ""));
      lines.push(`PRESSURE... <span class="glow-soft">${fmt(pressureIn," in",2)}</span> <span class="glow-soft">${tendArrow}</span>`);
      lines.push(`VIS........ <span class="glow-soft">${fmt(visMi," mi")}</span>${(cloudPct!=null?`   CLOUDS..... <span class="glow-soft">${fmt(cloudPct,"%")}</span>`:"")}`);
      lines.push("");
      lines.push(`CONDITION.. <span class="glow-strong">${txt.toUpperCase()}</span>`);

      const outEl = document.getElementById("conditionsOut");
      if(outEl) outEl.textContent = lines.join("\n");
    })
    .catch((err)=>{
      const outEl = document.getElementById("conditionsOut");
      const msg = "STATION.... KMKE
UPDATED.... —

CONDITIONS UNAVAILABLE

(If you are previewing locally, Safari/Dropbox often blocks live fetch. On GitHub Pages it should load.)";
      if(outEl) outEl.textContent = msg;
      try{ console.warn("[MKEWX] conditions fetch failed", err); }catch(_e){}
    });
}

  // ---------- RADAR ----------
  let radar = null;
  function radarInit(){
    const scope = $("#scopeBox");
    if(!scope || !window.MKEWX_Radar) return;
    radar = window.MKEWX_Radar.createRadarScope({
      el: scope,
      bboxText: $("#bboxText"),
      frameText: $("#frameText"),
      ageText: $("#ageText"),
      refreshMs: 120000
    });
  }
  function radarRefresh(){
    if(radar && radar.refreshFrame){
      radar.refreshFrame();
      logLine("RADAR: refreshed.");
    }else{
      logLine("RADAR: unavailable.");
    }
  }
  function radarScroll(){
    document.getElementById("radarPanel")?.scrollIntoView({behavior:"smooth", block:"start"});
  }

  // ---------- EXTRA DATASETS ----------
  let custardData=null, sfData=null, histData=null, filmData=null, commandHelp=null;
  function loadJSON(path){ return fetch(path, {credentials:"omit"}).then(r=>r.json()); }

  function pick(arr){ return arr[Math.floor(Math.random()*arr.length)]; }

  function runCustard(){
    if(!custardData?.ranges?.length){ logLine("CUSTARD: unavailable."); return; }
    const t = (lastTempF==null) ? 32 : lastTempF;
    const r = custardData.ranges.find(x=> t>=x.min && t<=x.max) || custardData.ranges[custardData.ranges.length-1];
    logLine(pick(r.lines || ["Custard approved."]));
  }

  const lambeau = { lat: 44.5013, lon: -88.0622 };
  let packersCache = { at: 0, lines: null };
  function runPackers(){
    const now = Date.now();
    if(packersCache.lines && (now - packersCache.at) < 10*60*1000){
      packersCache.lines.forEach(l=>logLine(l));
      return;
    }
    logLine("PACKERS: fetching Lambeau/Green Bay…");
    fetch(`https://api.weather.gov/points/${lambeau.lat},${lambeau.lon}`, { headers: { "Accept":"application/geo+json" } })
      .then(r=>r.json())
      .then(p=>{
        const forecastUrl = p?.properties?.forecast;
        const city = p?.properties?.relativeLocation?.properties?.city || "Green Bay";
        const state = p?.properties?.relativeLocation?.properties?.state || "WI";
        if(!forecastUrl) throw new Error("no forecast url");
        return fetch(forecastUrl, { headers: { "Accept":"application/geo+json" } })
          .then(r=>r.json())
          .then(f=>{
            const period = f?.properties?.periods?.[0];
            if(!period) throw new Error("no period");
            const lines = [];
            lines.push("PACKERS / LAMBEAU");
            lines.push(`AREA:      ${city}, ${state}`);
            lines.push(`FORECAST:  ${(period.name||"").toUpperCase()}`);
            lines.push(`TEMP:      ${period.temperature ?? "—"}${period.temperatureUnit ?? ""}`);
            lines.push(`WIND:      ${(period.windDirection||"").toUpperCase()} ${period.windSpeed||"—"}`);
            lines.push((period.shortForecast||"").toUpperCase());
            lines.forEach(l=>logLine(l));
            packersCache = { at: Date.now(), lines };
          });
      })
      .catch(()=>logLine("PACKERS: unavailable right now."));
  }

  function runSummerfest(){
    const list = sfData?.events || [];
    if(!list.length){ logLine("SUMMERFEST: unavailable."); return; }
    const e = pick(list);
    logLine("SUMMERFEST 2026:");
    logLine(`  ${e.date}`);
    logLine(`  ${e.time} p.m. — ${e.artist}`);
    logLine(`  STAGE: ${e.stage}`);
  }

  function runHistory(){
    const facts = histData?.facts || [];
    if(!facts.length){ logLine("HISTORY: unavailable."); return; }
    logLine("HISTORY:");
    logLine(`  ${pick(facts)}`);
  }

  function runFilm(){
    const items = filmData?.items || [];
    if(!items.length){ logLine("FILM: unavailable."); return; }
    const it = pick(items);
    const tag = (it.type || "").toUpperCase();
    logLine(`FILM ${tag}:`);
    logLine(`  ${it.text}`);
  }

  function help(){
    logLine("COMMANDS:");
    const list = commandHelp?.commands || [];
    if(list.length){
      list.forEach(c=>logLine(`  ${c.cmd} — ${c.desc}`));
    }else{
      logLine("  HELP — show commands");
      logLine("  LISTWX — list dispatches");
      logLine("  READ 1 — open dispatch");
    }
  }

  // ---------- COMMAND ROUTER ----------
  function runCommand(raw){
    const input = raw.trim();
    if(!input) return;
    logLine(`MKEWX> ${input}`);

    const parts = input.split(/\s+/);
    const cmd = (parts[0] || "").toUpperCase();
    const arg1 = (parts[1] || "").toUpperCase();

    if(cmd === "HELP" || cmd === "?") return help();
    if(cmd === "CLEAR"){ $("#termLog").innerHTML=""; return; }

    if(cmd === "READ"){
      const n = parseInt(parts[1], 10);
      if(!Number.isFinite(n)){ logLine("Usage: READ 1"); return; }
      loadDispatchByIndex(n);
      return;
    }

    if(cmd === "LISTWX") return listwx();

    if(cmd === "CUSTARD") return runCustard();
    if(cmd === "PACKERS") return runPackers();
    if(cmd === "SUMMERFEST") return runSummerfest();
    if(cmd === "HISTORY") return runHistory();
    if(cmd === "FILM") return runFilm();

    if(cmd === "RADAR" && arg1 === "REFRESH") return radarRefresh();
    if(cmd === "RADAR") return radarScroll();

    if(cmd === "RSS"){
      window.location.href = (document.querySelector("link[type='application/rss+xml']")?.getAttribute("href")) || "/feed.xml";
      return;
    }

    logLine("Unknown command. Type HELP.");
  }

  function wireTerminal(){
    const input = $("#cmd");
    if(!input) return;
    input.addEventListener("keydown", (e)=>{
      if(e.key === "Enter"){
        __beep("single");
        runCommand(input.value);
        input.value = "";
      }
    });
    setTimeout(()=>input.focus(), 400);
  }

  function init(){
    runBoot();
    startClock();
    wireTerminal();
    radarInit();

    // load datasets
    Promise.all([
      loadJSON(__asset("/assets/data/custard.json")).catch(()=>null),
      loadJSON(__asset("/assets/data/summerfest_2026.json")).catch(()=>null),
      loadJSON(__asset("/assets/data/history.json")).catch(()=>null),
      loadJSON(__asset("/assets/data/film.json")).catch(()=>null),
      loadJSON(__asset("/assets/data/commands.json")).catch(()=>null)
    ]).then(([c,s,h,f,ch])=>{
      custardData=c; sfData=s; histData=h; filmData=f; commandHelp=ch;
    });

    updateConditions();
    setInterval(updateConditions, 300000);

    logLine("MKEWX READY.");
    logLine("Type HELP. Try: LISTWX • READ 1 • SUMMERFEST");
  }

  document.addEventListener("DOMContentLoaded", init);
})();

// --- Tiny terminal beeps (WebAudio) ---
let __audioCtx = null;
function __beep(pattern="single"){
  try{
    if(!__audioCtx) __audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const ctx = __audioCtx;
    const now = ctx.currentTime;
    const mk = (t, dur, freq)=>{
      const o = ctx.createOscillator();
      const g = ctx.createGain();
      o.type = "square";
      o.frequency.value = freq;
      g.gain.setValueAtTime(0.0, t);
      g.gain.linearRampToValueAtTime(0.045, t+0.005);
      g.gain.linearRampToValueAtTime(0.0, t+dur);
      o.connect(g); g.connect(ctx.destination);
      o.start(t); o.stop(t+dur+0.01);
    };
    if(pattern === "double"){
      mk(now, 0.045, 520);
      mk(now+0.070, 0.045, 520);
    }else{
      mk(now, 0.040, 440);
    }
  }catch(e){ /* ignore */ }
}
