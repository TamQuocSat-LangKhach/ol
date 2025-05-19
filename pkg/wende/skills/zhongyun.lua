local zhongyun = fk.CreateSkill{
  name = "zhongyun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhongyun"] = "忠允",
  [":zhongyun"] = "锁定技，每回合各限一次，当你受到伤害或回复体力后，若你的体力值与你的手牌数相等，你回复1点体力或对你攻击范围内的"..
  "一名角色造成1点伤害；当你获得或失去手牌后，若你的体力值与你的手牌数相等，你摸一张牌或弃置一名其他角色的一张牌。",

  ["#zhongyun-damage"] = "忠允：对攻击范围内一名角色造成1点伤害，或点“取消”回复1点体力",
  ["#zhongyun-discard"] = "忠允：弃置一名其他角色的一张牌，或点“取消”摸一张牌",

  ["$zhongyun1"] = "秉公行事，无所亲疏。",
  ["$zhongyun2"] = "明晰法理，通晓人情。",
}

local spec = {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(zhongyun.name) and player.hp == player:getHandcardNum() and
      (player:usedEffectTimes(zhongyun.name, Player.HistoryTurn) + player:usedEffectTimes("#zhongyun_2_trig", Player.HistoryTurn)) == 0 and
      (player:isWounded() or table.find(player.room.alive_players, function (p)
        return player:inMyAttackRange(p)
      end))
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return player:inMyAttackRange(p)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = zhongyun.name,
      prompt = "#zhongyun-damage",
      cancelable = player:isWounded(),
    })
    if #to > 0 then
      room:damage{
        from = player,
        to = to[1],
        damage = 1,
        skillName = zhongyun.name,
      }
    elseif player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = zhongyun.name,
      }
    end
  end,
}

zhongyun:addEffect(fk.Damaged, spec)
zhongyun:addEffect(fk.HpRecover, spec)

zhongyun:addEffect(fk.AfterCardsMove,{
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(zhongyun.name) and player.hp == player:getHandcardNum() and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 then
        for _, move in ipairs(data) do
          if move.to == player and move.toArea == Card.PlayerHand then
            return true
          end
          if move.from == player then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                return true
              end
            end
          end
        end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = zhongyun.name,
      prompt = "#zhongyun-discard",
      cancelable = true,
    })
    if #to > 0 then
      local card = room:askToChooseCard(player, {
        target = to[1],
        flag = "he",
        skill_name = zhongyun.name,
      })
      room:throwCard(card, zhongyun.name, to[1], player)
    else
      player:drawCards(1, zhongyun.name)
    end
  end,
})

return zhongyun
