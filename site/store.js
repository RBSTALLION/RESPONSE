// Shared RESPONSE state: localStorage + BroadcastChannel + same-window event
const KEY='response.state.v1';
const bc = ('BroadcastChannel' in window) ? new BroadcastChannel('response') : null;
export const officers=[
 {id:'DO',name:'Daniel Owusu',role:'Nights',site:'Riverside DC',status:'On shift',sia:'1017 •••• •••• 2291',exp:'14 Mar 2028',welfare:'OK'},
 {id:'KP',name:'Karan Patel',role:'Mobile',site:'Mobile · RX-04',status:'Responding',sia:'1017 •••• •••• 4410',exp:'02 Jun 2027',welfare:'OK'},
 {id:'AN',name:'Aleksander Novak',role:'Nights',site:'Northgate Retail',status:'Check call overdue',sia:'1017 •••• •••• 0871',exp:'19 Nov 2027',welfare:'Overdue'},
 {id:'JE',name:'Jade Evans',role:'Days',site:'Canal Wharf',status:'Off shift',sia:'1017 •••• •••• 7732',exp:'30 Jan 2029',welfare:'—'},
 {id:'SH',name:'Samira Hussain',role:'Days',site:'Hospital Car Park B',status:'On shift',sia:'1017 •••• •••• 5519',exp:'08 Aug 2027',welfare:'OK'},
 {id:'TB',name:'Tom Brooks',role:'Nights',site:'Riverside DC',status:'On shift',sia:'1017 •••• •••• 3306',exp:'12 Oct 2026',welfare:'OK'},
 {id:'LG',name:'Leah Grant',role:'Days',site:'Canal Wharf',status:'Off shift',sia:'1017 •••• •••• 9925',exp:'22 May 2028',welfare:'—'},
];
export const sites=[
 {name:'Riverside Distribution Centre',client:'[Client A]',type:'Static + patrol',officers:2,patrols:168,onTime:'89.2%',status:'Review'},
 {name:'Northgate Retail Park',client:'[Client B]',type:'Static',officers:1,patrols:140,onTime:'93.5%',status:'Watch'},
 {name:'Canal Wharf Apartments',client:'[Client C]',type:'Concierge',officers:0,patrols:112,onTime:'97.9%',status:'Good'},
 {name:'Hospital Car Park B',client:'[Client D]',type:'Static',officers:1,patrols:196,onTime:'98.4%',status:'Good'},
 {name:'Fengate Industrial Estate',client:'[Client E]',type:'Keyholding + alarm',officers:0,patrols:84,onTime:'99.1%',status:'Good'},
 {name:'City Centre Office Campus',client:'[Client F]',type:'Static + patrol',officers:0,patrols:210,onTime:'97.2%',status:'Good'},
 {name:'Station Road Retail',client:'[Client G]',type:'Mobile patrol',officers:0,patrols:98,onTime:'96.6%',status:'Good'},
];
export const route=['Gate House','Yard North','Fuel Store','Loading Bay 1','Loading Bay 2','Loading Bay 3','Bay 4','Roof Access','Plant Room','Yard South','Car Park','Gate House (close)'];
export function initial(){
 return {
  clock: Date.now(),
  bookedOn:false, shiftStart:null,
  scanned:5, // checkpoints done on Route B
  checkCall:{due:true, deadline:null, ok:null},
  sos:false, sosStart:null,
  incidents:[{id:'IR-4471',site:'Riverside DC',type:'Damage',title:'Forced side gate, area secured',officer:'K. Patel',time:'Sat 02:14',photos:3,status:'Needs review'}],
  events:[
   {t:'02:14',title:'Intruder alarm · Unit 7',sub:'K. Patel assigned · ETA 9 min',kind:'alarm'},
   {t:'02:13',title:'Panel alarm · Canal Wharf',sub:'No keyholder accepted',kind:'alarm'},
   {t:'02:11',title:'Missed check call · A. Novak',sub:'Northgate Retail · escalated to supervisor',kind:'warn'},
   {t:'02:09',title:'Checkpoint missed · Bay 4',sub:'Riverside DC',kind:'warn'},
   {t:'02:05',title:'Check call OK · J. Evans',sub:'Canal Wharf',kind:'ok'},
   {t:'01:58',title:'Incident report filed',sub:'Northgate Retail · 3 photos',kind:'info'},
   {t:'01:55',title:'Booked on · S. Hussain',sub:'Hospital Car Park B · on time',kind:'ok'},
  ],
 };
}
export function load(){ try{ const s=JSON.parse(localStorage.getItem(KEY)); if(s&&s.events) return s; }catch(e){} return initial(); }
function apply(s){ localStorage.setItem(KEY, JSON.stringify(s)); window.dispatchEvent(new CustomEvent('response:state',{detail:s})); if(bc) bc.postMessage(s); }
export function save(s){ apply(s); pushRemote(s); }
export function reset(){ const s=initial(); save(s); return s; }
export function subscribe(fn){
 const a=e=>fn(e.detail); const b=e=>{ if(e.key===KEY) fn(load()); }; const c=e=>fn(e.data);
 window.addEventListener('response:state',a); window.addEventListener('storage',b); if(bc) bc.addEventListener('message',c);
 return ()=>{ window.removeEventListener('response:state',a); window.removeEventListener('storage',b); if(bc) bc.removeEventListener('message',c); };
}
export function hhmm(d=new Date()){ return d.toTimeString().slice(0,5); }
export function hhmmss(d=new Date()){ return d.toTimeString().slice(0,8); }
export function push(s,ev){ return {...s, events:[{t:hhmm(),...ev},...s.events].slice(0,40)}; }
// background chatter for the control room
const chatter=[
 ()=>({title:'Checkpoint verified · Fuel Store',sub:'T. Brooks · Riverside DC · tagless · view matched',kind:'ok'}),
 ()=>({title:'Check call OK · S. Hussain',sub:'Hospital Car Park B',kind:'ok'}),
 ()=>({title:'Patrol completed · Route A',sub:'City Centre Office Campus · 10 of 10 checkpoints',kind:'ok'}),
 ()=>({title:'Vehicle RX-04 moving',sub:'K. Patel · 1.4 mi from Unit 7',kind:'info'}),
 ()=>({title:'Checkpoint verified · Car Park',sub:'S. Hussain · Hospital CP · tagless',kind:'ok'}),
 ()=>({title:'Lock-up check complete',sub:'Station Road Retail · form + 4 photos',kind:'info'}),
];
export function randomEvent(){ return chatter[Math.floor(Math.random()*chatter.length)](); }

// Demo accounts: salted SHA-256 only, no plaintext. Swap for the /api auth endpoint in production.
export const accounts = [
  { email:'admin@recreateteam.com', role:'officer', name:'Admin', hash:'a13ce071c6d88ac0d25c25599771bc9a273b44fc497f5f0aacbdd15f59f0f5c5' },
  { email:'roberto@recreateteam.com', role:'controller', name:'Roberto', hash:'7535cd1a12893d32a0d993ae160db617ac95c2132b67c63b72607bc70cb1d417' }
];
export async function verify(email, password, role){
  const e = String(email||'').trim().toLowerCase();
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode('response:'+e+':'+password));
  const h = [...new Uint8Array(buf)].map(b=>b.toString(16).padStart(2,'0')).join('');
  return accounts.find(a => a.email===e && a.hash===h && (!role || a.role===role)) || null;
}

// Tagless patrol: floors, default route (Riverside DC · Night patrol B)
export const floorsDef=[
 {k:0,label:'Ground',short:'G',alt:0,rooms:[{n:'Reception',x:4,y:6,w:30,h:40},{n:'Loading bay',x:58,y:6,w:38,h:40},{n:'Car park B1',x:4,y:60,w:40,h:34},{n:'Stairwell B',x:80,y:62,w:16,h:32}]},
 {k:1,label:'Floor 1',short:'1',alt:3.2,rooms:[{n:'Open office',x:4,y:6,w:54,h:40},{n:'Kitchen',x:64,y:6,w:32,h:32},{n:'Meeting',x:60,y:62,w:16,h:24},{n:'Stairwell B',x:80,y:62,w:16,h:32}]},
 {k:2,label:'Floor 2',short:'2',alt:6.4,rooms:[{n:'Plant room',x:4,y:6,w:34,h:40},{n:'Server room',x:42,y:6,w:32,h:40},{n:'Roof access',x:78,y:6,w:18,h:30},{n:'Stairwell B',x:80,y:62,w:16,h:32}]},
];
export const P={"door":"https://images.unsplash.com/photo-1754390755713-8f7e9973ab3d?w=640&q=60&auto=format&fit=crop","server":"https://images.unsplash.com/photo-1695668548342-c0c1ad479aee?w=640&q=60&auto=format&fit=crop","stair":"https://images.unsplash.com/photo-1617512184788-62870b9f8eb2?w=640&q=60&auto=format&fit=crop","office":"https://images.unsplash.com/photo-1542081403278-ba5973c25c7a?w=640&q=60&auto=format&fit=crop","doors":"https://images.unsplash.com/photo-1691153431097-417d65a265f7?w=640&q=60&auto=format&fit=crop"};
export const photoFor=(t='')=>{ t=String(t).toLowerCase(); if(/server/.test(t)) return P.server; if(/stair|roof|hatch|car park|basement|b1/.test(t)) return P.stair; if(/office|kitchen|meeting|desk/.test(t)) return P.office; if(/plant|panel|door/.test(t)) return P.door; return P.doors; };
export const corridorY=53;
export const taglessDefault=()=>({name:'Night patrol B',published:true,idx:3,dist:38,points:[
 {name:'Gate house',floor:0,x:14,y:44,photo:P.doors,tasks:[{q:'Barrier down?',t:'yesno'}]},
 {name:'Car park B1',floor:0,x:24,y:62,low:true,photo:P.stair,tasks:[{q:'Any vehicles left overnight?',t:'yesno'}]},
 {name:'Stairwell B',floor:0,x:88,y:64,low:true,photo:P.stair,tasks:[{q:'Fire door closed?',t:'yesno'}]},
 {name:'Plant room door',floor:2,x:30,y:45,photo:P.door,tasks:[{q:'Is the door locked?',t:'yesno'},{q:'Alarm panel green?',t:'photo'}]},
 {name:'Server room corridor',floor:2,x:58,y:53,photo:P.server,tasks:[{q:'Server room door secured?',t:'yesno'}]},
 {name:'Roof access hatch',floor:2,x:87,y:35,photo:P.stair,tasks:[{q:'Hatch padlocked?',t:'yesno'}]},
 {name:'Open office',floor:1,x:30,y:45,photo:P.office,tasks:[{q:'Lights off, windows shut?',t:'yesno'}]},
 {name:'Fire door east',floor:1,x:96,y:53,photo:P.doors,tasks:[{q:'Fire door locked and alarmed?',t:'yesno'}]},
 {name:'Kitchen',floor:1,x:78,y:37,photo:P.office,tasks:[{q:'Appliances off?',t:'yesno'}]},
 {name:'Loading bay',floor:0,x:76,y:45,photo:P.doors,tasks:[{q:'Shutters down?',t:'yesno'}]},
 {name:'Yard gate',floor:0,x:50,y:53,photo:P.doors,tasks:[{q:'Gate chained?',t:'yesno'}]},
 {name:'Gate house (close)',floor:0,x:20,y:45,photo:P.doors,tasks:[{q:'Log book signed?',t:'yesno'}]},
]});
export const narrationSamples=['Gate house. Check the barrier is down.','Car park B1. Check no vehicles are left overnight.','Stairwell B, ground floor. Check the fire door is closed.','Plant room, second floor. Check the door is locked and the alarm panel shows green.','Server room corridor. Check the server room door is secured.','Roof access hatch. Make sure the padlock is on.'];

// Live sync between devices through Supabase (one shared demo row, pushed by Realtime).
// Off unless /config.js sets supabaseUrl and supabaseAnonKey; then state stays browser-local.
const ROW='demo', ME=Math.random().toString(36).slice(2);
let sb=null, pushT=null;
function loadScript(src){ return new Promise((ok,no)=>{ const el=document.createElement('script'); el.src=src; el.onload=ok; el.onerror=no; document.head.appendChild(el); }); }
function pushRemote(s){
 if(!sb) return;
 clearTimeout(pushT);
 pushT=setTimeout(()=>{ sb.from('demo_state').upsert({id:ROW, state:{...s,_by:ME}, updated_at:new Date().toISOString()}).then(r=>{ if(r&&r.error) console.warn('[response] sync failed', r.error.message); }); },150);
}
export const live = (async()=>{
 try{
  await loadScript('/config.js');
  const c=window.RESPONSE_CONFIG||{};
  if(!c.supabaseUrl||!c.supabaseAnonKey) return false;
  if(!window.supabase) await loadScript('/vendor/supabase.js');
  sb=window.supabase.createClient(c.supabaseUrl, c.supabaseAnonKey, {auth:{persistSession:false}});
  const {data,error}=await sb.from('demo_state').select('state').eq('id',ROW).maybeSingle();
  if(error) throw error;
  if(data&&data.state&&data.state.events) apply(data.state); else pushRemote(load());
  sb.channel('response-demo')
   .on('postgres_changes',{event:'*',schema:'public',table:'demo_state',filter:'id=eq.'+ROW},p=>{ const s=p.new&&p.new.state; if(s&&s.events&&s._by!==ME) apply(s); })
   .subscribe();
  return true;
 }catch(e){ console.warn('[response] live sync off:', e&&e.message||e); sb=null; return false; }
})();
