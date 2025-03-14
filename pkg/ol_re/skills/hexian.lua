local hexian = fk.CreateSkill{
  name = "ol__hexian",
}

Fk:loadTranslationTable{
  ["ol__hexian"] = "和弦",
  [":ol__hexian"] = "当你回复体力后，若没有角色处于濒死状态，你可以令一名其他角色回复1点体力并弃置一张装备牌。",

  ["#ol__hexian-choose"] = "和弦：你可以令一名角色回复1点体力并弃置一张装备",

  ["$ol__hexian"] = "和声悦悦，琴音悠悠。",
}

hexian:addEffect(fk.HpRecover, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hexian.name) and
      not table.find(player.room.alive_players, function(p)
        return p.dying
      end) and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = hexian.name,
      prompt = "#ol__hexian-choose",
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
    if to:isWounded() then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = hexian.name,
      }
    end
    if not to.dead and not to:isNude() then
      room:askToDiscard(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = hexian.name,
        cancelable = false,
        pattern = ".|.|.|.|.|equip",
      })
    end
  end,
})

return hexian
