local yishe = fk.CreateSkill{
  name = "yishe",
}

Fk:loadTranslationTable{
  ["yishe"] = "义舍",
  [":yishe"] = "结束阶段，若你没有“米”，你可以摸两张牌，然后将两张牌置于武将牌上，称为“米”。当最后一张“米”移至其他区域后，"..
  "你回复1点体力。",

  ["zhanglu_mi"] = "米",
  ["#yishe-ask"] = "义舍：将两张牌置为“米”",

  ["$yishe1"] = "行大义之举，须有向道之心。",
  ["$yishe2"] = "你有你的权谋，我，哼，自有我的道义。",
}

yishe:addEffect(fk.EventPhaseStart, {
  derived_piles = "zhanglu_mi",
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yishe.name) and player.phase == Player.Finish and
      #player:getPile("zhanglu_mi") == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, yishe.name)
    if player:isNude() or player.dead then return end
    local cards = room:askToCards(player, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = yishe.name,
      prompt = "#yishe-ask",
      cancelable = false,
    })
    player:addToPile("zhanglu_mi", cards, true, yishe.name)
  end,
})
yishe:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yishe.name) and #player:getPile("zhanglu_mi") == 0 and player:isWounded() then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromSpecialName == "zhanglu_mi" then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = yishe.name,
    }
  end,
})

return yishe
