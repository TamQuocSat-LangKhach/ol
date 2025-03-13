local nengchen = fk.CreateSkill{
  name = "nengchen",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["nengchen"] = "能臣",
  [":nengchen"] = "锁定技，当你受到伤害后，你获得随机一张与造成伤害的牌牌名相同的“定西”牌。",

  ["$nengchen1"] = "当今四海升平，可为治世之能臣。",
  ["$nengchen2"] = "为大汉江山鞠躬尽瘁，臣死犹生。",
}

nengchen:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(nengchen.name) and data.card and
      table.find(player:getPile("dingxi"), function (id)
        return data.card.trueName == Fk:getCardById(id).trueName
      end)
  end,
  on_use = function(self, event, target, player, data)
    local cards = table.filter(player:getPile("dingxi"), function (id)
      return data.card.trueName == Fk:getCardById(id).trueName
    end)
    player.room:moveCardTo(table.random(cards), Card.PlayerHand, player, fk.ReasonJustMove, nengchen.name, nil, true, player)
  end,
})

return nengchen
