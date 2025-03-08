local zengou = fk.CreateSkill{
  name = "zengou",
}

Fk:loadTranslationTable{
  ["zengou"] = "谮构",
  [":zengou"] = "当你攻击范围内一名角色使用【闪】时，你可以弃置一张非基本牌或失去1点体力，令此【闪】无效，然后你获得之。",

  ["#zengou-invoke"] = "谮构：你可以弃置一张非基本牌（不选牌则失去体力），令 %dest 使用的%arg无效且你获得之",

  ["$zengou1"] = "此书定能置夏侯楙于死地。",
  ["$zengou2"] = "夏侯违制，请君上定夺。",
}

zengou:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zengou.name) and data.card.name == "jink" and
      player:inMyAttackRange(target)
  end,
  on_cost = function(self, event, target, player, data)
    local discard_data = {
      num = 1,
      min_num = player.hp > 0 and 0 or 1,
      include_equip = true,
      skillName = zengou.name,
      pattern = ".|.|.|.|.|^basic",
    }
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "discard_skill",
      prompt = "#zengou-invoke::"..target.id..":"..data.card:toLogString(),
      extra_data = discard_data,
      skip = true,
    })
    if success and dat then
      event:setCostData(self, {tos = {target}, cards = dat.cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.toCard = nil
    --data:removeAllTargets()
    if #event:getCostData(self).cards > 0 then
      room:throwCard(event:getCostData(self).cards, zengou.name, player, player)
    else
      room:loseHp(player, 1, zengou.name)
    end
    if not player.dead and room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, zengou.name)
    end
  end,
})

return zengou
