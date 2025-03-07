local bizheng = fk.CreateSkill{
  name = "bizheng",
}

Fk:loadTranslationTable{
  ["bizheng"] = "弼政",
  [":bizheng"] = "摸牌阶段结束时，你可令一名其他角色摸两张牌，然后你与其之中，手牌数大于体力上限的角色弃置两张牌。",

  ["#bizheng-choose"] = "弼政：令一名其他角色摸两张牌，然后你与其手牌数大于体力上限的角色弃两张牌",

  ["$bizheng1"] = "弼亮四世，正色率下。",
  ["$bizheng2"] = "弼佐辅君，国事政法。",
}

bizheng:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bizheng.name) and player.phase == Player.Draw and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = player.room:getOtherPlayers(player, false),
      skill_name = bizheng.name,
      prompt = "#bizheng-choose",
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
    to:drawCards(2, bizheng.name)
    if not player.dead and player:getHandcardNum() > player.maxHp then
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = bizheng.name,
        cancelable = false,
      })
    end
    if not to.dead and to:getHandcardNum() > to.maxHp then
      room:askToDiscard(to, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = bizheng.name,
        cancelable = false,
      })
    end
  end,
})

return bizheng
