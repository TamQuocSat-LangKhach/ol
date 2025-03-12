local jiawei = fk.CreateSkill{
  name = "jiawei",
}

Fk:loadTranslationTable{
  ["jiawei"] = "假威",
  [":jiawei"] = "【杀】被抵消的回合结束时，你可以将任意张手牌当【决斗】对本回合抵消过【杀】的一名角色使用。每轮限一次，若此【决斗】造成伤害，"..
  "你可以令你或当前回合角色将手牌摸至手牌上限（至多摸至5）。",

  ["jiawei_viewas"] = "假威",
  ["#jiawei-use"] = "假威：你可以将任意张手牌当【决斗】对其中一名角色使用",
  ["#jiawei-choose"] = "假威：你可以令一名角色将手牌摸至手牌上限",

  ["$jiawei1"] = "",
  ["$jiawei2"] = "",
}

jiawei:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(jiawei.name) and #player:getHandlyIds() > 0 then
      local targets = {}
      player.room.logic:getEventsOfScope(GameEvent.CardEffect, 1, function (e)
        local effect = e.data
        if effect.card.trueName == "slash" and effect.isCancellOut then
          if effect.to ~= player and not effect.to.dead then
            table.insertIfNeed(targets, effect.to)
          end
        end
      end, Player.HistoryTurn)
      if #targets > 0 then
        event:setCostData(self, {tos = targets})
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "jiawei_viewas",
      prompt = "#jiawei-use",
      extra_data = {
        exclusive_targets = table.map(event:getCostData(self).tos, Util.IdMapper),
      },
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, cards = dat.cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local use = room:useVirtualCard("duel", event:getCostData(self).cards, player, event:getCostData(self).tos, jiawei.name)
    if use and use.damageDealt and not player.dead and player:getMark("jiawei-round") == 0 then
      local targets = {}
      if player:getHandcardNum() < math.min(player:getMaxCards(), 5) then
        table.insert(targets, player)
      end
      if not target.dead and target:getHandcardNum() < math.min(target:getMaxCards(), 5) then
        table.insertIfNeed(targets, target)
      end
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = jiawei.name,
          prompt = "#jiawei-choose",
          cancelable = true,
        })
        if #to > 0 then
          to = to[1]
          room:setPlayerMark(player, "jiawei-round", 1)
          to:drawCards(math.min(to:getMaxCards(), 5) - to:getHandcardNum(), jiawei.name)
        end
      end
    end
  end,
})

return jiawei
