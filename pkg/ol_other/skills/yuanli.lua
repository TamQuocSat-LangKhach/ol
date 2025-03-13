local yuanli = fk.CreateSkill{
  name = "qin__yuanli",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__yuanli"] = "爰历",
  [":qin__yuanli"] = "锁定技，出牌阶段开始时，你随机获得两张普通锦囊牌。",

  ["$qin__yuanli"] = "玉律法令，爰历皆记。",
}

yuanli:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuanli.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(table.connect(room.draw_pile, room.discard_pile), function (id)
      return Fk:getCardById(id):isCommonTrick()
    end)
    if #cards > 0 then
      room:moveCardTo(table.random(cards, 2), Card.PlayerHand, player, fk.ReasonJustMove, yuanli.name, nil, false, player)
    end
  end,
})

return yuanli
