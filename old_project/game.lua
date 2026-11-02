local Game = {}
Game.__index = Game
Game.resourceForPiece = {T='Tin', S='Iron', Z='Iron', L='Copper', J='Copper', O='Orichalcum', I='Platinum'}
Game.shapes = {
 I = {{0,1},{1,1},{2,1},{3,1}}, O = {{1,0},{2,0},{1,1},{2,1}},
 T = {{1,0},{0,1},{1,1},{2,1}}, S = {{1,0},{2,0},{0,1},{1,1}},
 Z = {{0,0},{1,0},{1,1},{2,1}}, J = {{0,0},{0,1},{1,1},{2,1}},
 L = {{2,0},{0,1},{1,1},{2,1}}
}
local enemies = {
 {name='CRYPT RAT', hp=4, rate=10, push=.09, kind='rat'},
 {name='BONE GUARD', hp=7, rate=9, push=.105, kind='skeleton'},
 {name='MIRE SLIME', hp=8, rate=8.5, push=.11, kind='slime'},
 {name='KEEP WRAITH', hp=10, rate=8, push=.12, kind='wraith'},
 {name='THE IRON WARDEN', hp=14, rate=7.5, push=.13, kind='warden'}
}
function Game.new(random,resources)
 local self=setmetatable({},Game)
 self.random=random or math.random
 self.board={} for y=1,20 do self.board[y]={} end
 self.bag={} self.queue={} self.status='playing' self.position=.56
 self.enemyIndex=1 self.enemyHP=enemies[1].hp self.attack=0 self.travel=1.5
 self.lines=0 self.score=0 self.kills=0 self.combo=-1 self.gravity=0 self.lockTime=0
 self.resources=resources or {Tin=0,Iron=0,Copper=0,Orichalcum=0,Platinum=0}
 self.loot={Tin=0,Iron=0,Copper=0,Orichalcum=0,Platinum=0}
 self.events={} self.time=0 self.held=nil self.holdUsed=false self:fillQueue() self:spawn()
 return self
end
function Game:emit(kind,data) self.events[#self.events+1]={kind=kind,data=data} end
function Game:enemy() return enemies[self.enemyIndex] end
function Game:fillQueue()
 while #self.queue<5 do
  if #self.bag==0 then
   self.bag={'I','O','T','S','Z','J','L'}
   for i=#self.bag,2,-1 do local j=self.random(i) self.bag[i],self.bag[j]=self.bag[j],self.bag[i] end
  end
  self.queue[#self.queue+1]=table.remove(self.bag)
 end
end
function Game:cells(piece,dx,dy,rotation)
 piece=piece or self.piece local out={}
 for _,c in ipairs(Game.shapes[piece.kind]) do
  local x,y=c[1],c[2]
  for _=1,rotation or piece.rotation do x,y=(piece.kind=='I' and 3 or 2)-y,x end
  out[#out+1]={x+piece.x+(dx or 0),y+piece.y+(dy or 0)}
 end return out
end
function Game:valid(piece,dx,dy,rotation)
 for _,c in ipairs(self:cells(piece,dx,dy,rotation)) do
  if c[1]<1 or c[1]>10 or c[2]>20 or (c[2]>=1 and self.board[c[2]][c[1]]) then return false end
 end return true
end
function Game:spawn(kind)
 self.piece={kind=kind or table.remove(self.queue,1),x=4,y=0,rotation=0}
 self:fillQueue() self.gravity=0 self.lockTime=0 self.lockResets=0
 if not self:valid() then self:lose('The room filled with rubble.') end
end
function Game:lose(reason) self.status='lost' self.reason=reason self:emit('lost') end
function Game:move(dx,dy)
 if self.status~='playing' then return false end
 if self:valid(nil,dx,dy) then
  self.piece.x=self.piece.x+dx self.piece.y=self.piece.y+dy
  if dx~=0 and self.lockResets<15 then self.lockTime=0 self.lockResets=self.lockResets+1 end
  return true
 end return false
end
function Game:rotate(direction)
 if self.status~='playing' or self.piece.kind=='O' then return end
 local r=(self.piece.rotation+direction)%4
 for _,kick in ipairs({{0,0},{-1,0},{1,0},{-2,0},{2,0},{0,-1},{-1,-1},{1,-1},{0,-2}}) do
  if self:valid(nil,kick[1],kick[2],r) then
   self.piece.x=self.piece.x+kick[1] self.piece.y=self.piece.y+kick[2] self.piece.rotation=r
   if self.lockResets<15 then self.lockTime=0 self.lockResets=self.lockResets+1 end
   self:emit('rotate') return
  end
 end
end
function Game:hold()
 if self.status~='playing' or self.holdUsed then return end
 local old=self.held self.held=self.piece.kind self:spawn(old) self.holdUsed=true self:emit('hold')
end
function Game:ghostY()
 local n=0 while self:valid(nil,0,n+1) do n=n+1 end return self.piece.y+n
end
function Game:drop()
 if self.status~='playing' then return end
 local y=self:ghostY() self.score=self.score+(y-self.piece.y)*2 self.piece.y=y self:lock()
end
function Game:clearRows()
 local count=0 local y=20 local clearedRows={}
 while y>=1 do
  local full=true for x=1,10 do if not self.board[y][x] then full=false break end end
  if full then
   local blocks={I=0,O=0,T=0,S=0,Z=0,J=0,L=0}
   for x=1,10 do
    local kind=self.board[y][x]
    blocks[kind]=blocks[kind]+1
    local resource=Game.resourceForPiece[kind]
    self.resources[resource]=self.resources[resource]+10
    self.loot[resource]=self.loot[resource]+10
   end
   clearedRows[#clearedRows+1]=blocks
   table.remove(self.board,y) table.insert(self.board,1,{}) count=count+1
  else y=y-1 end
 end return count,clearedRows
end
function Game:lock()
 local overflow=false
 for _,c in ipairs(self:cells()) do
  if c[2]<1 then overflow=true else self.board[c[2]][c[1]]=self.piece.kind end
 end
 if overflow then self:lose('The room filled with rubble.') return end
 local count,clearedRows=self:clearRows()
 if count>0 then
  self.combo=self.combo+1 self.lines=self.lines+count
  local damage=({1,3,5,9})[count]
  self.score=self.score+({100,300,500,1000})[count]+math.max(0,self.combo)*50
  self.position=math.min(.92,self.position+.035*count)
  self.enemyHP=self.enemyHP-damage self:emit('clear',{lines=count,damage=damage,rows=clearedRows})
  if self.enemyHP<=0 then
   self.kills=self.kills+1 self:emit('kill')
   if self.enemyIndex==#enemies then self.status='won' self:emit('won') return end
   self.enemyIndex=self.enemyIndex+1 self.enemyHP=self:enemy().hp self.attack=0 self.travel=2
  end
 else self.combo=-1 self:emit('lock') end
 self.holdUsed=false self:spawn()
end
function Game:update(dt,soft)
 if self.status~='playing' then return end
 dt=math.min(dt,.1) self.time=self.time+dt
 if self.travel>0 then self.travel=math.max(0,self.travel-dt)
 else
  self.attack=self.attack+dt
  if self.attack>=self:enemy().rate then
   self.attack=self.attack-self:enemy().rate self.position=self.position-self:enemy().push self:emit('hit')
   if self.position<=0 then self.position=0 self:lose('You were driven out of the keep.') return end
  end
 end
 local interval=soft and .045 or math.max(.38,.8-self.lines*.008)
 self.gravity=self.gravity+dt
 while self.gravity>=interval do
  self.gravity=self.gravity-interval
  if self:move(0,1) and soft then self.score=self.score+1 end
 end
 if not self:valid(nil,0,1) then
  self.lockTime=self.lockTime+dt if self.lockTime>=.45 then self:lock() end
 else self.lockTime=0 end
end
return Game
