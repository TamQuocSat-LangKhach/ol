local jianhui = fk.CreateSkill{
  name = "jianhui",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jianhui"] = "奸回",
  [":jianhui"] = "锁定技，你记录上次对你造成伤害的角色。当你对其造成伤害后，你摸一张牌；当你受到其造成的伤害后，其弃置一张牌。",

  ["@jianhui"] = "奸回",

  ["$jianhui1"] = "一箭之仇，十年不忘！",
  ["$jianhui2"] = "此仇不报，怨恨难消！",
}

jianhui:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data
      if damage.to == player and damage.from then
        room:setPlayerMark(player, jianhui.name, damage.from.id)
        room:setPlayerMark(player, "@jianhui", damage.from.general)
        return true
      end
    end, 1)
  end
end)

jianhui:addEffect(fk.DamageFinished, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(jianhui.name, true) and data.from
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, jianhui.name, data.from.id)
    player.room:setPlayerMark(player, "@jianhui", data.from.general)
  end,
})

jianhui:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianhui.name) and player:getMark(jianhui.name) == data.to.id
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, jianhui.name)
  end,
})

jianhui:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianhui.name) and
      data.from and player:getMark(jianhui.name) == data.from.id and not data.from.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player, {data.from})
    room:askToDiscard(data.from, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = jianhui.name,
      cancelable = false,
    })
  end,
})

return jianhui
