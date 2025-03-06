local xuehen = fk.CreateSkill{
  name = "ol__xuehen",
}

Fk:loadTranslationTable{
  ["ol__xuehen"] = "雪恨",
  [":ol__xuehen"] = "出牌阶段限一次，你可以弃置一张红色牌并选择至多X名角色（X为你已损失的体力值且至少为1），你横置这些角色，"..
  "然后对其中一名角色造成1点火焰伤害。",

  ["#ol__xuehen"] = "雪恨：弃置一张红色牌并选择至多%arg名角色，横置这些角色，然后对其中一名角色造成1点火焰伤害",
  ["#ol__xuehen-choose"] = "雪恨：对其中一名角色造成1点火焰伤害",

  ["$ol__xuehen1"] = "就用你的性命，一雪前耻。",
  ["$ol__xuehen2"] = "雪耻旧恨，今日清算。",
}

xuehen:addEffect("active", {
  anim_type = "offensive",
  prompt = function (self, player)
    return "#ol__xuehen:::"..math.max(1, player:getLostHp())
  end,
  card_num = 1,
  min_target_num = 1,
  max_target_num = function (self, player)
    return math.max(1, player:getLostHp())
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(xuehen.name, Player.HistoryTurn) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected < math.max(1, player:getLostHp())
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = table.simpleClone(effect.tos)
    room:sortByAction(targets)
    room:throwCard(effect.cards, xuehen.name, player, player)
    for _, p in ipairs(targets) do
      if not p.dead and not p.chained then
        p:setChainState(true)
      end
    end
    targets = table.filter(targets, function(p)
      return not p.dead
    end)
    if #targets == 0 or player.dead then return end
    local to = targets[1]
    if #targets > 1 then
      to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = xuehen.name,
        prompt = "#ol__xuehen-choose",
        cancelable = false,
      })[1]
    end
    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = xuehen.name,
      damageType = fk.FireDamage,
    }
  end,
})

return xuehen
