local zhiji = fk.CreateSkill{
  name = "zhijil",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhijil"] = "掷戟",
  [":zhijil"] = "锁定技，你使用非伤害牌指定“义父”为目标时，你判定X次，若判定牌包含：装备牌，你获得〖神戟〗；【杀】或【决斗】，你获得〖无双〗和"..
  "此判定牌。你使用伤害牌指定“义父”为目标时，你令此牌伤害+X并移除其“恨”标记（X为其“恨”标记的数量）。",

  ["$zhijil1"] = "老贼，我与你势不两立！",
  ["$zhijil2"] = "我堂堂大丈夫，安肯为汝之义子！",
}

zhiji:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhiji.name) and
      table.contains(player:getTableMark("fengzhu"), data.to.id) and
      data.to:getMark("@lvbu_hate") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local father = data.to
    local n = father:getMark("@lvbu_hate")
    if data.card.is_damage_card then
      data.additionalDamage = (data.additionalDamage or 0) + n
      room:setPlayerMark(father, "@lvbu_hate", 0)
    else
      for _ = 1, n, 1 do
        local judge = {
          who = player,
          reason = zhiji.name,
          pattern = "slash,duel;.|.|.|.|.|equip",
        }
        room:judge(judge)
        if judge.card.type == Card.TypeEquip then
          room:handleAddLoseSkills(player, "shenji")
        elseif table.contains({"slash", "duel"}, judge.card.trueName) then
          room:handleAddLoseSkills(player, "wushuang", nil, true, false)
          if room:getCardArea(judge.card) == Card.DiscardPile then
            room:moveCardTo(judge.card, Card.PlayerHand, player, fk.ReasonJustMove, zhiji.name, nil, true, player)
          end
        end
      end
    end
  end,
})

return zhiji
