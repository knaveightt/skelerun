local Game=require('game')
local W,H=500,800
local game,fonts,canvas
local paused=false
local t=0 local particles={} local notices={} local shake=0 local hitFlash=0 local clearFlash=0
local repeatKey,repeatTime,repeatStarted=nil,0,false
local muted=false local sounds={}
local C={bg={.035,.043,.065},stone={.12,.14,.19},edge={.25,.29,.36},ink={.065,.08,.12},text={.88,.88,.82},dim={.46,.51,.57},gold={1,.74,.32},red={.96,.31,.36},green={.44,.85,.64},I={.34,.81,.86},O={.98,.76,.32},T={.70,.48,.86},S={.45,.75,.46},Z={.91,.37,.40},J={.38,.54,.88},L={.93,.57,.30}}
local function color(c,a) c=type(c)=='string' and C[c] or c love.graphics.setColor(c[1],c[2],c[3],a or 1) end
local function rect(x,y,w,h,c,a) color(c,a) love.graphics.rectangle('fill',math.floor(x),math.floor(y),w,h) end
local function text(s,x,y,size,c,width,align)
 love.graphics.setFont(fonts[size or 12]) color(c or 'text')
 if width then love.graphics.printf(s,math.floor(x),math.floor(y),width,align or 'left') else love.graphics.print(s,math.floor(x),math.floor(y)) end
end
local function panel(x,y,w,h)
 rect(x,y,w,h,'edge') rect(x+2,y+2,w-4,h-4,'ink')
 rect(x+4,y+4,w-8,1,{.18,.21,.27})
end
local function play(name)
 if not muted and sounds[name] then sounds[name]:stop() sounds[name]:play() end
end
local function tone(freq,duration,slide)
 local rate=22050 local d=love.sound.newSoundData(math.floor(rate*duration),rate,16,1)
 for i=0,d:getSampleCount()-1 do
  local u=i/rate local phase=u*freq+(slide or 0)*u*u
  d:setSample(i,((phase%1)<.5 and 1 or -1)*.065*(1-u/duration)^2)
 end return love.audio.newSource(d,'static')
end
local function restart()
 game=Game.new() paused=false particles={} notices={} shake=0 hitFlash=0 clearFlash=0 repeatKey=nil
end
function love.load()
 love.graphics.setDefaultFilter('nearest','nearest')
 fonts={} for _,s in ipairs({9,10,11,12,14,16,20,26,34}) do fonts[s]=love.graphics.newFont(s) fonts[s]:setFilter('nearest','nearest') end
 canvas=love.graphics.newCanvas(W,H) canvas:setFilter('nearest','nearest')
 math.randomseed(os.time())
 local ok=pcall(function()
  sounds.lock=tone(100,.08,-80) sounds.rotate=tone(340,.045,300)
  sounds.hold=tone(260,.08,500) sounds.clear=tone(520,.22,900)
  sounds.hit=tone(95,.22,-100) sounds.kill=tone(650,.3,900)
  sounds.won=tone(780,.7,500) sounds.lost=tone(180,.7,-120)
 end)
 restart()
end
local function burst(x,y,c,n)
 for _=1,n do particles[#particles+1]={x=x,y=y,vx=math.random(-80,80),vy=math.random(-95,20),life=.6+math.random()*.4,c=c} end
end
local function event(e)
 play(e.kind)
 if e.kind=='clear' then
  local n=e.data.lines clearFlash=.22 shake=n==4 and 5 or 2
  local labels={'SINGLE','DOUBLE','TRIPLE','TETRIS! CRITICAL'}
  notices[#notices+1]={label=labels[n]..'   -'..e.data.damage..' HP',life=1.6,c=n==4 and 'gold' or 'green'}
  burst(380,102,C.gold,24) burst(250,530,C[game.piece.kind],20)
 elseif e.kind=='hit' then hitFlash=.35 shake=6 burst(100+game.position*230,104,C.red,14)
 elseif e.kind=='kill' then burst(390,102,C.gold,28) end
end
function love.update(dt)
 t=t+dt
 if not paused then
  game:update(dt,love.keyboard.isDown('down','s'))
  if game.status=='playing' and repeatKey then
   repeatTime=repeatTime+dt
   local delay=repeatStarted and .055 or .16
   while repeatTime>=delay do
    repeatTime=repeatTime-delay repeatStarted=true
    game:move(repeatKey=='left' and -1 or 1,0) delay=.055
   end
  end
  for _,e in ipairs(game.events) do event(e) end game.events={}
 end
 shake=math.max(0,shake-dt*20) hitFlash=math.max(0,hitFlash-dt) clearFlash=math.max(0,clearFlash-dt)
 for i=#particles,1,-1 do local p=particles[i] p.life=p.life-dt p.x=p.x+p.vx*dt p.y=p.y+p.vy*dt p.vy=p.vy+160*dt if p.life<=0 then table.remove(particles,i) end end
 for i=#notices,1,-1 do notices[i].life=notices[i].life-dt if notices[i].life<=0 then table.remove(notices,i) end end
end
function love.keypressed(key)
 if key=='m' then muted=not muted return end
 if key=='escape' or key=='p' then if game.status=='playing' then paused=not paused repeatKey=nil end return end
 if key=='r' then restart() return end
 if game.status~='playing' then if key=='return' or key=='space' then restart() end return end
 if paused then return end
 if key=='left' or key=='a' or key=='right' or key=='d' then
  repeatKey=(key=='left' or key=='a') and 'left' or 'right' repeatTime=0 repeatStarted=false game:move(repeatKey=='left' and -1 or 1,0)
 elseif key=='up' or key=='x' or key=='w' then game:rotate(1)
 elseif key=='z' then game:rotate(-1)
 elseif key=='space' then game:drop()
 elseif key=='c' or key=='lshift' or key=='rshift' then game:hold() end
end
function love.keyreleased(key)
 if (repeatKey=='left' and (key=='left' or key=='a')) or (repeatKey=='right' and (key=='right' or key=='d')) then repeatKey=nil end
end
function love.focus(f) if not f and game and game.status=='playing' then paused=true repeatKey=nil end end
local function torch(x,y)
 rect(x-3,y+6,6,17,{.29,.19,.15}) rect(x-5,y+4,10,4,'edge')
 local flick=math.floor(math.sin(t*13+x)*2)
 rect(x-7,y-6,14,15,C.L,.15) rect(x-4,y-4+flick,8,11-flick,C.L) rect(x-2,y-6+flick,4,12-flick,'gold') rect(x-1,y,2,5,{1,.94,.66})
end
local function hero(x,y,running)
 local step=running and math.floor(t*9)%2 or 0
 local bob=running and step or math.sin(t*3)*.6 y=y+bob
 rect(x-12,y+24,26,4,{0,0,0},.35)
 rect(x-9,y+3,8,20,{.51,.16,.24}) rect(x-9,y+17,6,8,{.66,.22,.28})
 rect(x-4,y+17,5,8+step*2,'edge') rect(x+4,y+17,5,10-step*2,'edge')
 rect(x-5,y+4,15,15,{.43,.55,.62}) rect(x-3,y+5,10,4,{.67,.75,.77})
 rect(x-5,y-9,15,14,{.68,.74,.75}) rect(x-3,y-11,10,3,{.82,.85,.79})
 rect(x+2,y-4,9,3,'ink') rect(x+6,y-4,2,2,'gold')
 rect(x+9,y+8,5,7,{.79,.63,.45}) rect(x+15,y-5,3,22,{.77,.84,.84}) rect(x+11,y+12,11,3,'gold')
end
local function monster(kind,x,y)
 y=y+math.floor(math.sin(t*3)*2)
 rect(x-17,y+24,36,5,{0,0,0},.4)
 if kind=='rat' then
  rect(x-13,y+5,26,16,{.43,.36,.48}) rect(x-21,y+9,12,9,{.54,.45,.56}) rect(x-14,y-1,7,9,{.68,.48,.52}) rect(x-19,y+11,3,3,'red') rect(x+12,y+11,13,3,{.61,.4,.46}) rect(x-10,y+20,5,5,'dim') rect(x+7,y+20,5,5,'dim')
 elseif kind=='slime' then
  rect(x-19,y+11,38,13,{.21,.48,.37}) rect(x-15,y+2,30,17,'green') rect(x-9,y-2,18,5,'green') rect(x-10,y+8,4,5,'ink') rect(x+5,y+8,4,5,'ink') rect(x-6,y+2,7,3,{.7,.96,.67})
 elseif kind=='wraith' then
  rect(x-13,y-8,27,32,{.31,.24,.47}) rect(x-9,y-14,19,9,{.42,.32,.59}) rect(x-19,y+6,8,14,{.31,.24,.47}) rect(x+12,y+5,8,17,{.31,.24,.47}) rect(x-7,y-3,16,10,'ink') rect(x-5,y,4,3,C.T) rect(x+3,y,4,3,C.T)
  for i=0,3 do rect(x-13+i*7,y+22,4,6-math.floor(math.sin(t*6+i)*3),{.42,.32,.59}) end
 else
  local boss=kind=='warden' local bone=boss and {.48,.49,.57} or {.79,.76,.64}
  rect(x-10,y-13,21,17,bone) rect(x-7,y-8,5,5,'ink') rect(x+3,y-8,5,5,'ink') rect(x-4,y+1,12,3,'ink')
  rect(x-3,y+5,6,15,bone)
  for i=0,2 do rect(x-10,y+6+i*5,20,2,bone) end
  rect(x-9,y+20,5,8,bone) rect(x+5,y+20,5,8,bone)
  rect(x-17,y+7,5,14,bone) rect(x+14,y+5,5,16,bone)
  if boss then rect(x-15,y+4,30,7,'edge') rect(x-13,y-17,5,7,'gold') rect(x+8,y-17,5,7,'gold') rect(x-7,y-8,4,3,'red') rect(x+4,y-8,4,3,'red') end
  rect(x-23,y-3,3,29,'dim') rect(x-29,y-3,15,7,'dim')
 end
end
local function dungeon()
 panel(16,53,468,143)
 love.graphics.setScissor(18,55,464,139)
 rect(18,55,464,139,{.09,.10,.14})
 local scroll=game.travel>0 and t*25 or t*3
 for row=0,3 do for col=-1,10 do
  local x=col*56-(scroll%56)+(row%2)*28
  rect(x,58+row*26,54,24,{.13+row*.005,.145,.18}) rect(x+4,61+row*26,44,1,{.17,.18,.22})
 end end
 for i=0,3 do
  local x=36+i*145-(scroll%145)
  rect(x,60,20,104,{.10,.11,.15}) rect(x+3,60,14,104,{.19,.20,.24}) rect(x+1,145,18,7,'edge')
 end
 torch(59,95) torch(445,95)
 rect(18,161,464,33,{.18,.18,.22}) rect(18,161,464,3,'edge')
 for i=0,16 do rect(i*32-(scroll%32),181,22,2,{.25,.24,.27}) end
 local px=42+game.position*285
 hero(px,133,game.travel>0)
 local mx=game.travel>0 and 400+game.travel*50 or 400
 monster(game:enemy().kind,mx,133)
 love.graphics.setScissor()
 text('RETREAT',24,178,9,'red') text('ADVANCE',413,178,9,'dim')
 rect(91,181,294,4,'ink') rect(91,181,294*game.position,4,game.position<.25 and 'red' or 'gold')
 if hitFlash>0 then rect(18,55,464,139,'red',hitFlash*.5) end
end
local BX,BY,BS=112,254,25
local function block(x,y,kind,ghost)
 local c=C[kind]
 if ghost then
  color(c,.45) love.graphics.rectangle('line',x+3.5,y+3.5,18,18)
  rect(x+9,y+9,7,7,c,.18) return
 end
 rect(x+1,y+1,23,23,{c[1]*.45,c[2]*.45,c[3]*.45})
 rect(x+2,y+2,21,19,c) rect(x+3,y+3,19,3,{math.min(1,c[1]+.19),math.min(1,c[2]+.19),math.min(1,c[3]+.19)})
 rect(x+4,y+7,2,11,{1,1,1},.14) rect(x+19,y+8,2,12,{0,0,0},.13)
 rect(x+9,y+10,7,7,{0,0,0},.12) rect(x+11,y+12,3,3,{1,1,1},.22)
end
local function preview(kind,x,y,small)
 if not kind then text('--',x+14,y+10,14,'dim') return end
 local s=small and 15 or 17
 for _,c in ipairs(Game.shapes[kind]) do
  local px=x+c[1]*s local py=y+c[2]*s
  rect(px+1,py+1,s-2,s-2,C[kind]) rect(px+2,py+2,s-4,2,{1,1,1},.3)
 end
end
local function board()
 panel(BX-5,BY-5,260,510)
 for y=1,20 do for x=1,10 do
  local px,py=BX+(x-1)*BS,BY+(y-1)*BS
  rect(px,py,24,24,(x+y)%2==0 and {.085,.105,.14} or {.09,.11,.15})
  rect(px+11,py+11,2,2,{.15,.18,.22})
  if game.board[y][x] then block(px,py,game.board[y][x]) end
 end end
 if game.status=='playing' then
  local gy=game:ghostY()-game.piece.y
  for _,c in ipairs(game:cells(nil,0,gy)) do if c[2]>=1 then block(BX+(c[1]-1)*BS,BY+(c[2]-1)*BS,game.piece.kind,true) end end
  for _,c in ipairs(game:cells()) do if c[2]>=1 then block(BX+(c[1]-1)*BS,BY+(c[2]-1)*BS,game.piece.kind) end end
 end
 if clearFlash>0 then rect(BX,BY,250,500,'gold',clearFlash*.6) end
end
local function sidebar()
 panel(16,249,82,87) text('HOLD',16,260,11,'dim',82,'center') preview(game.held,22,287,true)
 text('C / SHIFT',16,317,9,game.holdUsed and 'dim' or 'gold',82,'center')
 panel(377,249,107,251) text('NEXT',377,261,11,'dim',107,'center')
 for i=1,4 do preview(game.queue[i],397,283+(i-1)*52,true) end
 text('LINE POWER',377,520,10,'gold',107,'center')
 local labels={'1 LINE   1','2 LINES  3','3 LINES  5','4 LINES  9'}
 for i,s in ipairs(labels) do text(s,384,545+(i-1)*24,10,i==4 and 'gold' or 'dim') end
 text('CRITICAL!',377,641,10,'gold',107,'center')
 panel(16,349,82,303)
 text('RESOURCES',16,358,10,'gold',82,'center')
 text('+10 / BLOCK',19,373,9,'dim',76,'center')
 local resources={{'Tin','T','T'},{'Iron','S / Z','S'},{'Copper','L / J','L'},{'Orichalcum','O','O'},{'Platinum','I','I'}}
 for i,r in ipairs(resources) do
  local y=393+(i-1)*52
  text(r[1]:upper(),19,y,9,r[3],76,'center')
  text(tostring(game.resources[r[1]]),19,y+12,16,'text',76,'center')
  text(r[2],19,y+32,9,'dim',76,'center')
 end
 text('SCORE',16,668,10,'dim',82,'center') text(string.format('%05d',game.score),16,685,16,'text',82,'center')
 text('LINES',16,717,10,'dim',82,'center') text(tostring(game.lines),16,733,16,'text',82,'center')
 text('SLAIN',377,690,10,'dim',107,'center') text(game.kills..' / 5',377,708,16,'gold',107,'center')
 if game.position<.25 then text('DANGER',377,741,10,'red',107,'center') end
end
local function overlay()
 if not paused and game.status=='playing' then return end
 rect(0,0,W,H,'bg',.85)
 panel(51,262,398,250)
 local won=game.status=='won' local lost=game.status=='lost'
 text(won and 'KEEP CLEARED' or lost and 'RUN ENDED' or 'PAUSED',65,286,26,won and 'gold' or lost and 'red' or 'text',370,'center')
 text(won and 'The Iron Warden falls. Dawn awaits.' or lost and game.reason or 'Take a breath. The dungeon can wait.',73,336,12,'dim',354,'center')
 text(game.lines..' LINES   /   '..game.kills..' SLAIN   /   '..game.score..' POINTS',65,376,12,'text',370,'center')
 text(paused and '[ P / ESC ]  CONTINUE' or '[ ENTER ]  RUN AGAIN',65,431,14,'gold',370,'center')
 text(paused and 'R to restart  /  M to toggle sound' or 'Every descent is another chance.',65,472,10,'dim',370,'center')
end
function love.draw()
 love.graphics.setCanvas(canvas) love.graphics.clear(C.bg)
 love.graphics.push()
 if shake>0 and not paused then love.graphics.translate(math.random(-1,1)*math.floor(shake),math.random(-1,1)*math.floor(shake)) end
 text('SKELERUN',16,12,26,'gold') text('THE SUNKEN KEEP',277,17,12,'dim',207,'right')
 for i=1,5 do rect(388+(i-1)*19,37,13,3,i<game.enemyIndex and 'gold' or i==game.enemyIndex and 'text' or 'edge') end
 dungeon()
 text(string.format('%02d / 05',game.enemyIndex)..'  '..game:enemy().name,18,207,12,'text')
 local hp=math.max(0,game.enemyHP) local max=game:enemy().hp
 text(hp..' / '..max..' HP',366,207,11,'dim',115,'right')
 rect(18,227,318,6,'stone') rect(18,227,318*hp/max,6,'red')
 rect(352,227,130,6,'stone') rect(352,227,130*game.attack/game:enemy().rate,6,'gold')
 text(game.travel>0 and 'APPROACHING' or 'NEXT ATTACK',352,237,9,'dim',130,'right')
 board() sidebar()
 for _,p in ipairs(particles) do rect(p.x,p.y,3,3,p.c,math.min(1,p.life*2)) end
 if #notices>0 then local n=notices[#notices] panel(118,348,238,36) text(n.label,118,359,12,n.c,238,'center') end
 text('A D / ARROWS  MOVE    UP / X  ROTATE    Z  REVERSE',16,770,10,'dim',468,'center')
 text('SPACE  DROP    C  HOLD    P  PAUSE    M  '..(muted and 'UNMUTE' or 'MUTE'),16,786,9,'dim',468,'center')
 love.graphics.pop() overlay()
 love.graphics.setCanvas()
 local ww,wh=love.graphics.getDimensions() local scale=math.min(ww/W,wh/H)
 love.graphics.clear(.02,.025,.035) color({1,1,1}) love.graphics.draw(canvas,math.floor((ww-W*scale)/2),math.floor((wh-H*scale)/2),0,scale,scale)
end
