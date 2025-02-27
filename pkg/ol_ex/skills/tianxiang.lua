local tianxiang = fk.CreateSkill{
  name = "ol_ex__tianxiang",
}

Fk:loadTranslationTable {
  ["ol_ex__tianxiang"] = "天香",
  [":ol_ex__tianxiang"] = "当你受到伤害时，你可以弃置一张<font color='red'>♥</font>牌并选择一名其他角色。你防止此伤害并选择一项："..
  "1.伤害来源对其造成1点伤害，其摸X张牌（X为其已损失的体力值且至多为5）；2.令其失去1点体力，其获得牌堆或弃牌堆中你以此法弃置的牌。",

  ["#ol_ex__tianxiang-choose"] = "天香：弃置一张<font color='red'>♥</font>手牌并选择一名其他角色",
  ["#ol_ex__tianxiang-choice"] = "天香：选择一项令 %dest 执行",
  ["ol_ex__tianxiang_damage"] = "令其受到1点伤害并摸已损失体力值的牌",
  ["ol_ex__tianxiang_loseHp"] = "令其失去1点体力并获得你弃置的牌",

  ["$ol_ex__tianxiang1"] = "碧玉闺秀，只可远观。",
  ["$ol_ex__tianxiang2"] = "你岂会懂我的美丽？",
}

tianxiang:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tianxiang.name) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      pattern = ".|.|heart",
      skill_name = tianxiang.name,
      prompt = "#tianxiang-choose",
      cancelable = true,
      will_throw = true,
    })
    if #tos > 0 and #cards == 1 then
      event:setCostData(self, {tos = tos, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    local to = event:getCostData(self).tos[1]
    local cid = event:getCostData(self).cards[1]
    room:throwCard(event:getCostData(self).cards, tianxiang.name, player, player)
    if player.dead or to.dead then return end

    local choices = {"ol_ex__tianxiang_loseHp"}
    if data.from and not data.from.dead then
      table.insert(choices, 1, "ol_ex__tianxiang_damage")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = tianxiang.name,
      prompt = "#ol_ex__tianxiang-choice::"..to.id,
    })
    if choice == "ol_ex__tianxiang_loseHp" then
      room:loseHp(to, 1, tianxiang.name)
      if not to.dead and (room:getCardArea(cid) == Card.DrawPile or room:getCardArea(cid) == Card.DiscardPile) then
        room:obtainCard(to, cid, true, fk.ReasonJustMove)
      end
    else
      room:damage{
        from = data.from,
        to = to,
        damage = 1,
        skillName = tianxiang.name,
      }
      if not to.dead then
        to:drawCards(math.min(to:getLostHp(), 5), tianxiang.name)
      end
    end
  end,
})

return tianxiang