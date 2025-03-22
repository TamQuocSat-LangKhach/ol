local muyin = fk.CreateSkill{
  name = "muyin",
  tags = { Skill.Family },
}

Fk:loadTranslationTable{
  ["muyin"] = "穆荫",
  [":muyin"] = "宗族技，回合开始时，你可以令一名手牌上限不为全场最大的同族角色手牌上限+1。",

  ["#muyin-choose"] = "穆荫：你可以令一名同族角色手牌上限+1",
}

local U = require "packages/utility/utility"

muyin:addEffect(fk.TurnStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(muyin.name) and
      table.find(player.room.alive_players, function(p)
        return U.FamilyMember(player, p) and
          not table.every(player.room.alive_players, function (q)
            return p:getMaxCards() >= q:getMaxCards()
          end)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return U.FamilyMember(player, p) and
        not table.every(player.room.alive_players, function (q)
          return p:getMaxCards() >= q:getMaxCards()
        end)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = muyin.name,
      prompt = "#muyin-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(event:getCostData(self).tos[1], MarkEnum.AddMaxCards, 1)
  end,
})

return muyin
