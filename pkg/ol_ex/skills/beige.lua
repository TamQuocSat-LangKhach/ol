local this = fk.CreateSkill {
  name = "ol_ex__beige",
}

this:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(this.name) and data.card and data.card.trueName == "slash" and not data.to.dead and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#ol_ex__beige-invoke::"..target.id})
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local judge = {
      who = target,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if player.dead then return false end
    local card = player.room:askToDiscard(player, { min_num = 1, max_num = 1, include_equip = true,
      skill_name = self.name, cancelable = true, pattern = ".", prompt = "#ol_ex__beige-discard::"..target.id, skip = true
    })
    if #card ~= 1 then return end
    local dis_card = Fk:getCardById(card[1])
    local suit = dis_card.suit
    local number = dis_card.number
    room:throwCard(card, self.name, player, player)
    if not player.dead then
      local cards = {}
      if suit == judge.card.suit and room:getCardArea(judge.card.id) == Card.DiscardPile then
        table.insert(cards, judge.card.id)
      end
      if number == judge.card.number and room:getCardArea(dis_card.id) == Card.DiscardPile then
        table.insert(cards, dis_card.id)
      end
      if #cards > 0 then
        room:obtainCard(player, cards, true, fk.ReasonJustMove)
      end
    end
    if judge.card.suit == Card.Heart then
      if not target.dead and target:isWounded() then
        room:recover{
          who = target,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
      end
    elseif judge.card.suit == Card.Diamond then
      if not target.dead then
        target:drawCards(2, self.name)
      end
    elseif judge.card.suit == Card.Club then
      if data.from and not data.from.dead then
        room:askToDiscard(data.from, { min_num = 2, max_num = 2, include_equip = true, skill_name = self.name, cancelable = false})
      end
    elseif judge.card.suit == Card.Spade then
      if data.from and not data.from.dead then
        data.from:turnOver()
      end
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__beige"] = "悲歌",
  [":ol_ex__beige"] = "当一名角色受到【杀】造成的伤害后，若你有牌，你可以令其判定，然后你可以弃置一张牌，根据判定结果执行："..
  "<font color='red'>♥</font>，其回复1点体力；<font color='red'>♦</font>，其摸两张牌；"..
  "♣，来源弃置两张牌；♠，来源翻面。若判定牌与你弃置的牌：花色相同，你获得判定牌；点数相同，你获得你弃置的牌。",

  ["#ol_ex__beige-invoke"] = "悲歌：你可以令%dest进行判定",
  ["#ol_ex__beige-discard"] = "悲歌：你可以弃置一张牌令%dest根据判定的花色执行对应效果",

  ["$ol_ex__beige1"] = "箜篌鸣九霄，闻者心俱伤。",
  ["$ol_ex__beige2"] = " 琴弹十八拍，听此双泪流。",
}

return this
