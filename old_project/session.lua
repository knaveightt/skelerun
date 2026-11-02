local Game=require('game')
local Session={}
Session.__index=Session
Session.resourceNames={'Tin','Iron','Copper','Orichalcum','Platinum'}
function Session.new(saved,onSave)
 local self=setmetatable({scene='cell',resources={},blacksmithUnlocked=false,onSave=onSave},Session)
 saved=type(saved)=='table' and saved or {}
 for _,name in ipairs(Session.resourceNames) do
  local n=type(saved.resources)=='table' and saved.resources[name] or 0
  self.resources[name]=type(n)=='number' and n==n and n>=0 and n<1e12 and math.floor(n) or 0
 end
 self.blacksmithUnlocked=saved.blacksmithUnlocked==true
 return self
end
function Session:encode()
 local lines={'SKELERUN_SAVE_1','Blacksmith='..(self.blacksmithUnlocked and '1' or '0')}
 for _,name in ipairs(Session.resourceNames) do lines[#lines+1]=name..'='..self.resources[name] end
 return table.concat(lines,'\n')..'\n'
end
function Session.decode(data)
 if type(data)~='string' or not data:match('^SKELERUN_SAVE_1\n') then return nil end
 local saved={resources={}}
 for key,value in data:gmatch('([%a]+)=(%d+)') do
  if key=='Blacksmith' then saved.blacksmithUnlocked=value=='1'
  else saved.resources[key]=tonumber(value) end
 end
 return saved
end
function Session:save() if self.onSave then self.onSave(self:encode()) end end
function Session:startRun(random)
 if self.scene~='cell' then return nil end
 self.run=Game.new(random,self.resources) self.scene='run' self.summary=nil
 return self.run
end
function Session:returnToCell()
 if self.scene~='run' then return false end
 local run=self.run
 local total=0 for _,n in pairs(run.loot) do total=total+n end
 self.summary={status=run.status,reason=run.reason,lines=run.lines,kills=run.kills,loot=total}
 self.scene='cell' self:save() return true
end
function Session:canUnlockBlacksmith()
 return not self.blacksmithUnlocked and self.resources.Iron>=500 and self.resources.Copper>=500
end
function Session:unlockBlacksmith()
 if self.scene~='cell' then return false,'Return to your cell first.' end
 if self.blacksmithUnlocked then return false,'The Blacksmith is open. Refining will come later.' end
 if not self:canUnlockBlacksmith() then return false,'The Blacksmith needs 500 Iron AND 500 Copper.' end
 self.resources.Iron=self.resources.Iron-500 self.resources.Copper=self.resources.Copper-500
 self.blacksmithUnlocked=true self:save()
 return true,'Blacksmith unlocked! Refining will come later.'
end
return Session
