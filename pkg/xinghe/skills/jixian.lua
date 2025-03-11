local jixian = fk.CreateSkill{
  name = "jixian",
}

Fk:loadTranslationTable{
  ["jixian"] = "急陷",
  [":jixian"] = "摸牌阶段结束时，你可以视为对符合以下任意条件的一名其他角色使用一张【杀】并摸X张牌（X为其符合的条件数）："..
  "1.装备区里有防具牌；2.技能数多于你；3.未受伤。然后若此【杀】未造成伤害，你失去1点体力。",

  ["#jixian-choose"] = "急陷：你可以视为使用【杀】并摸牌，若未造成伤害则失去1点体力",
  ["#jixian_tip"] = "摸%arg张牌",

  ["$jixian1"] = "全军出击，速攻敌城。",
  ["$jixian2"] = "勿以我为念，攻城！",
}

jixian:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jixian.name) and player.phase == Player.Draw and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not player:isProhibited(p, Fk:cloneCard("slash")) and
          (#p:getEquipments(Card.SubtypeArmor) > 0 or
          #p:getSkillNameList() > #player:getSkillNameList() or
          not p:isWounded())
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not player:isProhibited(p, Fk:cloneCard("slash")) and
        (#p:getEquipments(Card.SubtypeArmor) > 0 or
        #p:getSkillNameList() > #player:getSkillNameList() or
        not p:isWounded())
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = jixian.name,
      prompt = "#jixian-choose",
      cancelable = true,
      target_tip_name = jixian.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    local to = event:getCostData(self).tos[1]
    if #to:getEquipments(Card.SubtypeArmor) > 0 then
      n = n + 1
    end
    if #to:getSkillNameList() > #player:getSkillNameList() then
      n = n + 1
    end
    if not to:isWounded() then
      n = n + 1
    end
    local use = room:useVirtualCard("slash", nil, player, to, jixian.name, true)
    if not use or player.dead then return end
    player:drawCards(n, jixian.name)
    if not (player.dead or use.damageDealt) then
      room:loseHp(player, 1, jixian.name)
    end
  end,
})
Fk:addTargetTip{
  name = "jixian",
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable)
    if not selectable then return end
    local n = 0
    if #to_select:getEquipments(Card.SubtypeArmor) > 0 then
      n = n + 1
    end
    if #to_select:getSkillNameList() > #player:getSkillNameList() then
      n = n + 1
    end
    if not to_select:isWounded() then
      n = n + 1
    end
    return "#jixian_tip:::"..n
  end,
}

return jixian
