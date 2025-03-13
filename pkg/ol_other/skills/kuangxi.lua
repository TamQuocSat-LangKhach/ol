local kuangxi = fk.CreateSkill{
  name = "kuangxi",
}

Fk:loadTranslationTable{
  ["kuangxi"] = "狂袭",
  [":kuangxi"] = "出牌阶段，你可以失去1点体力，对一名其他角色造成1点伤害。若该角色因此进入濒死状态，此技能本回合失效。",

  ["#kuangxi"] = "狂袭：失去1点体力，对一名其他角色造成1点伤害！",
}

kuangxi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#kuangxi",
  card_num = 0,
  target_num = 1,
  can_use = Util.TrueFunc,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:loseHp(player, 1, kuangxi.name)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = kuangxi.name,
      }
    end
  end,
})
kuangxi:addEffect(fk.EnterDying, {
  can_refresh = function(self, event, target, player, data)
    return data.damage and data.damage.skillName == kuangxi.name and
      data.damage.from == player and not player.dead
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:invalidateSkill(player, kuangxi.name, "-turn")
  end,
})

return kuangxi
