local this = fk.CreateSkill{ name = "ol_ex__buqu" }

this:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  derived_piles = "ol_ex__buqu_scar",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(this.name) and player.dying
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local scar_id = room:getNCards(1)[1]
    local scar = Fk:getCardById(scar_id)
    player:addToPile("ol_ex__buqu_scar", scar_id, true, self.name)
    if player.dead or not table.contains(player:getPile("ol_ex__buqu_scar"), scar_id) then return false end
    local success = true
    for _, id in pairs(player:getPile("ol_ex__buqu_scar")) do
      if id ~= scar_id then
        local card = Fk:getCardById(id)
        if (Fk:getCardById(id).number == scar.number) then
          success = false
          break
        end
      end
    end
    if success then
      room:recover({
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = self.name
      })
    else
      room:throwCard(scar:getEffectiveId(), self.name, player)
    end
  end,
})

this:addEffect("maxcards", {
  fixed_func = function (self, player)
    if player:hasSkill(this.name) and #player:getPile("ol_ex__buqu_scar") > 0 then
      return #player:getPile("ol_ex__buqu_scar")
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__buqu"] = "不屈",
  [":ol_ex__buqu"] = "锁定技，①当你处于濒死状态时，你将牌堆顶的一张牌置于武将牌上（称为“创”），若：没有与此“创”点数相同的其他“创”，你将体力回复至1点；有与此“创”点数相同的其他“创”，你将此“创”置入弃牌堆。②若有“创”，你的手牌上限初值改为“创”数，",
  
  ["ol_ex__buqu_scar"] = "创",

  ["$ol_ex__buqu1"] = "战如熊虎，不惜躯命！",
  ["$ol_ex__buqu2"] = "哼！这点小伤算什么。",
}

return this
