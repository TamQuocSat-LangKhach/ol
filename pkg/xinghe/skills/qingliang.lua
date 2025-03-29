local qingliang = fk.CreateSkill{
  name = "qingliang",
}

Fk:loadTranslationTable{
  ["qingliang"] = "清靓",
  [":qingliang"] = "每回合限一次，当你成为其他角色使用的【杀】或伤害锦囊牌的唯一目标时，你可以展示所有手牌并选择一项："..
  "1.你与其各摸一张牌；2.弃置一种花色的所有手牌，取消此目标。",

  ["#qingliang-choice"] = "清靓：%dest 对你使用%arg，你可以展示手牌并选一项",
  ["qingliang_draw"] = "与%dest各摸一张牌",
  ["qingliang_discard"] = "弃置一种花色的手牌，取消目标",
  ["#qingliang-suit"] = "清靓：弃置一种花色的所有手牌",

  ["$qingliang1"] = "挥斧摇清风，笑颜比朝霞。",
  ["$qingliang2"] = "素手抚重斧，飞矢擦靓装。",
}

qingliang:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingliang.name) and
      data.from ~= player and data.card.is_damage_card and
      data:isOnlyTarget(player) and not player:isKongcheng() and
      player:usedSkillTimes(qingliang.name, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local all_choices = {"qingliang_draw::"..data.from.id, "qingliang_discard", "Cancel"}
    local choices = table.simpleClone(all_choices)
    if table.every(player:getCardIds("h"), function (id)
      return player:prohibitDiscard(id)
    end) then
      table.remove(choices, 2)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = qingliang.name,
      prompt = "#qingliang-choice::"..data.from.id..":"..data.card:toLogString(),
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:showCards(player:getCardIds("h"))
    if player.dead then return end
    if event:getCostData(self).choice:startsWith("qingliang_draw") then
      player:drawCards(1, qingliang.name)
      if not data.from.dead then
        data.from:drawCards(1, qingliang.name)
      end
    else
      local suits = table.filter({"log_spade", "log_heart", "log_club", "log_diamond"}, function (suit)
        return table.find(player:getCardIds("h"), function (id)
          return Fk:getCardById(id):getSuitString(true) == suit and not player:prohibitDiscard(id)
        end) ~= nil
      end)
      if #suits == 0 then return end
      data:cancelTarget(player)
      local choice = room:askToChoice(player, {
        choices = suits,
        skill_name = qingliang.name,
        prompt = "#qingliang-suit",
      })
      local cards = table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getSuitString(true) == choice and not player:prohibitDiscard(id)
      end)
      room:throwCard(cards, qingliang.name, player, player)
    end
  end
})

return qingliang
