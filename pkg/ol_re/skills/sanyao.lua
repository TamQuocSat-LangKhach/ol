local sanyao = fk.CreateSkill{
  name = "ol__sanyao",
}

Fk:loadTranslationTable{
  ["ol__sanyao"] = "散谣",
  [":ol__sanyao"] = "出牌阶段各限一次，你可以弃置一张牌，对一名体力值最大/手牌数最多的角色造成1点伤害。",

  ["#ol__sanyao"] = "散谣：弃一张牌，对一名符合条件的角色造成1点伤害",
  ["ol__sanyao_hp"] = "体力值最大",
  ["ol__sanyao_hand"] = "手牌数最多",

  ["$ol__sanyao1"] = "吾有一计，可致司马懿于死地。",
  ["$ol__sanyao2"] = "丞相勿忧，司马懿不足为患。",
}

sanyao:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ol__sanyao",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("ol__sanyao_hp-phase") + player:getMark("ol__sanyao_hand-phase") < 2
  end,
  interaction = function(self, player)
    local all_choices = {"ol__sanyao_hp", "ol__sanyao_hand"}
    local choices = table.filter(all_choices, function (choice)
      return player:getMark(choice.."-phase") == 0
    end)
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, cards)
    if #selected > 0 or not self.interaction.data or #cards ~= 1 then return end
    if self.interaction.data == "ol__sanyao_hp" then
      return table.every(Fk:currentRoom().alive_players, function(p)
        return p.hp <= to_select.hp
      end)
    else
      return table.every(Fk:currentRoom().alive_players, function(p)
        return p:getHandcardNum() <= to_select:getHandcardNum()
      end)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:setPlayerMark(player, self.interaction.data.."-phase", 1)
    room:throwCard(effect.cards, sanyao.name, player, player)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = sanyao.name,
      }
    end
  end,
})

return sanyao
