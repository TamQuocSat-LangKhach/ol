local xichu = fk.CreateSkill{
  name = "qin__xichu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__xichu"] = "戏楚",
  [":qin__xichu"] = "锁定技，当你成为【杀】的目标时，使用者需弃置一张点数为6的牌，否则你将此【杀】的目标转移给其攻击范围内你指定的另一名角色。",

  ["#qin__xichu-discard"] = "戏楚：你需弃置一张点数6的牌，否则对 %src 使用的【杀】转移给其指定的角色",
  ["#qin__xichu-choose"] = "戏楚：选择一名角色，将 %dest 对你使用的【杀】转移给指定的角色",

  ["$qin__xichu"] = "楚王欲贪，此戏方成。",
}

xichu:addEffect(fk.TargetConfirming, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xichu.name) and
      data.card.trueName == "slash" and not data.from.dead and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return data.from:inMyAttackRange(p) and table.contains(data:getExtraTargets(), p)
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #room:askToDiscard(data.from, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = xichu.name,
      pattern = ".|6",
      prompt = "#qin__xichu-discard:"..player.id,
      cancelable = true,
    }) == 0 then
      local targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return data.from:inMyAttackRange(p) and table.contains(data:getExtraTargets(), p)
      end)
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = xichu.name,
        prompt = "#qin__xichu-choose::"..data.from.id,
        cancelable = false,
      })[1]
      data:cancelTarget(player)
      data:addTarget(to)
    end
  end,
})

return xichu
