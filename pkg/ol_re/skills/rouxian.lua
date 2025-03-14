local rouxian = fk.CreateSkill{
  name = "ol__rouxian",
}

Fk:loadTranslationTable{
  ["ol__rouxian"] = "柔弦",
  [":ol__rouxian"] = "当你受到伤害后，若没有角色处于濒死状态，你可以令伤害来源回复1点体力并弃置一张装备牌。",

  ["#ol__rouxian-invoke"] = "柔弦：你可以令 %dest 回复1点体力并弃置一张装备",

  ["$ol__rouxian"] = "稍安勿躁，请先听我一曲。",
}

rouxian:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(rouxian.name) and
      data.from and not data.from.dead and
      not table.find(player.room.alive_players, function(p)
        return p.dying
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = rouxian.name,
      prompt = "#ol__rouxian-invoke::"..data.from.id,
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if data.from:isWounded() then
      room:recover{
        who = data.from,
        num = 1,
        recoverBy = player,
        skillName = rouxian.name,
      }
    end
    if not data.from.dead and not data.from:isNude() then
      room:askToDiscard(data.from, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = rouxian.name,
        cancelable = false,
        pattern = ".|.|.|.|.|equip",
      })
    end
  end,
})

return rouxian
