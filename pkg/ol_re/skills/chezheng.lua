local chezheng = fk.CreateSkill{
  name = "ol__chezheng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__chezheng"] = "掣政",
  [":ol__chezheng"] = "锁定技，你于你的出牌阶段内对攻击范围内不包含你的其他角色造成伤害时，防止之。出牌阶段结束时，若你本阶段使用的牌数小于"..
  "这些角色数，你弃置其中一名角色一张牌。",

  ["#ol__chezheng-choose"] = "掣政：选择攻击范围内不包含你的一名角色，弃置其一张牌",

  ["$ol__chezheng1"] = "朕倒要看看，这大吴是谁的江山！",
  ["$ol__chezheng2"] = "只要朕还在，老贼休想稳坐一天！",
}

chezheng:addEffect(fk.DamageCaused, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(chezheng.name) and player.phase == Player.Play and
      data.to ~= player and not data.to:inMyAttackRange(player)
  end,
  on_use = function (self, event, target, player, data)
    data:preventDamage()
  end,
})
chezheng:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(chezheng.name) and player.phase == Player.Play then
      local targets = table.filter(player.room:getOtherPlayers(player, false), function(p)
        return not p:inMyAttackRange(player)
      end)
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function (e)
        local use = e.data
        return use.from == player
      end, Player.HistoryPhase)
      return #events < #targets
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:inMyAttackRange(player) and not p:isNude()
    end)
    if #targets > 0 then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = chezheng.name,
        prompt = "#ol__chezheng-choose",
        cancelable = false,
      })[1]
      local card = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = chezheng.name,
      })
      room:throwCard(card, chezheng.name, to, player)
    end
  end,
})

return chezheng
