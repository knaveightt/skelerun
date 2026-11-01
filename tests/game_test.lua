package.path='./?.lua;'..package.path
local Game=require('game')
local checks=0
local function check(value,message) assert(value,message) checks=checks+1 end
local function fresh() return Game.new(function(n) return n end) end
local g=fresh()
check(#g.queue==5,'five previews are queued')
local seen={} seen[g.piece.kind]=true
for i=1,6 do g:spawn() seen[g.piece.kind]=true end
local n=0 for _ in pairs(seen) do n=n+1 end
check(n==7,'seven-bag contains every piece')
g=fresh() local first=g.piece.kind g:hold()
check(g.held==first and g.holdUsed,'hold stores a piece')
local active=g.piece.kind g:hold() check(g.piece.kind==active,'hold is once per placement')
g=fresh() for _=1,20 do g:move(-1,0) end check(g:valid(),'left wall collision')
for _=1,4 do g:rotate(1) end check(g:valid(),'wall rotation remains valid')
g=fresh() local ghost=g:ghostY() g:drop()
local occupied=0 for y=1,20 do for x=1,10 do if g.board[y][x] then occupied=occupied+1 end end end
check(occupied==4 and ghost>0,'hard drop locks four cells')
for count=1,4 do
 g=fresh() g.enemyHP=100 local pos=g.position
 for y=21-count,20 do for x=1,10 do if x~=5 then g.board[y][x]='J' end end end
 g.piece={kind='I',x=3,y=17,rotation=1} g:lock()
 check(g.lines==count,'clears '..count..' rows')
 check(g.enemyHP==100-({1,3,5,9})[count],'damage scales for '..count..' rows')
 check(g.position>pos,'line clears advance player')
end
g=fresh() g.travel=0 g.attack=g:enemy().rate-.01 local pos=g.position g:update(.02,false)
check(g.position<pos,'monster hit pushes left')
g.position=.01 g.attack=g:enemy().rate-.01 g:update(.02,false)
check(g.status=='lost','left edge ends run')
g=fresh() for x=1,10 do g.board[1][x]='Z' end g:spawn('O') check(g.status=='lost','blocked spawn ends run')
for index=1,5 do
 g=fresh() g.enemyIndex=index g.enemyHP=1
 for x=1,10 do if x<4 or x>7 then g.board[20][x]='L' end end
 g.piece={kind='I',x=4,y=19,rotation=0} g:lock()
 check(g.kills==1,'enemy defeated')
 check(index==5 and g.status=='won' or index<5 and g.enemyIndex==index+1 and g.travel==2,'enemy progression or victory')
end
print(checks..' gameplay checks passed')
