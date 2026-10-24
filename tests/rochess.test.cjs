const { test } = require('node:test');
const { readFileSync } = require('node:fs');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const source = readFileSync('Rochess.lua', 'utf8');
const section = (start, end) => source.slice(source.indexOf(start), source.indexOf(end, source.indexOf(start)));
function run(code, execute = true) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  let status = lauxlib.luaL_loadstring(L, to_luastring(code));
  if (status === lua.LUA_OK && execute) status = lua.lua_pcall(L, 0, 0, 0);
  if (status !== lua.LUA_OK) throw new Error(to_jsstring(lua.lua_tostring(L, -1)));
}
const common = `
local active = true
local function alive() return active end
local S = {best="e2e4", thinkAt=0, autoAt=0, ply=-1}
local RUNTIME = {AUTO=true}
local App = {}
local CFG = {PROMO={q=5,r=4,b=3,n=2}}
local Engine = {algToIndex64=function(s) return s end}
local function buildEngine() return {} end
local function sanOf(_, uci) if uci == "e2e4" then return "e4" end end
local function tapInput() end
local session = {ucis={}, viewPly=0, startFen="start", isMyTurn=function() return true end}
App.session = session
S.session, S.positionKey = session, "start|"
local queue = {}
local task = {spawn=function(fn) table.insert(queue,fn) end}
local function drain() local fn=table.remove(queue,1); assert(fn); fn() end
`;
const play = section('local function playUci(uci)', 'local function humanDelay()');
test('Rochess syntax', () => {
  run(source, false);
});
test('move validation, confirmation, and single dispatch', () => run(common + play + `
local calls=0
App.onBoardMove=function() calls=calls+1; return true end
App.playMove=function() error("duplicate dispatch") end
assert(not playUci(nil)); assert(not playUci("a9a1")); assert(not playUci("e2e5"))
assert(calls==0)
assert(not playUci("e2e4")); assert(calls==1)
App.onBoardMove=function() table.insert(session.ucis,"e2e4"); return true end
assert(playUci("e2e4"))
session.viewPly=0
assert(not playUci("e2e4"))
`));
test('autoplay is single-flight and discards stale or disabled work', () => run(common + `
local picks, plays = 0, 0
local function pickMove() picks=picks+1; return "e2e4" end
local function playUci() plays=plays+1; return true end
` + section('local function autopilotTick(session, ply)', '-- ui ---') + `
autopilotTick(session,0); autopilotTick(session,0)
assert(#queue==1)
RUNTIME.AUTO=false; drain(); assert(plays==0 and not S.playPending)
RUNTIME.AUTO=true; S.autoAt=0
autopilotTick(session,0); session.ucis={"d2d4"}; drain(); assert(plays==0)
session.ucis={}; S.autoAt=0
autopilotTick(session,0); drain(); assert(plays==1)
S.autoAt=0; pickMove=function() error("engine failure") end
autopilotTick(session,0); drain(); assert(not S.playPending and S.status=="autoplay failed")
`));
const tickStart = source.indexOf('local session = App.session', source.indexOf('while alive() do'));
const tickEnd = source.indexOf('\n\t\tif session then\n\t\t\tlocal live', tickStart);
const tick = 'local function tick()\n' + source.slice(tickStart, tickEnd) + '\nend\n';
const analysisMocks = `
local Bot={clearTT=function() end}
local lastEval
local function clearArrows() end
local function humanDelay() return 0 end
local function analyseBest() return {best="e2e4",score=10,depth=2} end
local function rankContinuations() return {} end
table.clone=function(t) local c={} for k,v in pairs(t) do c[k]=v end return c end
`;
test('same-ply replacements supersede stale analysis without clearing current busy state', () => run(common + analysisMocks + tick + `
tick(); assert(S.busy and #queue==1)
session.ucis={"d2d4"}; session.viewPly=1; tick(); assert(#queue==2)
session.ucis={"c2c4"}; tick(); assert(#queue==3)
drain(); assert(S.busy and S.best==nil)
drain(); assert(S.busy and S.best==nil)
drain(); assert(not S.busy and S.best=="e2e4")
App.session=nil; tick(); assert(S.best==nil and not S.busy)
drain(); assert(S.second==nil)
`));
test('engine errors release busy state', () => run(common + analysisMocks + `
analyseBest=function() error("analysis failed") end
` + tick + `tick(); drain(); assert(not S.busy and S.status=="engine failed")`));

test('manual move discards positions changed while selecting and releases lock on errors', () => run(common + `
local playNow
local plays=0
local function playUci() plays=plays+1; return true,"e2e4" end
local pickMove=function() session.ucis={"d2d4"}; return "e2e4" end
` + section('playNow = function()', 'copyPosition = function()') + `
playNow(); assert(plays==0 and not S.playPending)
S.autoAt=0; S.positionKey="start|d2d4"; pickMove=function() error("selection failed") end
playNow(); assert(not S.playPending and S.status=="move selection failed")
S.autoAt=0; pickMove=function() return "e2e4" end
playNow(); assert(plays==1 and S.status=="played e2e4")
`));
test('illegal engine output is not published', () => run(common + analysisMocks + `
analyseBest=function() return {best="e2e5"} end
` + tick + `tick(); drain(); assert(S.best==nil and not S.busy and S.status=="engine returned an illegal move")`));

test('ranking excludes failed searches and stops superseded work', () => run(`
local CFG={}
local calls=0
local Bot={analyse=function(fen)
 calls=calls+1
 if fen=="a2a3" then error("failed") end
 if fen=="b2b3" then return {} end
 return {score=-10}
end}
local function buildEngine()
 local e={}
 function e:legalMoves()
  local i=0; local moves={"a2a3","b2b3","c2c3"}
  return function() i=i+1; if moves[i] then return i,moves[i] end end
 end
 function e:moveToUci(m) return m end
 function e:moveToSan(m) return m end
 function e:playUci(m) self.fen=m end
 function e:getFen() return self.fen or "board w turn" end
 return e
end
` + section('local function rankContinuations(', 'local function pickMove(') + `
local ranked=rankContinuations("",{},nil,function() return true end)
assert(#ranked==1 and ranked[1].uci=="c2c3")
calls=0
assert(rankContinuations("",{},nil,function() return false end)==nil and calls==0)
`));

test('Zenin UI binds controls to runtime state, syncs silently, and cleans up', () => run(common + `
math.clamp=function(v,lo,hi) return math.max(lo,math.min(hi,v)) end
loadstring=load
local disposed=false
local disposers={}
local function cleanup(fn) table.insert(disposers,fn) end
local function dispose() if disposed then return end disposed=true for _,fn in ipairs(disposers) do fn() end end
local GENV={}
local cleared=0
local function clearArrows() cleared=cleared+1 end
local Enum={KeyCode={PageUp="PageUp"}}
local tabs, elements, flags = {}, {}, {}
local function element(kind, o)
 local e={kind=kind,value=o.Default,name=o.Name,description=o.Description,enabled=true,o=o}
 if o.Flag then flags[o.Flag]=e end
 function e:Set(v,silent) local changed=v~=self.value; self.value=v; if changed and not silent and o.Callback then o.Callback(v) end end
 function e:Get() return self.value end
 function e:SetEnabled(v) self.enabled=v end
 function e:SetName(v) self.name=v; self.renames=(self.renames or 0)+1 end
 function e:SetDescription(v) self.description=v end
 function e:Click() o.Callback() end
 elements[o.Name]=e; return e
end
local section={}
for _,k in ipairs({"Toggle","Slider","Dropdown","Button","CardButton"}) do section["Add"..k]=function(_,o) return element(k,o) end end
local tab={AddSection=function(_,o) assert(o.Name and o.Side); return section end}
local W={Settings=tab}
function W:AddTab(o) tabs[o.Name]=true; return tab end
function W:OnUnload(fn) self.unload=fn end
function W:Destroy() self.destroyed=true; self.unload() end
function W:Notify(o) self.notified=o.Content end
function W:Toggle() end
_G.MockLibrary={CreateWindow=function(_,o)
 assert(o.Configs and o.ConfigFolder=="RoCheese" and o.Theme==nil and o.Accent==nil)
 return W
end}
local game={HttpGet=function() return "return MockLibrary" end}
local warn=function(e) error(e) end
CFG.DELAY_MIN,CFG.DELAY_MAX,CFG.DELAY_STEP=0,20,0.5
RUNTIME.SOURCE,RUNTIME.MODE,RUNTIME.STYLE="local","elo","legit"
RUNTIME.ELO,RUNTIME.NOISE,RUNTIME.BLUNDER,RUNTIME.DELAY_MIN,RUNTIME.DELAY_MAX,RUNTIME.SHOW_ARROW=1500,0.32,0.06,5,10,true
local PRESETS={raj={source="vortex",mode="best",elo=1800,noise=0,blunder=0,delayMin=0.5,delayMax=1.5}}
` + section('-- ui ---', '-- actions ---') + `
applyPreset=function(name)
 local p=PRESETS[name]
 RUNTIME.STYLE,RUNTIME.SOURCE,RUNTIME.MODE,RUNTIME.ELO=name,p.source,p.mode,p.elo
 RUNTIME.NOISE,RUNTIME.BLUNDER,RUNTIME.DELAY_MIN,RUNTIME.DELAY_MAX=p.noise,p.blunder,p.delayMin,p.delayMax
 syncControls()
end
toggleAuto=function() RUNTIME.AUTO=not RUNTIME.AUTO; syncControls() end
assert(buildUi())
assert(tabs.Main and tabs.Engine and tabs.Automation and not tabs.Appearance and not tabs.Profiles)
assert(elements.Theme==nil and elements.Accent==nil and W.notified)

-- preset dropdown applies values and pushes them into the controls without callbacks
elements.Preset:Set("Raj")
assert(RUNTIME.SOURCE=="vortex" and flags.RC_Source.value=="Vortex" and flags.RC_Mode.value=="Best move")
assert(flags.RC_DelayMin.value==0.5 and flags.RC_DelayMax.value==1.5 and RUNTIME.STYLE=="raj")
assert(not flags.RC_Elo.enabled, "rating sliders disabled in best-move mode")

-- manual change (e.g. a Zenin config load) leaves the preset
flags.RC_Mode:Set("Rating")
assert(RUNTIME.MODE=="elo" and RUNTIME.STYLE=="custom" and elements.Preset.value=="Custom" and flags.RC_Elo.enabled)
flags.RC_Noise:Set(50); assert(RUNTIME.NOISE==0.5)

-- delay sliders keep a valid range
flags.RC_DelayMin:Set(19.5); assert(RUNTIME.DELAY_MAX==20 and flags.RC_DelayMax.value==20)
flags.RC_DelayMax:Set(0.5); assert(RUNTIME.DELAY_MIN==0 and flags.RC_DelayMin.value==0)

-- toggles
flags.RC_Auto:Set(true); assert(RUNTIME.AUTO==true)
flags.RC_Arrows:Set(false); assert(RUNTIME.SHOW_ARROW==false and cleared==1)

-- status cards only re-render on change
local function formatClock() return "1:00" end
local function evalText(s) return "+0.35" end
local function pushEval() end
` + section('local function setCard(', '-- main loop ---') + `
S.best,S.san,S.depth,S.busy,S.second,S.secondSan=nil,nil,0,false,nil,nil
refreshUi(nil,-1); assert(elements["Waiting for game"])
local card=ui.best
S.best,S.san,S.depth,S.score,S.secondSan="e2e4","e4",16,35,"Nf3"
refreshUi(session,0)
assert(card.name=="e4   +0.35" and card.description:find("Nf3"))
local renames=card.renames; refreshUi(session,0); assert(card.renames==renames)

-- unloading from the menu disposes the script once
W:Destroy(); assert(disposed and Window==nil)
`));
