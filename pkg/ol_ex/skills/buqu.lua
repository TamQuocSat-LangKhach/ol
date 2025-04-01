local buqu = fk.CreateSkill{
  name = "ol_ex__buqu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ol_ex__buqu"] = "不屈",
  [":ol_ex__buqu"] = "锁定技，当你处于濒死状态时，你将牌堆顶的一张牌置于武将牌上（称为“创”），若没有与此“创”点数相同的其他“创”，你将体力回复至1点；"..
  "有与此“创”点数相同的其他“创”，你将此“创”置入弃牌堆。若有“创”，你的手牌上限改为“创”数。",

  ["ol_ex__buqu_scar"] = "创",

  ["$ol_ex__buqu1"] = "战如熊虎，不惜躯命！",
  ["$ol_ex__buqu2"] = "哼！这点小伤算什么。",
}

buqu:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  derived_piles = "ol_ex__buqu_scar",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(buqu.name) and player.dying
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:getNCards(1)[1]
    player:addToPile("ol_ex__buqu_scar", card, true, buqu.name)
    if player.dead or not table.contains(player:getPile("ol_ex__buqu_scar"), card) then return false end
    local success = true
    for _, id in pairs(player:getPile("ol_ex__buqu_scar")) do
      if id ~= card then
        if Fk:getCardById(id).number == Fk:getCardById(id).number then
          success = false
          break
        end
      end
    end
    if success then
      if player.hp < 1 then
        room:recover{
          who = player,
          num = 1 - player.hp,
          recoverBy = player,
          skillName = buqu.name,
        }
      end
    else
      room:throwCard(card, buqu.name, player)
    end
  end,
})

buqu:addEffect("maxcards", {
  fixed_func = function (self, player)
    if player:hasSkill(buqu.name) and #player:getPile("ol_ex__buqu_scar") > 0 then
      return #player:getPile("ol_ex__buqu_scar")
    end
  end,
})

return buqu
