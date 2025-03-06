local renxia = fk.CreateSkill{
  name = "renxia",
}

Fk:loadTranslationTable{
  ["renxia"] = "任侠",
  [":renxia"] = "出牌阶段限一次，你可以执行一项，然后本阶段结束时执行另一项：1.弃置两张牌，重复此流程，直到手牌中没有【杀】或伤害锦囊牌；"..
  "2.摸两张牌，重复此流程，直到手牌中有【杀】或伤害锦囊牌。",

  ["#renxia1"] = "任侠：弃两张牌，重复直到手牌中没有伤害牌，本阶段结束时执行另一项",
  ["#renxia2"] = "任侠：摸两张牌，重复直到手牌中有伤害牌，本阶段结束时执行另一项",
  ["renxia1"] = "弃两张牌",
  ["renxia2"] = "摸两张牌",

  ["$renxia1"] = "俊毅如风，任胸中长虹惊云。",
  ["$renxia2"] = "侠之大者，为国为民。",
}

renxia:addEffect("active", {
  anim_type = "drawcard",
  prompt = function (self, selected_cards, selected_targets)
    return "#"..self.interaction.data
  end,
  min_card_num = 0,
  msx_card_num = 2,
  target_num = 0,
  interaction = function(self)
    return UI.ComboBox { choices = {"renxia1", "renxia2"} }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(renxia.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (self, player, to_select, selected)
    if self.interaction.data == "renxia1" then
      return #selected < 2 and not player:prohibitDiscard(to_select)
    else
      return false
    end
  end,
  feasible = function (self, player, selected, selected_cards)
    if self.interaction.data == "renxia1" then
      return #selected_cards == 2
    else
      return #selected_cards == 0
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:addTableMark(player, "renxia-phase", self.interaction.data[7])
    if self.interaction.data == "renxia1" then
      if effect.cards then
        room:throwCard(effect.cards, renxia.name, player, player)
      else
        room:askToDiscard(player, {
          min_num = 2,
          max_num = 2,
          include_equip = true,
          skill_name = renxia.name,
          cancelable = false,
        })
      end
      while not player.dead do
        if table.find(player:getCardIds("h"), function (id)
          return Fk:getCardById(id).is_damage_card
        end) and table.find(player:getCardIds("he"), function (id)
          return not player:prohibitDiscard(id)
        end) then
          room:askToDiscard(player, {
            min_num = 2,
            max_num = 2,
            include_equip = true,
            skill_name = renxia.name,
            cancelable = false,
          })
        else
          break
        end
      end
    else
      player:drawCards(2, renxia.name)
      while not player.dead and not table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).is_damage_card
      end) do
        player:drawCards(2, renxia.name)
      end
    end
  end,
})
renxia:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("renxia-phase") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("renxia-phase")
    for _, n in ipairs(mark) do
      if player.dead then return end
      local i = 1
      if n == "1" then
        i = 2
      end
      local skill = Fk.skills[renxia.name]
      skill.interaction = skill.interaction or {}
      skill.interaction.data = "renxia"..i
      skill:onUse(room, {
        from = player,
      })
    end
  end,
})

return renxia
