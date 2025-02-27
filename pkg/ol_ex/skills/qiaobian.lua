local qiaobian = fk.CreateSkill {
  name = "ol_ex__qiaobian"
}

Fk:loadTranslationTable {
  ["ol_ex__qiaobian"] = "巧变",
  [":ol_ex__qiaobian"] = "游戏开始时，你获得2枚“变”标记。你可以弃置一张牌或移除1枚“变”标记并跳过你的一个阶段（准备阶段和结束阶段除外）："..
  "若跳过摸牌阶段，你可以获得至多两名角色的各一张手牌；若跳过出牌阶段，你可以移动场上的一张牌。结束阶段开始时，若你的手牌数与之前你的每一回合"..
  "结束阶段开始时的手牌数均不相等，你获得1枚“变”标记。",

  ["@ol_ex__qiaobian_change"] = "变",
  ["#ol_ex__qiaobian-invoke"] = "巧变：弃一张牌，或直接点“确定”弃置变标记，来跳过 %arg",
  ["#ol_ex__qiaobian-prey"] = "巧变：你可以选择至多两名角色，获得这些角色各一张手牌",
  ["#ol_ex__qiaobian-move"] = "巧变：你可以移动场上的一张牌",

  ["$ol_ex__qiaobian1"] = "顺势而变，则胜矣。",
  ["$ol_ex__qiaobian2"] = "万物变化，固无休息。",
}

qiaobian:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qiaobian.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@ol_ex__qiaobian_change", 2)
  end
})

qiaobian:addEffect(fk.EventPhaseChanging, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qiaobian.name) and
      (not player:isNude() or player:getMark("@ol_ex__qiaobian_change") > 0) and
      (data.phase > Player.Start and data.phase < Player.Finish) and
      not data.skipped
  end,
  on_cost = function (self, event, target, player, data)
    local discard_data = {
      num = 1,
      min_num = player:getMark("@ol_ex__qiaobian_change") == 0 and 1 or 0,
      include_equip = true,
      skillName = qiaobian.name,
      pattern = ".",
    }
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "discard_skill",
      prompt = "#ol_ex__qiaobian-invoke:::" .. Util.PhaseStrMapper(data.phase),
      cancelable = true,
      extra_data = discard_data,
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    data.skipped = true
    if #event:getCostData(self).cards > 0 then
      room:throwCard(event:getCostData(self).cards, qiaobian.name, player, player)
      if player.dead then return false end
    else
      room:removePlayerMark(player, "@ol_ex__qiaobian_change")
    end
    if data.phase == Player.Draw then
      local targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return not p:isKongcheng()
      end)
      if #targets > 0 then
        local tos = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 2,
          targets = targets,
          skill_name = qiaobian.name,
          prompt = "#ol_ex__qiaobian-prey",
          cancelable = true,
        })
        if #tos > 0 then
          room:sortByAction(tos)
          for _, p in ipairs(tos) do
            if player.dead then return end
            if not p:isKongcheng() then
              local card_id = room:askToChooseCard(player, {
                skill_name = qiaobian.name,
                target = p,
                flag = "h",
              })
              room:obtainCard(player, card_id, false, fk.ReasonPrey, player, qiaobian.name)
            end
          end
        end
      end
    elseif data.phase == Player.Play and #room:canMoveCardInBoard() > 0 then
      local targets = room:askToChooseToMoveCardInBoard(player, {
        prompt = "#ol_ex__qiaobian-move",
        skill_name = qiaobian.name,
        cancelable = true,
      })
      if #targets == 2 then
        room:askToMoveCardInBoard(player, {
          target_one = targets[1],
          target_two = targets[2],
          skill_name = qiaobian.name,
        })
      end
    end
  end
})

qiaobian:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qiaobian.name) and player.phase == Player.Finish and
      not table.contains(player:getTableMark("ol_ex__qiaobian_number"), player:getHandcardNum())
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "ol_ex__qiaobian_number", player:getHandcardNum())
    room:addPlayerMark(player, "@ol_ex__qiaobian_change")
  end
})

return qiaobian