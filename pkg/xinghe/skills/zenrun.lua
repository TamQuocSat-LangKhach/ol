local zenrun = fk.CreateSkill{
  name = "zenrun",
}

Fk:loadTranslationTable{
  ["zenrun"] = "谮润",
  [":zenrun"] = "每阶段限一次，当你摸牌时，你可以改为获得一名其他角色等量张牌，然后其选择一项："..
  "1.摸等量的牌；2.本局游戏中你发动〖险诐〗和〖谮润〗不能指定其为目标。",

  ["#zenrun-choose"] = "谮润：你可以将摸牌改为获得一名其他角色%arg张牌，然后其选择摸等量牌或你本局不能对其发动技能",
  ["#zenrun-choice"] = "谮润：选择 %src 令你执行的一项",
  ["zenrun_draw"] = "你摸%arg张牌",
  ["zenrun_forbid"] = "%src本局不能对你发动“险诐”和“谮润”",

  ["$zenrun1"] = "据图谋不轨，今奉诏索命。",
  ["$zenrun2"] = "休妄论芍陂之战，当诛之。",
}

zenrun:addEffect(fk.BeforeDrawCard, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zenrun.name) and
      player:usedSkillTimes(zenrun.name, Player.HistoryPhase) == 0 and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not table.contains(player:getTableMark(zenrun.name), p.id) and #p:getCardIds("he") >= data.num
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not table.contains(player:getTableMark(zenrun.name), p.id) and #p:getCardIds("he") >= data.num
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = zenrun.name,
      prompt = "#zenrun-choose:::"..data.num,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n = data.num
    data.num = 0
    local cards = room:askToChooseCards(player, {
      target = to,
      min = n,
      max = n,
      flag = "he",
      skill_name = zenrun.name,
    })
    room:obtainCard(player, cards, false, fk.ReasonPrey, player, zenrun.name)
    if to.dead then return end
    local choice = room:askToChoice(player, {
      choices = {"zenrun_draw:::"..n, "zenrun_forbid:"..player.id},
      skill_name = zenrun.name,
      prompt = "#zenrun-choice:"..player.id,
    })
    if choice:startsWith("zenrun_draw") then
      to:drawCards(n, zenrun.name)
    elseif not player.dead then
      room:addTableMark(player, zenrun.name, to.id)
    end
  end,
})

return zenrun
