local baozu = fk.CreateSkill{
  name = "baozu",
  tags = { Skill.Family , Skill.Limited },
}

Fk:loadTranslationTable{
  ["baozu"] = "保族",
  [":baozu"] = "宗族技，限定技，当同族角色进入濒死状态时，你可以令其横置并回复1点体力。",

  ["#baozu-invoke"] = "保族：你可以令 %dest 横置并回复1点体力",
}

local U = require "packages/utility/utility"

baozu:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(baozu.name) and target.dying and not target.chained and
      U.FamilyMember(player, target) and
      player:usedSkillTimes(baozu.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = baozu.name,
      prompt = "#baozu-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not target.chained then
      target:setChainState(true)
    end
    if not target.dead and target:isWounded() then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = baozu.name,
      }
    end
  end,
})

return baozu
