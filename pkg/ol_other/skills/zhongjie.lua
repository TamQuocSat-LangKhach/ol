local zhongjie = fk.CreateSkill{
  name = "zhongjiex",
}

Fk:loadTranslationTable{
  ["zhongjiex"] = "忠节",
  [":zhongjiex"] = "你死亡时，你可以令一名其他角色加1点体力上限，回复1点体力，摸一张牌。",

  ["#zhongjiex-choose"] = "忠节：你可以令一名角色加1点体力上限，回复1点体力，摸一张牌",

  ["$zhongjiex1"] = "义士有忠节，可杀不可量！",
  ["$zhongjiex2"] = "愿以骨血为饲，事汝君临天下。",
}

zhongjie:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhongjie.name, false, true) and
      #player.room.alive_players > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = zhongjie.name,
      prompt = "#zhongjiex-choose",
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
    room:changeMaxHp(to, 1)
    if not to.dead and to:isWounded() then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = zhongjie.name,
      }
    end
    if not to.dead then
      to:drawCards(1, zhongjie.name)
    end
  end,
})

return zhongjie
