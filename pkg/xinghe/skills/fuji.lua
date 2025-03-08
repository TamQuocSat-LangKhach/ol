local fuji = fk.CreateSkill{
  name = "fuji",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fuji"] = "伏骑",
  [":fuji"] = "锁定技，当你使用【杀】或普通锦囊牌时，你令所有至你距离为1的角色不能响应此牌。",

  ["$fuji1"] = "白马？不足挂齿！",
  ["$fuji2"] = "掌握之中，岂可逃之？",
}

fuji:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuji.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:distanceTo(player) == 1
      end)
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room:getOtherPlayers(player, false)) do
      if p:distanceTo(player) == 1 then
        table.insertIfNeed(data.disresponsiveList, p)
      end
    end
  end,
})

return fuji
