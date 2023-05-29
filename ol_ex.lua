local extension = Package("ol_ex")
extension.extensionName = "ol"

Fk:loadTranslationTable{
  ["ol_ex"] = "OL界",
}

local weiyan = General(extension, "ol_ex__weiyan", "shu", 4)
local ol_ex__kuanggu = fk.CreateTriggerSkill{
  name = "ol_ex__kuanggu",
  anim_type = "drawcard",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target == player and player:distanceTo(data.to) <= 1
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      self:doCost(event, target, player, data)
      if self.cost_data == "Cancel" then break end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw1", "Cancel"}
    if player:isWounded() then
      table.insert(choices, 2, "recover")
    end
    self.cost_data = room:askForChoice(player, choices, self.name)
    return self.cost_data ~= "Cancel"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "recover" then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    elseif self.cost_data == "draw1" then
      player:drawCards(1, self.name)
    end
  end,
}
local ol_ex__qimou_targetmod = fk.CreateTargetModSkill{
  name = "#ol_ex__qimou_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@qimou-turn") or 0
    end
  end,
}
local ol_ex__qimou_distance = fk.CreateDistanceSkill{
  name = "#ol_ex__qimou_distance",
  correct_func = function(self, from, to)
    return -from:getMark("@qimou-turn")
  end,
}
local ol_ex__qimou = fk.CreateActiveSkill{
  name = "ol_ex__qimou",
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  interaction = function()
    return UI.Spin {
      from = 1,
      to = Self.hp,
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local tolose = self.interaction.data
    room:loseHp(player, tolose, self.name)
    player:drawCards(tolose)
    room:setPlayerMark(player, "@qimou-turn", tolose)
  end,
}
ol_ex__qimou:addRelatedSkill(ol_ex__qimou_targetmod)
ol_ex__qimou:addRelatedSkill(ol_ex__qimou_distance)
weiyan:addSkill(ol_ex__kuanggu)
weiyan:addSkill(ol_ex__qimou)
Fk:loadTranslationTable{
  ["ol_ex__weiyan"] = "界魏延",
  ["ol_ex__kuanggu"] = "狂骨",
  [":ol_ex__kuanggu"] = "你对距离1以内的角色造成1点伤害后，你可以选择摸一张牌或回复1点体力。",
  ["ol_ex__qimou"] = "奇谋",
  [":ol_ex__qimou"] = "限定技，出牌阶段，你可以失去X点体力，本回合内与其他角色计算距离-X且可以多使用X张杀。",
  ["@qimou-turn"] = "奇谋",

  ["$ol_ex__kuanggu1"] = "反骨狂傲，彰显本色！",
  ["$ol_ex__kuanggu2"] = "只有战场，能让我感到兴奋！",
  ["$ol_ex__qimou1"] = "为了胜利，可以出其不意！",
  ["$ol_ex__qimou2"] = "勇战不如奇谋。",
  ["~ol_ex__weiyan"] = "这次失败，意料之中……",
}

return extension
