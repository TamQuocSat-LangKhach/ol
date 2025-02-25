local this = fk.CreateSkill {
  name = "ol_ex__qiaobian"
}

this:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return not player:hasSkill(this.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@ol_ex__qiaobian_change", 2)
  end
})

this:addEffect(fk.EventPhaseChanging, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(this.name) then
      return player == target and (not player:isNude() or player:getMark("@ol_ex__qiaobian_change") > 0) and data.to > Player.Start and data.to < Player.Finish
    end
  end,
  on_cost = function (self, event, target, player, data)
    local discard_data = {
      num = 1,
      min_num = player:getMark("@ol_ex__qiaobian_change") == 0 and 1 or 0,
      include_equip = true,
      skillName = this.name,
      pattern = ".",
    }
    local success, ret = player.room:askToUseActiveSkill(player, { skill_name = "discard_skill", prompt = "#ol_ex__qiaobian-invoke:::" .. Util.PhaseStrMapper(data.to), cancelable = true, extra_data = discard_data })
    if success and ret then
      self.cost_data = ret.cards
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if #self.cost_data > 0 then
      room:throwCard(self.cost_data, this.name, player, player)
      if player.dead then return false end
    else
      room:removePlayerMark(player, "@ol_ex__qiaobian_change")
    end
    if data.to == Player.Draw then
      local tos = room:askToChoosePlayers(player, { targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
        return not p:isKongcheng() end), Util.IdMapper), min_num = 1, max_num = 2, prompt = "#ol_ex__qiaobian-prey", skill_name = this.name, cancelable = true
      })
      if #tos > 0 then
        room:sortByAction(tos)
        table.forEach(tos, function(to)
          if not player.dead then
            if not to.dead and not to:isKongcheng() then
              local c = room:askToChooseCard(player, {target = to, flag = "h", skill_name = this.name})
              room:obtainCard(player, c, false, fk.ReasonPrey)
            end
          end
        end)
      end
    elseif data.to == Player.Play then
      local to = room:askToChooseToMoveCardInBoard(player, { prompt = "#ol_ex__qiaobian-movecard", skill_name = this.name, cancelable = true})
      if #to == 2 then
        room:askToMoveCardInBoard(player, { target_one = to[1], target_two = to[2], skill_name = this.name})
      end
    end
    player:skip(data.to)
    return true
  end
})

this:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(this.name) then
      return player.phase == Player.Finish and not table.contains(player:getTableMark("ol_ex__qiaobian_number"), player:getHandcardNum())
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "ol_ex__qiaobian_number", player:getHandcardNum())
    room:addPlayerMark(player, "@ol_ex__qiaobian_change")
  end
})

Fk:loadTranslationTable {
  ["ol_ex__qiaobian"] = "巧变",
  [":ol_ex__qiaobian"] = "游戏开始时，你获得2枚“变”标记。你可以弃置一张牌或移除1枚“变”标记并跳过你的一个阶段（准备阶段和结束阶段除外）：若跳过摸牌阶段，你可以获得至多两名角色的各一张手牌；若跳过出牌阶段，你可以移动场上的一张牌。结束阶段开始时，若你的手牌数与之前你的每一回合结束阶段开始时的手牌数均不相等，你获得1枚“变”标记。",

  ["@ol_ex__qiaobian_change"] = "变",
  ["#ol_ex__qiaobian-invoke"] = "巧变：你可选择一张牌弃置，或直接点确定则弃置变标记。来跳过 %arg",
  ["#ol_ex__qiaobian-prey"] = "巧变：你可以选择一至两名角色，获得这些角色各一张手牌",
  ["#ol_ex__qiaobian-movecard"] = "巧变：你可以选择两名角色，移动这些角色装备区或判定区的一张牌",

  ["$ol_ex__qiaobian1"] = "顺势而变，则胜矣。",
  ["$ol_ex__qiaobian2"] = "万物变化，固无休息。",
}

return this