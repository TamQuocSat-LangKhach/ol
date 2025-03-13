local mojun = fk.CreateSkill{
  name = "mojun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mojun"] = "魔军",
  [":mojun"] = "锁定技，当友方角色使用【杀】造成伤害后，你判定，若结果为黑色，友方角色各摸一张牌。",
}

local U = require "packages/utility/utility"

mojun:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mojun.name) and data.from and
      table.contains(U.GetFriends(player.room, player, true, true), data.from) and
      data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = mojun.name,
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge:matchPattern() then
      room:doIndicate(player, U.GetFriends(room, player))
      for _, p in ipairs(U.GetFriends(room, player)) do
        if not p.dead then
          p:drawCards(1, mojun.name)
        end
      end
    end
  end,
})

return mojun
