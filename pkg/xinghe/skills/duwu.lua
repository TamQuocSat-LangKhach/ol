local duwu = fk.CreateSkill{
  name = "duwu",
}

Fk:loadTranslationTable{
  ["duwu"] = "黩武",
  [":duwu"] = "出牌阶段，你可以弃置X张牌，对你攻击范围内的一名其他角色造成1点伤害（X为该角色的体力值）。"..
  "若其因此进入濒死状态且被救回，则濒死状态结算后你失去1点体力，且本回合不能再发动〖黩武〗。",

  ["#duwu"] = "黩武：弃置一名角色体力值张数的牌，对其造成1点伤害",

  ["$duwu1"] = "破曹大功，正在今朝！",
  ["$duwu2"] = "全力攻城！言退者，斩！",
}

duwu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#duwu",
  target_num = 1,
  can_use = Util.TrueFunc,
  card_filter = function(self, player, to_select)
    return not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= player and to_select.hp > 0 then
      if to_select.hp == #selected_cards then
        --FIXME: 飞刀、飞坐骑
        if table.contains(selected_cards, player:getEquipment(Card.SubtypeWeapon)) then
          return player:distanceTo(to_select) == 1
        else
          return player:inMyAttackRange(to_select)
        end
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, duwu.name, player, player)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = duwu.name,
      }
    end
  end,
})
duwu:addEffect(fk.AfterDying, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.duwu and data.extra_data.duwu == player and not target.dead and not player.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:invalidateSkill(player, duwu.name, "-turn")
    room:loseHp(player, 1, duwu.name)
  end,
})
duwu:addEffect(fk.EnterDying, {
  can_refresh = function(self, event, target, player, data)
    return data.damage and data.damage.skillName == duwu.name and data.damage.from == player
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.duwu = player
  end,
})

return duwu
