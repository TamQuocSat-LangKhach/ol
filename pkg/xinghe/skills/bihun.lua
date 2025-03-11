local bihun = fk.CreateSkill{
  name = "bihun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["bihun"] = "弼昏",
  [":bihun"] = "锁定技，当你使用牌指定其他角色为目标时，若你的手牌数大于手牌上限，你取消之并令唯一目标获得此牌。",

  ["$bihun1"] = "辅弼天家，以扶朝纲。",
  ["$bihun2"] = "为国治政，尽忠匡辅。",
}

bihun:addEffect(fk.TargetSpecifying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bihun.name) and data.firstTarget and
      player:getHandcardNum() > player:getMaxCards() and
      table.find(data.use.tos, function (p)
        return p ~= player
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #data.use.tos == 1 and not data.to.dead and room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(data.to, data.card, true, fk.ReasonJustMove, player, bihun.name)
    end
    for _, p in ipairs(data.use.tos) do
      data:cancelTarget(p)
    end
  end,
})

return bihun
