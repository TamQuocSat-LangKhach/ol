local chuming = fk.CreateSkill{
  name = "chuming",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["chuming"] = "畜鸣",
  [":chuming"] = "锁定技，当你对其他角色造成伤害或受到其他角色造成的伤害时，若此伤害：没有对应的实体牌，此伤害+1；有对应的实体牌，"..
  "其本回合结束时将造成伤害的牌当【借刀杀人】或【过河拆桥】对你使用。",

  ["#chuming-invoke"] = "畜鸣：选择对 %dest 使用的牌",

  ["$chuming1"] = "明公为何如此待我兄弟？",
  ["$chuming2"] = "栖佳木之良禽，其鸣亦哀乎？",
}

chuming:addEffect(fk.DamageCaused, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(chuming.name) and data.to ~= player
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if not data.card or #Card:getIdList(data.card) == 0 then
      player:broadcastSkillInvoke(chuming.name, 2)
      room:notifySkillInvoked(player, chuming.name, "offensive")
      data:changeDamage(1)
    else
      player:broadcastSkillInvoke(chuming.name)
      room:notifySkillInvoked(player, chuming.name, "negative")
      room:addTableMark(player, "chuming-turn", {data.to.id, Card:getIdList(data.card)})
    end
  end,
})

chuming:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(chuming.name) and data.from and data.from ~= player
  end,
  on_use = function (self, event, target, player, data)
    if not data.card or #Card:getIdList(data.card) == 0 then
      data:changeDamage(1)
    else
      player.room:addTableMark(player, "chuming-turn", {data.from.id, Card:getIdList(data.card)})
    end
  end,
})

chuming:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return player:getMark("chuming-turn") ~= 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local infos = table.simpleClone(player:getMark("chuming-turn"))
    for _, info in ipairs(infos) do
      if player.dead then return end
      local from = room:getPlayerById(info[1])
      if not from.dead and table.every(info[2], function(id)
        return room:getCardArea(id) == Card.DiscardPile
      end) then
        room:askToUseVirtualCard(from, {
          name = {"dismantlement", "collateral"},
          skill_name = chuming.name,
          prompt = "#chuming-invoke::"..player.id,
          cancelable = false,
          extra_data = {
            exclusive_targets = {player.id},
          },
          subcards = info[2],
        })
      end
    end
  end,
})

return chuming
