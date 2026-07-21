/* ═══════════════════════════════════════════════════════════════
   ShipEast Admin Portal — application logic
   Firebase 10.x modular SDK. Styled through SEDS tokens (styles.css).
   ═══════════════════════════════════════════════════════════════ */

import{initializeApp}from'https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js';
import{getAuth,signInWithEmailAndPassword,signOut,onAuthStateChanged}from'https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js';
import{getFirestore,collection,doc,addDoc,setDoc,updateDoc,deleteDoc,onSnapshot,query,orderBy,limit,serverTimestamp}from'https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js';

// ── Firebase Config (shipeast-1a1f6) ──
const firebaseConfig={
  apiKey:           'AIzaSyDcETjuHcvmy7TKL7vHW6sYlUk9sxa-6CA',
  authDomain:       'shipeast-1a1f6.firebaseapp.com',
  projectId:        'shipeast-1a1f6',
  storageBucket:    'shipeast-1a1f6.firebasestorage.app',
  messagingSenderId:'783428944628'
};
const app=initializeApp(firebaseConfig);
const auth=getAuth(app);
const db=getFirestore(app);

// ══════════════════════ LOCAL DATA MIRRORS ══════════════════════
var orders=[],drivers=[],merchants=[],promoCodes=[],notifHistory=[];
var analyticsStats={
  'Today':    [{lbl:'Revenue',val:'J$0'},{lbl:'Orders',val:'0'},{lbl:'Customers',val:'0'},{lbl:'Avg Order Value',val:'J$0'}],
  'This Week':[{lbl:'Revenue',val:'J$0'},{lbl:'Orders',val:'0'},{lbl:'Customers',val:'0'},{lbl:'Avg Order Value',val:'J$0'}],
  'This Month':[{lbl:'Revenue',val:'J$0'},{lbl:'Orders',val:'0'},{lbl:'Customers',val:'0'},{lbl:'Avg Order Value',val:'J$0'}],
};
var currentPeriod='Today',ordersFilter='All',driverMode='add',driverEditId=null,merchantMode='add',merchantEditId=null,unsubscribers=[];
var panelMerchantId=null,menuItemsUnsub=null,menuItemEditId=null,panelMenuItems=[];
var loadedOnce={orders:false,drivers:false,merchants:false,promos:false,notifs:false};

// ══════════════════════ PRIMITIVES ══════════════════════
function esc(s){ return String(s==null?'':s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
function $(id){ return document.getElementById(id); }
function reduceMotion(){ return window.matchMedia('(prefers-reduced-motion: reduce)').matches; }

/** Phosphor icon from the inline sprite. */
function icon(name,cls){ return '<svg class="ic '+(cls||'')+'" aria-hidden="true"><use href="#i-'+name+'"/></svg>'; }

/** JMD money, always tabular. */
function money(n){ return 'J$'+Math.round(Number(n)||0).toLocaleString('en-JM'); }
function parseAmt(a){ var n=parseFloat(String(a==null?'0':a).replace(/[^0-9.]/g,'')); return isNaN(n)?0:n; }

// ── Toasts (replaces every alert()) ──
var TOAST_ICON={success:'success',error:'error',warning:'warning',info:'info'};
function toast(type,msg,title){
  var host=$('toast-host'); if(!host) return;
  var el=document.createElement('div');
  el.className='toast t-'+type;
  el.setAttribute('role',type==='error'?'alert':'status');
  el.innerHTML=icon(TOAST_ICON[type]||'info')+
    '<div class="toast-msg">'+(title?'<b>'+esc(title)+'</b>':'')+esc(msg)+'</div>';
  host.appendChild(el);
  var life=type==='error'?6000:3600;
  setTimeout(function(){
    el.classList.add('out');
    setTimeout(function(){ el.remove(); },reduceMotion()?0:200);
  },life);
}

// ── Confirm dialog (replaces every confirm()) ──
var confirmResolve=null;
function confirmDialog(opts){
  return new Promise(function(resolve){
    confirmResolve=resolve;
    $('cf-ico').className='m-ico '+(opts.tone||'danger');
    $('cf-ico').innerHTML=icon(opts.tone==='warning'?'warning':'delete','ic-lg');
    $('cf-title').textContent=opts.title||'Are you sure?';
    $('cf-body').textContent=opts.body||'';
    var ok=$('cf-ok');
    ok.textContent=opts.confirmLabel||'Delete';
    ok.className='btn '+(opts.tone==='warning'?'btn-primary':'btn-danger');
    openModal('modal-confirm');
  });
}
function settleConfirm(result){
  closeModal('modal-confirm');
  if(confirmResolve){ var r=confirmResolve; confirmResolve=null; r(result); }
}

// ── Count-up numbers ──
function countUp(el,target,fmt){
  if(!el) return;
  fmt=fmt||function(v){ return String(v); };
  var from=Number(el.dataset.val||0), to=Number(target)||0;
  el.dataset.val=to;
  if(reduceMotion()||from===to){ el.textContent=fmt(to); return; }
  var start=performance.now(),dur=600;
  (function step(now){
    var p=Math.min(1,(now-start)/dur);
    var eased=1-Math.pow(1-p,3);              // decelerate
    el.textContent=fmt(Math.round(from+(to-from)*eased));
    if(p<1) requestAnimationFrame(step);
  })(start);
}

// ── Skeletons ──
function skeletonRows(cols,rows){
  var out='';
  for(var r=0;r<(rows||5);r++){
    out+='<tr class="sk-row">';
    for(var c=0;c<cols;c++){
      var w=c===0?'62%':(c===cols-1?'46px':(38+((c*29)%42))+'%');
      out+='<td><div class="sk sk-line" style="width:'+w+'"></div></td>';
    }
    out+='</tr>';
  }
  return out;
}

// ── Empty-state illustrations (2-tone: coral/red + warm cream) ──
var ART={
  box:'<circle cx="100" cy="104" r="66" fill="#FFF1F3"/>'+
      '<path d="M100 46 40 76v56l60 30 60-30V76z" fill="#F7B9C2"/>'+
      '<path d="M100 46 40 76l60 30 60-30z" fill="#E1495F"/>'+
      '<path d="M100 106v56l60-30V76z" fill="#C8102E"/>'+
      '<path d="M70 61l60 30v22" stroke="#FFF1F3" stroke-width="6" fill="none" stroke-linecap="round"/>',
  search:'<circle cx="100" cy="104" r="66" fill="#FFF1F3"/>'+
      '<circle cx="90" cy="94" r="34" fill="none" stroke="#E1495F" stroke-width="10"/>'+
      '<circle cx="90" cy="94" r="22" fill="#FFE0E5"/>'+
      '<path d="M116 120l26 26" stroke="#C8102E" stroke-width="12" stroke-linecap="round"/>',
  bell:'<circle cx="100" cy="104" r="66" fill="#FFF1F3"/>'+
      '<path d="M100 56a30 30 0 0 1 30 30v26l12 16H58l12-16V86a30 30 0 0 1 30-30z" fill="#E1495F"/>'+
      '<path d="M86 136a14 14 0 0 0 28 0z" fill="#C8102E"/>'+
      '<circle cx="100" cy="50" r="7" fill="#C8102E"/>',
  ticket:'<circle cx="100" cy="104" r="66" fill="#FFF1F3"/>'+
      '<path d="M46 82h108v18a12 12 0 0 0 0 24v18H46v-18a12 12 0 0 0 0-24z" fill="#E1495F"/>'+
      '<path d="M100 82v60" stroke="#FFF1F3" stroke-width="5" stroke-dasharray="8 8"/>'+
      '<circle cx="72" cy="112" r="10" fill="#FFE0E5"/>',
  users:'<circle cx="100" cy="104" r="66" fill="#FFF1F3"/>'+
      '<circle cx="100" cy="88" r="24" fill="#E1495F"/>'+
      '<path d="M56 152a44 44 0 0 1 88 0z" fill="#C8102E"/>',
  store:'<circle cx="100" cy="104" r="66" fill="#FFF1F3"/>'+
      '<path d="M56 88h88v62H56z" fill="#F7B9C2"/>'+
      '<path d="M50 66h100l10 22H40z" fill="#E1495F"/>'+
      '<path d="M86 150v-32h28v32z" fill="#C8102E"/>'
};
function emptyState(art,title,copy,cta){
  return '<div class="empty">'+
    '<svg viewBox="0 0 200 200" aria-hidden="true">'+(ART[art]||ART.box)+'</svg>'+
    '<div class="empty-title">'+esc(title)+'</div>'+
    '<div class="empty-copy">'+esc(copy)+'</div>'+
    (cta||'')+'</div>';
}
function emptyRow(cols,art,title,copy){
  return '<tr><td colspan="'+cols+'">'+emptyState(art,title,copy)+'</td></tr>';
}

// ── Status badges ──
var STATUS_TONE={
  delivered:'success',approved:'success',Active:'success',Online:'success',Open:'success',
  pending:'info',Pending:'info',
  confirmed:'warning',accepted:'warning',in_transit:'warning',picked_up:'warning',
  'On the Way':'warning','On Delivery':'warning','Picked Up':'warning',
  cancelled:'danger',rejected:'danger',Cancelled:'danger',Closed:'danger',
  Expired:'neutral',Offline:'neutral',Inactive:'neutral'
};
var STATUS_LABEL={in_transit:'In Transit',picked_up:'Picked Up',accepted:'Accepted',
  confirmed:'Confirmed',delivered:'Delivered',pending:'Pending',cancelled:'Cancelled',
  approved:'Approved',rejected:'Rejected'};
function badge(s){
  return '<span class="bdg bg-'+(STATUS_TONE[s]||'neutral')+'">'+esc(STATUS_LABEL[s]||s)+'</span>';
}

// ── Stars ──
function stars(r){
  var v=Number(r)||0,f=Math.round(v),s='';
  for(var i=1;i<=5;i++) s+=icon(i<=f?'star-f':'star',i<=f?'':'off');
  return '<span class="stars">'+s+'</span><span class="rating-val">'+v.toFixed(1)+'</span>';
}

// ── Category glyphs (duotone tinted chips, per-category hue) ──
var CATS={Food:{ic:'cat-food',cls:'c-food'},Grocery:{ic:'cat-grocery',cls:'c-grocery'},
  Pharmacy:{ic:'cat-pharmacy',cls:'c-pharmacy'},Packages:{ic:'cat-packages',cls:'c-packages'}};
function catIcon(cat,size){
  var c=CATS[cat]||{ic:'merchants',cls:'c-other'};
  return '<div class="cat-ico '+(size==='lg'?'lg ':'')+c.cls+'">'+icon(c.ic)+'</div>';
}
function merchantMedia(m,size){
  if(m.imageUrl) return '<img class="thumb'+(size==='lg'?' lg':'')+'" src="'+esc(m.imageUrl)+'" alt="" '+
    'onerror="this.outerHTML=this.dataset.fb" data-fb="'+esc(catIcon(m.category,size))+'">';
  return catIcon(m.category,size);
}

// ══════════════════════ THEME ══════════════════════
function applyTheme(theme){
  document.documentElement.setAttribute('data-theme',theme);
  var btn=$('theme-btn');
  if(btn){
    btn.innerHTML=icon(theme==='dark'?'sun':'moon');
    btn.setAttribute('aria-label',theme==='dark'?'Switch to light theme':'Switch to dark theme');
    btn.title=btn.getAttribute('aria-label');
  }
}
function initTheme(){
  var saved=null;
  try{ saved=localStorage.getItem('se-theme'); }catch(e){}
  applyTheme(saved||'light');   // dark ships default-off; toggle lives in the topbar
}
function toggleTheme(){
  var next=document.documentElement.getAttribute('data-theme')==='dark'?'light':'dark';
  applyTheme(next);
  try{ localStorage.setItem('se-theme',next); }catch(e){}
}

// ══════════════════════ AUTH ══════════════════════
// NOTE: Create admin user in Firebase Console → Authentication → Add user → admin@shipeast.com
function doLogin(){
  var e=$('l-email').value.trim(), p=$('l-pass').value;
  var errEl=$('l-err'), btnEl=$('login-btn');
  errEl.classList.remove('show');
  function fail(msg){
    errEl.innerHTML=icon('warning','ic-sm')+'<span>'+esc(msg)+'</span>';
    errEl.classList.add('show');
    btnEl.disabled=false; btnEl.innerHTML='Sign In'+icon('caret-right');
  }
  if(!e||!p){ fail('Please enter your email and password.'); return; }
  btnEl.disabled=true; btnEl.innerHTML='<span class="spin"></span>Signing in…';
  signInWithEmailAndPassword(auth,e,p).catch(function(err){
    var bad=['auth/user-not-found','auth/wrong-password','auth/invalid-credential','auth/invalid-email'];
    fail(bad.indexOf(err.code)>-1?'Invalid credentials. Please try again.':err.message);
  });
}
function doLogout(){ signOut(auth); }

// ══════════════════════ NAVIGATION ══════════════════════
var pageLabels={dashboard:'Dashboard',orders:'Orders',drivers:'Drivers',merchants:'Merchants',
  notifications:'Notifications',promos:'Promo Codes',analytics:'Analytics'};
function navTo(page){
  document.querySelectorAll('.ni').forEach(function(n){ n.classList.remove('active'); });
  var ni=document.querySelector('.ni[data-page="'+page+'"]'); if(ni) ni.classList.add('active');
  document.querySelectorAll('.page').forEach(function(p){ p.classList.remove('active'); });
  var pg=$('page-'+page); if(pg) pg.classList.add('active');
  var lbl=pageLabels[page]||page;
  $('tb-pg').textContent=lbl;
  $('tb-title').textContent=lbl;
  if(page==='analytics'){ renderBarChart(); }
  if(window.innerWidth<=900) closeMobileSidebar();
}

// ══════════════════════ SIDEBAR ══════════════════════
var sidebarCollapsed=false;
function toggleSidebar(){
  if(window.innerWidth<=900){
    var sb=$('sidebar'), mob=$('mob-overlay');
    if(sb.classList.contains('mob-open')){ sb.classList.remove('mob-open'); mob.classList.remove('open'); }
    else{ sb.classList.remove('collapsed'); sb.classList.add('mob-open'); mob.classList.add('open'); }
  }else{
    sidebarCollapsed=!sidebarCollapsed;
    $('sidebar').classList.toggle('collapsed',sidebarCollapsed);
    $('main').classList.toggle('expanded',sidebarCollapsed);
  }
}
function closeMobileSidebar(){
  $('sidebar').classList.remove('mob-open');
  $('mob-overlay').classList.remove('open');
}

// ══════════════════════ FIRESTORE LISTENERS ══════════════════════
function startListeners(){
  // ORDERS
  try{
    unsubscribers.push(onSnapshot(
      query(collection(db,'orders'),orderBy('createdAt','desc'),limit(200)),
      function(snap){
        orders=snap.docs.map(function(d){
          var o=d.data();
          var ts=o.createdAt&&o.createdAt.toDate?o.createdAt.toDate():null;
          var tsStr=ts?ts.toLocaleTimeString('en-JM',{hour:'2-digit',minute:'2-digit'}):o.time||'—';
          var drvName=o.driverName||o.driver||'';
          if(!drvName&&o.driverId){ var drv=drivers.find(function(x){return x.id===o.driverId;}); if(drv) drvName=drv.name; }
          var rawTotal=o.total!=null?Number(o.total):null;
          return {id:d.id,customer:o.customerName||o.customer||'Unknown',custPhone:o.customerPhone||o.custPhone||'—',
            merchant:o.merchantName||o.merchant||'Unknown',merchantId:o.merchantId||'',merchantAddr:o.merchantAddr||'—',
            driver:drvName||'—',driverId:o.driverId||'',
            driverPhone:o.driverPhone||'—',rawTotal:rawTotal,
            amount:rawTotal!=null?money(rawTotal):(o.amount||'—'),
            payment:o.paymentMethod||o.payment||'—',
            status:o.status||'pending',time:tsStr,_ts:ts,items:o.items||[],
            address:o.deliveryAddress||o.address||'—',_docId:d.id};
        });
        loadedOnce.orders=true;
        renderDashboard();renderOrders();renderAnalytics();renderTopMerch();
      },
      function(e){ loadedOnce.orders=true; console.warn('orders:',e.message); toast('error','Could not load orders: '+e.message); renderOrders(); }
    ));
  }catch(e){ console.warn('orders init:',e.message); }

  // DRIVERS
  try{
    unsubscribers.push(onSnapshot(
      collection(db,'drivers'),
      function(snap){
        drivers=snap.docs.map(function(d){
          var o=d.data();
          var rawStatus=o.status||'pending';
          var approved=rawStatus==='approved';
          var statusLbl=approved?(o.onDelivery?'On Delivery':(o.isOnline?'Online':'Offline')):rawStatus;
          return {id:d.id,name:o.name||'—',phone:o.phone||'—',email:o.email||'—',
            vtype:o.vehicleType||o.vtype||'Car',vehicle:o.vehicleModel||o.vehicle||'—',
            plate:o.licencePlate||o.plate||'—',dlicence:o.licenceNumber||o.dlicence||'—',
            rating:o.averageRating||o.rating||5.0,trips:o.totalTrips||o.trips||0,
            ratingCounts:o.ratingCounts||o.ratingBreakdown||null,
            ratingTotal:o.ratingCount!=null?o.ratingCount:null,
            status:statusLbl,rawStatus:rawStatus,approved:approved,
            isOnline:o.isOnline||false,onDelivery:o.onDelivery||false,_docId:d.id};
        });
        loadedOnce.drivers=true;
        renderDrivers();renderDashboard();renderOrders();
      },
      function(e){ loadedOnce.drivers=true; console.warn('drivers:',e.message); toast('error','Could not load drivers: '+e.message); renderDrivers(); }
    ));
  }catch(e){ console.warn('drivers init:',e.message); }

  // MERCHANTS
  try{
    unsubscribers.push(onSnapshot(
      collection(db,'merchants'),
      function(snap){
        merchants=snap.docs.map(function(d){
          var o=d.data();
          var isOpenVal=o.isOpen!=null?o.isOpen:(o.open!=null?o.open:true);
          return {id:d.id,name:o.name||'—',category:o.category||'Food',owner:o.owner||'—',
            phone:o.phone||'—',email:o.email||'—',address:o.address||'—',hours:o.hours||o.deliveryTime||'—',
            fee:o.fee||o.deliveryFee||'—',ordersToday:o.ordersToday||0,rating:o.averageRating||o.rating||5.0,
            open:isOpenVal,imageUrl:o.imageUrl||o.image||'',_docId:d.id};
        });
        loadedOnce.merchants=true;
        renderMerchants();renderTopMerch();
      },
      function(e){ loadedOnce.merchants=true; console.warn('merchants:',e.message); toast('error','Could not load merchants: '+e.message); renderMerchants(); }
    ));
  }catch(e){ console.warn('merchants init:',e.message); }

  // PROMO CODES
  try{
    unsubscribers.push(onSnapshot(
      query(collection(db,'promoCodes'),orderBy('createdAt','desc')),
      function(snap){
        var now=new Date();
        promoCodes=snap.docs.map(function(d){
          var o=d.data();
          var expired=o.validUntil&&o.validUntil!=='—'&&new Date(o.validUntil)<now;
          var active=o.active!==false&&!expired;
          var discAmt=o.discountAmount!=null?o.discountAmount:null;
          var discType=o.discountType||o.type||'percent';
          var discStr=discAmt!=null?(discType==='percent'?discAmt+'% Off':money(discAmt)+' Off'):(o.discount||'—');
          return {id:d.id,code:o.code||d.id,discount:discStr,discountType:discType,discountAmount:discAmt,
            usedCount:o.usedCount!=null?o.usedCount:(o.used!=null?o.used:0),
            maxUses:o.maxUses!=null?o.maxUses:(o.max!=null?o.max:100),
            validUntil:o.validUntil||'—',status:active?'Active':'Expired',_docId:d.id};
        });
        loadedOnce.promos=true;
        renderPromos();
      },
      function(e){ loadedOnce.promos=true; console.warn('promoCodes:',e.message); toast('error','Could not load promo codes: '+e.message); renderPromos(); }
    ));
  }catch(e){ console.warn('promoCodes init:',e.message); }

  // NOTIFICATIONS
  try{
    unsubscribers.push(onSnapshot(
      query(collection(db,'notifications'),orderBy('createdAt','desc'),limit(50)),
      function(snap){
        notifHistory=snap.docs.map(function(d){
          var o=d.data();
          var ts=o.createdAt&&o.createdAt.toDate
            ?new Date(o.createdAt.toDate()).toLocaleString('en-JM',{month:'short',day:'numeric',hour:'2-digit',minute:'2-digit'})
            :'—';
          var TARGETS={customers:'All Customers',drivers:'All Drivers',all:'Everyone'};
          var t=o.target||'all';
          return {id:d.id,title:o.title||'—',msg:o.message||'—',target:TARGETS[t]||t,time:ts,_docId:d.id};
        });
        loadedOnce.notifs=true;
        renderNotifHist();
      },
      function(e){ loadedOnce.notifs=true; console.warn('notifications:',e.message); renderNotifHist(); }
    ));
  }catch(e){ console.warn('notifications init:',e.message); }
}
function stopListeners(){ unsubscribers.forEach(function(u){ u(); }); unsubscribers=[]; }

// ══════════════════════ SPARKLINE ══════════════════════
function sparkline(values,color){
  if(!values||values.length<2) return '';
  var w=120,h=26,max=Math.max.apply(null,values)||1;
  var pts=values.map(function(v,i){
    return [(i/(values.length-1))*w, h-2-(v/max)*(h-6)];
  });
  var d=pts.map(function(p,i){ return (i?'L':'M')+p[0].toFixed(1)+' '+p[1].toFixed(1); }).join(' ');
  var area=d+' L'+w+' '+h+' L0 '+h+' Z';
  var uid='sp'+Math.random().toString(36).slice(2,8);
  return '<svg class="spark" viewBox="0 0 '+w+' '+h+'" preserveAspectRatio="none" aria-hidden="true">'+
    '<defs><linearGradient id="'+uid+'" x1="0" y1="0" x2="0" y2="1">'+
      '<stop offset="0%" stop-color="'+color+'" stop-opacity=".28"/>'+
      '<stop offset="100%" stop-color="'+color+'" stop-opacity="0"/></linearGradient></defs>'+
    '<path d="'+area+'" fill="url(#'+uid+')"/>'+
    '<path d="'+d+'" fill="none" stroke="'+color+'" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" vector-effect="non-scaling-stroke"/>'+
  '</svg>';
}
function hourlyCounts(list){
  var now=new Date(), out=[];
  for(var h=0;h<24;h+=3){
    var s=new Date(now.getFullYear(),now.getMonth(),now.getDate(),h);
    var e=new Date(s.getTime()+3*3600000);
    out.push(list.filter(function(o){ return o._ts&&o._ts>=s&&o._ts<e; }).length);
  }
  return out;
}

// ══════════════════════ DASHBOARD ══════════════════════
function renderDashboard(){
  var now=new Date();
  var todayStart=new Date(now.getFullYear(),now.getMonth(),now.getDate());
  var todayOrders=orders.filter(function(o){ return o._ts&&o._ts>=todayStart; });
  var deliveredToday=todayOrders.filter(function(o){ return isDeliveredStatus(o.status); });
  var pendingOrders=orders.filter(function(o){ return o.status==='pending'||o.status==='Pending'; }).length;
  var revenueToday=deliveredToday.reduce(function(s,o){ return s+(o.rawTotal!=null?o.rawTotal:parseAmt(o.amount)); },0);
  var onlineDrv=drivers.filter(function(d){ return d.isOnline&&d.approved; }).length;

  countUp($('stat-orders'),todayOrders.length);
  countUp($('stat-revenue'),revenueToday,money);
  countUp($('stat-pending'),pendingOrders);
  countUp($('stat-drivers'),onlineDrv);

  var sp1=$('spark-orders'); if(sp1) sp1.innerHTML=sparkline(hourlyCounts(todayOrders),'#C8102E');
  var sp2=$('spark-revenue'); if(sp2) sp2.innerHTML=sparkline(hourlyCounts(deliveredToday),'#F5A524');

  var tbody=$('dash-tbody');
  if(!loadedOnce.orders){ tbody.innerHTML=skeletonRows(7,5); return; }
  if(!orders.length){
    tbody.innerHTML=emptyRow(7,'box','No orders yet','New customer orders will appear here the moment they are placed.');
    return;
  }
  tbody.innerHTML=orders.slice(0,10).map(function(o){
    return '<tr>'+
      '<td><span class="cell-id">'+esc(o.id)+'</span></td>'+
      '<td>'+esc(o.customer)+'</td>'+
      '<td>'+esc(o.merchant)+'</td>'+
      '<td class="cell-mute">'+esc(o.driver)+'</td>'+
      '<td class="right cell-strong">'+esc(o.amount)+'</td>'+
      '<td>'+badge(o.status)+'</td>'+
      '<td><button class="aicon ai-v" data-action="view-order" data-oid="'+esc(o._docId||o.id)+'" title="View order" aria-label="View order">'+icon('view')+'</button></td>'+
    '</tr>';
  }).join('');
}

// ══════════════════════ ORDERS ══════════════════════
function isActiveStatus(s){ return['pending','accepted','confirmed','in_transit','picked_up','Pending','On the Way','Confirmed','Picked Up'].indexOf(s)>-1; }
function isDeliveredStatus(s){ return s==='delivered'||s==='Delivered'; }
function isCancelledStatus(s){ return s==='cancelled'||s==='Cancelled'; }
function updateOrdersTabs(){
  var counts={
    All:orders.length,
    Active:orders.filter(function(o){ return isActiveStatus(o.status); }).length,
    Completed:orders.filter(function(o){ return isDeliveredStatus(o.status); }).length,
    Cancelled:orders.filter(function(o){ return isCancelledStatus(o.status); }).length
  };
  var tabs=$('orders-tabs'); if(!tabs) return;
  tabs.innerHTML=['All','Active','Completed','Cancelled'].map(function(k){
    return '<div class="tab'+(ordersFilter===k?' active':'')+'" data-filter="'+k+'" role="tab" tabindex="0">'+
      k+' <b class="num">'+counts[k]+'</b></div>';
  }).join('');
}
function renderOrders(){
  updateOrdersTabs();
  var tbody=$('orders-tbody'); if(!tbody) return;
  if(!loadedOnce.orders){ tbody.innerHTML=skeletonRows(9,7); return; }
  var search=(($('orders-search')||{}).value||'').toLowerCase();
  var rows=orders.filter(function(o){
    var tm=ordersFilter==='All'||
      (ordersFilter==='Active'&&isActiveStatus(o.status))||
      (ordersFilter==='Completed'&&isDeliveredStatus(o.status))||
      (ordersFilter==='Cancelled'&&isCancelledStatus(o.status));
    var sm=!search||o.id.toLowerCase().includes(search)||o.customer.toLowerCase().includes(search)||o.merchant.toLowerCase().includes(search);
    return tm&&sm;
  });
  if(!rows.length){
    tbody.innerHTML=search
      ? emptyRow(9,'search','No matching orders','Nothing matched “'+search+'”. Try an order ID, customer, or merchant name.')
      : emptyRow(9,'box','Nothing in “'+ordersFilter+'”','No orders currently sit in this state.');
    return;
  }
  tbody.innerHTML=rows.map(function(o){
    return '<tr>'+
      '<td><span class="cell-id">'+esc(o.id)+'</span></td>'+
      '<td>'+esc(o.customer)+'</td>'+
      '<td>'+esc(o.merchant)+'</td>'+
      '<td class="cell-mute">'+esc(o.driver)+'</td>'+
      '<td class="right cell-strong">'+esc(o.amount)+'</td>'+
      '<td><span class="bdg bg-neutral plain">'+esc(o.payment)+'</span></td>'+
      '<td>'+badge(o.status)+'</td>'+
      '<td class="cell-mute num">'+esc(o.time)+'</td>'+
      '<td><button class="aicon ai-v" data-action="view-order" data-oid="'+esc(o._docId||o.id)+'" title="View order" aria-label="View order">'+icon('view')+'</button></td>'+
    '</tr>';
  }).join('');
}

// ══════════════════════ ORDER SIDE PANEL ══════════════════════
function openOrderPanel(oid){
  var o=orders.find(function(x){ return x._docId===oid||x.id===oid; });
  if(!o) return;
  $('sp-sub').textContent='Order Details';
  $('sp-title').textContent=o.id;
  var steps=['Placed','Confirmed','Picked Up','On the Way','Delivered'];
  var sfMap={pending:1,confirmed:2,accepted:2,picked_up:3,in_transit:4,delivered:5,
    Pending:1,Confirmed:2,'Picked Up':3,'On the Way':4,Delivered:5};
  var idx=sfMap[o.status]||1;
  if(isCancelledStatus(o.status)) idx=0;
  var flow='<div class="sf">';
  steps.forEach(function(s,i){
    var state=i<idx-1?'done':(i===idx-1?'done current':'');
    flow+='<div class="sf-wrap"><div class="sf-dot '+state+'"></div><div class="sf-lbl">'+s+'</div></div>';
    if(i<steps.length-1) flow+='<div class="sf-line'+(i<idx-1?' done':'')+'"></div>';
  });
  flow+='</div><div style="text-align:center;margin-bottom:16px">'+badge(o.status)+'</div>';

  var itemsHtml=(o.items||[]).map(function(item){
    if(item&&typeof item==='object'){
      var qty=item.quantity||1;
      var price=item.price!=null?money(item.price):'—';
      return '<div class="sp-row"><span class="sp-lbl">'+esc(item.name||item.title||'Item')+'</span>'+
             '<span class="sp-val num">'+qty+'× '+price+'</span></div>';
    }
    return '<div class="sp-row"><span class="sp-lbl">'+esc(item)+'</span></div>';
  }).join('');
  if(!itemsHtml) itemsHtml='<div class="empty-copy">No items listed on this order.</div>';

  var di=o.driverId?drivers.find(function(x){ return x.id===o.driverId; }):null;
  var dp=di?di.phone:(o.driverPhone||'—');

  $('sp-body').innerHTML=
    '<div class="sp-sec"><div class="sp-sec-title">Status Flow</div>'+flow+'</div>'+
    '<div class="sp-sec"><div class="sp-sec-title">Customer</div>'+
      row('Name',esc(o.customer))+row('Phone',esc(o.custPhone))+
      row('Delivery Address','<span class="sp-val sm">'+esc(o.address)+'</span>',true)+
      row('Payment',esc(o.payment))+
    '</div>'+
    '<div class="sp-sec"><div class="sp-sec-title">Merchant</div>'+
      row('Name',esc(o.merchant))+
      row('Address','<span class="sp-val sm">'+esc(o.merchantAddr)+'</span>',true)+
    '</div>'+
    '<div class="sp-sec"><div class="sp-sec-title">Driver</div>'+
      row('Name',esc(o.driver))+row('Phone',esc(dp))+
    '</div>'+
    '<div class="sp-sec"><div class="sp-sec-title">Order Total</div>'+
      '<div class="sp-row"><span class="sp-lbl">Amount</span><span class="sp-val money">'+esc(o.amount)+'</span></div>'+
    '</div>'+
    '<div class="sp-sec"><div class="sp-sec-title">Items</div>'+itemsHtml+'</div>'+
    '<div class="sp-sec"><div class="sp-sec-title">Admin Actions</div>'+
      '<div class="fr"><label for="sp-assign-driver">Assign Driver</label>'+
        '<select id="sp-assign-driver"><option value="">— Unassigned —</option>'+
          drivers.filter(function(d){ return d.approved; }).map(function(d){
            return '<option value="'+esc(d.id)+'"'+(o.driverId===d.id?' selected':'')+'>'+
              esc(d.name)+(d.isOnline?' (online)':' (offline)')+'</option>';
          }).join('')+
        '</select></div>'+
      '<div class="fr"><label for="sp-update-status">Update Status</label>'+
        '<select id="sp-update-status">'+
          ['pending','confirmed','accepted','in_transit','picked_up','delivered','cancelled'].map(function(s){
            return '<option value="'+s+'"'+(o.status===s?' selected':'')+'>'+(STATUS_LABEL[s]||s)+'</option>';
          }).join('')+
        '</select></div>'+
      '<button class="btn btn-primary btn-block" id="sp-save-btn" data-action="save-order" data-oid="'+esc(o._docId)+'">'+
        icon('check')+'Save Changes</button>'+
    '</div>';
  openSidePanel();
}
function row(label,valueHtml,raw){
  return '<div class="sp-row"><span class="sp-lbl">'+label+'</span>'+
    (raw?valueHtml:'<span class="sp-val">'+valueHtml+'</span>')+'</div>';
}
function saveOrderChanges(docId){
  var driverId=(($('sp-assign-driver')||{}).value)||'';
  var status=(($('sp-update-status')||{}).value)||'';
  var upd={updatedAt:serverTimestamp()};
  if(driverId){
    var drv=drivers.find(function(d){ return d.id===driverId; });
    if(drv){ upd.driverId=driverId; upd.driverName=drv.name; upd.driverPhone=drv.phone||'—'; }
  }
  if(status) upd.status=status;
  if(Object.keys(upd).length<=1){ toast('warning','Nothing to save — pick a driver or a status first.'); return; }
  var btn=$('sp-save-btn');
  if(btn){ btn.disabled=true; btn.innerHTML='<span class="spin"></span>Saving…'; }
  updateDoc(doc(db,'orders',docId),upd).then(function(){
    closeSidePanel();
    toast('success','Order updated.');
  }).catch(function(e){
    toast('error',e.message,'Could not update order');
    if(btn){ btn.disabled=false; btn.innerHTML=icon('check')+'Save Changes'; }
  });
}

// ══════════════════════ DRIVERS ══════════════════════
function renderDrivers(){
  var el=$('drivers-stats');
  if(el){
    var onlineC=drivers.filter(function(d){ return d.isOnline&&d.approved; }).length;
    var delC=drivers.filter(function(d){ return d.onDelivery; }).length;
    var pendC=drivers.filter(function(d){ return d.rawStatus==='pending'; }).length;
    el.innerHTML=
      statCard('drivers','Total Drivers',drivers.length,'','')+
      statCard('bolt','Online',onlineC,'Available now','success')+
      statCard('orders','On Delivery',delC,'Currently delivering','ocean')+
      statCard('clock','Pending Approval',pendC,'Awaiting review','gold');
  }
  var tbody=$('drivers-tbody'); if(!tbody) return;
  if(!loadedOnce.drivers){ tbody.innerHTML=skeletonRows(9,5); return; }
  if(!drivers.length){
    tbody.innerHTML=emptyRow(9,'users','No drivers yet','Add your first driver, or wait for a rider to sign up in the driver app.');
    return;
  }
  tbody.innerHTML=drivers.map(function(d){
    var activeCol;
    if(d.rawStatus==='pending'){
      activeCol='<div class="cell-actions">'+
        '<button class="btn btn-sm btn-success" data-action="approve-driver" data-id="'+esc(d.id)+'">'+icon('check')+'Approve</button>'+
        '<button class="btn btn-sm btn-danger" data-action="reject-driver" data-id="'+esc(d.id)+'">'+icon('close')+'Reject</button>'+
      '</div>';
    }else if(d.rawStatus==='rejected'){
      activeCol='<button class="btn btn-sm btn-outline" data-action="approve-driver" data-id="'+esc(d.id)+'" title="Re-approve this driver">'+
        icon('undo')+'Re-approve</button>';
    }else{
      activeCol='<label class="tgl" title="Toggle online"><input type="checkbox"'+(d.isOnline?' checked':'')+
        ' class="tgl-driver-online" data-id="'+esc(d.id)+'" aria-label="Driver online"><span class="ts"></span></label>';
    }
    return '<tr>'+
      '<td><div class="cell-media"><span class="dot'+(d.isOnline&&d.approved?' on':'')+'"></span><b>'+esc(d.name)+'</b></div></td>'+
      '<td class="cell-mute num">'+esc(d.phone)+'</td>'+
      '<td>'+esc(d.vtype)+'</td>'+
      '<td><span class="bdg bg-neutral plain num">'+esc(d.plate)+'</span></td>'+
      '<td>'+stars(d.rating)+'</td>'+
      '<td class="right num">'+d.trips+'</td>'+
      '<td>'+badge(d.rawStatus)+'</td>'+
      '<td>'+activeCol+'</td>'+
      '<td><div class="cell-actions">'+
        '<button class="aicon ai-v" data-action="view-driver" data-id="'+esc(d.id)+'" title="View" aria-label="View driver">'+icon('view')+'</button>'+
        '<button class="aicon ai-e" data-action="edit-driver" data-id="'+esc(d.id)+'" title="Edit" aria-label="Edit driver">'+icon('edit')+'</button>'+
        '<button class="aicon ai-d" data-action="del-driver" data-id="'+esc(d.id)+'" title="Delete" aria-label="Delete driver">'+icon('delete')+'</button>'+
      '</div></td>'+
    '</tr>';
  }).join('');
}
function statCard(ic,label,value,sub,accent){
  var a=accent?' ac-'+accent:'';
  var c=accent?' c-'+accent:'';
  return '<div class="sc'+a+'"><div class="sc-top"><div><div class="sc-lbl">'+esc(label)+'</div>'+
    '<div class="sc-val num">'+esc(String(value))+'</div></div>'+
    '<div class="sc-chip'+c+'">'+icon(ic)+'</div></div>'+
    (sub?'<div class="sc-sub">'+esc(sub)+'</div>':'')+'</div>';
}

function openDriverModal(mode,id){
  driverMode=mode; driverEditId=id||null;
  var isEdit=mode==='edit';
  $('drv-modal-title').textContent=isEdit?'Edit Driver':'Add New Driver';
  $('drv-save-btn').innerHTML=icon('check')+(isEdit?'Save Changes':'Add Driver');
  var d=isEdit?drivers.find(function(x){ return x.id===id; }):null;
  $('d-name').value    =d?d.name:'';
  $('d-phone').value   =d?d.phone:'';
  $('d-email').value   =d?d.email:'';
  $('d-vtype').value   =d?d.vtype:'Car';
  $('d-vehicle').value =d?d.vehicle:'';
  $('d-plate').value   =d?d.plate:'';
  $('d-dlicence').value=d?d.dlicence:'';
  $('d-status').value  =d?(d.approved?'Active':'Inactive'):'Active';
  openModal('modal-driver');
}
function saveDriver(){
  var name=$('d-name').value.trim();
  if(!name){ toast('warning','Full name is required.'); $('d-name').focus(); return; }
  var active=$('d-status').value==='Active';
  var obj={name:name,phone:$('d-phone').value.trim()||'—',email:$('d-email').value.trim()||'—',
    vehicleType:$('d-vtype').value,vehicleModel:$('d-vehicle').value.trim()||'—',
    licencePlate:$('d-plate').value.trim().toUpperCase()||'—',
    licenceNumber:$('d-dlicence').value.trim()||'—',
    status:active?'approved':'pending',isOnline:active,
    updatedAt:serverTimestamp()};
  var btn=$('drv-save-btn'), isEdit=driverMode==='edit';
  btn.disabled=true; btn.innerHTML='<span class="spin"></span>Saving…';
  var promise;
  if(isEdit){ promise=updateDoc(doc(db,'drivers',driverEditId),obj); }
  else{ obj.rating=5.0; obj.totalTrips=0; obj.createdAt=serverTimestamp(); promise=addDoc(collection(db,'drivers'),obj); }
  promise.then(function(){
    closeModal('modal-driver');
    btn.disabled=false;
    toast('success',isEdit?'Driver updated.':'Driver added.');
  }).catch(function(e){
    toast('error',e.message,'Could not save driver');
    btn.disabled=false; btn.innerHTML=icon('check')+(isEdit?'Save Changes':'Add Driver');
  });
}
function deleteDriver(id){
  var d=drivers.find(function(x){ return x.id===id; }); if(!d) return;
  confirmDialog({title:'Delete driver?',body:'“'+d.name+'” will be permanently removed. This cannot be undone.',confirmLabel:'Delete driver'})
    .then(function(ok){
      if(!ok) return;
      deleteDoc(doc(db,'drivers',id))
        .then(function(){ toast('success','Driver deleted.'); })
        .catch(function(e){ toast('error',e.message,'Delete failed'); });
    });
}
function approveDriver(id){
  updateDoc(doc(db,'drivers',id),{status:'approved',updatedAt:serverTimestamp()})
    .then(function(){ toast('success','Driver approved.'); })
    .catch(function(e){ toast('error',e.message,'Approval failed'); });
}
function rejectDriver(id){
  var d=drivers.find(function(x){ return x.id===id; }); if(!d) return;
  confirmDialog({title:'Reject application?',body:'“'+d.name+'” will be marked rejected and taken offline. You can re-approve later.',confirmLabel:'Reject',tone:'warning'})
    .then(function(ok){
      if(!ok) return;
      updateDoc(doc(db,'drivers',id),{status:'rejected',isOnline:false,updatedAt:serverTimestamp()})
        .then(function(){ toast('info','Driver rejected.'); })
        .catch(function(e){ toast('error',e.message,'Could not reject'); });
    });
}
function toggleDriverOnline(id){
  var d=drivers.find(function(x){ return x.id===id; }); if(!d) return;
  updateDoc(doc(db,'drivers',id),{isOnline:!d.isOnline,updatedAt:serverTimestamp()})
    .catch(function(e){ toast('error',e.message,'Could not change status'); });
}
function openDriverPanel(id){
  var d=drivers.find(function(x){ return x.id===id; }); if(!d) return;
  $('sp-sub').textContent='Driver Profile';
  $('sp-title').textContent=d.name;
  var recent=orders.filter(function(o){ return d.id&&o.driverId===d.id; });
  if(!recent.length) recent=orders.filter(function(o){ return o.driver===d.name; });
  var recentHtml=recent.slice(0,5).map(function(o){
    return '<div class="sp-row"><span class="sp-lbl">'+esc(o.id)+' — '+esc(o.merchant)+'</span>'+
      '<span class="sp-val">'+badge(o.status)+'</span></div>';
  }).join('')||'<div class="empty-copy">No deliveries recorded yet.</div>';

  // Rating breakdown — real aggregates only. No synthesised distribution.
  var rh;
  var rc=d.ratingCounts;
  if(rc&&typeof rc==='object'){
    var total=[1,2,3,4,5].reduce(function(s,k){ return s+(Number(rc[k])||0); },0);
    if(total>0){
      rh=[5,4,3,2,1].map(function(s){
        var n=Number(rc[s])||0, pct=Math.round((n/total)*100);
        return '<div class="rbar-row"><span class="rbar-lbl">'+s+'</span>'+
          '<div class="rbar-t"><div class="rbar-f" data-w="'+pct+'"></div></div>'+
          '<span class="rbar-pct">'+pct+'%</span></div>';
      }).join('')+'<div class="sc-sub" style="margin-top:8px">Based on '+total+' rating'+(total===1?'':'s')+'.</div>';
    }
  }
  if(!rh) rh='<div class="empty-copy">No per-star rating data recorded yet — only the average ('+
    (Number(d.rating)||0).toFixed(1)+') is available.</div>';

  $('sp-body').innerHTML=
    '<div class="sp-hero"><div class="sp-avatar">'+esc((d.name[0]||'?').toUpperCase())+'</div>'+
      '<div><div class="sp-hero-name">'+esc(d.name)+'</div><div style="margin-top:5px">'+badge(d.status)+'</div></div></div>'+
    '<div class="sp-sec"><div class="sp-sec-title">Contact</div>'+
      row('Phone','<span class="num">'+esc(d.phone)+'</span>')+
      row('Email','<span class="sp-val sm">'+esc(d.email)+'</span>',true)+'</div>'+
    '<div class="sp-sec"><div class="sp-sec-title">Vehicle</div>'+
      row('Type',esc(d.vtype))+row('Model',esc(d.vehicle))+
      row('Plate','<span class="num">'+esc(d.plate)+'</span>')+
      row('Licence No.','<span class="num">'+esc(d.dlicence)+'</span>')+'</div>'+
    '<div class="sp-sec"><div class="sp-sec-title">Performance</div>'+
      '<div class="sp-row"><span class="sp-lbl">Total Trips</span><span class="sp-val money">'+d.trips+'</span></div>'+
      row('Avg Rating',stars(d.rating),false)+
      row('Account',badge(d.rawStatus))+'</div>'+
    '<div class="sp-sec"><div class="sp-sec-title">Rating Breakdown</div>'+rh+'</div>'+
    '<div class="sp-sec"><div class="sp-sec-title">Recent Deliveries</div>'+recentHtml+'</div>';
  openSidePanel();
  animateBars();
}
/** Bars render at width 0 then transition — gives the fill its motion. */
function animateBars(){
  requestAnimationFrame(function(){
    document.querySelectorAll('.rbar-f[data-w],.zf[data-w],.pfill[data-w]').forEach(function(b){
      b.style.width=b.getAttribute('data-w')+'%';
    });
  });
}

// ══════════════════════ MERCHANTS ══════════════════════
function renderMerchantStats(){
  var el=$('merchants-stats'); if(!el) return;
  var openC=merchants.filter(function(m){ return m.open; }).length;
  el.innerHTML=
    statCard('merchants','Total Merchants',merchants.length,'','')+
    statCard('check','Open Now',openC,'Accepting orders','success')+
    statCard('clock','Closed',merchants.length-openC,'Not accepting','gold');
}
function renderMerchants(){
  renderMerchantStats();
  var tbody=$('merchants-tbody'); if(!tbody) return;
  if(!loadedOnce.merchants){ tbody.innerHTML=skeletonRows(9,5); return; }
  if(!merchants.length){
    tbody.innerHTML=emptyRow(9,'store','No merchants yet','Add a restaurant, grocer, or pharmacy to start taking orders.');
    return;
  }
  tbody.innerHTML=merchants.map(function(m){
    return '<tr>'+
      '<td><div class="cell-media">'+merchantMedia(m)+'<b>'+esc(m.name)+'</b></div></td>'+
      '<td><span class="bdg bg-info plain">'+esc(m.category)+'</span></td>'+
      '<td class="cell-mute num">'+esc(m.phone)+'</td>'+
      '<td class="cell-mute" style="max-width:180px;font-size:12px">'+esc(m.address)+'</td>'+
      '<td class="right cell-id">'+m.ordersToday+'</td>'+
      '<td>'+stars(m.rating)+'</td>'+
      '<td>'+badge(m.open?'Open':'Closed')+'</td>'+
      '<td><label class="tgl" title="Toggle open"><input type="checkbox"'+(m.open?' checked':'')+
        ' class="tgl-merchant" data-id="'+esc(m.id)+'" aria-label="Merchant open"><span class="ts"></span></label></td>'+
      '<td><div class="cell-actions">'+
        '<button class="aicon ai-v" data-action="view-merchant" data-id="'+esc(m.id)+'" title="View" aria-label="View merchant">'+icon('view')+'</button>'+
        '<button class="aicon ai-e" data-action="edit-merchant" data-id="'+esc(m.id)+'" title="Edit" aria-label="Edit merchant">'+icon('edit')+'</button>'+
        '<button class="aicon ai-d" data-action="del-merchant" data-id="'+esc(m.id)+'" title="Delete" aria-label="Delete merchant">'+icon('delete')+'</button>'+
      '</div></td>'+
    '</tr>';
  }).join('');
}
function openMerchantModal(mode,id){
  merchantMode=mode; merchantEditId=id||null;
  var isEdit=mode==='edit';
  $('mer-modal-title').textContent=isEdit?'Edit Merchant':'Add New Merchant';
  $('mer-save-btn').innerHTML=icon('check')+(isEdit?'Save Changes':'Add Merchant');
  var m=isEdit?merchants.find(function(x){ return x.id===id; }):null;
  $('m-name').value    =m?m.name:'';
  $('m-cat').value     =m?m.category:'Food';
  $('m-owner').value   =m?(m.owner||''):'';
  $('m-phone').value   =m?m.phone:'';
  $('m-email').value   =m?(m.email||''):'';
  $('m-fee').value     =m?String(m.fee||'').replace(/[^0-9.]/g,''):'';
  $('m-hours').value   =m?(m.hours||''):'';
  $('m-address').value =m?m.address:'';
  $('m-status').value  =m?(m.open?'Open':'Closed'):'Open';
  $('m-imageurl').value=m?(m.imageUrl||''):'';
  openModal('modal-merchant');
}
function saveMerchant(){
  var name=$('m-name').value.trim();
  if(!name){ toast('warning','Business name is required.'); $('m-name').focus(); return; }
  var isOpenState=$('m-status').value==='Open';
  var obj={name:name,category:$('m-cat').value,owner:$('m-owner').value.trim()||'—',
    phone:$('m-phone').value.trim()||'—',email:$('m-email').value.trim()||'—',
    address:$('m-address').value.trim()||'—',hours:$('m-hours').value.trim()||'—',
    fee:'$'+($('m-fee').value.trim()||'0'),isOpen:isOpenState,open:isOpenState,
    imageUrl:$('m-imageurl').value.trim()||'',updatedAt:serverTimestamp()};
  var btn=$('mer-save-btn'), isEdit=merchantMode==='edit';
  btn.disabled=true; btn.innerHTML='<span class="spin"></span>Saving…';
  var promise;
  if(isEdit){ promise=updateDoc(doc(db,'merchants',merchantEditId),obj); }
  else{ obj.ordersToday=0; obj.rating=5.0; obj.createdAt=serverTimestamp(); promise=addDoc(collection(db,'merchants'),obj); }
  promise.then(function(){
    closeModal('modal-merchant');
    btn.disabled=false;
    toast('success',isEdit?'Merchant updated.':'Merchant added.');
  }).catch(function(e){
    toast('error',e.message,'Could not save merchant');
    btn.disabled=false; btn.innerHTML=icon('check')+(isEdit?'Save Changes':'Add Merchant');
  });
}
function deleteMerchant(id){
  var m=merchants.find(function(x){ return x.id===id; }); if(!m) return;
  confirmDialog({title:'Delete merchant?',body:'“'+m.name+'” and its menu items will be permanently removed. This cannot be undone.',confirmLabel:'Delete merchant'})
    .then(function(ok){
      if(!ok) return;
      deleteDoc(doc(db,'merchants',id))
        .then(function(){ toast('success','Merchant deleted.'); })
        .catch(function(e){ toast('error',e.message,'Delete failed'); });
    });
}
function toggleMerchant(id){
  var m=merchants.find(function(x){ return x.id===id; }); if(!m) return;
  updateDoc(doc(db,'merchants',id),{isOpen:!m.open,open:!m.open,updatedAt:serverTimestamp()})
    .catch(function(e){ toast('error',e.message,'Could not change status'); });
}
function openMerchantPanel(id){
  panelMerchantId=id;
  var m=merchants.find(function(x){ return x.id===id; }); if(!m) return;
  $('sp-sub').textContent='Merchant Profile';
  $('sp-title').textContent=m.name;
  var recent=orders.filter(function(o){ return m.id&&o.merchantId===m.id; });
  if(!recent.length) recent=orders.filter(function(o){ return o.merchant===m.name; });
  var recentHtml=recent.slice(0,5).map(function(o){
    return '<div class="sp-row"><span class="sp-lbl">'+esc(o.id)+' — '+esc(o.customer)+'</span>'+
      '<span class="sp-val">'+badge(o.status)+'</span></div>';
  }).join('')||'<div class="empty-copy">No orders recorded yet.</div>';

  var detailsHtml=
    '<div class="sp-hero">'+merchantMedia(m,'lg')+
      '<div><div class="sp-hero-name">'+esc(m.name)+'</div><div style="margin-top:5px">'+badge(m.open?'Open':'Closed')+'</div></div></div>'+
    '<div class="sp-sec"><div class="sp-sec-title">Business Details</div>'+
      row('Category','<span class="bdg bg-info plain">'+esc(m.category)+'</span>')+
      row('Owner',esc(m.owner))+
      row('Hours','<span class="sp-val sm">'+esc(m.hours)+'</span>',true)+
      row('Delivery Fee','<span class="num">'+esc(m.fee)+'</span>')+
      row('Address','<span class="sp-val sm">'+esc(m.address)+'</span>',true)+'</div>'+
    '<div class="sp-sec"><div class="sp-sec-title">Contact</div>'+
      row('Phone','<span class="num">'+esc(m.phone)+'</span>')+
      row('Email','<span class="sp-val sm">'+esc(m.email)+'</span>',true)+'</div>'+
    '<div class="sp-sec"><div class="sp-sec-title">Stats</div>'+
      '<div class="sp-row"><span class="sp-lbl">Orders Today</span><span class="sp-val money">'+m.ordersToday+'</span></div>'+
      row('Rating',stars(m.rating))+'</div>'+
    '<div class="sp-sec"><div class="sp-sec-title">Recent Orders</div>'+recentHtml+'</div>';

  $('sp-body').innerHTML=
    '<div class="tabs" style="width:100%">'+
      '<div id="mptab-details" class="tab active" data-mtab="details" style="flex:1;justify-content:center">Details</div>'+
      '<div id="mptab-menu" class="tab" data-mtab="menu" style="flex:1;justify-content:center">Menu Items</div>'+
    '</div>'+
    '<div id="merch-tab-details">'+detailsHtml+'</div>'+
    '<div id="merch-tab-menu" hidden></div>';
  openSidePanel();
}
function switchMerchantTab(tab){
  $('mptab-details').classList.toggle('active',tab==='details');
  $('mptab-menu').classList.toggle('active',tab==='menu');
  $('merch-tab-details').hidden=tab!=='details';
  $('merch-tab-menu').hidden=tab!=='menu';
  if(tab==='menu') loadMenuItemsTab(panelMerchantId);
}
function loadMenuItemsTab(merchantId){
  if(menuItemsUnsub){ menuItemsUnsub(); menuItemsUnsub=null; }
  menuItemEditId=null;
  var el=$('merch-tab-menu'); if(!el) return;
  el.innerHTML=
    '<div class="mi-form">'+
      '<div class="mi-form-title" id="mi-form-title">Add Menu Item</div>'+
      '<div class="fr"><label for="mi-name">Name *</label><input id="mi-name" placeholder="Item name"/></div>'+
      '<div class="fr"><label for="mi-desc">Description</label><input id="mi-desc" placeholder="Brief description"/></div>'+
      '<div class="fr"><label for="mi-price">Price (JMD) *</label><input id="mi-price" type="number" placeholder="1200" min="0"/></div>'+
      '<div class="fr"><label for="mi-cat">Category</label>'+
        '<select id="mi-cat"><option value="mains">Mains</option><option value="sides">Sides</option>'+
        '<option value="drinks">Drinks</option><option value="popular">Popular</option></select></div>'+
      '<div class="fr"><label for="mi-img">Image URL <small>(optional)</small></label><input id="mi-img" placeholder="https://…"/></div>'+
      '<div style="display:flex;gap:8px;margin-top:12px">'+
        '<button class="btn btn-outline" id="mi-cancel-btn" data-action="cancel-menu-item" style="flex:1;display:none">Cancel</button>'+
        '<button class="btn btn-primary" data-action="save-menu-item" style="flex:1">'+icon('check')+'Save Item</button>'+
      '</div>'+
    '</div>'+
    '<div id="menu-items-list">'+
      '<div class="mi-card"><div class="sk sk-sq" style="width:40px;height:40px"></div>'+
      '<div style="flex:1"><div class="sk sk-line" style="width:58%;margin-bottom:7px"></div>'+
      '<div class="sk sk-line" style="width:34%"></div></div></div>'+
      '<div class="mi-card"><div class="sk sk-sq" style="width:40px;height:40px"></div>'+
      '<div style="flex:1"><div class="sk sk-line" style="width:44%;margin-bottom:7px"></div>'+
      '<div class="sk sk-line" style="width:28%"></div></div></div>'+
    '</div>';
  try{
    menuItemsUnsub=onSnapshot(
      collection(db,'merchants',merchantId,'menuItems'),
      function(snap){
        panelMenuItems=snap.docs.map(function(d){
          var o=d.data();
          return {id:d.id,name:o.name||'',description:o.description||'',price:Number(o.price)||0,
            category:o.category||'mains',imageUrl:o.imageUrl||''};
        });
        renderMenuItems();
      },
      function(e){ console.warn('menuItems:',e.message); toast('error',e.message,'Could not load menu'); }
    );
  }catch(e){ console.warn('menuItems init:',e.message); }
}
function renderMenuItems(){
  var listEl=$('menu-items-list'); if(!listEl) return;
  if(!panelMenuItems.length){
    listEl.innerHTML=emptyState('store','No menu items yet','Add the first dish or product using the form above.');
    return;
  }
  listEl.innerHTML=panelMenuItems.map(function(item){
    var media=item.imageUrl
      ? '<img class="thumb" src="'+esc(item.imageUrl)+'" alt="" onerror="this.outerHTML=this.dataset.fb" data-fb="'+esc('<div class="cat-ico c-food">'+icon('cat-food')+'</div>')+'">'
      : '<div class="cat-ico c-food">'+icon('cat-food')+'</div>';
    return '<div class="mi-card">'+media+
      '<div style="flex:1;min-width:0">'+
        '<div class="mi-name">'+esc(item.name)+'</div>'+
        (item.description?'<div class="mi-desc">'+esc(item.description)+'</div>':'')+
        '<div style="display:flex;align-items:center;gap:8px;margin-top:4px">'+
          '<span class="mi-price">'+money(item.price)+'</span>'+
          '<span class="bdg bg-info plain" style="font-size:10px;text-transform:capitalize">'+esc(item.category)+'</span>'+
        '</div>'+
      '</div>'+
      '<div class="cell-actions">'+
        '<button class="aicon ai-e" data-action="edit-menu-item" data-id="'+esc(item.id)+'" title="Edit" aria-label="Edit item">'+icon('edit')+'</button>'+
        '<button class="aicon ai-d" data-action="del-menu-item" data-id="'+esc(item.id)+'" title="Delete" aria-label="Delete item">'+icon('delete')+'</button>'+
      '</div>'+
    '</div>';
  }).join('');
}
function editMenuItemFn(id){
  var item=panelMenuItems.find(function(i){ return i.id===id; }); if(!item) return;
  menuItemEditId=id;
  $('mi-form-title').textContent='Edit Menu Item';
  $('mi-name').value=item.name;
  $('mi-desc').value=item.description;
  $('mi-price').value=item.price;
  $('mi-cat').value=item.category;
  $('mi-img').value=item.imageUrl;
  $('mi-cancel-btn').style.display='';
  $('mi-name').scrollIntoView({behavior:reduceMotion()?'auto':'smooth',block:'nearest'});
}
function cancelMenuItemEdit(){
  menuItemEditId=null;
  $('mi-form-title').textContent='Add Menu Item';
  ['mi-name','mi-desc','mi-price','mi-img'].forEach(function(id){ var el=$(id); if(el) el.value=''; });
  var cat=$('mi-cat'); if(cat) cat.value='mains';
  var cb=$('mi-cancel-btn'); if(cb) cb.style.display='none';
}
function saveMenuItem(){
  var name=($('mi-name').value||'').trim();
  var price=parseInt($('mi-price').value,10)||0;
  if(!name){ toast('warning','Item name is required.'); $('mi-name').focus(); return; }
  if(!price){ toast('warning','Price is required.'); $('mi-price').focus(); return; }
  var obj={name:name,description:($('mi-desc').value||'').trim(),price:price,
    category:$('mi-cat').value,imageUrl:($('mi-img').value||'').trim()};
  var isEdit=!!menuItemEditId;
  var promise=isEdit
    ? updateDoc(doc(db,'merchants',panelMerchantId,'menuItems',menuItemEditId),obj)
    : addDoc(collection(db,'merchants',panelMerchantId,'menuItems'),obj);
  promise.then(function(){
    cancelMenuItemEdit();
    toast('success',isEdit?'Menu item updated.':'Menu item added.');
  }).catch(function(e){ toast('error',e.message,'Could not save item'); });
}
function deleteMenuItemFn(id){
  var item=panelMenuItems.find(function(i){ return i.id===id; });
  confirmDialog({title:'Delete menu item?',body:item?'“'+item.name+'” will be removed from this merchant’s menu.':'This item will be removed.',confirmLabel:'Delete item'})
    .then(function(ok){
      if(!ok) return;
      deleteDoc(doc(db,'merchants',panelMerchantId,'menuItems',id))
        .then(function(){ toast('success','Menu item deleted.'); })
        .catch(function(e){ toast('error',e.message,'Delete failed'); });
    });
}

// ══════════════════════ NOTIFICATIONS ══════════════════════
function updPhonePreview(){
  $('pv-title').textContent=$('n-title').value||'Notification Title';
  $('pv-msg').textContent=$('n-msg').value||'Your message will appear here.';
}
function renderNotifHist(){
  var el=$('notif-hist'); if(!el) return;
  if(!loadedOnce.notifs){
    el.innerHTML='<div class="nh-item"><div class="sk sk-sq" style="width:38px;height:38px"></div>'+
      '<div style="flex:1"><div class="sk sk-line" style="width:52%;margin-bottom:8px"></div>'+
      '<div class="sk sk-line" style="width:76%"></div></div></div>';
    return;
  }
  if(!notifHistory.length){
    el.innerHTML=emptyState('bell','Nothing sent yet','Notifications you compose will be logged here with their audience and timestamp.');
    return;
  }
  el.innerHTML=notifHistory.map(function(n){
    return '<div class="nh-item"><div class="nh-ico">'+icon('notifications')+'</div>'+
      '<div style="min-width:0">'+
        '<div class="nh-title">'+esc(n.title)+'</div>'+
        '<div class="nh-meta">'+esc(n.msg)+'</div>'+
        '<div style="display:flex;gap:8px;align-items:center;margin-top:7px">'+
          '<span class="bdg bg-info plain">'+esc(n.target)+'</span>'+
          '<span style="font-size:11px;color:var(--text-mute)" class="num">'+esc(n.time)+'</span>'+
        '</div>'+
      '</div></div>';
  }).join('');
}
function sendNotif(){
  var title=$('n-title').value.trim();
  var msg=$('n-msg').value.trim();
  var target=$('n-target').value;
  if(!title||!msg){ toast('warning','Enter both a title and a message.'); return; }
  var btn=$('notif-send-btn');
  btn.disabled=true; btn.innerHTML='<span class="spin"></span>Saving…';
  addDoc(collection(db,'notifications'),{
    title:title,message:msg,target:target,
    sentBy:auth.currentUser?auth.currentUser.email:'admin',
    createdAt:serverTimestamp()
  }).then(function(){
    $('n-title').value=''; $('n-msg').value='';
    updPhonePreview();
    btn.disabled=false; btn.innerHTML=icon('send')+'Log Notification';
    toast('success','Saved to the notification log.','Logged');
  }).catch(function(e){
    toast('error',e.message,'Could not save notification');
    btn.disabled=false; btn.innerHTML=icon('send')+'Log Notification';
  });
}

// ══════════════════════ PROMO CODES ══════════════════════
function updPromoPreview(){
  var code=($('pc-code').value||'PROMO').toUpperCase();
  var disc=$('pc-disc').value, type=$('pc-type').value, valid=$('pc-valid').value;
  $('pcp-code').textContent=code;
  $('pcp-disc').textContent=disc?(type==='percent'?disc+'% Off':money(disc)+' Off'):'Discount';
  $('pcp-valid').textContent='Valid until '+(valid||'—');
}
function renderPromos(){
  var tbody=$('promos-tbody'); if(!tbody) return;
  if(!loadedOnce.promos){ tbody.innerHTML=skeletonRows(7,4); return; }
  if(!promoCodes.length){
    tbody.innerHTML=emptyRow(7,'ticket','No promo codes yet','Create one on the left — it becomes redeemable at checkout immediately.');
    return;
  }
  tbody.innerHTML=promoCodes.map(function(p){
    return '<tr>'+
      '<td><b class="cell-id" style="letter-spacing:1.2px">'+esc(p.code)+'</b></td>'+
      '<td class="cell-strong">'+esc(p.discount)+'</td>'+
      '<td class="right num">'+p.usedCount+'</td>'+
      '<td class="right num">'+p.maxUses+'</td>'+
      '<td class="cell-mute num">'+esc(p.validUntil||'—')+'</td>'+
      '<td>'+badge(p.status)+'</td>'+
      '<td><button class="aicon ai-d" data-action="del-promo" data-id="'+esc(p.id)+'" title="Delete" aria-label="Delete promo code">'+icon('delete')+'</button></td>'+
    '</tr>';
  }).join('');
}
function createPromo(){
  var code=$('pc-code').value.trim().toUpperCase();
  var discAmt=parseFloat($('pc-disc').value.trim())||0;
  var discType=$('pc-type').value;
  if(!code){ toast('warning','A promo code is required.'); $('pc-code').focus(); return; }
  if(!discAmt){ toast('warning','A discount amount is required.'); $('pc-disc').focus(); return; }
  var maxUses=parseInt($('pc-max').value,10)||100;
  var validUntil=$('pc-valid').value||'';
  var btn=$('promo-create-btn');
  btn.disabled=true; btn.innerHTML='<span class="spin"></span>Creating…';
  setDoc(doc(db,'promoCodes',code),{
    code:code,discountType:discType,discountAmount:discAmt,
    maxUses:maxUses,usedCount:0,validUntil:validUntil,
    active:true,createdAt:serverTimestamp()
  }).then(function(){
    ['pc-code','pc-disc','pc-max','pc-valid'].forEach(function(i){ $(i).value=''; });
    $('pc-type').value='percent';
    updPromoPreview();
    btn.disabled=false; btn.innerHTML=icon('plus')+'Create Promo Code';
    toast('success','Promo code '+code+' is live.');
  }).catch(function(e){
    toast('error',e.message,'Could not create promo code');
    btn.disabled=false; btn.innerHTML=icon('plus')+'Create Promo Code';
  });
}
function deletePromo(id){
  confirmDialog({title:'Delete promo code?',body:'“'+id+'” will stop working at checkout immediately.',confirmLabel:'Delete code'})
    .then(function(ok){
      if(!ok) return;
      deleteDoc(doc(db,'promoCodes',id))
        .then(function(){ toast('success','Promo code deleted.'); })
        .catch(function(e){ toast('error',e.message,'Delete failed'); });
    });
}

// ══════════════════════ ANALYTICS ══════════════════════
function periodStart(p){
  var now=new Date();
  if(p==='Today') return new Date(now.getFullYear(),now.getMonth(),now.getDate());
  if(p==='This Week'){ var d=new Date(now.getFullYear(),now.getMonth(),now.getDate()); d.setDate(d.getDate()-d.getDay()); return d; }
  return new Date(now.getFullYear(),now.getMonth(),1);
}
function renderAnalytics(){
  ['Today','This Week','This Month'].forEach(function(p){
    var start=periodStart(p);
    var os=orders.filter(function(o){ return o._ts&&o._ts>=start; });
    var completed=os.filter(function(o){ return isDeliveredStatus(o.status); });
    var revenue=completed.reduce(function(s,o){ return s+(o.rawTotal!=null?o.rawTotal:parseAmt(o.amount)); },0);
    var uniq=new Set(os.map(function(o){ return o.customer; })).size;
    var avg=completed.length?Math.round(revenue/completed.length):0;
    analyticsStats[p]=[
      {lbl:'Revenue',val:money(revenue),ic:'revenue',accent:'gold'},
      {lbl:'Orders',val:String(os.length),ic:'orders',accent:''},
      {lbl:'Customers',val:String(uniq),ic:'users',accent:'ocean'},
      {lbl:'Avg Order Value',val:money(avg),ic:'receipt',accent:'success'}
    ];
  });
  renderAnalyticsStats();
  renderBarChart();
  renderZones();
  renderPaySplit();
}
function renderAnalyticsStats(){
  var el=$('analytics-stats'); if(!el) return;
  var s=analyticsStats[currentPeriod]||analyticsStats['Today'];
  el.innerHTML=s.map(function(c){
    return '<div class="sc'+(c.accent?' ac-'+c.accent:'')+'"><div class="sc-top"><div>'+
      '<div class="sc-lbl">'+esc(c.lbl)+'</div>'+
      '<div class="sc-val sm num">'+esc(c.val)+'</div></div>'+
      '<div class="sc-chip'+(c.accent?' c-'+c.accent:'')+'">'+icon(c.ic||'analytics')+'</div></div>'+
      '<div class="sc-sub">'+esc(currentPeriod)+'</div></div>';
  }).join('');
}
function barChartData(){
  var now=new Date();
  if(currentPeriod==='Today'){
    return {title:'Hourly Orders — Today',data:[8,10,12,14,16,18,20].map(function(h){
      var s=new Date(now.getFullYear(),now.getMonth(),now.getDate(),h);
      var e=new Date(s.getTime()+7200000);
      return {l:h>12?(h-12)+'PM':(h===12?'12PM':h+'AM'),
        v:orders.filter(function(o){ return o._ts&&o._ts>=s&&o._ts<e; }).length};
    })};
  }
  if(currentPeriod==='This Week'){
    var wk=periodStart('This Week');
    return {title:'Daily Orders — This Week',data:['Sun','Mon','Tue','Wed','Thu','Fri','Sat'].map(function(d,i){
      var s=new Date(wk); s.setDate(s.getDate()+i);
      var e=new Date(s); e.setDate(e.getDate()+1);
      return {l:d,v:orders.filter(function(o){ return o._ts&&o._ts>=s&&o._ts<e; }).length};
    })};
  }
  var mStart=periodStart('This Month');
  return {title:'Weekly Orders — This Month',data:['Wk 1','Wk 2','Wk 3','Wk 4'].map(function(w,i){
    var s=new Date(mStart); s.setDate(s.getDate()+i*7);
    var e=new Date(s); e.setDate(e.getDate()+7);
    return {l:w,v:orders.filter(function(o){ return o._ts&&o._ts>=s&&o._ts<e; }).length};
  })};
}
/** Rounded gradient bars, faint gridlines, emphasised max, hover tooltip. */
function renderBarChart(){
  var host=$('bar-chart'); if(!host) return;
  var cfg=barChartData();
  var titleEl=$('bar-title'); if(titleEl) titleEl.textContent=cfg.title;
  var data=cfg.data;
  var W=Math.max(280,host.clientWidth||520), H=190;
  var padL=8,padR=8,padT=24,padB=30;
  var plotH=H-padT-padB, plotW=W-padL-padR;
  var max=Math.max.apply(null,data.map(function(d){ return d.v; }))||1;
  var slot=plotW/data.length, bw=Math.min(46,slot*0.56);

  var grid='';
  for(var g=0;g<=3;g++){
    var y=padT+(plotH/3)*g;
    grid+='<line class="grid-line" x1="'+padL+'" y1="'+y.toFixed(1)+'" x2="'+(W-padR)+'" y2="'+y.toFixed(1)+'"/>';
  }
  var bars=data.map(function(d,i){
    var h=Math.max(3,(d.v/max)*plotH);
    var x=padL+slot*i+(slot-bw)/2;
    var y=padT+plotH-h;
    var cx=padL+slot*i+slot/2;
    // A zero bar reads as a muted baseline stub, never a tiny brand-red sliver.
    var cls=d.v===0?' zero':(d.v===max&&max>0?' max':'');
    return '<g class="bar-g" data-label="'+esc(d.l)+'" data-value="'+d.v+'" data-x="'+cx.toFixed(1)+'" data-y="'+y.toFixed(1)+'">'+
      '<rect class="bar'+cls+'" x="'+x.toFixed(1)+'" y="'+y.toFixed(1)+'" width="'+bw.toFixed(1)+'" height="'+h.toFixed(1)+'" rx="5"/>'+
      '<text class="bar-val" x="'+cx.toFixed(1)+'" y="'+(y-7).toFixed(1)+'">'+d.v+'</text>'+
      '<text class="bar-lbl" x="'+cx.toFixed(1)+'" y="'+(H-10)+'">'+esc(d.l)+'</text>'+
      '<rect class="bar-hit" x="'+(padL+slot*i).toFixed(1)+'" y="'+padT+'" width="'+slot.toFixed(1)+'" height="'+plotH+'"/>'+
    '</g>';
  }).join('');

  host.innerHTML=
    '<svg viewBox="0 0 '+W+' '+H+'" role="img" aria-label="'+esc(cfg.title)+'">'+
      '<defs>'+
        '<linearGradient id="barGrad" x1="0" y1="1" x2="0" y2="0">'+
          '<stop offset="0%" stop-color="#C8102E"/><stop offset="100%" stop-color="#E1495F"/></linearGradient>'+
        '<linearGradient id="barGradMax" x1="0" y1="1" x2="0" y2="0">'+
          '<stop offset="0%" stop-color="#E11D34"/><stop offset="100%" stop-color="#FF6A3D"/></linearGradient>'+
      '</defs>'+grid+bars+
    '</svg><div class="chart-tip" id="chart-tip"></div>';
}
function renderZones(){
  var el=$('zone-chart'); if(!el) return;
  var start=periodStart(currentPeriod);
  var scoped=orders.filter(function(o){ return o._ts&&o._ts>=start; });
  var zones={};
  scoped.forEach(function(o){
    var addr=o.address||'', zone='Other';
    if(/kingston/i.test(addr)) zone='Kingston';
    else if(/portmore/i.test(addr)) zone='Portmore';
    else if(/st\.?\s*thomas|morant/i.test(addr)) zone='St Thomas';
    else if(/st\.?\s*catherine|spanish town/i.test(addr)) zone='St Catherine';
    zones[zone]=(zones[zone]||0)+1;
  });
  var keys=Object.keys(zones);
  if(!keys.length){
    el.innerHTML=emptyState('search','No delivery data','Zones are derived from delivery addresses — none recorded for this period yet.');
    return;
  }
  var total=keys.reduce(function(a,k){ return a+zones[k]; },0)||1;
  el.innerHTML=keys.sort(function(a,b){ return zones[b]-zones[a]; }).slice(0,5).map(function(z){
    var pct=Math.round((zones[z]/total)*100);
    return '<div class="zr"><div class="zn">'+esc(z)+'</div>'+
      '<div class="zt"><div class="zf" data-w="'+pct+'"></div></div>'+
      '<div class="zv">'+zones[z]+'</div></div>';
  }).join('');
  animateBars();
}
function renderTopMerch(){
  var el=$('top-merch'); if(!el) return;
  var counts={},revenue={};
  orders.forEach(function(o){
    var n=o.merchant||'Unknown';
    counts[n]=(counts[n]||0)+1;
    revenue[n]=(revenue[n]||0)+(o.rawTotal!=null?o.rawTotal:parseAmt(o.amount));
  });
  var data=Object.keys(counts).map(function(n){ return {n:n,o:counts[n],r:revenue[n]}; });
  data.sort(function(a,b){ return b.o-a.o; });
  if(!data.length){
    el.innerHTML=emptyRow(3,'store','No merchant activity','Rankings appear once orders start coming in.');
    return;
  }
  el.innerHTML=data.slice(0,5).map(function(m){
    return '<tr><td><b>'+esc(m.n)+'</b></td>'+
      '<td class="right cell-id">'+m.o+'</td>'+
      '<td class="right cell-strong">'+money(m.r)+'</td></tr>';
  }).join('');
}
function renderPaySplit(){
  var el=$('pay-split'); if(!el) return;
  var start=periodStart(currentPeriod);
  var src=orders.filter(function(o){ return o._ts&&o._ts>=start; });
  function has(o,words){
    var p=(o.payment||'').toLowerCase();
    return words.some(function(w){ return p.includes(w); });
  }
  var online=src.filter(function(o){ return has(o,['paypal','card','online']); }).length;
  var cod=src.filter(function(o){ return has(o,['cod','cash']); }).length;
  var total=online+cod;
  if(!total){
    el.innerHTML=emptyState('ticket','No payment data','Payment split appears once orders are recorded for this period.');
    return;
  }
  var onPct=Math.round((online/total)*100), codPct=100-onPct;
  el.innerHTML=
    '<div class="prow"><div class="prow-lbl">Card / PayPal</div>'+
      '<div class="ptrack"><div class="pfill brand" data-w="'+onPct+'"></div></div>'+
      '<div class="prow-pct">'+onPct+'%</div></div>'+
    '<div class="prow"><div class="prow-lbl">Cash on Delivery</div>'+
      '<div class="ptrack"><div class="pfill gold" data-w="'+codPct+'"></div></div>'+
      '<div class="prow-pct">'+codPct+'%</div></div>'+
    '<div class="sc-sub" style="text-align:center;margin-top:10px">Based on '+total+
      ' transaction'+(total===1?'':'s')+' — '+currentPeriod.toLowerCase()+'</div>';
  animateBars();
}
function setPeriod(period){
  currentPeriod=period;
  document.querySelectorAll('.pb').forEach(function(b){ b.classList.toggle('active',b.getAttribute('data-period')===period); });
  renderAnalyticsStats(); renderBarChart(); renderZones(); renderPaySplit();
}

// ══════════════════════ MODAL / SIDE PANEL ══════════════════════
var lastFocus=null;
function openModal(id){ lastFocus=document.activeElement; $(id).classList.add('open'); }
function closeModal(id){ $(id).classList.remove('open'); if(lastFocus&&lastFocus.focus) lastFocus.focus(); }
function openSidePanel(){ $('sp-overlay').classList.add('open'); $('spanel').classList.add('open'); }
function closeSidePanel(){
  $('sp-overlay').classList.remove('open');
  $('spanel').classList.remove('open');
  if(menuItemsUnsub){ menuItemsUnsub(); menuItemsUnsub=null; }
  panelMerchantId=null; panelMenuItems=[];
}

// ══════════════════════ EVENT DELEGATION ══════════════════════
document.addEventListener('click',function(e){
  var t=e.target;
  var ni=t.closest('.ni[data-page]'); if(ni){ navTo(ni.getAttribute('data-page')); return; }
  if(t.closest('#logout-btn')){ doLogout(); return; }
  if(t.closest('#hamburger')){ toggleSidebar(); return; }
  if(t.closest('#theme-btn')){ toggleTheme(); return; }
  if(t.closest('#login-btn')){ doLogin(); return; }
  if(t.id==='sp-overlay'||t.closest('#sp-close')){ closeSidePanel(); return; }
  if(t.id==='mob-overlay'){ closeMobileSidebar(); return; }
  if(t.closest('#cf-ok')){ settleConfirm(true); return; }
  if(t.closest('#cf-cancel')){ settleConfirm(false); return; }

  var cb=t.closest('[data-close]'); if(cb){ closeModal(cb.getAttribute('data-close')); return; }
  var mbg=t.closest('.mbg');
  if(mbg&&t===mbg){ if(mbg.id==='modal-confirm') settleConfirm(false); else closeModal(mbg.id); return; }

  if(t.closest('#add-driver-btn')){ openDriverModal('add'); return; }
  if(t.closest('#add-merchant-btn')){ openMerchantModal('add'); return; }

  var pb=t.closest('.pb'); if(pb){ setPeriod(pb.getAttribute('data-period')); return; }
  var mtab=t.closest('[data-mtab]'); if(mtab){ switchMerchantTab(mtab.getAttribute('data-mtab')); return; }
  var tab=t.closest('.tab[data-filter]'); if(tab){ ordersFilter=tab.getAttribute('data-filter'); renderOrders(); return; }

  var btn=t.closest('[data-action]'); if(!btn) return;
  var action=btn.getAttribute('data-action'),
      id=btn.getAttribute('data-id'),
      oid=btn.getAttribute('data-oid');
  switch(action){
    case 'view-order':      openOrderPanel(oid); break;
    case 'save-order':      saveOrderChanges(oid); break;
    case 'view-driver':     openDriverPanel(id); break;
    case 'edit-driver':     openDriverModal('edit',id); break;
    case 'del-driver':      deleteDriver(id); break;
    case 'approve-driver':  approveDriver(id); break;
    case 'reject-driver':   rejectDriver(id); break;
    case 'view-merchant':   openMerchantPanel(id); break;
    case 'edit-merchant':   openMerchantModal('edit',id); break;
    case 'del-merchant':    deleteMerchant(id); break;
    case 'del-promo':       deletePromo(id); break;
    case 'edit-menu-item':  editMenuItemFn(id); break;
    case 'del-menu-item':   deleteMenuItemFn(id); break;
    case 'save-menu-item':  saveMenuItem(); break;
    case 'cancel-menu-item':cancelMenuItemEdit(); break;
    case 'save-driver':     saveDriver(); break;
    case 'save-merchant':   saveMerchant(); break;
    case 'send-notif':      sendNotif(); break;
    case 'create-promo':    createPromo(); break;
  }
});
document.addEventListener('change',function(e){
  if(e.target.classList.contains('tgl-driver-online')) toggleDriverOnline(e.target.getAttribute('data-id'));
  if(e.target.classList.contains('tgl-merchant')) toggleMerchant(e.target.getAttribute('data-id'));
  if(e.target.id==='pc-type'||e.target.id==='pc-valid') updPromoPreview();
});
document.addEventListener('input',function(e){
  if(e.target.id==='orders-search') renderOrders();
  if(e.target.id==='n-title'||e.target.id==='n-msg') updPhonePreview();
  if(['pc-code','pc-disc','pc-valid'].indexOf(e.target.id)>-1) updPromoPreview();
});
document.addEventListener('keydown',function(e){
  if(e.key==='Enter'&&(e.target.id==='l-email'||e.target.id==='l-pass')){ doLogin(); return; }
  if(e.key==='Enter'&&e.target.classList.contains('tab')){ e.target.click(); return; }
  if(e.key==='Escape'){
    if($('modal-confirm').classList.contains('open')){ settleConfirm(false); return; }
    var open=document.querySelector('.mbg.open');
    if(open){ closeModal(open.id); return; }
    if($('spanel').classList.contains('open')){ closeSidePanel(); return; }
    if($('sidebar').classList.contains('mob-open')){ closeMobileSidebar(); }
  }
});
// Chart tooltip
document.addEventListener('mouseover',function(e){
  var g=e.target.closest&&e.target.closest('.bar-g'); if(!g) return;
  var tip=$('chart-tip'), host=$('bar-chart'); if(!tip||!host) return;
  var svg=host.querySelector('svg'), scale=svg.clientWidth/svg.viewBox.baseVal.width;
  tip.textContent=g.getAttribute('data-label')+' · '+g.getAttribute('data-value')+' orders';
  tip.style.left=(Number(g.getAttribute('data-x'))*scale)+'px';
  tip.style.top=(Number(g.getAttribute('data-y'))*scale)+'px';
  tip.classList.add('show');
});
document.addEventListener('mouseout',function(e){
  if(e.target.closest&&e.target.closest('.bar-g')){ var tip=$('chart-tip'); if(tip) tip.classList.remove('show'); }
});
var resizeTimer=null;
window.addEventListener('resize',function(){
  clearTimeout(resizeTimer);
  resizeTimer=setTimeout(function(){ if($('page-analytics').classList.contains('active')) renderBarChart(); },160);
});

// ══════════════════════ INIT ══════════════════════
function initApp(){
  $('tb-date').textContent=new Date().toLocaleDateString('en-JM',{weekday:'long',month:'long',day:'numeric'});
  renderDashboard(); renderOrders(); renderDrivers(); renderMerchants();
  renderPromos(); renderNotifHist(); renderAnalytics();
  updPromoPreview(); updPhonePreview();
  startListeners();
}

onAuthStateChanged(auth,function(user){
  if(user){
    $('login-page').style.display='none';
    $('app').style.display='block';
    var anEl=document.querySelector('.an'); if(anEl) anEl.textContent=user.displayName||user.email;
    var avEl=document.querySelector('.av');
    if(avEl) avEl.textContent=((user.displayName||user.email||'A')[0]||'A').toUpperCase();
    initApp();
  }else{
    $('login-page').style.display='flex';
    $('app').style.display='none';
    stopListeners();
    orders=[]; drivers=[]; merchants=[]; promoCodes=[]; notifHistory=[];
    loadedOnce={orders:false,drivers:false,merchants:false,promos:false,notifs:false};
    var btn=$('login-btn');
    if(btn){ btn.disabled=false; btn.innerHTML='Sign In'+icon('caret-right'); }
  }
});

initTheme();

// ── SETUP: Firebase Console → shipeast-1a1f6 → Authentication → Add user → admin@shipeast.com
// ── Collections: orders · drivers · merchants · promoCodes · notifications
