local lieshi = fk.CreateSkill{
  name = "lieshi",
}

Fk:loadTranslationTable{
  ["lieshi"] = "烈誓",
  [":lieshi"] = "出牌阶段，你可以选择一项：1.废除判定区并受到你的1点火焰伤害；2.弃置所有【闪】；3.弃置所有【杀】。然后令一名角色选择执行另一项。",

  ["#lieshi"] = "烈誓：执行一项效果，然后令一名角色选择执行一项与你不同的效果",
  ["#lieshi-choose"] = "烈誓：选择一名角色，令其选择执行与你不同的效果",
  ["#lieshi-choice"] = "烈誓：废除判定区并受到 %src 造成的1点火焰伤害，或弃置手牌中所有【杀】或【闪】",
  ["lieshi_damage"] = "废除判定区并受到1点火焰伤害",
  ["lieshi_slash"] = "弃置手牌区中所有的【杀】",
  ["lieshi_jink"] = "弃置手牌区中所有的【闪】",

  ["$lieshi1"] = "拭刃为誓，女无二夫。",
  ["$lieshi2"] = "霜刃证言，宁死不贰。",
}

lieshi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#lieshi",
  interaction = function(self, player)
    local choices = {}
    if not table.contains(player.sealedSlots, Player.JudgeSlot) then
      table.insert(choices, "lieshi_damage")
    end
    if table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).trueName == "slash" and not player:prohibitDiscard(id)
    end) then
      table.insert(choices, "lieshi_slash")
    end
    if table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).trueName == "jink" and not player:prohibitDiscard(id)
    end) then
      table.insert(choices, "lieshi_jink")
    end
    return UI.ComboBox { choices = choices , all_choices = {"lieshi_damage", "lieshi_slash", "lieshi_jink"} }
  end,
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return not table.contains(player.sealedSlots, Player.JudgeSlot) or
      table.find(player:getCardIds("h"), function (id)
        return table.contains({"slash", "jink"}, Fk:getCardById(id).trueName) and not player:prohibitDiscard(id)
      end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local choice = self.interaction.data
    local to = player
    for i = 1, 2, 1 do
      if i == 2 then
        if player.dead then return end
        to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = room.alive_players,
          skill_name = lieshi.name,
          prompt = "#lieshi-choose",
          cancelable = false,
        })[1]
        local choices, all_choices = {}, {"lieshi_damage", "lieshi_slash", "lieshi_jink"}
        if not table.contains(to.sealedSlots, Player.JudgeSlot) then
          table.insert(choices, "lieshi_damage")
        end
        if table.find(to:getCardIds("h"), function (id)
          return Fk:getCardById(id).trueName == "slash" and not to:prohibitDiscard(id)
        end) then
          table.insert(choices, "lieshi_slash")
        end
        if table.find(to:getCardIds("h"), function (id)
          return Fk:getCardById(id).trueName == "jink" and not to:prohibitDiscard(id)
        end) then
          table.insert(choices, "lieshi_jink")
        end
        table.removeOne(choices, choice)
        if #choices == 0 then return end
        choice = room:askToChoice(to, {
          choices = choices,
          skill_name = lieshi.name,
          prompt = "#lieshi-choice:"..player.id,
          all_choices = all_choices,
        })
      end
      if choice == "lieshi_damage" then
        room:abortPlayerArea(to, Player.JudgeSlot)
        if not to.dead then
          room:damage{
            from = player,
            to = to,
            damage = 1,
            damageType = fk.FireDamage,
            skillName = lieshi.name,
          }
        end
      elseif choice == "lieshi_slash" then
        local cards = table.filter(to:getCardIds("h"), function (id)
          return Fk:getCardById(id).trueName == "slash" and not to:prohibitDiscard(id)
        end)
        if #cards > 0 then
          room:throwCard(cards, lieshi.name, to, to)
        end
      elseif choice == "lieshi_jink" then
        local cards = table.filter(to:getCardIds("h"), function (id)
          return Fk:getCardById(id).trueName == "jink" and not to:prohibitDiscard(id)
        end)
        if #cards > 0 then
          room:throwCard(cards, lieshi.name, to, to)
        end
      end
    end
  end,
})

return lieshi
