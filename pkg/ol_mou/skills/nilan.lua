local nilan = fk.CreateSkill{
  name = "nilan",
}

Fk:loadTranslationTable{
  ["nilan"] = "逆澜",
  [":nilan"] = "当你不因此技能造成伤害后，你可以执行一项：1.弃置所有手牌，若其中有【杀】，则你可以对一名其他角色造成1点伤害；2.摸两张牌。"..
  "若如此做，你下一次受到伤害后可以执行另一项。",

  ["#nilan-choice"] = "逆澜：你可以执行一项，下次受到伤害后可以执行另一项",
  ["nilan_discard"] = "弃置所有手牌，若其中有【杀】，可以对一名角色造成1点伤害",
  ["#nilan-damage"] = "逆澜：你可以对一名其他角色造成1点伤害",
  ["#nilan-invoke"] = "逆澜：是否%arg",
}

nilan:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(nilan.name) and data.skillName ~= nilan.name
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"draw2", "Cancel"}
    if table.find(player:getCardIds("h"), function (id)
      return not player:prohibitDiscard(id)
    end) then
      table.insert(choices, 1, "nilan_discard")
    end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = nilan.name,
      prompt = "#nilan-choice",
      all_choices = {"nilan_discard", "draw2", "Cancel"},
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self)
    if not (dat and dat.extra_data and dat.nilan_delay) then
      if dat.choice == "nilan_discard" then
        room:addTableMark(player, nilan.name, "draw2")
      else
        room:addTableMark(player, nilan.name, "nilan_discard")
      end
    end
    if dat.choice == "nilan_discard" then
      local yes = table.find(player:getCardIds("h"), function (id)
        return not player:prohibitDiscard(id) and Fk:getCardById(id).trueName == "slash"
      end)
      player:throwAllCards("h", nilan.name)
      if not player.dead and yes and #room:getOtherPlayers(player, false) > 0 then
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = room:getOtherPlayers(player, false),
          skill_name = nilan.name,
          prompt = "#nilan-damage",
          cancelable = true,
        })
        if #to > 0 then
          room:damage{
            from = player,
            to = to[1],
            damage = 1,
            skillName = nilan.name,
          }
        end
      end
    else
      player:drawCards(2, nilan.name)
    end
  end,
})
nilan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(nilan.name) and player:getMark(nilan.name) ~= 0
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local choices = player:getTableMark(nilan.name)
    room:setPlayerMark(player, nilan.name, 0)
    for _, choice in ipairs(choices) do
      if player.dead then return end
      if choice == "draw2" or
        table.find(player:getCardIds("h"), function (id)
          return not player:prohibitDiscard(id)
        end) then
        event:setCostData(self, {choice = choice})
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = nilan.name,
      prompt = "#nilan-invoke:::"..event:getCostData(self).choice,
    })
  end,
  on_use = function (self, event, target, player, data)
    local skill = Fk.skills["nilan"]
    event:setCostData(skill, {choice = event:getCostData(self).choice, extra_data = {nilan_delay = true}})
    skill:use(event, player, player, data)
  end,
})

return nilan
