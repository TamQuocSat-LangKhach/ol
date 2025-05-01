local tiangong = fk.CreateSkill{
  name = "tiangong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tiangong"] = "天公",
  [":tiangong"] = "锁定技，回合开始时，你视为使用一张<a href=':thunder_god_help'>【雷公助我】</a>；"..
  "回合结束时，你视为使用一张<a href=':sharing_risk'>【有难同当】</a>。<br>"..
  "一名角色判定后，若为♠，你对另一名角色造成1点雷电伤害。",

  ["#tiangong-choose"] = "天公：对另一名角色造成1点雷电伤害",

  ["$tiangong1"] = "此番受天书教化，当你我兄弟显名之时！",
  ["$tiangong2"] = "天地人本同一元气，分为三体。你我兄弟亦然。",
}

tiangong:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tiangong.name) and
      #Fk:cloneCard("thunder_god_help"):getAvailableTargets(player) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard("thunder_god_help")
    card.skillName = tiangong.name
    local targets = card:getAvailableTargets(player)
    room:sortByAction(targets)
    room:useVirtualCard("thunder_god_help", nil, player, targets, tiangong.name)
  end,
})

tiangong:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tiangong.name) and
      #Fk:cloneCard("sharing_risk"):getAvailableTargets(player) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard("sharing_risk")
    card.skillName = tiangong.name
    local targets = card:getAvailableTargets(player)
    room:sortByAction(targets)
    room:useVirtualCard("sharing_risk", nil, player, targets, tiangong.name)
  end,
})

tiangong:addEffect(fk.FinishJudge, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tiangong.name) and
      data.card and data.card.suit == Card.Spade and
      table.find(player.room.alive_players, function (p)
        return p ~= target
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p ~= target
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = tiangong.name,
      prompt = "#tiangong-choose",
      cancelable = false,
    })[1]
    room:damage{
      from = player,
      to = to,
      damage = 1,
      damageType = fk.ThunderDamage,
      skillName = tiangong.name,
    }
  end,
})

return tiangong
