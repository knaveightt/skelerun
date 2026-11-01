package.path='./?.lua;'..package.path
local Session=require('session')
local checks=0
local function check(value,message) assert(value,message) checks=checks+1 end
local saved,writes=nil,0
local s=Session.new(nil,function(data) saved=data writes=writes+1 end)
check(s.scene=='cell' and not s.blacksmithUnlocked,'new game starts in cell with locked workshop')
for _,name in ipairs(Session.resourceNames) do check(s.resources[name]==0,'empty initial stash: '..name) end
check(not s:unlockBlacksmith(),'cannot unlock without resources')
s.resources.Iron=500 s.resources.Copper=499
check(not s:unlockBlacksmith() and s.resources.Iron==500 and s.resources.Copper==499,'both costs required and failure spends nothing')
s.resources.Iron=499 s.resources.Copper=500
check(not s:unlockBlacksmith(),'iron must also meet cost')
local run=s:startRun(function(n) return n end)
check(s.scene=='run' and run.resources==s.resources,'run uses persistent inventory')
check(s:startRun()==nil,'cannot replace an active run')
check(not s:unlockBlacksmith(),'workshop is only accessible in cell')
for x=1,10 do if x<4 or x>7 then run.board[20][x]='S' end end
run.piece={kind='I',x=4,y=19,rotation=0} run:lock()
check(s.resources.Iron==559 and s.resources.Platinum==40,'line rewards enter persistent stash')
check(run.loot.Iron==60 and run.loot.Platinum==40,'run loot excludes prior stash')
run:lose('Test defeat')
check(s:returnToCell() and s.scene=='cell','death returns to cell')
check(s.summary.status=='lost' and s.summary.loot==100 and s.summary.lines==1,'return summarizes run')
check(writes==1 and saved~=nil,'return saves inventory')
local before=s.resources.Tin
check(s:unlockBlacksmith(),'enough materials unlock workshop')
check(s.resources.Iron==59 and s.resources.Copper==0,'unlock spends exactly 500 of each resource')
check(s.blacksmithUnlocked and s.resources.Tin==before and s.resources.Platinum==40,'unlock affects only correct resources')
check(not s:unlockBlacksmith() and s.resources.Iron==59,'cannot charge twice')
check(writes==2,'unlock saves immediately')
local restored=Session.new(Session.decode(saved))
check(restored.scene=='cell' and restored.blacksmithUnlocked,'reload preserves unlock and starts in cell')
for _,name in ipairs(Session.resourceNames) do check(restored.resources[name]==s.resources[name],'save roundtrip '..name) end
run=restored:startRun(function(n) return n end)
check(run.resources.Iron==59 and run.lines==0 and run.loot.Iron==0,'next run retains stash and resets board progress')
run.status='won' restored:returnToCell()
check(restored.scene=='cell' and restored.summary.status=='won','victory also returns to cell')
restored:startRun() restored:returnToCell()
check(restored.summary.status=='playing' and restored.resources.Platinum==40,'early return preserves stash')
check(not restored:returnToCell(),'return cannot double-process an ended run')
check(Session.decode('untrusted lua()')==nil,'save parser never executes input')
check(Session.decode(nil)==nil,'missing save supported')
local bad=Session.new({resources={Iron=-100,Copper='500',Tin=math.huge,Orichalcum=0/0,Platinum=1.5}})
check(bad.resources.Iron==0 and bad.resources.Copper==0 and bad.resources.Tin==0 and bad.resources.Orichalcum==0 and bad.resources.Platinum==1,'invalid save values sanitized')
print(checks..' cell and persistence checks passed')
