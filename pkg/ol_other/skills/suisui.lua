local suisui = fk.CreateSkill{
  name = "suisui",
}

Fk:loadTranslationTable{
  ["suisui"] = "岁祟",
  [":suisui"] = "游戏开始时，所有角色抢拼手气红包。手气最好的角色从三个生肖兽祝福中选择一个令你获得。准备阶段，你可以消耗10个欢乐豆"..
  "重新发一次拼手气红包（每局限三次）。",

  ["#suisui-invoke"] = "岁祟：是否重新发红包？（还能重发%arg次）",
  ["$lucky_money"] = "%from 获得红包 %arg 欢乐豆",
  ["#suisui-choice"] = "岁祟：选择 %src 获得的生肖兽祝福",
}

local spec = {
  on_use = function (self, event, target, player, data)
    local room = player.room
    if player:getMark("suisui_skill") ~= 0 then
      room:handleAddLoseSkills(player, "-"..player:getMark("suisui_skill"))
      room:setPlayerMark(player, "suisui_skill", 0)
    end
    local to = table.random(room.alive_players)
    for _, p in ipairs(room:getAlivePlayers()) do
      if p == to then
        room:sendLog{
          type = "$lucky_money",
          from = p.id,
          arg = #room.alive_players + math.random(5),
          toast = true,
        }
      else
        room:sendLog{
          type = "$lucky_money",
          from = p.id,
          arg = math.random(#room.alive_players),
          toast = true,
        }
      end
    end
    local shengxiao_skills = {
      "shengxiao_zishu", "shengxiao_chouniu", "shengxiao_yinhu", "shengxiao_maotu",
      "shengxiao_chenlong", "shengxiao_sishe", "shengxiao_wuma", "shengxiao_weiyang",
      "shengxiao_shenhou", "shengxiao_youji", "shengxiao_xugou", "shengxiao_haizhu"
    }
    local skill = room:askToChoice(to, {
      choices = table.random(shengxiao_skills, 3),
      skill_name = suisui.name,
      prompt = "#suisui-choice:"..player.id,
      detailed = true,
    })
    room:setPlayerMark(player, "suisui_skill", skill)
    room:handleAddLoseSkills(player, skill)
  end,
}

suisui:addEffect(fk.GameStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(suisui.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = spec.on_use,
})
suisui:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(suisui.name) and player.phase == Player.Start and
      player:usedEffectTimes(self.name, Player.HistoryGame) < 3
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = suisui.name,
      prompt = "#suisui-invoke:::"..(3 - player:usedEffectTimes(self.name, Player.HistoryGame)),
    })
  end,
  on_use = spec.on_use,
})

return suisui
