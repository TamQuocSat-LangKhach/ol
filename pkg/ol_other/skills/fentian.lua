local fentian = fk.CreateSkill{
  name = "fentian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fentian"] = "焚天",
  [":fentian"] = "锁定技，结束阶段，若你的手牌数小于你的体力值，你将攻击范围内的一名角色的一张牌置于你的武将牌上，称为“焚”；"..
  "你的攻击范围+X（X为“焚”数）。",

  ["fentian_burn"] = "焚",
  ["#fentian-choose"] = "焚天：选择一名角色，将其一张牌置为你的“焚”",

  ["$fentian1"] = "烈火燎原，焚天灭地！",
  ["$fentian2"] = "骄阳似火，万物无生！",
}

fentian:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  derived_piles = "fentian_burn",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fentian.name) and player.phase == Player.Finish and
      player:getHandcardNum() < player.hp and
      table.find(player.room.alive_players, function (p)
        return player:inMyAttackRange(p) and not p:isNude()
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return player:inMyAttackRange(p) and not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = fentian.name,
      prompt = "#fentian-choose",
      cancelable = false,
    })[1]
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = fentian.name,
    })
    player:addToPile("fentian_burn", card, true, fentian.name)
  end,
})

return fentian
