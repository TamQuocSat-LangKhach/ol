local douchan = fk.CreateSkill{
  name = "douchan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["douchan"] = "斗缠",
  [":douchan"] = "锁定技，准备阶段，若牌堆中：有【决斗】，你从牌堆中获得一张【决斗】；"..
  "没有【决斗】，你的攻击范围和出牌阶段使用【杀】的次数上限+1（增加次数至多为游戏人数）。",

  ["@douchan"] = "斗缠",

  ["$douchan1"] = "此时不捉孙策，更待何时！",
  ["$douchan2"] = "有胆气者，都随我来！",
}

douchan:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(douchan.name) and player.phase == Player.Start and
      (player:getMark("@douchan") < #player.room.players or
      table.find(player.room.draw_pile, function (id)
        return Fk:getCardById(id).trueName == "duel"
      end))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule("duel")
    if #cards > 0 then
      room:obtainCard(player, cards[1], true, fk.ReasonPrey, player, douchan.name)
    elseif player:getMark("@douchan") < #room.players then
      room:addPlayerMark(player, "@douchan", 1)
      room:addPlayerMark(player, MarkEnum.SlashResidue)
    end
  end,
})
douchan:addEffect("atkrange", {
  correct_func = function (self, from, to)
    return from:getMark("@douchan")
  end,
})

return douchan
