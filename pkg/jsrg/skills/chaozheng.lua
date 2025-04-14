local chaozheng = fk.CreateSkill {
  name = "ol__chaozheng",
}

Fk:loadTranslationTable{
  ["ol__chaozheng"] = "朝争",
  [":ol__chaozheng"] = "准备阶段，你可以与所有其他角色议事，结果为：红色，意见为红色的角色各回复1点体力；黑色，意见为红色的其他角色"..
  "各失去1点体力。议事结束后，你摸X张牌（X为意见与你相同的角色数，至多为2）。你参与议事的意见视为+1。",

  ["#ol__chaozheng-invoke"] = "朝争：你可以与所有其他角色议事！",

  ["$ol__chaozheng1"] = "",
  ["$ol__chaozheng2"] = "",
}

local U = require "packages/utility/utility"

chaozheng:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chaozheng.name) and player.phase == Player.Start and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = chaozheng.name,
      prompt = "#ol__chaozheng-invoke",
    }) then
      local tos = table.filter(room:getOtherPlayers(player, false), function(p)
        return not p:isKongcheng()
      end)
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos
    table.insert(targets, player)
    local discussion = U.Discussion(player, targets, chaozheng.name)
    if discussion.color == "red" then
      for _, p in ipairs(targets) do
        if p:isWounded() and not p.dead and discussion.results[p].opinion == "red" then
          room:recover{
            who = p,
            num = 1,
            recoverBy = player,
            skillName = chaozheng.name,
          }
        end
      end
    elseif discussion.color == "black" then
      for _, p in ipairs(targets) do
        if p ~= player and not p.dead and discussion.results[p].opinion == "red" then
          room:loseHp(p, 1, chaozheng.name)
        end
      end
    end
    if not player.dead then
      local n = 0
      for _, p in ipairs(targets) do
        if discussion.results[p].opinion == discussion.results[player].opinion then
          n = n + 1
        end
      end
      player:drawCards(n, chaozheng.name)
    end
  end,
})

chaozheng:addEffect(U.DiscussionResultConfirming, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(chaozheng.name) and table.contains(data.tos, player) and
      data.results[player].opinion
  end,
  on_refresh = function (self, event, target, player, data)
    local opinion = data.results[player].opinion
    data.opinions[opinion] = (data.opinions[opinion] or 0) + 1
  end,
})

return chaozheng
