local this = fk.CreateSkill { name = "ol_ex__piaoling" }

this:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(this.name)
      and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = this.name,
      pattern = ".|.|heart",
    }
    room:judge(judge)
  end,
})

this:addEffect(fk.FinishJudge, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and data.card.suit == Card.Heart and data.reason == this.name
      and player.room:getCardArea(data.card.id) == Card.Processing
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.suit == Card.Heart and room:getCardArea(data.card) == Card.Processing then
      local targets = room:askToChoosePlayers(player, { targets = table.map(room.alive_players, Util.IdMapper), min_num = 1, max_num = 1, prompt = "#ol_ex__piaoling-choose", skill_name = this.name, cancelable = true})
      if #targets == 0 then
        room:moveCards({
          ids = {data.card.id},
          fromArea = Card.Processing,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = this.name,
        })
      else
        local to = targets[1]
        room:obtainCard(to, data.card, true, fk.ReasonJustMove)
        if to == player and not to.dead then
          room:askToDiscard(to, { min_num = 1, max_num = 1, include_equip = true, skill_name = this.name, cancelable = false, pattern = ".", prompt = "#ol_ex__piaoling-discard"})
        end
      end
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__piaoling"] = "飘零",
  ["#ol_ex__piaoling_delay"] = "飘零",
  [":ol_ex__piaoling"] = "结束阶段，你可判定，然后当判定结果确定后，若为<font color='red'>♥</font>，你选择：1.将判定牌置于牌堆顶；"..
  "2.令一名角色获得判定牌，若其为你，你弃置一张牌。",
  
  ["#ol_ex__piaoling-choose"] = "飘零：选择一名角色令其获得判定牌，若其为你，你弃置一张牌，或点取消将判定牌置于牌堆顶",
  ["#ol_ex__piaoling-discard"] = "飘零：弃置1张牌",

  ["$ol_ex__piaoling1"] = "花自飘零水自流。",
  ["$ol_ex__piaoling2"] = "清风拂枝，落花飘零。",
}

return this