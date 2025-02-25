local this = fk.CreateSkill{
  name = "ol_ex__juece",
}

this:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(this.name) and player.phase == Player.Finish
    and table.find(player.room:getOtherPlayers(player, false), function (p)
      return p:getHandcardNum() <= player:getHandcardNum()
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return p:getHandcardNum() <= player:getHandcardNum()
    end)
    local to = room:askToChoosePlayers(player, { targets = targets, min_num = 1, max_num = 1, prompt = "#ol_ex__juece-choose", skill_name = this.name, cancelable = true})
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = player.room:getPlayerById(self.cost_data.tos[1]),
      damage = 1,
      skillName = this.name,
    }
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__juece"] = "绝策",
  [":ol_ex__juece"] = "结束阶段，你可以对一名手牌数不大于你的其他角色造成1点伤害。",

  ["#ol_ex__juece-choose"] = "绝策：你可以对一名手牌数不大于你的角色造成1点伤害",

  ["$ol_ex__juece1"] = "汝为孤家寡人，生死自当由我。",
  ["$ol_ex__juece2"] = "我以拳殴帝，帝可有还手之力？",
}

return this