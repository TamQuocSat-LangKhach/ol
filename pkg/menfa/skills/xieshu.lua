local xieshu = fk.CreateSkill{
  name = "xieshu",
}

Fk:loadTranslationTable{
  ["xieshu"] = "挟术",
  [":xieshu"] = "当你造成或受到牌的伤害后，你可以横置，弃置X张牌（X为此牌牌名字数），摸你已损失体力值张数的牌。"..
  "若本回合有角色进入过濒死状态，此技能本回合失效。",

  ["#xieshu-invoke"] = "挟术：是否横置武将牌，弃置%arg张牌并摸%arg2张牌",

  ["$xieshu1"] = "今长缨在手，欲问鼎九州。",
  ["$xieshu2"] = "我有佐国之术，可缚苍龙。",
  ["$xieshu3"] = "大丈夫胸怀四海，有提携玉龙之术。",
  ["$xieshu4"] = "王霸之志在胸，我岂池中之物？",
  ["$xieshu5"] = "历经风浪至此，会不可止步于龙门。",
  ["$xieshu6"] = "我若束手无策，诸位又有何施为？",
}

local spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xieshu.name) and not player.chained and data.card
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = xieshu.name,
      prompt = "#xieshu-invoke:::"..Fk:translate(data.card.trueName, "zh_CN"):len()..":"..player:getLostHp(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:setChainState(true)
    if player.dead then return false end
    local n = Fk:translate(data.card.trueName, "zh_CN"):len()
    local cards = room:askToDiscard(player, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = xieshu.name,
      cancelable = false,
    })
    if #cards == 0 or player.dead then return end
    if player:isWounded() then
      player:drawCards(player:getLostHp(), xieshu.name)
      if player.dead then return false end
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      if #room.logic:getEventsOfScope(GameEvent.Dying, 1, Util.TrueFunc, Player.HistoryTurn) > 0 then
        room:invalidateSkill(player, xieshu.name, "-turn")
      end
    end
  end,
}
xieshu:addEffect(fk.Damage, spec)
xieshu:addEffect(fk.Damaged, spec)

return xieshu
