local daojie = fk.CreateSkill{
  name = "daojie",
  tags = { Skill.Family, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["daojie"] = "蹈节",
  [":daojie"] = "宗族技，锁定技，当你每回合首次使用非伤害类普通锦囊牌后，你选择一项：1.失去1点体力；2.失去一个锁定技。然后令一名同族角色获得此牌。",

  ["#daojie-choice"] = "蹈节：选择失去一个锁定技，或失去1点体力",
  ["#daojie-choose"] = "蹈节：令一名同族角色获得此%arg",
}

local U = require "packages/utility/utility"

daojie:addEffect(fk.CardUseFinished, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(daojie.name) then return false end
    if not data.card:isCommonTrick() or data.card.is_damage_card then return false end
    local room = player.room
    local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
    if #cardlist == 0 or not table.every(cardlist, function (id)
      return room:getCardArea(id) == Card.Processing
    end) then return false end
    local logic = room.logic
    local use_event = logic:getCurrentEvent()
    local mark_name = "daojie_record-turn"
    local mark = player:getMark(mark_name)
    if mark == 0 then
      logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local last_use = e.data
        if last_use.from == player and last_use.card:isCommonTrick() and not last_use.card.is_damage_card then
          mark = e.id
          room:setPlayerMark(player, mark_name, mark)
          return true
        end
        return false
      end, Player.HistoryTurn)
    end
    return mark == use_event.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = table.filter(player:getSkillNameList(), function (s)
      return Fk.skills[s]:hasTag(Skill.Compulsory, false)
    end)
    table.insert(skills, "loseHp")
    local choice = room:askToChoice(player, {
      choices = skills,
      skill_name = daojie.name,
      prompt = "#daojie-choice",
      detailed = true,
    })
    if choice == "loseHp" then
      room:loseHp(player, 1, daojie.name)
    else
      room:handleAddLoseSkills(player, "-"..choice)
    end
    if not player.dead and table.every(Card:getIdList(data.card), function (id)
      return room:getCardArea(id) == Card.Processing
    end) then
      local targets = table.filter(room.alive_players, function (p)
        return U.FamilyMember(player, p)
      end)
      if #targets > 1 then
        targets = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = daojie.name,
          prompt = "#daojie-choose:::"..data.card:toLogString(),
          cancelable = false,
        })
      end
      room:obtainCard(targets[1], data.card, true, fk.ReasonPrey, player, daojie.name)
    end
  end,
})

return daojie
