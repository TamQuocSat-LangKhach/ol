local feiyang = fk.CreateSkill {
  name = "ol_feiyang&",
}

Fk:loadTranslationTable{
  ["ol_feiyang&"] = "飞扬",
  [":ol_feiyang&"] = "判定阶段开始时，你可以弃置两张手牌，然后弃置自己判定区所有牌。",

  ["#ol_feiyang-invoke"] = "飞扬：你可以弃置两张手牌，弃置自己判定区所有牌",
}

feiyang:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(feiyang.name) and player.phase == Player.Judge and
      player:getHandcardNum() >= 2 and #player:getCardIds("j") > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 2,
      max_num = 2,
      include_equip = false,
      skill_name = feiyang.name,
      prompt = "#ol_feiyang-invoke",
      cancelable = true,
      skip = true,
    })
    if #cards == 2 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, feiyang.name, player, player)
    player:throwAllCards("j", feiyang.name)
  end,
})

return feiyang
