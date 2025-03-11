local fengji = fk.CreateSkill{
  name = "fengji",
}

Fk:loadTranslationTable{
  ["fengji"] = "丰积",
  [":fengji"] = "每轮开始时，你可以令你本轮以下任意项数值-1，令一名其他角色本轮对应项数值+2，令你本轮未选择选项的数值+1：<br>"..
  "1.摸牌阶段摸牌数；2.出牌阶段使用【杀】次数上限。",

  ["#fengji-choice"] = "丰积：令你本轮-1，令一名其他角色本轮+2，令你本轮未选择的+1",
  ["fengji_draw"] = "摸牌阶段摸牌数",
  ["fengji_slash"] = "出牌阶段使用【杀】次数",
  ["@fengji_draw-round"] = "丰积:摸牌",
  ["@fengji_slash-round"] = "丰积:使用杀",
  ["#fengji-choose"] = "丰积：你可以令一名其他角色本轮%arg+2",

  ["$fengji1"] = "取舍有道，待机而赢。",
  ["$fengji2"] = "此退彼进，月亏待盈。",
}

fengji:addEffect(fk.RoundStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fengji.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"fengji_draw", "fengji_slash", "Cancel"}
    while true do
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = fengji.name,
        prompt = "#fengji-choice",
      })
      table.removeOne(choices, choice)
      if choice == "Cancel" then
        break
      else
        room:setPlayerMark(player, "@"..choice.."-round", -1)
        if #room:getOtherPlayers(player, false) > 0 then
          local to = room:askToChoosePlayers(player, {
            min_num = 1,
            max_num = 1,
            targets = room:getOtherPlayers(player, false),
            skill_name = fengji.name,
            prompt = "#fengji-choose:::"..choice,
            cancelable = true,
          })
          if #to > 0 then
            room:addPlayerMark(to[1], "@"..choice.."-round", 2)
          end
        end
      end
    end
    if #choices > 0 then
      for _, choice in ipairs(choices) do
        room:addPlayerMark(player, "@"..choice.."-round", 1)
      end
    end
  end,
})
fengji:addEffect(fk.DrawNCards, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@fengji_draw-round") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@fengji_draw-round")
  end,
})
fengji:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@fengji_slash-round") ~= 0 and scope == Player.HistoryPhase then
      return player:getMark("@fengji_slash-round")
    end
  end,
})

return fengji
