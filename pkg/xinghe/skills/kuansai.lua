local kuansai = fk.CreateSkill{
  name = "kuansai",
}

Fk:loadTranslationTable{
  ["kuansai"] = "款塞",
  [":kuansai"] = "每回合限一次，当一张牌指定目标后，若目标数不小于你的体力值，你可以令其中一个目标选择一项：1.交给你一张牌；2.你回复1点体力。",

  ["#kuansai-choose"] = "款塞：你可以令其中一个目标选择交给你一张牌或令你回复体力",
  ["#kuansai-give"] = "款塞：交给 %src 一张牌，否则其回复1点体力",

  ["$kuansai1"] = "君既以礼相待，我何干戈相向。",
  ["$kuansai2"] = "我备美酒，待君玉帛。",
}

kuansai:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(kuansai.name) and data.firstTarget and
      #data.use.tos >= player.hp and player:usedSkillTimes(kuansai.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = data.use.tos,
      skill_name = kuansai.name,
      prompt = "#kuansai-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if to:isNude() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = kuansai.name,
      }
    else
      local card = room:askToCards(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = kuansai.name,
        prompt = "#kuansai-give:"..player.id,
        cancelable = player:isWounded(),
      })
      if #card > 0 then
        room:moveCardTo(card, Player.Hand, player, fk.ReasonGive, kuansai.name, nil, false, to)
      else
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = kuansai.name,
        }
      end
    end
  end,
})

return kuansai
