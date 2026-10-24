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
` + section('local function autopilotTick(session, ply)', '-- gui') + `
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

test('Zenin UI adapter builds tabs, updates readouts, preserves zoom, and cleans up', () => run(common + `
math.clamp=function(v,lo,hi) return math.max(lo,math.min(hi,v)) end
Color3={fromRGB=function(r,g,b) return {r,g,b} end}
UDim2={fromScale=function(x,y) return {x=x,y=y} end}
Vector2={new=function(x,y) return {X=x,Y=y} end}
workspace={CurrentCamera=nil}
loadstring=load
local disposers={}
local function cleanup(fn) table.insert(disposers,fn) end
local GENV={__RoCheeseDispose=function() active=false end}
local store={active="1",profiles={},names={}}
local configNotice="Ready"
local DEFAULTS={}
local function validated(t) return t end
local function persistProfiles() return "Saved" end
local function applyConfig() end
local function clearArrows() end
local HttpService={GenerateGUID=function() return "profile-id" end}
local pg, screen, frame = {}, {}, {}
screen.Parent=pg; frame.Parent=screen
function screen:FindFirstChild(name) if name=="Window" then return frame end end
function pg:FindFirstChild(name) if name=="RoCheesePanel" then return screen end end
local LocalPlayer={FindFirstChildOfClass=function() return pg end}
local allElements, tabs = {}, {}
local function element(o)
 local e={value=o.Default, name=o.Name, callback=o.Callback}
 function e:Set(v,silent) self.value=v; if not silent and self.callback then self.callback(v) end end
 function e:Get() return self.value end
 function e:SetName(v) self.name=v end
 function e:SetOptions(v,silent) self.options=v; if not silent and self.callback then self.callback(self.value) end end
 table.insert(allElements,e); return e
end
local section={AddButton=function(_,o) return element(o) end,AddToggle=function(_,o) return element(o) end,
 AddDropdown=function(_,o) return element(o) end,AddSlider=function(_,o) return element(o) end}
local tab={AddSection=function() return section end}
local W={visible=true,scale=1}
function W:AddTab(o) tabs[o.Name]=true; return tab end
function W:SetTheme() end
function W:SetAccent() end
function W:SetScale(v) self.scale=v; self.scaleCalls=(self.scaleCalls or 0)+1 end
function W:GetScale() return self.scale end
function W:SetVisible(v) self.visible=v end
function W:IsVisible() return self.visible end
function W:OnUnload(fn) self.unload=fn end
function W:Destroy() self.destroyed=true; if self.unload then self.unload() end end
_G.MockLibrary={AddTheme=function() end,CreateWindow=function(_,o)
 assert(o.MouseWheel and o.Parent==pg); return W
end}
local game={HttpGet=function() return "return MockLibrary" end}
local warn=function(e) error(e) end
CFG.DELAY_MIN,CFG.DELAY_MAX,CFG.DELAY_STEP=0,20,0.5
RUNTIME.THEME,RUNTIME.ACCENT,RUNTIME.ELO="Midnight","Blue",1500
RUNTIME.NOISE,RUNTIME.BLUNDER,RUNTIME.DELAY_MIN,RUNTIME.DELAY_MAX=0.32,0.06,5,10
` + section('-- gui ---', '-- actions ---') + `
assert(buildGui())
assert(tabs.Overview and tabs.Engine and tabs.Automation and tabs.Appearance and tabs.Profiles)
rows.status.Text="engine ready"
local displayed=false
for _,e in ipairs(allElements) do if e.name=="engine ready" then displayed=true end end
assert(displayed and rows.status.Text=="engine ready")
controls.delayMax.callback(0); assert(RUNTIME.DELAY_MAX-RUNTIME.DELAY_MIN>=0.5)
controls.delayMin.callback(20); assert(RUNTIME.DELAY_MAX<=20 and RUNTIME.DELAY_MAX-RUNTIME.DELAY_MIN>=0.5)
controls.scale.callback(0.65); assert(W.scale==0.65)
local calls=W.scaleCalls; layoutPanel(); assert(W.scaleCalls==calls and W.scale==0.65)
W.visible=false; layoutPanel(); assert(RUNTIME.UI_VISIBLE==false)
assert(#disposers==1); disposers[1](); assert(W.destroyed and not active)
`));
