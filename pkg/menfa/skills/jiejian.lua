local jiejian = fk.CreateSkill{
  name = "jiejian",
}

Fk:loadTranslationTable{
  ["jiejian"] = "捷谏",
  [":jiejian"] = "当你每回合使用第X张牌指定目标后，若此牌不为装备牌，你可以令其中一个目标摸X张牌（X为此牌牌名字数）。",

  ["#jiejian-choose"] = "捷谏：你可以令其中一个目标摸%arg张牌",

  ["$jiejian1"] = "庙胜之策，不临矢石。",
  ["$jiejian2"] = "王者之兵，有征无战。",
}

jiejian:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiejian.name) and
      data.card.type ~= Card.TypeEquip and data.firstTarget and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 10, function(e)
        return e.data.from == player
      end, Player.HistoryTurn) == Fk:translate(data.card.trueName, "zh_CN"):len() and
      table.find(data.use.tos, function (p)
        return not p.dead
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = data.use.tos,
      skill_name = jiejian.name,
      prompt = "#jiejian-choose:::"..Fk:translate(data.card.trueName, "zh_CN"):len(),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(Fk:translate(data.card.trueName, "zh_CN"):len(), jiejian.name)
  end,
})

return jiejian
