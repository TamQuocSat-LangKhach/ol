local qiuxin = fk.CreateSkill{
  name = "qiuxin",
}

Fk:loadTranslationTable{
  ["qiuxin"] = "求心",
  [":qiuxin"] = "出牌阶段限一次，你可以令一名其他角色声明一项：1.当你对其使用一张【杀】后，你可以视为对其使用一张普通锦囊牌；"..
  "2.当你对其使用一张普通锦囊牌后，你可以视为对其使用一张无距离限制的【杀】。",

  ["#qiuxin"] = "求心：令一名其他角色声明一项",
  ["#qiuxin-choice"] = "求心：声明一项“求心”，%src 对你使用声明项后，可以视为对你使用另一项",
  ["@@qiuxin_slash"] = "求心 杀",
  ["@@qiuxin_trick"] = "求心 锦囊",
  ["#qiuxin-slash"] = "求心：是否视为对 %dest 使用【杀】？",
  ["#qiuxin-trick"] = "求心：是否视为对 %dest 使用锦囊？",

  ["$qiuxin1"] = "此生所求者，顺心意尔。",
  ["$qiuxin2"] = "羡孔丘知天命之岁，叹吾生之不达。",
}

qiuxin.zhongliu_type = Player.HistoryPhase

qiuxin:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    room:removeTableMark(p, "@@qiuxin_slash", player.id)
    room:removeTableMark(p, "@@qiuxin_trick", player.id)
  end
end)

qiuxin:addEffect("active", {
  anim_type = "control",
  prompt = "#qiuxin",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedEffectTimes(qiuxin.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local choice = room:askToChoice(target, {
      choices = {"slash", "trick"},
      skill_name = qiuxin.name,
      prompt = "#qiuxin-choice:"..player.id,
    })
    room:addTableMarkIfNeed(target, "@@qiuxin_"..choice, player.id)
  end,
})
qiuxin:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(qiuxin.name) then
      local qiuxin_type = ""
      if data.card.trueName == "slash" then
        qiuxin_type = "slash"
      elseif data.card:isCommonTrick() then
        qiuxin_type = "trick"
      else
        return false
      end
      return table.find(data.tos, function (p)
        return table.contains(p:getTableMark("@@qiuxin_"..qiuxin_type), player.id) and not p.dead
      end)
    end
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local targets = {}
    local qiuxin_type = ""
    if data.card.trueName == "slash" then
      qiuxin_type = "slash"
    elseif data.card:isCommonTrick() then
      qiuxin_type = "trick"
    end
    for _, p in ipairs(data.tos) do
      if room:removeTableMark(p, "@@qiuxin_"..qiuxin_type, player.id) then
        table.insert(targets, p)
      end
    end
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not player:hasSkill(qiuxin.name) then return end
      if not p.dead then
        if qiuxin_type == "trick" then
          if player:canUseTo(Fk:cloneCard("slash"), p, {bypass_distances = true, bypass_times = true}) then
            event:setCostData(self, {tos = {p}})
            self:doCost(event, target, player, data)
          end
        else
          event:setCostData(self, {tos = {p}})
          self:doCost(event, target, player, data)
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if data.card.trueName == "slash" then
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "qiuxin_viewas",
        prompt = "#qiuxin-trick::"..to.id,
        cancelable = true,
        extra_data = {
          qiuxin_to = to.id,
        }
      })
      if success and dat then
        event:setCostData(self, {extra_data = dat})
        return true
      end
    elseif data.card:isCommonTrick() then
      return room:askToSkillInvoke(player, {
        skill_name = qiuxin.name,
        prompt = "#qiuxin-slash::"..to.id,
      })
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if data.card.trueName == "slash" then
      local dat = table.simpleClone(event:getCostData(self).extra_data)
      local card = Fk:cloneCard(dat.interaction)
      card.skillName = qiuxin.name
      room:useCard{
        from = player,
        tos = dat.targets,
        card = card,
      }
    elseif data.card:isCommonTrick() then
      room:useVirtualCard("slash", nil, player, event:getCostData(self).tos, qiuxin.name, true)
    end
  end,
})

return qiuxin
