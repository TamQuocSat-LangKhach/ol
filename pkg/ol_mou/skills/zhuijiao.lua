local zhuijiao = fk.CreateSkill{
  name = "zhuijiao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhuijiao"] = "追剿",
  [":zhuijiao"] = "锁定技，你使用【杀】时，若你使用的上一张牌未造成伤害，则你摸一张牌并令此【杀】伤害+1，此【杀】结算后，若仍未造成伤害，"..
  "你弃置一张牌。",

  ["$zhuijiao1"] = "曹阿瞒，这次看你往哪里逃！",
  ["$zhuijiao2"] = "我倒要看看，你曹孟德有几个儿子！",
}

zhuijiao:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhuijiao.name) and data.card.trueName == "slash" then
      local dat = nil
      player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        if e.id ~= player.room.logic:getCurrentEvent().id then
          local use = e.data
          if use.from == player then
            dat = use
            return true
          end
        end
      end, 1)
      return dat and not dat.damageDealt
    end
  end,
  on_use = function (self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
    data.extra_data = data.extra_data or {}
    data.extra_data.zhuijiao = true
    player:drawCards(1, zhuijiao.name)
  end,
})
zhuijiao:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not data.damageDealt and data.extra_data and data.extra_data.zhuijiao and
      not player.dead and not player:isNude()
  end,
  on_use = function (self, event, target, player, data)
    player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = zhuijiao.name,
      cancelable = false,
    })
  end,
})

return zhuijiao
