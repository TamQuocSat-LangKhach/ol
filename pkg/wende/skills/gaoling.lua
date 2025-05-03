local gaoling = fk.CreateSkill{
  name = "gaoling",
  tags = { Skill.Hidden },
}

Fk:loadTranslationTable{
  ["gaoling"] = "高陵",
  [":gaoling"] = "隐匿技，当你于其他角色的回合内登场时，你可以令一名角色回复1点体力。",

  ["#gaoling-choose"] = "高陵：你可以令一名角色回复1点体力",

  ["$gaoling1"] = "天家贵胄，福泽四海。",
  ["$gaoling2"] = "宣王之女，恩惠八方。",
}

local U = require "packages/utility/utility"

gaoling:addEffect(U.GeneralAppeared, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasShownSkill(gaoling.name) then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      return turn_event.data.who ~= player and
        table.find(player.room.alive_players, function (p)
          return p:isWounded()
        end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p:isWounded()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = gaoling.name,
      prompt = "#gaoling-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover {
      num = 1,
      skillName = gaoling.name,
      who = event:getCostData(self).tos[1],
      recoverBy = player,
    }
  end,
})

return gaoling
