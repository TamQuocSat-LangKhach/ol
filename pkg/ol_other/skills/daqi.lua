local daqi = fk.CreateSkill{
  name = "qin__daqi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__daqi"] = "大期",
  [":qin__daqi"] = "锁定技，每当你使用或打出牌、造成或受到1点伤害后，你获得一个“期”标记；回合开始时，若你拥有的“期”标记数不小于10，"..
  "你弃置所有“期”标记，然后将体力回复至体力上限、将手牌摸至体力上限。",

  ["@qin__daqi"] = "期",

  ["$qin__daqi"] = "大期之时，福运轮转。",
}

daqi:addEffect(fk.TurnStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(daqi.name) and player:getMark("@qin__daqi") > 9
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@qin__daqi", 0)
    if player:isWounded() then
      room:recover{
        who = player,
        num = player.maxHp - player.hp,
        recoverBy = player,
        skillName = daqi.name
      }
    end
    if player:getHandcardNum() < player.maxHp and not player.dead then
      player:drawCards(player.maxHp - player:getHandcardNum(), daqi.name)
    end
  end,
})
local daqi_spec = {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(daqi.name)
  end,
  on_use = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@qin__daqi", 1)
  end,
}
daqi:addEffect(fk.CardUsing, daqi_spec)
daqi:addEffect(fk.CardResponding, daqi_spec)
daqi:addEffect(fk.Damage, {
  trigger_times = function (self, event, target, player, data)
    return data.damage
  end,
  can_trigger = daqi_spec.can_trigger,
  on_use = daqi_spec.on_use,
})
daqi:addEffect(fk.Damaged, {
  trigger_times = function (self, event, target, player, data)
    return data.damage
  end,
  can_trigger = daqi_spec.can_trigger,
  on_use = daqi_spec.on_use,
})

return daqi
