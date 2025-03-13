local sushou = fk.CreateSkill{
  name = "guandu__sushou",
}

Fk:loadTranslationTable{
  ["guandu__sushou"] = "宿守",
  [":guandu__sushou"] = "弃牌阶段开始时，你可以摸X+1张牌（X为“粮”标记数），然后你可以交给任意名角色各一张牌。",

  ["#guandu__sushou-give"] = "宿守：你可以交给任意名角色各一张牌",

  ["$guandu__sushou1"] = "吾军之所守，为重中之重，尔等、切莫懈怠！",
  ["$guandu__sushou2"] = "今夜，需再加强巡逻，不要出了差池。",
}

sushou:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(sushou.name) and player.phase == Player.Discard
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:drawCards(1 + player:getMark("@guandu_grain"), sushou.name)
    if player.dead or player:isNude() or #player.room:getOtherPlayers(player, false) == 0 then return end
    room:askToYiji(player, {
      min_num = 0,
      max_num = 9,
      skill_name = sushou.name,
      targets = room:getOtherPlayers(player, false),
      cards = player:getCardIds("he"),
      prompt = "#guandu__sushou-give",
      single_max = 1,
    })
  end,
})

return sushou
