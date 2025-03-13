local yintui = fk.CreateSkill{
  name = "qin__yintui",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__yintui"] = "隐退",
  [":qin__yintui"] = "锁定技，当你失去最后一张手牌后，你翻面；当你受到伤害时，若你的武将牌背面朝上，此伤害-1，然后你摸一张牌。",

  ["$qin__yintui"] = "妾身为国尽心，你们怎可如此待我？",
}

yintui:addEffect(fk.AfterCardsMove, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yintui.name) and player:isKongcheng() then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    player:turnOver()
  end,
})
yintui:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yintui.name) and not player.faceup
  end,
  on_use = function (self, event, target, player, data)
    data:changeDamage(-1)
    player:drawCards(1, yintui.name)
  end,
})

return yintui
