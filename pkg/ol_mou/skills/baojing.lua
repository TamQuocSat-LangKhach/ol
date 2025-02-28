local baojing = fk.CreateSkill{
  name = "baojing",
}

Fk:loadTranslationTable{
  ["baojing"] = "保京",
  [":baojing"] = "出牌阶段限一次，你可以令一名其他角色的攻击范围+1/-1（至多减至1），直到你的下个出牌阶段开始。",

  ["#baojing"] = "保京：令一名角色攻击范围+1/-1直到你下个出牌阶段开始",
  ["@baojing_add"] = "攻击范围+",
  ["@baojing_minus"] = "攻击范围-",
}

baojing:addEffect("active", {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#baojing",
  interaction = UI.ComboBox {choices = {"+1", "-1"}},
  can_use = function(self, player)
    return player:usedSkillTimes(baojing.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if self.interaction.data == "+1" then
      room:addPlayerMark(target, "@baojing_add", 1)
    else
      room:addPlayerMark(target, "@baojing_minus", 1)
    end
    room:setPlayerMark(player, baojing.name, {target.id, self.interaction.data})
  end,
})
baojing:addEffect(fk.EventPhaseStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark(baojing.name) ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local info = player:getMark(baojing.name)
    room:setPlayerMark(player, baojing.name, 0)
    local to = room:getPlayerById(info[1])
    if not to.dead then
      local mark = info[2] == "+1" and "@baojing_add" or "@baojing_minus"
      room:removePlayerMark(to, mark, 1)
    end
  end,
})
baojing:addEffect("atkrange", {
  correct_func = function (self, from, to)
    return from:getMark("@baojing_add") - from:getMark("@baojing_minus")
  end,
})

return baojing
