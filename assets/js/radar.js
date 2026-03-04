(function(){
  const SERVICE = "https://mapservices.weather.noaa.gov/eventdriven/rest/services/radar/radar_base_reflectivity_time/ImageServer";
  const EXPORT  = SERVICE + "/exportImage";
  const DEFAULT_BBOX = { xmin:-88.95, ymin:42.30, xmax:-86.95, ymax:44.10 };

  function bboxToString(b){ return [b.xmin,b.ymin,b.xmax,b.ymax].join(","); }
  function buildExportUrl(bbox){
    const u = new URL(EXPORT);
    u.searchParams.set("f","image");
    u.searchParams.set("bbox", bboxToString(bbox));
    u.searchParams.set("bboxSR","4326");
    u.searchParams.set("imageSR","4326");
    u.searchParams.set("size","760,760");
    u.searchParams.set("format","png32");
    u.searchParams.set("_ts", String(Date.now()));
    return u.toString();
  }
  function fmtMilwaukeeTime(d){
    const fmt = new Intl.DateTimeFormat("en-US",{
      timeZone:"America/Chicago",
      hour:"numeric", minute:"2-digit", second:"2-digit",
      hour12:true, timeZoneName:"short"
    });
    return fmt.format(d);
  }

  function createRadarScope(opts){
    const o = opts || {};
    const bbox = Object.assign({}, DEFAULT_BBOX, o.bbox || {});
    const refreshMs = o.refreshMs || 120000;

    const el = o.el;
    if(!el) throw new Error("createRadarScope: opts.el is required");

    const bg = el.querySelector("canvas[data-layer='bg']");
    const ret= el.querySelector("canvas[data-layer='returns']");
    const ui = el.querySelector("canvas[data-layer='ui']");
    const ov = el.querySelector("canvas[data-layer='overlay']");
    const bboxText = o.bboxText || null;
    const frameText= o.frameText || null;
    const ageText  = o.ageText || null;

    const bgc = bg.getContext("2d");
    const rtc = ret.getContext("2d");
    const uic = ui.getContext("2d");
    const ovc = ov.getContext("2d");

    let W=0,H=0,cx=0,cy=0,R=0;
    let running = true;
    let sweep = 0;
    let wedgeWidth = 0.14;
    let sweepSpeed = 0.018;
    let lastFrameAt = 0;
    let timer = null;

    const img = new Image();
    img.crossOrigin="anonymous";
    img.onload = ()=>{ lastFrameAt = Date.now(); if(frameText) frameText.textContent="OK (NOAA)"; };
    img.onerror = ()=>{ if(frameText) frameText.textContent="ERR (NOAA)"; };

    function project(lon, lat){
      const x=(lon-bbox.xmin)/(bbox.xmax-bbox.xmin);
      const y=1-(lat-bbox.ymin)/(bbox.ymax-bbox.ymin);
      const px=cx+(x-0.5)*2*R*0.95;
      const py=cy+(y-0.5)*2*R*0.95;
      return [px,py];
    }

    function resize(){
      const rect = el.getBoundingClientRect();
      const dpr = Math.max(1, window.devicePixelRatio||1);
      W = Math.floor(rect.width*dpr);
      H = Math.floor(rect.height*dpr);
      [bg,ret,ui,ov].forEach(c=>{ c.width=W; c.height=H; });
      cx=W/2; cy=H/2; R=Math.min(W,H)*0.45;
      rtc.clearRect(0,0,W,H);
      drawBackground();
      drawVectorOverlay();
    }

    function drawBackground(){
      bgc.clearRect(0,0,W,H);
      bgc.save();
      bgc.strokeStyle="rgba(242,178,74,0.28)";
      bgc.lineWidth=Math.max(1, W*0.002);
      bgc.beginPath(); bgc.arc(cx,cy,R,0,Math.PI*2); bgc.stroke();
      bgc.strokeStyle="rgba(242,178,74,0.12)";
      bgc.beginPath(); bgc.arc(cx,cy,R*1.02,0,Math.PI*2); bgc.stroke();
      bgc.restore();

      bgc.save();
      bgc.strokeStyle="rgba(242,178,74,0.12)";
      bgc.lineWidth=Math.max(1, W*0.0015);
      for(const rr of [0.25,0.50,0.75]){
        bgc.beginPath(); bgc.arc(cx,cy,R*rr,0,Math.PI*2); bgc.stroke();
      }
      bgc.restore();

      bgc.save();
      bgc.strokeStyle="rgba(242,178,74,0.10)";
      bgc.lineWidth=Math.max(1, W*0.0012);
      bgc.beginPath(); bgc.moveTo(cx-R,cy); bgc.lineTo(cx+R,cy); bgc.stroke();
      bgc.beginPath(); bgc.moveTo(cx,cy-R); bgc.lineTo(cx,cy+R); bgc.stroke();
      bgc.restore();
    }

    function drawVectorOverlay(){
      uic.clearRect(0,0,W,H);
      uic.save();
      uic.beginPath(); uic.arc(cx,cy,R,0,Math.PI*2); uic.clip();

      uic.strokeStyle="rgba(242,178,74,0.32)";
      uic.lineWidth=Math.max(1, W*0.0020);
      const coast=[
        [-87.71,43.75],
        [-87.93,43.28],
        [-87.91,43.04],
        [-87.82,42.80],
        [-87.82,42.58],
      ];
      uic.beginPath();
      coast.forEach((p,i)=>{ const [x,y]=project(p[0],p[1]); if(i===0) uic.moveTo(x,y); else uic.lineTo(x,y); });
      uic.stroke();

      const cities=[
        {name:"SBY", lon:-87.72, lat:43.75},
        {name:"MKE", lon:-87.91, lat:43.04},
        {name:"RAC", lon:-87.78, lat:42.73},
        {name:"KEN", lon:-87.82, lat:42.58},
      ];
      uic.fillStyle="rgba(242,178,74,0.44)";
      uic.font=`${Math.max(10, Math.floor(W*0.019))}px ui-monospace, Menlo, Monaco, Consolas, monospace`;
      cities.forEach(c=>{
        const [x,y]=project(c.lon,c.lat);
        uic.beginPath(); uic.arc(x,y, Math.max(2, W*0.006), 0, Math.PI*2); uic.fill();
        uic.fillText(c.name, x+Math.max(6,W*0.011), y-Math.max(6,W*0.011));
      });

      uic.restore();
    }

    function drawWedgeClip(ctx, ang, width){
      const a1=ang-width/2, a2=ang+width/2;
      ctx.beginPath(); ctx.moveTo(cx,cy); ctx.arc(cx,cy,R,a1,a2); ctx.closePath(); ctx.clip();
    }

    function drawAmberWedge(ctx){
      const s = R*2;
      ctx.filter="grayscale(1) contrast(2.2) brightness(1.05)";
      ctx.drawImage(img, cx-R, cy-R, s, s);
      ctx.filter="none";
      ctx.globalCompositeOperation="source-atop";
      ctx.fillStyle="rgba(242,178,74,1)";
      ctx.fillRect(cx-R, cy-R, s, s);
      ctx.globalCompositeOperation="source-over";
    }

    let lastUrl = "";
    function refreshFrame(){
      if(bboxText) bboxText.textContent = bboxToString(bbox);
      lastUrl = buildExportUrl(bbox);
      img.src = lastUrl;
    }

    function step(){
      if(running){
        rtc.save();
        rtc.beginPath(); rtc.arc(cx,cy,R,0,Math.PI*2); rtc.clip();
        rtc.fillStyle="rgba(0,0,0,0.07)";
        rtc.fillRect(0,0,W,H);
        rtc.restore();

        rtc.save();
        rtc.beginPath(); rtc.arc(cx,cy,R,0,Math.PI*2); rtc.clip();
        rtc.save();
        drawWedgeClip(rtc, sweep, wedgeWidth);
        rtc.globalAlpha=0.75;
        if(img.complete && img.naturalWidth){
          drawAmberWedge(rtc);
        }
        rtc.restore();
        rtc.restore();
        rtc.globalAlpha=1;

        ovc.clearRect(0,0,W,H);
        ovc.save();
        ovc.beginPath(); ovc.arc(cx,cy,R,0,Math.PI*2); ovc.clip();
        ovc.strokeStyle="rgba(242,178,74,0.60)";
        ovc.lineWidth=Math.max(1, W*0.0022);
        ovc.shadowColor="rgba(242,178,74,0.35)";
        ovc.shadowBlur=Math.max(6, W*0.01);
        ovc.beginPath();
        ovc.moveTo(cx,cy);
        ovc.lineTo(cx + Math.cos(sweep)*R, cy + Math.sin(sweep)*R);
        ovc.stroke();
        ovc.restore();

        sweep += sweepSpeed;
        if(sweep > Math.PI*2) sweep -= Math.PI*2;
      }

      if(ageText){
        const ageSec = lastFrameAt ? Math.max(0, Math.floor((Date.now()-lastFrameAt)/1000)) : 0;
        const ageStr = lastFrameAt ? `${Math.floor(ageSec/60)}m ${ageSec%60}s ago` : "—";
        ageText.textContent = `${ageStr} • ${fmtMilwaukeeTime(new Date())}`;
      }
      requestAnimationFrame(step);
    }

    function start(){
      resize();
      window.addEventListener("resize", resize);
      window.addEventListener("orientationchange", ()=>setTimeout(resize, 80));
      if(frameText) frameText.textContent="…";
      refreshFrame();
      timer = setInterval(()=>refreshFrame(), refreshMs);
      requestAnimationFrame(step);
    }

    start();
    return { refreshFrame, setRunning:(v)=>{running=!!v;}, stop:()=>{ if(timer) clearInterval(timer); }, getLastUrl:()=>lastUrl || buildExportUrl(bbox) };
  }

  window.MKEWX_Radar = { createRadarScope, buildExportUrl, DEFAULT_BBOX };
})();
