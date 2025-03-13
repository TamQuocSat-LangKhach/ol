local huojie = fk.CreateSkill{
  name = "huojie",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["huojie"] = "祸结",
  [":huojie"] = "锁定技，出牌阶段开始时，若X大于游戏人数，你进行X次【闪电】判定直到你以此法受到伤害（X为“定西”牌的数量）。若你以此法受到伤害，"..
  "你获得所有“定西”牌。",

  ["$huojie1"] = "国虽大，忘战必危，好战必亡。",
  ["$huojie2"] = "这穷兵黩武的罪，让我一人受便可！",
}

huojie:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(huojie.name) and player.phase == Player.Play and
      #player:getPile("dingxi") > #player.room.players
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = #player:getPile("dingxi")
    for _ = 1, n, 1 do
      if player.dead then return end
      local judge = {
        who = player,
        reason = "lightning",
        pattern = ".|2~9|spade",
      }
      room:judge(judge)
      if judge:matchPattern() then
        if player.dead then return end
        room:damage{
          to = player,
          damage = 3,
          damageType = fk.ThunderDamage,
          skillName = huojie.name,
        }
        if player.dead then return end
        if #player:getPile("dingxi") > 0 then
          room:moveCardTo(player:getPile("dingxi"), Card.PlayerHand, player, fk.ReasonJustMove, huojie.name, nil, true, player)
        end
        break
      end
    end
  end,
})

return huojie
