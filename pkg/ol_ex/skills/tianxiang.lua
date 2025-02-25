local this = fk.CreateSkill{ name = "ol_ex__tianxiang" }

this:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(this.name) and target == player and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player:getCardIds("he"), function(id)
      return not player:prohibitDiscard(Fk:getCardById(id)) and Fk:getCardById(id).suit == Card.Heart
    end)
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local tar, card =  room:askToChooseCardAndPlayers(player, { targets = targets, min_num = 1, max_num = 1, pattern = tostring(Exppattern{ id = ids }), prompt = "#ol_ex__tianxiang-choose", skill_name = this.name, cancelable = true})
    if #tar > 0 and card then
      self.cost_data = {tar[1], card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    local cid = self.cost_data[2]
    room:throwCard(cid, this.name, player, player)

    if player.dead or to.dead then return true end

    local choices = {"ol_ex__tianxiang_loseHp"}
    if data.from and not data.from.dead then
      table.insert(choices, "ol_ex__tianxiang_damage")
    end
    local choice = room:askToChoice(player, { choices = choices, skill_name = this.name, prompt = "#ol_ex__tianxiang-choice::"..to.id})
    if choice == "ol_ex__tianxiang_loseHp" then
      room:loseHp(to, 1, this.name)
      if not to.dead and (room:getCardArea(cid) == Card.DrawPile or room:getCardArea(cid) == Card.DiscardPile) then
        room:obtainCard(to, cid, true, fk.ReasonJustMove)
      end
    else
      room:damage{
        from = data.from,
        to = to,
        damage = 1,
        skillName = this.name,
      }
      if not to.dead then
        to:drawCards(math.min(to:getLostHp(), 5), this.name)
      end
    end
    return true
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__tianxiang"] = "天香",
  [":ol_ex__tianxiang"] = "当你受到伤害时，你可弃置一张<font color='red'>♥</font>牌并选择一名其他角色。你防止此伤害，"..
  "选择：1.令来源对其造成1点普通伤害，其摸X张牌（X为其已损失的体力值且至多为5）；2.令其失去1点体力，其获得牌堆或弃牌堆中你以此法弃置的牌。",
  
  ["#ol_ex__tianxiang-choose"] = "天香：弃置一张<font color='red'>♥</font>手牌并选择一名其他角色",
  ["#ol_ex__tianxiang-choice"] = "天香：选择一项令 %dest 执行",
  ["ol_ex__tianxiang_damage"] = "令其受到1点伤害并摸已损失体力值的牌",
  ["ol_ex__tianxiang_loseHp"] = "令其失去1点体力并获得你弃置的牌",
  
  ["$ol_ex__tianxiang1"] = "碧玉闺秀，只可远观。",
  ["$ol_ex__tianxiang2"] = "你岂会懂我的美丽？",
}

return this