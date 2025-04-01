local cuorui = fk.CreateSkill{
  name = "ol__cuorui",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__cuorui"] = "挫锐",
  [":ol__cuorui"] = "锁定技，游戏开始时，你将手牌数摸至X张（X为场上角色数）。当你成为延时锦囊牌的目标后，你跳过下个判定阶段。",

  ["@@ol__cuorui"] = "挫锐",

  ["$ol__cuorui1"] = "敌锐气正盛，吾欲挫之。",
  ["$ol__cuorui2"] = "锐气受挫，则未敢恋战。",
}

cuorui:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(cuorui.name) and player:getHandcardNum() < #player.room.alive_players
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(#player.room.alive_players - player:getHandcardNum(), cuorui.name)
  end,
})
cuorui:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cuorui.name) and data.card.sub_type == Card.SubtypeDelayedTrick and
      player:getMark("@@ol__cuorui") == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ol__cuorui", 1)
  end,
})
cuorui:addEffect(fk.EventPhaseChanging, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.phase == Player.Judge and
      player:getMark("@@ol__cuorui") > 0 and not data.skipped
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ol__cuorui", 0)
    data.skipped = true
  end,
})

return cuorui
