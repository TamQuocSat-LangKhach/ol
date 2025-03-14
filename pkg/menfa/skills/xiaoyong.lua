local xiaoyong = fk.CreateSkill{
  name = "xiaoyong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xiaoyong"] = "啸咏",
  [":xiaoyong"] = "锁定技，当你于回合内首次使用牌名字数为X的牌时（X为你上次发动〖观骨〗观看牌数），你视为未发动〖观骨〗。",

  ["$xiaoyong1"] = "凉风萧条，露沾我衣。",
  ["$xiaoyong2"] = "忧来多方，慨然永怀。",
}

xiaoyong:addEffect(fk.CardUsing, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(xiaoyong.name) or
      player:usedSkillTimes("guangu", Player.HistoryPhase) == 0 then return end
    local n = Fk:translate(data.card.trueName, "zh_CN"):len()
    if n ~= player:getMark("@guangu-phase") then return false end
    local mark = player:getMark("xiaoyong-turn")
    if type(mark) ~= "table" then mark = {0, 0, 0, 0} end
    local room = player.room
    local use_event = room.logic:getCurrentEvent()
    if mark[n] == 0 then
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.from == player and Fk:translate(use.card.trueName, "zh_CN"):len() == n then
          mark[n] = e.id
          room:setPlayerMark(player, "xiaoyong-turn", mark)
          return true
        end
      end, Player.HistoryTurn)
    end
    return use_event.id == mark[n]
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@guangu-phase", 0)
    player:setSkillUseHistory("guangu", 0, Player.HistoryPhase)
  end,
})

return xiaoyong
