local linjie = fk.CreateSkill{
  name = "linjie",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["linjie"] = "临节",
  [":linjie"] = "锁定技，当你受到伤害后，伤害来源须弃置一张手牌，若为【杀】，你摸一张牌。",

  ["$linjie1"] = "",
  ["$linjie2"] = "",
}

linjie:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(linjie.name) and
      data.from and not data.from.dead and not data.from:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {data.from}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(data.from, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = linjie.name,
      cancelable = false,
    })
    if #card > 0 and Fk:getCardById(card[1]).trueName == "slash" and not player.dead then
      player:drawCards(1, linjie.name)
    end
  end,
})

return linjie
