local yinhu = fk.CreateSkill{
  name = "shengxiao_yinhu",
}

Fk:loadTranslationTable{
  ["shengxiao_yinhu"] = "寅虎",
  [":shengxiao_yinhu"] = "出牌阶段，你可以弃置一张牌（需与你以此法弃置过的类别均不同），对一名其他角色造成1点伤害；若以此法造成伤害使一名角色"..
  "进入濒死状态，则此技能失效直到回合结束。",

  ["#shengxiao_yinhu"] = "寅虎：弃置一张牌（需与弃置过的类别不同），对一名角色造成1点伤害",
}

yinhu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#shengxiao_yinhu",
  card_num = 1,
  target_num = 1,
  can_use = Util.TrueFunc,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not table.contains(player:getTableMark(yinhu.name), Fk:getCardById(to_select).type) and
      not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, yinhu.name, Fk:getCardById(effect.cards[1]).type)
    room:throwCard(effect.cards, yinhu.name, player)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = yinhu.name,
      }
    end
  end,
})
yinhu:addEffect(fk.EnterDying, {
  can_refresh = function(self, event, target, player, data)
    return data.damage and data.damage.skillName == "shengxiao_yinhu" and
      data.damage.from == player and not player.dead
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:invalidateSkill(player, "shengxiao_yinhu", "-turn")
  end,
})

return yinhu
