local jiewan = fk.CreateSkill{
  name = "jiewan",
}

Fk:loadTranslationTable{
  ["jiewan"] = "解腕",
  [":jiewan"] = "每个准备阶段，你可以减1点体力上限或移除两张“谷”，然后你可以将一张手牌当无距离限制的【顺手牵羊】使用。每个结束阶段，"..
  "若你的“谷”数与手牌数相同且你的体力上限不为全场唯一最多，你加1点体力上限。",

  ["#jiewan-invoke"] = "解腕：移去两张“谷”，或不选“谷”减1点体力上限，然后将一张手牌当无距离限制的【顺手牵羊】使用",
  ["#jiewan-use"] = "解腕：将一张手牌当无距离限制的【顺手牵羊】使用",
}

jiewan:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jiewan.name) then
      if target.phase == Player.Start then
        return not player:isKongcheng()
      elseif target.phase == Player.Finish then
        return player:getHandcardNum() == #player:getPile("dengai_grain") and
          table.find(player.room:getOtherPlayers(player, false), function (p)
            return player.maxHp <= p.maxHp
          end)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if target.phase == Player.Start then
      local success, dat = player.room:askToUseActiveSkill(player, {
        skill_name = "jiewan_active",
        prompt = "#jiewan-invoke",
        no_indicate = true,
      })
      if success and dat then
        event:setCostData(self, {cards = dat.cards})
        return true
      end
    elseif target.phase == Player.Finish then
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if target.phase == Player.Start then
      if #event:getCostData(self).cards > 0 then
        room:moveCardTo(event:getCostData(self).cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, jiewan.name, nil, true, player)
      else
        room:changeMaxHp(player, -1)
      end
      if player.dead or #player:getHandlyIds() == 0 then return end
      room:askToUseVirtualCard(player, {
        name = "snatch",
        skill_name = jiewan.name,
        prompt = "#jiewan-use",
        cancelable = true,
        extra_data = {
          bypass_distances = true,
        },
        card_filter = {
          n = 1,
          cards = player:getHandlyIds(),
        },
      })
    elseif target.phase == Player.Finish then
      room:changeMaxHp(player, 1)
    end
  end,
})

return jiewan
