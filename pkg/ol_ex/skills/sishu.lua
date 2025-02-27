
local sishu = fk.CreateSkill {
  name = "ol_ex__sishu",
}

Fk:loadTranslationTable {
  ["ol_ex__sishu"] = "思蜀",
  [":ol_ex__sishu"] = "出牌阶段开始时，你可选择一名角色，其本局游戏【乐不思蜀】的判定结果反转。",

  ["#ol_ex__sishu-choose"] = "思蜀：选择一名角色，令其本局游戏【乐不思蜀】的判定结果反转",
  ["@@ol_ex__sishu_effect"] = "思蜀",

  ["$ol_ex__sishu1"] = "蜀乐乡土，怎不思念？",
  ["$ol_ex__sishu2"] = "思乡心切，徘徊惶惶。",
}

sishu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sishu.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#ol_ex__sishu-choose",
      skill_name = sishu.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    player.room:setPlayerMark(to, "@@ol_ex__sishu_effect", 1 - to:getMark("@@ol_ex__sishu_effect"))
  end,
})

local orig_indulgence_skill = Fk.skills["indulgence_skill"]
local indulgenceSkill = Fk.skills["trans__indulgence_skill"]

sishu:addEffect(fk.CardEffecting, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@@ol_ex__sishu_effect") > 0 and target == player and data.card.trueName == "indulgence"
  end,
  on_refresh = function(self, event, target, player, data)
    local card = data.card:clone()
    local c = table.simpleClone(data.card)
    for k, v in pairs(c) do
      card[k] = v
    end
    local ogri_skill = orig_indulgence_skill
    card.skill = (card.skill == ogri_skill) and indulgenceSkill or ogri_skill
    data.card = card
  end,
})

return sishu