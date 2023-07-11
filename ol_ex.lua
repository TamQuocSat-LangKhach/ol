local extension = Package("ol_ex")
extension.extensionName = "ol"

Fk:loadTranslationTable{
  ["ol_ex"] = "OL界",
}

local xiahouyuan = General(extension, "ol_ex__xiahouyuan", "wei", 4)
local ol_ex__shensu = fk.CreateTriggerSkill{
  name = "ol_ex__shensu",
  anim_type = "offensive",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and not player:prohibitUse(Fk:cloneCard("slash")) then
      if (data.to == Player.Judge and not player.skipped_phases[Player.Draw]) or data.to == Player.Discard then
        return true
      elseif data.to == Player.Play then
        return not player:isNude()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local slash = Fk:cloneCard("slash")
    local max_num = slash.skill:getMaxTargetNum(player, slash)
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not player:isProhibited(p, slash) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 or max_num == 0 then return end
    if data.to == Player.Judge then
      local tos = room:askForChoosePlayers(player, targets, 1, max_num, "#ol_ex__shensu1-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = {tos}
        return true
      end
    elseif data.to == Player.Play then
      local tos, id = room:askForChooseCardAndPlayers(player, targets, 1, max_num, ".|.|.|.|.|equip", "#ol_ex__shensu2-choose", self.name, true)
      if #tos > 0 and id then
        self.cost_data = {tos, {id}}
        return true
      end
    elseif data.to == Player.Discard then
      local tos = room:askForChoosePlayers(player, targets, 1, max_num, "#ol_ex__shensu3-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = {tos}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.to == Player.Judge then
      player:skip(Player.Judge)
      player:skip(Player.Draw)
    elseif data.to == Player.Play then
      player:skip(Player.Play)
      room:throwCard(self.cost_data[2], self.name, player, player)
    elseif data.to == Player.Discard then
      player:skip(Player.Discard)
      player:turnOver()
    end

    local slash = Fk:cloneCard("slash")
    slash.skillName = self.name
    room:useCard({
      from = target.id,
      tos = table.map(self.cost_data[1], function(pid) return { pid } end),
      card = slash,
    })
    return true
  end,
}
local ol_ex__shebian = fk.CreateTriggerSkill{
  name = "ol_ex__shebian",
  events = { fk.TurnedOver },
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChooseToMoveCardInBoard(player, "#ol_ex__shebian-choose", self.name, true, "e")
    if #to == 2 then
      room:askForMoveCardInBoard(player, room:getPlayerById(to[1]), room:getPlayerById(to[2]), self.name, "e")
    end
  end,
}
xiahouyuan:addSkill(ol_ex__shensu)
xiahouyuan:addSkill(ol_ex__shebian)
Fk:loadTranslationTable{
  ["ol_ex__xiahouyuan"] = "界夏侯渊",
  ["ol_ex__shensu"] = "神速",
  [":ol_ex__shensu"] = "①判定阶段开始前，你可跳过此阶段和摸牌阶段来视为使用普【杀】。②出牌阶段开始前，你可跳过此阶段并弃置一张装备牌来视为使用普【杀】。③弃牌阶段开始前，你可跳过此阶段并翻面来视为使用普【杀】。",
  ["ol_ex__shebian"] = "设变",
  [":ol_ex__shebian"] = "当你翻面后，你可将一名角色装备区里的一张牌置入另一名角色的装备区。",
  ["#ol_ex__shensu1-choose"] = "神速：你可以跳过判定阶段和摸牌阶段，视为使用一张无距离限制的【杀】",
  ["#ol_ex__shensu2-choose"] = "神速：你可以跳过出牌阶段并弃置一张装备牌，视为使用一张无距离限制的【杀】",
  ["#ol_ex__shensu3-choose"] = "神速：你可以跳过弃牌阶段并翻面，视为使用一张无距离限制的【杀】",
  ["#ol_ex__shebian-choose"] = "设变：你可以移动场上的一张装备牌",

  ["$ol_ex__shensu1"] = "奔逸绝尘，不留踪影！",
  ["$ol_ex__shensu2"] = "健步如飞，破敌不备！",
  ["$ol_ex__shebian1"] = "设变力战，虏敌千万！",
  ["$ol_ex__shebian2"] = "随机应变，临机设变！",
  ["~ol_ex__xiahouyuan"] = "我的速度，还是不够……",
}

local caoren = General(extension, "ol_ex__caoren", "wei", 4)
local ol_ex__jushou_select = fk.CreateActiveSkill{
  name = "#ol_ex__jushou_select",
  can_use = function() return false end,
  target_num = 0,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    if #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip then
      local card = Fk:getCardById(to_select)
      if card.type == Card.TypeEquip then
        return not Self:prohibitUse(card)
      else
        return not Self:prohibitDiscard(card)
      end
    end
  end,
}
local ol_ex__jushou = fk.CreateTriggerSkill{
  name = "ol_ex__jushou",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:turnOver()
    if player.dead then return false end
    room:drawCards(player, 4, self.name)
    if player.dead then return false end
    local jushou_card
    for _, id in pairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      if (card.type == Card.TypeEquip and not player:prohibitUse(card)) or (card.type ~= Card.TypeEquip and not player:prohibitDiscard(card)) then
        jushou_card = card
        break
      end
    end
    if not jushou_card then return end
    local _, ret = room:askForUseActiveSkill(player, "#ol_ex__jushou_select", "#ol_ex__jushou-select", false)
    if ret then
      jushou_card = Fk:getCardById(ret.cards[1])
    end
    if jushou_card then
      if jushou_card.type == Card.TypeEquip then
        room:useCard({
          from = player.id,
          tos = {{player.id}},
          card = jushou_card,
        })
      else
        room:throwCard(jushou_card:getEffectiveId(), self.name, player, player)
      end
    end
  end,
}
local ol_ex__jiewei = fk.CreateViewAsSkill{
  name = "ol_ex__jiewei",
  anim_type = "defensive",
  pattern = "nullification",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("nullification")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function (self, player)
    return false
  end,
  enabled_at_response = function (self, player)
    return #player.player_cards[Player.Equip] > 0
  end,
}
local ol_ex__jiewei_trigger = fk.CreateTriggerSkill{
  name = "#ol_ex__jiewei_trigger",
  events = { fk.TurnedOver },
  anim_type = "control",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("ol_ex__jiewei") and not player:isNude() and player.faceup
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, true, "ol_ex__jiewei", true, ".", "#ol_ex__jiewei-discard", true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("ol_ex__jiewei")
    room:notifySkillInvoked(player, "ol_ex__jiewei", "control")
    room:throwCard(self.cost_data, self.name, player, player)
    local to = room:askForChooseToMoveCardInBoard(player, "#ol_ex__jiewei-choose", "ol_ex__jiewei", true)
    if #to == 2 then
      room:askForMoveCardInBoard(player, room:getPlayerById(to[1]), room:getPlayerById(to[2]), "ol_ex__jiewei")
    end
  end,
}
ol_ex__jushou:addRelatedSkill(ol_ex__jushou_select)
ol_ex__jiewei:addRelatedSkill(ol_ex__jiewei_trigger)
caoren:addSkill(ol_ex__jushou)
caoren:addSkill(ol_ex__jiewei)
Fk:loadTranslationTable{
  ["ol_ex__caoren"] = "界曹仁",
  ["ol_ex__jushou"] = "据守",
  ["#ol_ex__jushou_select"] = "据守",
  [":ol_ex__jushou"] = "结束阶段，你可翻面，你摸四张牌，选择：1.使用一张为装备牌的手牌；2.弃置一张不为装备牌的手牌。",
  ["ol_ex__jiewei"] = "解围",
  ["#ol_ex__jiewei_trigger"] = "解围",
  [":ol_ex__jiewei"] = "①你可将一张装备区里的牌转化为普【无懈可击】使用。②当你翻面后，若你的武将牌正面朝上，你可弃置一张牌，你可将一名角色装备区或判定区里的一张牌置入另一名角色的相同区域。",

  ["#ol_ex__jushou-select"] = "据守：选择使用手牌中的一张装备牌或弃置手牌中的一张非装备牌",
  ["#ol_ex__jiewei-discard"] = "解围：弃置一张牌发动，之后可以移动场上的一张牌",
  ["#ol_ex__jiewei-choose"] = "解围：你可以移动场上的一张装备牌",

  ["$ol_ex__jushou1"] = "兵精粮足，守土一方。",
  ["$ol_ex__jushou2"] = "坚守此地，不退半步。",
  ["$ol_ex__jiewei1"] = "化守为攻，出奇制胜！",
  ["$ol_ex__jiewei2"] = "坚壁清野，以挫敌锐！",
  ["~ol_ex__caoren"] = "长江以南，再无王土矣……",
}

local huangzhong = General(extension, "ol_ex__huangzhong", "shu", 4)
local ol_ex__liegong = fk.CreateTriggerSkill{
  name = "ol_ex__liegong",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self.name)) then return end
    local to = player.room:getPlayerById(data.to)
    return data.card.trueName == "slash" and (#to:getCardIds(Player.Hand) <= #player:getCardIds(Player.Hand) or to.hp >= player.hp)
  end,
  on_use = function(self, event, target, player, data)
    local to = player.room:getPlayerById(data.to)
    if #to:getCardIds(Player.Hand) <= #player:getCardIds(Player.Hand) then
      data.disresponsive = true -- FIXME: use disreponseList. this is FK's bug
    end
    if to.hp >= player.hp then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
}
local ol_ex__liegong_targetmod = fk.CreateTargetModSkill{
  name = "#ol_ex__liegong_targetmod",
  distance_limit_func =  function(self, player, skill, card, target)
    if skill.trueName == "slash_skill" and player:hasSkill("ol_ex__liegong") then
      if card and target and player:distanceTo(target) <= card.number then
        return 999
      end
    end
  end,
}
ol_ex__liegong:addRelatedSkill(ol_ex__liegong_targetmod)
huangzhong:addSkill(ol_ex__liegong)
Fk:loadTranslationTable{
  ["ol_ex__huangzhong"] = "界黄忠",
  ["ol_ex__liegong"] = "烈弓",
  [":ol_ex__liegong"] = "①你对至其距离不大于此【杀】点数的角色使用【杀】无距离关系的限制。②当你使用【杀】指定一个目标后，你可执行：1.若其手牌数不大于你，此【杀】不能被此目标抵消；2.若其体力值不小于你，此【杀】对此目标的伤害值基数+1。",

  ["$ol_ex__liegong1"] = "龙骨成镞，矢破苍穹！",
  ["$ol_ex__liegong2"] = "凤翎为羽，箭没坚城！",
  ["~ol_ex__huangzhong"] = "末将，有负主公重托……",
}

local weiyan = General(extension, "ol_ex__weiyan", "shu", 4)
local ol_ex__kuanggu = fk.CreateTriggerSkill{
  name = "ol_ex__kuanggu",
  anim_type = "drawcard",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target == player and (data.extra_data or {}).kuanggucheak
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      self:doCost(event, target, player, data)
      if self.cost_data == "Cancel" then break end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw1", "Cancel"}
    if player:isWounded() then
      table.insert(choices, 2, "recover")
    end
    self.cost_data = room:askForChoice(player, choices, self.name)
    return self.cost_data ~= "Cancel"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "recover" then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    elseif self.cost_data == "draw1" then
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.BeforeHpChanged},
  can_refresh = function(self, event, target, player, data)
    if data.damageEvent and player == data.damageEvent.from and player:distanceTo(target) < 2 then
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.damageEvent.extra_data = data.damageEvent.extra_data or {}
    data.damageEvent.extra_data.kuanggucheak = true
  end,
}
local ol_ex__qimou_targetmod = fk.CreateTargetModSkill{
  name = "#ol_ex__qimou_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@qimou-turn") or 0
    end
  end,
}
local ol_ex__qimou_distance = fk.CreateDistanceSkill{
  name = "#ol_ex__qimou_distance",
  correct_func = function(self, from, to)
    return -from:getMark("@qimou-turn")
  end,
}
local ol_ex__qimou = fk.CreateActiveSkill{
  name = "ol_ex__qimou",
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  interaction = function()
    return UI.Spin {
      from = 1,
      to = Self.hp,
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local tolose = self.interaction.data
    room:loseHp(player, tolose, self.name)
    player:drawCards(tolose, self.name)
    room:setPlayerMark(player, "@qimou-turn", tolose)
  end,
}
ol_ex__qimou:addRelatedSkill(ol_ex__qimou_targetmod)
ol_ex__qimou:addRelatedSkill(ol_ex__qimou_distance)
weiyan:addSkill(ol_ex__kuanggu)
weiyan:addSkill(ol_ex__qimou)
Fk:loadTranslationTable{
  ["ol_ex__weiyan"] = "界魏延",
  ["ol_ex__kuanggu"] = "狂骨",
  [":ol_ex__kuanggu"] = "你对距离1以内的角色造成1点伤害后，你可以选择摸一张牌或回复1点体力。",
  ["ol_ex__qimou"] = "奇谋",
  [":ol_ex__qimou"] = "限定技，出牌阶段，你可以失去X点体力，摸X张牌，本回合内与其他角色计算距离-X且可以多使用X张杀。",
  ["@qimou-turn"] = "奇谋",

  ["$ol_ex__kuanggu1"] = "反骨狂傲，彰显本色！",
  ["$ol_ex__kuanggu2"] = "只有战场，能让我感到兴奋！",
  ["$ol_ex__qimou1"] = "为了胜利，可以出其不意！",
  ["$ol_ex__qimou2"] = "勇战不如奇谋。",
  ["~ol_ex__weiyan"] = "这次失败，意料之中……",
}

local xiaoqiao = General(extension, "ol_ex__xiaoqiao", "wu", 3, 3, General.Female)
local ol_ex__tianxiang = fk.CreateTriggerSkill{
  name = "ol_ex__tianxiang",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target == player
  end,
  on_cost = function(self, event, target, player, data)
    local tar, card =  player.room:askForChooseCardAndPlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
      return p.id end), 1, 1, ".|.|heart|.", "#ol_ex__tianxiang-choose", self.name, true)
    if #tar > 0 and card then
      self.cost_data = {tar[1], card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    local cid = self.cost_data[2]
    room:throwCard(cid, self.name, player, player)

    if to.dead then return true end

    local choices = {"ol_ex__tianxiang_loseHp"}
    if data.from and not data.from.dead then
      table.insert(choices, "ol_ex__tianxiang_damage")
    end
    local choice = room:askForChoice(player, choices, self.name, "#ol_ex__tianxiang-choice::"..to.id)
    if choice == "ol_ex__tianxiang_loseHp" then
      room:loseHp(to, 1, self.name)
      if not to.dead and (room:getCardArea(cid) == Card.DrawPile or room:getCardArea(cid) == Card.DiscardPile) then
        room:obtainCard(to, cid, true, fk.ReasonJustMove)
      end
    else
      room:damage{
        from = data.from,
        to = to,
        damage = 1,
        skillName = self.name,
      }
      if not to.dead then
        to:drawCards(math.min(to:getLostHp(), 5), self.name)
      end
    end
    return true
  end,
}
local ol_ex__hongyan = fk.CreateFilterSkill{
  name = "ol_ex__hongyan",
  card_filter = function(self, to_select, player)
    return to_select.suit == Card.Spade and player:hasSkill(self.name)
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard(to_select.name, Card.Heart, to_select.number)
  end,
}
local ol_ex__hongyan_maxcards = fk.CreateMaxCardsSkill{
  name = "#ol_ex__hongyan_maxcards",
  fixed_func = function (self, player)
    if player:hasSkill("ol_ex__hongyan") and #table.filter(player:getCardIds(Player.Equip), function (id) return Fk:getCardById(id).suit == Card.Heart end) > 0  then
      return player.maxHp
    end
  end,
}
local ol_ex__piaoling = fk.CreateTriggerSkill{
  name = "ol_ex__piaoling",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
      and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|heart",
    }
    room:judge(judge)
  end,
}
local ol_ex__piaoling_delay = fk.CreateTriggerSkill{
  name = "#ol_ex__piaoling_delay",
  events = {fk.FinishJudge},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.suit == Card.Heart and data.reason == ol_ex__piaoling.name
      and player.room:getCardArea(data.card.id) == Card.Processing
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.suit == Card.Heart and room:getCardArea(data.card) == Card.Processing then
      local targets = room:askForChoosePlayers(player, table.map(room.alive_players, function (p)
        return p.id end), 1, 1, "#ol_ex__piaoling-choose", ol_ex__piaoling.name, true)
      if #targets == 0 then
        room:moveCards({
          ids = {data.card.id},
          fromArea = Card.Processing,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = ol_ex__piaoling.name,
        })
      else
        local to = room:getPlayerById(targets[1])
        room:obtainCard(to, data.card, true, fk.ReasonJustMove)
        if to == player and not to.dead then
          room:askForDiscard(to, 1, 1, true, ol_ex__piaoling.name, false, ".", "#ol_ex__piaoling-discard")
        end
      end
    end
  end,
}
ol_ex__hongyan:addRelatedSkill(ol_ex__hongyan_maxcards)
ol_ex__piaoling:addRelatedSkill(ol_ex__piaoling_delay)
xiaoqiao:addSkill(ol_ex__tianxiang)
xiaoqiao:addSkill(ol_ex__hongyan)
xiaoqiao:addSkill(ol_ex__piaoling)
Fk:loadTranslationTable{
  ["ol_ex__xiaoqiao"] = "界小乔",
  ["ol_ex__tianxiang"] = "天香",
  [":ol_ex__tianxiang"] = "当你受到伤害时，你可弃置一张<font color='red'>♥</font>牌并选择一名其他角色。你防止此伤害，选择：1.令来源对其造成1点普通伤害，其摸X张牌（X为其已损失的体力值且至多为5）；2.令其失去1点体力，其获得牌堆或弃牌堆中你以此法弃置的牌。",
  ["ol_ex__hongyan"] = "红颜",
  [":ol_ex__hongyan"] = "锁定技，①你的♠牌视为<font color='red'>♥</font>牌。②若你的装备区里有<font color='red'>♥</font>牌，你的手牌上限初值改为体力上限。",
  ["ol_ex__piaoling"] = "飘零",
  ["#ol_ex__piaoling_delay"] = "飘零",  
  [":ol_ex__piaoling"] = "结束阶段，你可判定，然后当判定结果确定后，若为<font color='red'>♥</font>，你选择：1.将判定牌置于牌堆顶；2.令一名角色获得判定牌，若其为你，你弃置一张牌。",

  ["#ol_ex__tianxiang-choose"] = "天香：弃置一张<font color='red'>♥</font>手牌并选择一名其他角色",
  ["#ol_ex__tianxiang-choice"] = "天香：选择一项令 %dest 执行",
  ["ol_ex__tianxiang_damage"] = "令其受到1点伤害并摸已损失体力值的牌",
  ["ol_ex__tianxiang_loseHp"] = "令其失去1点体力并获得你弃置的牌",
  ["#ol_ex__piaoling-choose"] = "飘零：选择一名角色令其获得判定牌，若其为你，你弃置一张牌，或点取消将判定牌置于牌堆顶",
  ["#ol_ex__piaoling-discard"] = "飘零：弃置1张牌",

  ["$ol_ex__tianxiang1"] = "碧玉闺秀，只可远观。",
  ["$ol_ex__tianxiang2"] = "你岂会懂我的美丽？",
  ["$ol_ex__hongyan1"] = "红颜娇花好，折花门前盼。",
  ["$ol_ex__hongyan2"] = "我的容貌，让你心动了吗？",
  ["$ol_ex__piaoling1"] = "花自飘零水自流。",
  ["$ol_ex__piaoling2"] = "清风拂枝，落花飘零。",
  ["~ol_ex__xiaoqiao"] = "同心而离居，忧伤以终老……",
}

local zhoutai = General(extension, "ol_ex__zhoutai", "wu", 4)
local ol_ex__buqu = fk.CreateTriggerSkill{
  name = "ol_ex__buqu",
  anim_type = "defensive",
  events = {fk.AskForPeaches},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.dying
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local scar_id =room:getNCards(1)[1]
    local scar = Fk:getCardById(scar_id)
    player:addToPile("ol_ex__buqu_scar", scar_id, true, self.name)
    if player.dead or not table.contains(player:getPile("ol_ex__buqu_scar"), scar_id) then return false end
    local success = true
    for _, id in pairs(player:getPile("ol_ex__buqu_scar")) do
      if id ~= scar_id then
        local card = Fk:getCardById(id)
        if (Fk:getCardById(id).number == scar.number) then
          success = false
          break
        end
      end
    end
    if success then
      room:recover({
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = self.name
      })
    else
      room:throwCard(scar:getEffectiveId(), self.name, player) 
    end
  end,
}
local ol_ex__buqu_maxcards = fk.CreateMaxCardsSkill{
  name = "#ol_ex__buqu_maxcards",
  fixed_func = function (self, player)
    if player:hasSkill("ol_ex__buqu") and #player:getPile("ol_ex__buqu_scar") > 0 then
      return #player:getPile("ol_ex__buqu_scar")
    end
  end,
}
local ol_ex__fenji = fk.CreateTriggerSkill{
  name = "ol_ex__fenji",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.hp >= 1 then
      for _, move in ipairs(data) do
        if (move.moveReason == fk.ReasonDiscard or move.moveReason == fk.ReasonPrey) then
          if move.from and move.proposer and move.from ~= move.proposer then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, move in ipairs(data) do
      if not table.contains(targets, move.from) and (move.moveReason == fk.ReasonDiscard or move.moveReason == fk.ReasonPrey) then
        if move.from and move.proposer and move.from ~= move.proposer then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              table.insert(targets, move.from)
              break
            end
          end
        end
      end
    end
    room:sortPlayersByAction(targets)
    for _, target_id in ipairs(targets) do
      if not player:hasSkill(self.name) or player.hp < 1 then break end
      local skill_target = room:getPlayerById(target_id)
      if skill_target and not skill_target.dead then
        self:doCost(event, skill_target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ol_ex__fenji-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {target.id})
    player.room:loseHp(player, 1, self.name)
    if not target.dead then
      target:drawCards(2, self.name)
    end
  end,
}
ol_ex__buqu:addRelatedSkill(ol_ex__buqu_maxcards)
zhoutai:addSkill(ol_ex__buqu)
zhoutai:addSkill(ol_ex__fenji)
Fk:loadTranslationTable{
  ["ol_ex__zhoutai"] = "界周泰",
  ["ol_ex__buqu"] = "不屈",
  [":ol_ex__buqu"] = "锁定技，①当你处于濒死状态时，你将牌堆顶的一张牌置于武将牌上（称为“创”），若：没有与此“创”点数相同的其他“创”，你将体力回复至1点；有与此“创”点数相同的其他“创”，你将此“创”置入弃牌堆。②若有“创”，你的手牌上限初值改为“创”数，",
  ["ol_ex__fenji"] = "奋激",
  [":ol_ex__fenji"] = "当一名角色A因另一名角色B的弃置或获得而失去手牌后，你可失去1点体力，令A摸两张牌。",

  ["ol_ex__buqu_scar"] = "创",
  ["#ol_ex__fenji-invoke"] = "奋激：你可以失去1点体力，令 %dest 摸两张牌",

  ["$ol_ex__buqu1"] = "战如熊虎，不惜躯命！",
  ["$ol_ex__buqu2"] = "哼！这点小伤算什么。",
  ["$ol_ex__fenji1"] = "百战之身，奋勇趋前！",
  ["$ol_ex__fenji2"] = "两肋插刀，愿赴此去！",
  ["~ol_ex__zhoutai"] = "敌众我寡，无力回天……",
}

local zhangjiao = General(extension, "ol_ex__zhangjiao", "qun", 3)
local ol_ex__leiji = fk.CreateTriggerSkill{
  name = "ol_ex__leiji",
  anim_type = "offensive",
  events = {fk.AfterCardUseDeclared, fk.CardResponding, fk.FinishJudge},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target == player then
      if event == fk.AfterCardUseDeclared or event == fk.CardResponding then
        return data.card.name == "jink" or data.card.name == "lightning"
      elseif event == fk.FinishJudge then
        return data.card.color == Card.Black
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared or event == fk.CardResponding then
      return player.room:askForSkillInvoke(player, self.name)
    elseif event == fk.FinishJudge then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared or event == fk.CardResponding then
      local judge = {
        who = player,
        reason = self.name,
      }
      room:judge(judge)
    elseif event == fk.FinishJudge then
      local x = 2
      if data.card.suit == Card.Club then
        x = 1
        if player:isWounded() then
          room:recover({
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name,
          })
        end
        if player.dead then return false end
      end
      local targets = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
        return p.id end), 1, 1, "#ol_ex__leiji-choose:::" .. x, self.name, true)
       if #targets > 0 then
          local tar = targets[1]
          room:damage{
            from = player,
            to = room:getPlayerById(tar),
            damage = x,
            damageType = fk.ThunderDamage,
            skillName = self.name,
          }
       end
    end
end,
}
local ol_ex__guidao = fk.CreateTriggerSkill{
  name = "ol_ex__guidao",
  anim_type = "control",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForResponse(player, self.name, ".|.|spade,club|hand,equip", "#guidao-ask::" .. target.id, true)
    if card ~= nil then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(self.cost_data, player, data, self.name, true)
    if not player.dead and self.cost_data.suit == Card.Spade and self.cost_data.number > 1 and self.cost_data.number < 10 then
      player:drawCards(1, self.name)
    end
  end,
}
zhangjiao:addSkill(ol_ex__leiji)
zhangjiao:addSkill(ol_ex__guidao)
Fk:loadTranslationTable{
  ["ol_ex__zhangjiao"] = "界张角",
  ["ol_ex__leiji"] = "雷击",
  [":ol_ex__leiji"] = "①当你使用或打出【闪】或【闪电】时，你可判定。②当你的判定结果确定后，若结果为：黑桃，你可对一名其他角色造成2点雷电伤害；梅花，你回复1点体力，然后你可对一名其他角色造成1点雷电伤害。",
  ["ol_ex__guidao"] = "鬼道",
  [":ol_ex__guidao"] = "当一名角色的判定结果确定前，你可打出一张黑色牌代替之，你获得原判定牌，若你打出的牌是黑桃2~9，你摸一张牌。",
  ["#ol_ex__leiji-choose"] = "雷击：你可以选择一名其他角色，对其造成%arg点雷电伤害",
  ["#guidao-ask"] = "鬼道：你可以打出一张黑色牌替换 %dest 的判定，若打出的牌是黑桃2~9，你摸一张牌。",

  ["$ol_ex__leiji1"] = "疾雷迅电，不可趋避！",
  ["$ol_ex__leiji2"] = "雷霆之诛，灭军毁城！",
  ["$ol_ex__guidao1"] = "鬼道运行，由我把控！",
  ["$ol_ex__guidao2"] = "汝之命运，吾来改之！",
  ["$ol_ex__huangtian1"] = "黄天法力，万军可灭！",
  ["$ol_ex__huangtian2"] = "天书庇佑，黄巾可兴！",
  ["~ol_ex__zhangjiao"] = "天书无效，人心难聚……",
}

local ol_ex__qiangxi = fk.CreateActiveSkill{
  name = "ol_ex__qiangxi",
  anim_type = "offensive",
  prompt = "#ol_ex__qiangxi",
  max_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) < 2
  end,
  card_filter = function(self, to_select, selected)
    return Fk:getCardById(to_select).sub_type == Card.SubtypeWeapon
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local qiangxiRecorded = type(Self:getMark("ol_ex__qiangxi_targets-phase")) == "table" and Self:getMark("ol_ex__qiangxi_targets-phase") or {}
      return not table.contains(qiangxiRecorded, to_select)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local qiangxiRecorded = type(player:getMark("ol_ex__qiangxi_targets-phase")) == "table" and player:getMark("ol_ex__qiangxi_targets-phase") or {}
    table.insertIfNeed(qiangxiRecorded, target.id)
    room:setPlayerMark(player, "ol_ex__qiangxi_targets-phase", qiangxiRecorded)
    if #effect.cards > 0 then
      room:throwCard(effect.cards, self.name, player)
    else
      room:damage{
        to = player,
        damage = 1,
        skillName = self.name,
      }
    end
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
local ol_ex__ninge = fk.CreateTriggerSkill{
  name = "ol_ex__ninge",
  anim_type = "control",
  events = {fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and (target == player or data.from == player)  then
      return (data.extra_data or {}).secondDamageInTurn
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, { target.id })
    player:drawCards(1, self.name)
    if not player.dead and not target.dead and #target:getCardIds{Player.Judge, Player.Equip} > 0 then
      local id = room:askForCardChosen(player, target, "ej", self.name)
      room:throwCard({id}, self.name, target, player)
    end
  end,

  refresh_events = {fk.BeforeHpChanged},
  can_refresh = function(self, event, target, player, data)
    if data.damageEvent and player == target then
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "ol_ex__ninge-turn", 1)
    if player:getMark("ol_ex__ninge-turn") == 2 then
      data.damageEvent.extra_data = data.damageEvent.extra_data or {}
      data.damageEvent.extra_data.secondDamageInTurn = true
    end
  end,
}

local dianwei = General(extension, "ol_ex__dianwei", "wei", 4)
dianwei:addSkill(ol_ex__qiangxi)
dianwei:addSkill(ol_ex__ninge)

Fk:loadTranslationTable{
  ["ol_ex__dianwei"] = "界典韦",
  ["ol_ex__qiangxi"] = "强袭",
  [":ol_ex__qiangxi"] = "出牌阶段限两次，你可受到1点普通伤害或弃置一张武器牌并选择一名于此阶段内未选择过的其他角色，你对其造成1点普通伤害。",
  ["ol_ex__ninge"] = "狞恶",
  [":ol_ex__ninge"] = "锁定技，当一名角色于当前回合内第二次受到伤害后，若其为你或来源为你，你摸一张牌，弃置其装备区或判定区里的一张牌。",

  ["#ol_ex__qiangxi"] = "选择一张武器牌或不选（受到1点伤害），并选择强袭的目标",

  ["$ol_ex__qiangxi1"] = "典韦来也，谁敢一战！",
  ["$ol_ex__qiangxi2"] = "双戟青罡，百死无生！",
  ["$ol_ex__ninge1"] = "古之恶来，今之典韦！",
  ["$ol_ex__ninge2"] = "宁为刀俎，不为鱼肉！",
  ["~ol_ex__dianwei"] = "为将者，怎可徒手而亡？",
}

local xunyu = General(extension, "ol_ex__xunyu", "wei", 3)
local ol_ex__jieming = fk.CreateTriggerSkill{
  name = "ol_ex__jieming",
  anim_type = "masochism",
  events = {fk.Damaged, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.Damaged then
        return player:hasSkill(self.name)
      elseif event == fk.Death then
        return player:hasSkill(self.name, false, true)
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    if event == fk.Damaged then
      self.cancel_cost = false
      for i = 1, data.damage do
        if self.cancel_cost then break end
        self:doCost(event, target, player, data)
      end
    elseif event == fk.Death then
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function (p)
      return p.id end), 1, 1, "#ol_ex__jieming-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local to = player.room:getPlayerById(self.cost_data)
    to:drawCards(math.min(to.maxHp, 5), self.name)
    if to.dead then return false end
    local x = #to.player_cards[Player.Hand] - math.min(to.maxHp, 5)
    if x > 0 then
      player.room:askForDiscard(to, x, x, false, self.name, false, ".", "#ol_ex__jieming-discard:::"..x)
    end
  end,
}
xunyu:addSkill("quhu")
xunyu:addSkill(ol_ex__jieming)
Fk:loadTranslationTable{
  ["ol_ex__xunyu"] = "界荀彧",
  ["ol_ex__jieming"] = "节命",
  [":ol_ex__jieming"] = "当你受到1点伤害后或当你死亡时，你可令一名角色摸X张牌，其将手牌弃置至X张。（X为其体力上限且至多为5）",
  ["#ol_ex__jieming-choose"] = "节命：你可以令一名角色摸X张牌并将手牌弃至X张（X为其体力上限且至多为5）",
  ["#ol_ex__jieming-discard"] = "节命：选择%arg张手牌弃置",

  ["$ol_ex__quhu1"] = "两虎相斗，旁观成败。",
  ["$ol_ex__quhu2"] = "驱兽相争，坐收渔利。",
  ["$ol_ex__jieming1"] = "含气在胸，有进无退。",
  ["$ol_ex__jieming2"] = "蕴节于形，生死无惧。",
  ["~ol_ex__xunyu"] = "一招不慎，为虎所噬……",
}

local ol_ex__jianchu = fk.CreateTriggerSkill{
  name = "ol_ex__jianchu",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self.name)) then return end
    local to = player.room:getPlayerById(data.to)
    return data.card.trueName == "slash" and not to:isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    if to:isNude() then return end
    local id = room:askForCardChosen(player, to, "he", self.name)
    room:throwCard({id}, self.name, to, player)
    local card = Fk:getCardById(id)
    if card.type == Card.TypeBasic then
      if not to.dead then
        local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
        if table.every(cardlist, function(id) return room:getCardArea(id) == Card.Processing end) then
          room:obtainCard(to.id, data.card, false)
        end
      end
    else
      room:addPlayerMark(player, "ol_ex__jianchu_slash-phase", 1)
      data.disresponsive = true
    end
  end,
}
local ol_ex__jianchu_targetmod = fk.CreateTargetModSkill{
  name = "#ol_ex__jianchu_targetmod",
  residue_func = function(self, player, skill, scope, card)
    return (skill.trueName == "slash_skill" and scope == Player.HistoryPhase) and player:getMark("ol_ex__jianchu_slash-phase") or 0
  end,
}
local pangde = General(extension, "ol_ex__pangde", "qun", 4)
pangde:addSkill("mashu")
ol_ex__jianchu:addRelatedSkill(ol_ex__jianchu_targetmod)
pangde:addSkill(ol_ex__jianchu)
Fk:loadTranslationTable{
  ["ol_ex__pangde"] = "界庞德",
  ["ol_ex__jianchu"] = "鞬出",
  [":ol_ex__jianchu"] = "当你使用【杀】指定一个目标后，你可弃置其一张牌，若此牌：为基本牌，其获得此【杀】；不为基本牌，此【杀】不能被此目标抵消，你于此阶段内使用【杀】的次数上限+1。",

  ["$ol_ex__jianchu1"] = "你这身躯，怎么能快过我？",
  ["$ol_ex__jianchu2"] = "这些怎么能挡住我的威力！",
  ["~ol_ex__pangde"] = "人亡马倒，命之所归……",
}

local ol_ex__shuangxiong_trigger = fk.CreateTriggerSkill{
  name = "#ol_ex__shuangxiong_trigger",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd, fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill("ol_ex__shuangxiong") then
      if event == fk.EventPhaseEnd then
        return player.phase == Player.Draw and not player:isNude()
      elseif event == fk.EventPhaseStart and player.phase == Player.Finish then
        local damageRecorded = type(player:getMark("ol_ex__shuangxiong_damage-turn")) == "table" and player:getMark("ol_ex__shuangxiong_damage-turn") or {}
        return table.find(damageRecorded, function(id)
          return player.room:getCardArea(id) == Card.DiscardPile
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      local cards = player.room:askForDiscard(player, 1, 1, true, "ol_ex__shuangxiong", true, ".", "#ol_ex__shuangxiong-discard", true)
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    elseif event == fk.EventPhaseStart then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("ol_ex__shuangxiong")
    room:notifySkillInvoked(player, "ol_ex__shuangxiong")
    if event == fk.EventPhaseEnd then
      local color = Fk:getCardById(self.cost_data[1]):getColorString()
      room:throwCard(self.cost_data, self.name, player, player)
      local colorsRecorded = type(player:getMark("@ol_ex__shuangxiong-turn")) == "table" and player:getMark("@ol_ex__shuangxiong-turn") or {}
      table.insertIfNeed(colorsRecorded, color)
      room:setPlayerMark(player, "@ol_ex__shuangxiong-turn", colorsRecorded)
    elseif event == fk.EventPhaseStart then
      local damageRecorded = type(player:getMark("ol_ex__shuangxiong_damage-turn")) == "table" and player:getMark("ol_ex__shuangxiong_damage-turn") or {}
      local dummy = Fk:cloneCard("dilu")
      table.forEach(damageRecorded, function(id)
        if room:getCardArea(id) == Card.DiscardPile then
          dummy:addSubcard(id)
        end
      end)
      if #dummy.subcards > 0 then
        room:obtainCard(player, dummy, true, fk.ReasonJustMove)
      end
    end
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    if target == player and player.phase ~= Player.NotActive and data.card ~= nil then
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local damageRecorded = type(player:getMark("ol_ex__shuangxiong_damage-turn")) == "table" and player:getMark("ol_ex__shuangxiong_damage-turn") or {}
    local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
    table.forEach(cardlist, function(id)
      table.insertIfNeed(damageRecorded, id)
    end)
    room:setPlayerMark(player, "ol_ex__shuangxiong_damage-turn", damageRecorded)
  end,
}
local ol_ex__shuangxiong = fk.CreateViewAsSkill{
  name = "ol_ex__shuangxiong",
  anim_type = "offensive",
  pattern = "duel",
  card_filter = function(self, to_select, selected)
    if #selected == 1 or type(Self:getMark("@ol_ex__shuangxiong-turn")) ~= "table" then return false end
    local color = Fk:getCardById(to_select):getColorString()
    if color == "red" then
      color = "black"
    elseif color == "black" then
      color = "red"
    else
      return false
    end
    return table.contains(Self:getMark("@ol_ex__shuangxiong-turn"), color)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end

    local c = Fk:cloneCard("duel")
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return type(player:getMark("@ol_ex__shuangxiong-turn")) == "table"
  end,
  enabled_at_response = function(self, player)
    return type(player:getMark("@ol_ex__shuangxiong-turn")) == "table"
  end,
}
ol_ex__shuangxiong:addRelatedSkill(ol_ex__shuangxiong_trigger)
local yanliangwenchou = General(extension, "ol_ex__yanliangwenchou", "qun", 4)
yanliangwenchou:addSkill(ol_ex__shuangxiong)
Fk:loadTranslationTable{
  ["ol_ex__yanliangwenchou"] = "界颜良文丑",
  ["ol_ex__shuangxiong"] = "双雄",
  ["#ol_ex__shuangxiong_trigger"] = "双雄",
  [":ol_ex__shuangxiong"] = "①摸牌阶段结束时，你可弃置一张牌，你于此回合内可以将一张与此牌颜色不同的牌转化为【决斗】使用。②（你记录所有于回合内对你造成过伤害的牌直到回合结束）结束阶段，你获得弃牌堆中你记录的牌。",

  ["@ol_ex__shuangxiong-turn"] = "双雄",
  ["#ol_ex__shuangxiong-discard"] = "双雄：你可以弃置一张牌，本回合可以将不同颜色的牌当【决斗】使用",

  ["$ol_ex__shuangxiong1"] = "吾执矛，君执槊，此天下可有挡我者？",
  ["$ol_ex__shuangxiong2"] = "兄弟协力，定可于乱世纵横！",
  ["~ol_ex__yanliangwenchou"] = "双雄皆陨，徒隆武圣之名……",
}

local ol_ex__luanji = fk.CreateViewAsSkill{
  name = "ol_ex__luanji",
  anim_type = "offensive",
  pattern = "archery_attack",
  card_filter = function(self, to_select, selected)
    if #selected == 1 then 
      return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip and Fk:getCardById(to_select).suit == Fk:getCardById(selected[1]).suit
    elseif #selected == 2 then
      return false
    end
    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 2 then
      return nil
    end
    local c = Fk:cloneCard("archery_attack")
    c:addSubcards(cards)
    return c
  end,
}
local ol_ex__luanji_trigger = fk.CreateTriggerSkill{
  name = "#ol_ex__luanji_trigger",
  anim_type = "control",
  events = {fk.AfterCardTargetDeclared},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("ol_ex__luanji") and data.card.name == "archery_attack" and #data.tos > 0
  end,
  on_cost = function(self, event, target, player, data)
    if #data.tos == 0 then return false end
    local tos = player.room:askForChoosePlayers(player, TargetGroup:getRealTargets(data.tos), 1, 1, "#ol_ex__luanji-choose", "ol_ex__luanji", true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("ol_ex__luanji")
    room:notifySkillInvoked(player, "ol_ex__luanji", "control")
    TargetGroup:removeTarget(data.tos, self.cost_data)
  end,
}
local ol_ex__xueyi = fk.CreateTriggerSkill{
  name = "ol_ex__xueyi$",
  events = {fk.GameStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        for _, p in ipairs(player.room.alive_players) do
          if p.kingdom == "qun" then
            return true
          end
        end
      elseif event == fk.EventPhaseStart and player.phase == Player.Play and player:getMark("@ol_ex__xueyi_yi") > 0 then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    elseif event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local x = #table.filter(room.alive_players, function (p) return p.kingdom == "qun" end)
      if x > 0 then
        room:addPlayerMark(player, "@ol_ex__xueyi_yi", x*2)
      end
    elseif event == fk.EventPhaseStart then
      room:removePlayerMark(player, "@ol_ex__xueyi_yi")
      player:drawCards(1, self.name)
    end
  end,
}
local ol_ex__xueyi_maxcards = fk.CreateMaxCardsSkill{
  name = "#ol_ex__xueyi_maxcards",
  correct_func = function(self, player)
    if player:hasSkill("ol_ex__xueyi") then
      return player:getMark("@ol_ex__xueyi_yi")
    else
      return 0
    end
  end,
}
ol_ex__luanji:addRelatedSkill(ol_ex__luanji_trigger)
ol_ex__xueyi:addRelatedSkill(ol_ex__xueyi_maxcards)
local yuanshao = General:new(extension, "ol_ex__yuanshao", "qun", 4)
yuanshao:addSkill(ol_ex__luanji)
yuanshao:addSkill(ol_ex__xueyi)
Fk:loadTranslationTable{
  ["ol_ex__yuanshao"] = "界袁绍",
  ["ol_ex__luanji"] = "乱击",
  [":ol_ex__luanji"] = "①出牌阶段，你可以将两张花色相同的手牌转化为【万箭齐发】使用。②当你使用【万箭齐发】选择目标后，你可取消其中一个目标。",
  ["ol_ex__xueyi"] = "血裔",
  [":ol_ex__xueyi"] = "主公技，①游戏开始时，你获得2X枚“裔”（X为群势力角色数）。②出牌阶段开始时，你可弃1枚“裔”，你摸一张牌。③你的手牌上限+X（X为“裔”数）",

  ["#ol_ex__luanji-choose"] = "乱击：你可以为此【万箭齐发】减少一个目标",
  ["@ol_ex__xueyi_yi"] = "裔",

  ["$ol_ex__luanji1"] = "我的箭支，准备颇多！",
  ["$ol_ex__luanji2"] = "谁都挡不住，我的箭阵！",
  ["$ol_ex__xueyi1"] = "高贵名门，族裔盛名。",
  ["$ol_ex__xueyi2"] = "贵裔之脉，后起之秀！",
  ["~ol_ex__yuanshao"] = "孟德此计，防不胜防……",
}

local ol_ex__duanliang = fk.CreateViewAsSkill{
  name = "ol_ex__duanliang",
  anim_type = "control",
  pattern = "supply_shortage",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black and Fk:getCardById(to_select).type ~= Card.TypeTrick
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("supply_shortage")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
}
local ol_ex__duanliang_refresh = fk.CreateTriggerSkill{
  name = "#ol_ex__duanliang_refresh",
  anim_type = "control",
  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "ol_ex__duanliang_damage-turn", data.damage)
  end,
}
local ol_ex__duanliang_targetmod = fk.CreateTargetModSkill{
  name = "#ol_ex__duanliang_targetmod",
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(ol_ex__duanliang.name) and skill.name == "supply_shortage_skill" and
    player:getMark("ol_ex__duanliang_damage-turn") == 0
  end,
}
local ol_ex__jiezi = fk.CreateTriggerSkill{
  name = "ol_ex__jiezi",
  anim_type = "support",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player ~= target and target and target.skipped_phases[Player.Draw] and
        player:usedSkillTimes(self.name, Player.HistoryTurn) < 1 then
      return data.to == Player.Play or data.to == Player.Discard or data.to == Player.Finish
    end
  end,
  on_cost = function(self, event, target, player, data)
    local result = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, function (p)
      return p.id end), 1, 1, "#ol_ex__jiezi-choose", self.name, true)
    if #result == 1 then
      self.cost_data = result[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if to:getMark("@@ol_ex__jiezi_zi") == 0 and table.every(player.room.alive_players, function (p)
        return #p:getCardIds(Player.Hand) >= #to:getCardIds(Player.Hand)
      end) then
      room:addPlayerMark(to, "@@ol_ex__jiezi_zi")
    else
      to:drawCards(1, self.name)
    end
  end,
}
local ol_ex__jiezi_delay = fk.CreateTriggerSkill{
  name = "#ol_ex__jiezi_delay",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Draw and player:getMark("@@ol_ex__jiezi_zi") > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, ol_ex__jiezi.name, "support")
    player.room:setPlayerMark(player, "@@ol_ex__jiezi_zi", 0)
    player:gainAnExtraPhase(Player.Draw)
  end,
}
ol_ex__duanliang:addRelatedSkill(ol_ex__duanliang_refresh)
ol_ex__duanliang:addRelatedSkill(ol_ex__duanliang_targetmod)
ol_ex__jiezi:addRelatedSkill(ol_ex__jiezi_delay)
local xuhuang = General(extension, "ol_ex__xuhuang", "wei", 4)
xuhuang:addSkill(ol_ex__duanliang)
xuhuang:addSkill(ol_ex__jiezi)
Fk:loadTranslationTable{
  ["ol_ex__xuhuang"] = "界徐晃",
  ["ol_ex__duanliang"] = "断粮",
  [":ol_ex__duanliang"] = "①你可将一张不为锦囊牌的黑色牌转化为【兵粮寸断】使用。②若你于当前回合内未造成过伤害，你使用【兵粮寸断】无距离关系的限制。",
  ["ol_ex__jiezi"] = "截辎",
  ["#ol_ex__jiezi_delay"] = "截辎",
  [":ol_ex__jiezi"] = "其他角色的出牌阶段、弃牌阶段或结束阶段开始前，若其跳过过摸牌阶段且你于此回合内未发动过此技能，你可选择一名角色，若其手牌数为全场最少且没有“辎”，其获得1枚“辎”；否则其摸一张牌。当有“辎”的角色的摸牌阶段结束时，其弃所有“辎”，获得一个额外摸牌阶段。",

  ["@@ol_ex__jiezi_zi"] = "辎",
  ["#ol_ex__jiezi-choose"] = "截辎：选择一名角色，令其获得“辎”标记或摸一张牌",
  ["$ol_ex__duanliang1"] = "兵行无常，计行断粮。",
  ["$ol_ex__duanliang2"] = "焚其粮营，断其粮道。",
  ["$ol_ex__jiezi1"] = "剪径截辎，馈泽同袍。",
  ["$ol_ex__jiezi2"] = "截敌粮草，以资袍泽。",
  ["~ol_ex__xuhuang"] = "亚夫易老，李广难封……",
}

local ol_ex__changbiao = fk.CreateViewAsSkill{
  name = "ol_ex__changbiao",
  anim_type = "offensive",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards < 1 then
      return nil
    end
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    c:addSubcards(cards)
    return c
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  enabled_at_response = function() return false end,
  before_use = function(self, player, useData)
    useData.extra_data = useData.extra_data or {}
    useData.extra_data.ol_ex__changbiaoUser = player.id
  end,
}
local ol_ex__changbiao_trigger = fk.CreateTriggerSkill{
  name = "#ol_ex__changbiao_trigger",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@ol_ex__changbiao_draw-phase") > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "ol_ex__changbiao", "drawcard")
    player:drawCards(player:getMark("@ol_ex__changbiao_draw-phase"), "ol_ex__changbiao")
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return (data.extra_data or {}).ol_ex__changbiaoUser == player.id and data.damageDealt
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@ol_ex__changbiao_draw-phase", #data.card.subcards)
  end,
}
local ol_ex__changbiao_targetmod = fk.CreateTargetModSkill{
  name = "#ol_ex__changbiao_targetmod",
  bypass_distances =  function(self, player, skill, card, to)
    return table.contains(card.skillNames, ol_ex__changbiao.name)
  end,
}
ol_ex__changbiao:addRelatedSkill(ol_ex__changbiao_trigger)
ol_ex__changbiao:addRelatedSkill(ol_ex__changbiao_targetmod)
local zhurong = General(extension, "ol_ex__zhurong", "shu", 4, 4, General.Female)
zhurong:addSkill("juxiang")
zhurong:addSkill("lieren")
zhurong:addSkill(ol_ex__changbiao)

Fk:loadTranslationTable{
  ["ol_ex__zhurong"] = "界祝融",
  ["ol_ex__changbiao"] = "长标",
  ["#ol_ex__changbiao_trigger"] = "长标",
  [":ol_ex__changbiao"] = "出牌阶段限一次，你可将至少一张手牌转化为普【杀】使用（无距离关系的限制），此阶段结束时，若此【杀】造成过伤害，你摸x张牌（X为以此法转化的牌数）。",

  ["@ol_ex__changbiao_draw-phase"] = "长标",

  ["$ol_ex__juxiang1"] = "南兵象阵，刀枪不入！",
  ["$ol_ex__juxiang2"] = "巨象冲锋，踏平敌阵！",
  ["$ol_ex__lieren1"] = "烈火飞刃，例无虚发！",
  ["$ol_ex__lieren2"] = "烈刃一出，谁与争锋？",
  ["$ol_ex__changbiao1"] = "长标如虹，以伐蜀汉！",
  ["$ol_ex__changbiao2"] = "长标在此，谁敢拦我？",
  ["~ol_ex__zhurong"] = "这汉人，竟……如此厉害……",
}

local ol_ex__zaiqi = fk.CreateTriggerSkill{
  name = "ol_ex__zaiqi",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Discard then
      local ids = player:getMark("ol_ex__zaiqi_record-turn")
      if type(ids) ~= "table" then return false end
      for _, id in ipairs(ids) do
        if player.room:getCardArea(id) == Card.DiscardPile and Fk:getCardById(id).color == Card.Red then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local x = 0
    local ids = player:getMark("ol_ex__zaiqi_record-turn")
    if type(ids) ~= "table" then return false end
    for _, id in ipairs(ids) do
      if player.room:getCardArea(id) == Card.DiscardPile and Fk:getCardById(id).color == Card.Red then
        x = x + 1
      end
    end
    if x < 1 then return false end
    local result = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, function (p)
      return p.id end), 1, x, "#ol_ex__zaiqi-choose:::"..x, self.name, true)
    if #result > 0 then
      self.cost_data = result
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:sortPlayersByAction(self.cost_data)
    local targets = table.map(self.cost_data, function(id)
      return room:getPlayerById(id) end)

      for _, p in ipairs(targets) do
      if not p.dead then
        local choices = {"ol_ex__zaiqi_draw"}
        if player and not player.dead and player:isWounded() then
          table.insert(choices, "ol_ex__zaiqi_recover")
        end
        local choice = room:askForChoice(p, choices, self.name, "#ol_ex__zaiqi-choice:"..player.id)
        if choice == "ol_ex__zaiqi_draw" then
          p:drawCards(1, self.name)
        else
          room:recover({
            who = player,
            num = 1,
            recoverBy = p,
            skillName = self.name
          })
        end
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player.phase ~= Player.NotActive then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("ol_ex__zaiqi_record-turn")
    if mark == 0 then mark = {} end
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(mark, info.cardId)
        end
      end
    end
    player.room:setPlayerMark(player, "ol_ex__zaiqi_record-turn", mark)
  end,
}
--[[
local menghuo = General(extension, "ol_ex__menghuo", "shu", 4)
menghuo:addSkill("huoshou")
menghuo:addSkill(ol_ex__zaiqi)
]]

Fk:loadTranslationTable{
  ["ol_ex__menghuo"] = "界孟获",
  ["ol_ex__zaiqi"] = "再起",
  [":ol_ex__zaiqi"] = "弃牌阶段结束时，你可选择至多X名角色（X为弃牌堆里于此回合内移至此区域的红色牌数），这些角色各选择：1.令你回复1点体力；2.摸一张牌。",

  ["#ol_ex__zaiqi-choose"] = "再起：选择至多%arg名角色，这些角色各选择令你回复1点体力或摸一张牌",
  ["#ol_ex__zaiqi-choice"] = "再起：选择摸一张牌或令%src回复1点体力",
  ["ol_ex__zaiqi_draw"] = "摸一张牌",
  ["ol_ex__zaiqi_recover"] = "令其回复体力",

  ["$ol_ex__huoshou1"] = "坐据三山，蛮霸四野！",
  ["$ol_ex__huoshou2"] = "啸据哀牢，闻祸而喜！",
  ["$ol_ex__zaiqi1"] = "挫而弥坚，战而弥勇！",
  ["$ol_ex__zaiqi2"] = "蛮人骨硬，其势复来！",
  ["~ol_ex__menghuo"] = "勿再放我，但求速死！",
}

local ol_ex__wulie = fk.CreateTriggerSkill{
  name = "ol_ex__wulie",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and
      player:usedSkillTimes(self.name, Player.HistoryGame) < 1 and player.hp > 0
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, function (p)
      return p.id end), 1, player.hp, "#ol_ex__wulie-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, #self.cost_data, self.name)
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      if not p.dead then
        room:addPlayerMark(p, "@@ol_ex__wulie_lie")
      end
    end
  end,
}
local ol_ex__wulie_delay = fk.CreateTriggerSkill{
  name = "#ol_ex__wulie_delay",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@ol_ex__wulie_lie") > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, "ol_ex__wulie", "defensive")
    player.room:setPlayerMark(player, "@@ol_ex__wulie_lie", 0)
    return true
  end,
}
ol_ex__wulie:addRelatedSkill(ol_ex__wulie_delay)
local sunjian = General(extension, "ol_ex__sunjian", "wu", 4, 5)
sunjian:addSkill("yinghun")
sunjian:addSkill(ol_ex__wulie)

Fk:loadTranslationTable{
  ["ol_ex__sunjian"] = "界孙坚",
  ["ol_ex__wulie"] = "武烈",
  ["#ol_ex__wulie_delay"] = "武烈",
  [":ol_ex__wulie"] = "限定技，结束阶段，你可失去任意点体力并选择等量的角色，这些角色各获得1枚“烈”。当有“烈”的角色受到伤害时，其弃所有“烈”，防止此伤害。",

  ["@@ol_ex__wulie_lie"] = "烈",
  ["#ol_ex__wulie-choose"] = "武烈：选择任意名角色并失去等量的体力，防止这些角色受到的下次伤害",

  ["$ol_ex__yinghun1"] = "提刀奔走，灭敌不休。",
  ["$ol_ex__yinghun2"] = "贼寇草莽，我且出战。",
  ["$ol_ex__wulie1"] = "孙武之后，英烈勇战。",
  ["$ol_ex__wulie2"] = "兴义之中，忠烈之名。",
  ["~ol_ex__sunjian"] = "袁术之辈，不可共谋！",
}

local ol_ex__haoshi = fk.CreateTriggerSkill{
  name = "ol_ex__haoshi",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
}
local ol_ex__haoshi_active = fk.CreateActiveSkill{
  name = "#ol_ex__haoshi_active",
  anim_type = "support",
  target_num = 1,
  card_num = function ()
    return Self:getHandcardNum() // 2
  end,
  card_filter = function(self, to_select, selected)
    return #selected < self.card_num() and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    local room = Fk:currentRoom()
    local target = room:getPlayerById(to_select)
    return #selected == 0 and target ~= Self and table.every(room.alive_players, function(p)
      return target:getHandcardNum() <= p:getHandcardNum() or p == Self
    end)
  end,
}
local ol_ex__haoshi_delay = fk.CreateTriggerSkill{
  name = "#ol_ex__haoshi_delay",
  events = {fk.EventPhaseEnd, fk.TargetConfirmed},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    if event == fk.EventPhaseEnd and player:usedSkillTimes(ol_ex__haoshi.name, Player.HistoryPhase) > 0 then
      return #player.player_cards[Player.Hand] > 5
    elseif event == fk.TargetConfirmed and player == target and type(player:getMark("ol_ex__haoshi_target")) == "table" then
      if data.card.trueName == "slash" or data.card:isCommonTrick() then
        local targetRecorded = player:getMark("ol_ex__haoshi_target")
        return table.find(targetRecorded, function (pid)
          local p = player.room:getPlayerById(pid)
          return p and p ~= player and not p:isKongcheng()
        end)
      end
    end
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, ol_ex__haoshi.name, "support")
    if event == fk.EventPhaseEnd and not player:isKongcheng() then
      local x = player:getHandcardNum() // 2
      local to_give = table.random(player.player_cards[Player.Hand], x)
      local other_players = room:getOtherPlayers(player)
      local target = table.find(other_players, function (p1)
        return table.every(other_players, function (p2)
          return p2:getHandcardNum() >= p1:getHandcardNum()
        end)
      end)
      if target and #to_give > 0 then
        local _, ret = room:askForUseActiveSkill(player, "#ol_ex__haoshi_active",
          "#ol_ex__haoshi-give:::" .. x, false)
        if ret and #ret.cards == x and #ret.targets == 1 then
          to_give = ret.cards
          target = room:getPlayerById(ret.targets[1])
        end
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(to_give)
        room:obtainCard(target, dummy, false, fk.ReasonGive)
        local targetRecorded = type(player:getMark("ol_ex__haoshi_target")) == "table" and player:getMark("ol_ex__haoshi_target") or {}
        table.insert(targetRecorded, target.id)
        room:setPlayerMark(player, "ol_ex__haoshi_target", targetRecorded)
      end
    elseif event == fk.TargetConfirmed then
      local targetRecorded = player:getMark("ol_ex__haoshi_target")
      room:doIndicate(player.id, targetRecorded)
      room:sortPlayersByAction(targetRecorded)
      table.forEach(targetRecorded, function (pid)
        local p = room:getPlayerById(pid)
        if p and not player.dead and not p.dead and p ~= player and not p:isKongcheng() then
          local card = room:askForCard(p, 1, 1, true, ol_ex__haoshi.name, true, ".|.|.|hand", "#ol_ex__haoshi-regive:"..player.id)
          if #card > 0 then
            room:obtainCard(player, card[1], false, fk.ReasonGive)
          end
        end
      end)
    end
  end,
  
  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return player == target and data.from == Player.RoundStart and type(player:getMark("ol_ex__haoshi_target")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "ol_ex__haoshi_target", 0)
  end,
}
local ol_ex__dimeng = fk.CreateActiveSkill{
  name = "ol_ex__dimeng",
  anim_type = "control",
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected)
    if to_select == Self.id or #selected > 1 then return false end
    if #selected == 0 then
      return true
    else
      local target1 = Fk:currentRoom():getPlayerById(to_select)
      local target2 = Fk:currentRoom():getPlayerById(selected[1])
      if target1:isKongcheng() and #target2:isKongcheng() then
        return false
      end
      return math.abs(#target1.player_cards[Player.Hand] - #target2.player_cards[Player.Hand]) <= #Self:getCardIds({Player.Hand, Player.Equip})
    end
  end,
  on_use = function(self, room, effect)
    local cards1 = table.clone(room:getPlayerById(effect.tos[1]).player_cards[Player.Hand])
    local cards2 = table.clone(room:getPlayerById(effect.tos[2]).player_cards[Player.Hand])
    local move1 = {
      from = effect.tos[1],
      ids = cards1,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = effect.from,
      skillName = self.name,
    }
    local move2 = {
      from = effect.tos[2],
      ids = cards2,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = effect.from,
      skillName = self.name,
    }
    room:moveCards(move1, move2)
    local move3 = {
      ids = table.filter(cards1, function (id)
        return room:getCardArea(id) == Card.Processing
      end),
      fromArea = Card.Processing,
      to = effect.tos[2],
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      proposer = effect.from,
      skillName = self.name,
    }
    local move4 = {
      ids = table.filter(cards2, function (id)
        return room:getCardArea(id) == Card.Processing
      end),
      fromArea = Card.Processing,
      to = effect.tos[1],
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      proposer = effect.from,
      skillName = self.name,
    }
    room:moveCards(move3, move4)
    local player = room:getPlayerById(effect.from)
    local targetRecorded = type(player:getMark("ol_ex__dimeng_target-phase")) == "table" and player:getMark("ol_ex__dimeng_target-phase") or {}
    table.insert(targetRecorded, effect.tos)
    room:setPlayerMark(player, "ol_ex__dimeng_target-phase", targetRecorded)
  end,
}
local ol_ex__dimeng_delay = fk.CreateTriggerSkill{
  name = "#ol_ex__dimeng_delay",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead and player:usedSkillTimes(ol_ex__dimeng.name, Player.HistoryPhase) > 0 and not player:isNude() then
      local mark = player:getMark("ol_ex__dimeng_target-phase")
      if type(mark) ~= "table" then return false end
      for _, tos in ipairs(mark) do
        if type(tos) == "table" and #tos == 2 then
          local p1 = player.room:getPlayerById(tos[1])
          local p2 = player.room:getPlayerById(tos[2])
          if p1 and p2 and not p1.dead and not p2.dead and p1:getHandcardNum() ~= p2:getHandcardNum() then
            return true
          end
        end
      end
    end
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, ol_ex__dimeng.name, "negative")
    local x = 0
    local mark = player:getMark("ol_ex__dimeng_target-phase")
    if type(mark) ~= "table" then return false end
    for _, tos in ipairs(mark) do
      if type(tos) == "table" and #tos == 2 then
        local p1 = player.room:getPlayerById(tos[1])
        local p2 = player.room:getPlayerById(tos[2])
        if p1 and p2 and not p1.dead and not p2.dead then
          x = x + math.abs(p1:getHandcardNum() - p2:getHandcardNum())
        end
      end
    end
    if x > 0 then
      player.room:askForDiscard(player, x, x, true, ol_ex__dimeng.name, false, ".", "#ol_ex__dimeng-discard:::"..x)
    end
  end,
}
ol_ex__haoshi:addRelatedSkill(ol_ex__haoshi_active)
ol_ex__haoshi:addRelatedSkill(ol_ex__haoshi_delay)
ol_ex__dimeng:addRelatedSkill(ol_ex__dimeng_delay)
local lusu = General(extension, "ol_ex__lusu", "wu", 3)
lusu:addSkill(ol_ex__haoshi)
lusu:addSkill(ol_ex__dimeng)

Fk:loadTranslationTable{
  ["ol_ex__lusu"] = "界鲁肃",
  ["ol_ex__haoshi"] = "好施",
  ["#ol_ex__haoshi_active"] = "好施",
  ["#ol_ex__haoshi_delay"] = "好施",
  [":ol_ex__haoshi"] = "摸牌阶段，你可令额定摸牌数+2，此阶段结束时，若你的手牌数大于5，你将一半的手牌交给除你外手牌数最少的一名角色。当你于你的下个回合开始之前成为【杀】或普通锦囊牌的目标后，你令其可将一张手牌交给你。",
  ["ol_ex__dimeng"] = "缔盟",
  ["#ol_ex__dimeng_delay"] = "缔盟",
  [":ol_ex__dimeng"] = "出牌阶段限一次，你可选择两名手牌数之差不大于你的牌数的其他角色，这两名角色交换手牌。此阶段结束时，你弃置X张牌（X为这两名角色手牌数之差）。",

  ["#ol_ex__haoshi-give"] = "好施：选择%arg张手牌，交给除你外手牌数最少的一名角色",
  ["#ol_ex__haoshi-regive"] = "好施：你可以选择一张手牌交给 %src",
  ["#ol_ex__dimeng-discard"] = "缔盟：选择%arg张牌弃置",

  ["$ol_ex__haoshi1"] = "仗义疏财，深得人心。",
  ["$ol_ex__haoshi2"] = "招聚少年，给其衣食。",
  ["$ol_ex__dimeng1"] = "深知其奇，相与亲结。",
  ["$ol_ex__dimeng2"] = "同盟之人，言归于好。",
  ["~ol_ex__lusu"] = "一生为国，纵死无憾……",
}

local ol_ex__jiuchi = fk.CreateViewAsSkill{
  name = "ol_ex__jiuchi",
  anim_type = "offensive",
  pattern = "analeptic",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Spade and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("analeptic")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
}
local ol_ex__jiuchi_targetmod = fk.CreateTargetModSkill{
  name = "#ol_ex__jiuchi_targetmod",
  bypass_times = function(self, player, skill, scope)
    return player:hasSkill(ol_ex__jiuchi.name) and skill.trueName == "analeptic_skill" and scope == Player.HistoryTurn
  end,
}
local ol_ex__jiuchi_trigger = fk.CreateTriggerSkill{
  name = "#ol_ex__jiuchi_trigger",
  events = {fk.Damage},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill("ol_ex__jiuchi") and data.card and data.card.trueName == "slash"
        and player:getMark("@@ol_ex__benghuai_invalidity-turn") == 0 then
      local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if parentUseData then
        local drankBuff = parentUseData and (parentUseData.data[1].extra_data or {}).drankBuff or 0
        return drankBuff > 0
      end
    end
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "ol_ex__jiuchi", "defensive")
    room:broadcastSkillInvoke("ol_ex__jiuchi")
    room:addPlayerMark(player, "@@ol_ex__benghuai_invalidity-turn")
  end,
}
local ol_ex__jiuchi_invalidity = fk.CreateInvaliditySkill {
  name = "#ol_ex__jiuchi_invalidity",
  invalidity_func = function(self, from, skill)
    return
      from:getMark("@@ol_ex__benghuai_invalidity-turn") > 0 and skill.name == "benghuai"
  end
}
local ol_ex__baonve = fk.CreateTriggerSkill{
  name = "ol_ex__baonve$",
  anim_type = "support",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target and player:hasSkill(self.name) and player ~= target and target.kingdom == "qun"
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if self.cancel_cost then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, data) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|spade",
    }
    room:judge(judge)
    if judge.card.suit == Card.Spade and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = target,
        skillName = self.name
      })
    end
  end
}
local ol_ex__baonve_delay = fk.CreateTriggerSkill{
  name = "#ol_ex__baonve_delay",
  events = {fk.FinishJudge},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.suit == Card.Spade and data.reason == ol_ex__baonve.name
      and player.room:getCardArea(data.card.id) == Card.Processing
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:obtainCard(player.id, data.card)
  end,
}
ol_ex__jiuchi:addRelatedSkill(ol_ex__jiuchi_targetmod)
ol_ex__jiuchi:addRelatedSkill(ol_ex__jiuchi_trigger)
ol_ex__jiuchi:addRelatedSkill(ol_ex__jiuchi_invalidity)
ol_ex__baonve:addRelatedSkill(ol_ex__baonve_delay)
local donngzhuo = General(extension, "ol_ex__dongzhuo", "qun", 8)
donngzhuo:addSkill(ol_ex__jiuchi)
donngzhuo:addSkill("roulin")
donngzhuo:addSkill("benghuai")
donngzhuo:addSkill(ol_ex__baonve)

Fk:loadTranslationTable{
  ["ol_ex__dongzhuo"] = "界董卓",
  ["ol_ex__jiuchi"] = "酒池",
  ["#ol_ex__jiuchi_trigger"] = "酒池",
  [":ol_ex__jiuchi"] = "①你可将一张♠手牌转化为【酒】使用。②你使用【酒】无次数限制。③当你造成伤害后，若渠道为受【酒】效果影响的【杀】，你的〖崩坏〗于当前回合内无效。",
  ["ol_ex__baonve"] = "暴虐",
  [":ol_ex__baonve"] = "主公技，当其他群雄角色造成1点伤害后，你可判定，若结果为♠，回复1点体力，然后当判定牌生效后，你获得此牌。",

  ["@@ol_ex__benghuai_invalidity-turn"] = "崩坏失效",

  ["$ol_ex__jiuchi1"] = "好酒，痛快！",
  ["$ol_ex__jiuchi2"] = "某，千杯不醉！",
  ["$ol_ex__roulin1"] = "醇酒美人，幸甚乐甚！",
  ["$ol_ex__roulin2"] = "这些美人，都可进贡。",
  ["$ol_ex__benghuai1"] = "何人伤我？",
  ["$ol_ex__benghuai2"] = "酒色伤身呐……",
  ["$ol_ex__baonve1"] = "吾乃人屠，当以兵为贡。",
  ["$ol_ex__baonve2"] = "天下群雄，唯我独尊！",
  ["~ol_ex__dongzhuo"] = "地府……可有美人乎？",
}

local ol_ex__wansha = fk.CreateTriggerSkill{
  name = "ol_ex__wansha",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, self.name)
    player.room:broadcastSkillInvoke(self.name)
  end,
}
local ol_ex__wansha_prohibit = fk.CreateProhibitSkill{
  name = "#ol_ex__wansha_prohibit",
  prohibit_use = function(self, player, card)
    if card.name == "peach" and not player.dying then
      return table.find(Fk:currentRoom().alive_players, function(p)
        return p.phase ~= Player.NotActive and p:hasSkill(ol_ex__wansha.name) and p ~= player
      end)
    end
  end,
}
local ol_ex__wansha_invalidity = fk.CreateInvaliditySkill {
  name = "#ol_ex__wansha_invalidity",
  invalidity_func = function(self, from, skill)
    if table.contains(from.player_skills, skill) and not from.dying and skill.frequency ~= Skill.Compulsory
    and skill.frequency ~= Skill.Wake and not (skill.attached_equip or skill.name:endsWith("&")) then
      return table.find(Fk:currentRoom().alive_players, function(p)
        return p.dying
      end) and table.find(Fk:currentRoom().alive_players, function(p)
        return p.phase ~= Player.NotActive and p:hasSkill(ol_ex__wansha.name) and p ~= from
      end)
    end
  end,
}
local ol_ex__luanwu = fk.CreateActiveSkill{
  name = "ol_ex__luanwu",
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function() return false end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = room:getOtherPlayers(player)
    room:doIndicate(player.id, table.map(targets, function (p) return p.id end))
    for _, target in ipairs(targets) do
      if not target.dead then
        local other_players = room:getOtherPlayers(target)
        local luanwu_targets = table.map(table.filter(other_players, function(p2)
          return table.every(other_players, function(p1)
            return target:distanceTo(p1) >= target:distanceTo(p2)
          end)
        end), function (p)
          return p.id
        end)
        if #luanwu_targets > 1 then
          local tos = room:askForChoosePlayers(target, luanwu_targets, 1, 1, "#ol_ex__luanwu-slash", self.name, false, true)
          if #tos == 1 then
            luanwu_targets = tos
          else
            luanwu_targets = {luanwu_targets[1]}
          end
        end
        local use = room:askForUseCard(target, "slash", "slash", "#ol_ex__luanwu-use::" .. luanwu_targets[1], true, { must_targets = luanwu_targets})
        if use then
          room:useCard(use)
        else
          room:loseHp(target, 1, self.name)
        end
      end
    end
    if player.dead then return end
    local slash = Fk:cloneCard("slash")
    if player:prohibitUse(slash) then return end
    local max_num = slash.skill:getMaxTargetNum(player, slash)
    local slash_targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not player:isProhibited(p, slash) then
        table.insert(slash_targets, p.id)
      end
    end
    if #slash_targets == 0 or max_num == 0 then return end
    local tos = room:askForChoosePlayers(player, slash_targets, 1, max_num, "#ol_ex__luanwu-choose", self.name, true)
    if #tos > 0 then
      room:useVirtualCard("slash", nil, player, table.map(tos, function(id) return room:getPlayerById(id) end), self.name, true)
    end
  end,
}
local ol_ex__weimu = fk.CreateProhibitSkill{
  name = "ol_ex__weimu",
  frequency = Skill.Compulsory,
  is_prohibited = function(self, from, to, card)
    return to:hasSkill(self.name) and card.type == Card.TypeTrick and card.color == Card.Black
  end,
}
local ol_ex__weimu_trigger = fk.CreateTriggerSkill{
  name = "#ol_ex__weimu_trigger",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ol_ex__weimu.name) and player.phase ~= Player.NotActive
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, ol_ex__weimu.name, "defensive")
    player.room:broadcastSkillInvoke(ol_ex__weimu.name)
    player:drawCards(data.damage*2, self.name)
    return true
  end,
}
ol_ex__wansha:addRelatedSkill(ol_ex__wansha_prohibit)
ol_ex__wansha:addRelatedSkill(ol_ex__wansha_invalidity)
ol_ex__weimu:addRelatedSkill(ol_ex__weimu_trigger)

local jiaxu = General(extension, "ol_ex__jiaxu", "qun", 3)
jiaxu:addSkill(ol_ex__wansha)
jiaxu:addSkill(ol_ex__luanwu)
jiaxu:addSkill(ol_ex__weimu)

Fk:loadTranslationTable{
  ["ol_ex__jiaxu"] = "界贾诩",
  ["ol_ex__wansha"] = "完杀",
  [":ol_ex__wansha"] = "锁定技，①除进行濒死流程的角色以外的其他角色于你的回合内不能使用【桃】。②在一名角色于你的回合内进行的濒死流程中，除其以外的其他角色的不带“锁定技”标签的技能无效。",
  ["ol_ex__luanwu"] = "乱武",
  [":ol_ex__luanwu"] = "限定技，出牌阶段，你可选择所有其他角色，这些角色各需对包括距离最小的另一名角色在内的角色使用【杀】，否则失去1点体力。最后你可视为使用普【杀】。",
  ["ol_ex__weimu"] = "帷幕",
  ["#ol_ex__weimu_trigger"] = "帷幕",
  [":ol_ex__weimu"] = "锁定技，①你不是黑色锦囊牌的合法目标。②当你于回合内受到伤害时，你防止此伤害，摸2X张牌（X为伤害值）。",

  ["#ol_ex__luanwu-slash"] = "乱武：选择距离最近的一名角色，然后对其使用一张【杀】",
  ["#ol_ex__luanwu-use"] = "乱武：你需要对包含%dest在内的角色使用一张【杀】，否则失去1点体力",
  ["#ol_ex__luanwu-choose"] = "乱武：你可以视为使用一张【杀】，选择此【杀】的目标",

  ["$ol_ex__wansha1"] = "有谁敢试试？",
  ["$ol_ex__wansha2"] = "斩草务尽，以绝后患。",
  ["$ol_ex__luanwu1"] = "一切都在我的掌控中！",
  ["$ol_ex__luanwu2"] = "这乱世还不够乱！",
  ["$ol_ex__weimu1"] = "此伤与我无关。",
  ["$ol_ex__weimu2"] = "还是另寻他法吧。",
  ["~ol_ex__jiaxu"] = "此劫，我亦有所算……",
}

local ol_ex__qiaobian_select = fk.CreateActiveSkill{
  name = "#ol_ex__qiaobian_select",
  anim_type = "offensive",
  can_use = function() return false end,
  target_num = 0,
  max_card_num = 1,
  min_card_num = function ()
    if Self:getMark("@ol_ex__qiaobian_change") > 0 then
      return 0
    end
    return 1
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
}
local ol_ex__qiaobian = fk.CreateTriggerSkill{
  name = "ol_ex__qiaobian",
  anim_type = "control",
  events = {fk.EventPhaseChanging, fk.GameStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then return true
      elseif event == fk.EventPhaseStart and player.phase == Player.Finish then
        local numberRecorded = type(player:getMark("ol_ex__qiaobian_number")) == "table" and player:getMark("ol_ex__qiaobian_number") or {}
        return not table.contains(numberRecorded, player:getHandcardNum())
      elseif event == fk.EventPhaseChanging and player == target and
          (not player:isNude() or player:getMark("@ol_ex__qiaobian_change") > 0) then
        return data.to > Player.Start and data.to < Player.Finish
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart or event == fk.EventPhaseStart then
      return true
    elseif event == fk.EventPhaseChanging then
      local phase_name_table = {
        [2] = "phase_start",
        [3] = "phase_judge",
        [4] = "phase_draw",
        [5] = "phase_play",
        [6] = "phase_discard",
        [7] = "phase_finish",
      }
      local _, ret = player.room:askForUseActiveSkill(player, "#ol_ex__qiaobian_select", "#ol_ex__qiaobian-invoke:::" .. phase_name_table[data.to], true)
      if ret then
        self.cost_data = ret.cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:addPlayerMark(player, "@ol_ex__qiaobian_change", 2)
    elseif event == fk.EventPhaseStart then
      local numberRecorded = type(player:getMark("ol_ex__qiaobian_number")) == "table" and player:getMark("ol_ex__qiaobian_number") or {}
      table.insert(numberRecorded, player:getHandcardNum())
      room:setPlayerMark(player, "ol_ex__qiaobian_number", numberRecorded)
      room:addPlayerMark(player, "@ol_ex__qiaobian_change")
    elseif event == fk.EventPhaseChanging then
      if #self.cost_data > 0 then
        room:throwCard(self.cost_data, self.name, player, player)
      else
        room:removePlayerMark(player, "@ol_ex__qiaobian_change")
      end
      if data.to == Player.Draw then
        local tos = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
          return not p:isKongcheng() end), function (p) return p.id end), 1, 2, "#ol_ex__qiaobian-prey", self.name, true)
        if #tos > 0 then
          room:sortPlayersByAction(tos)
          table.forEach(tos, function(id)
            if not player.dead then
              local to = room:getPlayerById(id)
              if not to.dead and not to:isKongcheng() then
                local c = room:askForCardChosen(player, to, "h", self.name)
                room:obtainCard(player, c, false, fk.ReasonPrey)
              end
            end
          end)
        end
      elseif data.to == Player.Play then
        local to = room:askForChooseToMoveCardInBoard(player, "#ol_ex__qiaobian-movecard", self.name, true)
        if #to == 2 then
          room:askForMoveCardInBoard(player, room:getPlayerById(to[1]), room:getPlayerById(to[2]), self.name)
        end
      end
      player:skip(data.to)
      return true
    end
  end,
}
ol_ex__qiaobian:addRelatedSkill(ol_ex__qiaobian_select)
local zhanghe = General(extension, "ol_ex__zhanghe", "wei", 4)
zhanghe:addSkill(ol_ex__qiaobian)

Fk:loadTranslationTable{
  ["ol_ex__zhanghe"] = "界张郃",
  ["ol_ex__qiaobian"] = "巧变",
  ["#ol_ex__qiaobian_select"] = "巧变",
  [":ol_ex__qiaobian"] = "游戏开始时，你获得2枚“变”标记。你可以弃置一张牌或移除1枚“变”标记并跳过你的一个阶段（准备阶段和结束阶段除外）：若跳过摸牌阶段，你可以获得至多两名角色的各一张手牌；若跳过出牌阶段，你可以移动场上的一张牌。结束阶段开始时，若你的手牌数与之前你的每一回合结束阶段开始时的手牌数均不相等，你获得1枚“变”标记。",

  ["@ol_ex__qiaobian_change"] = "变",
  ["#ol_ex__qiaobian-invoke"] = "巧变：你可选择一张牌弃置，或直接点确定则弃置变标记。来跳过 %arg",
  ["#ol_ex__qiaobian-prey"] = "巧变：你可以选择一至两名角色，获得这些角色各一张手牌",
  ["#ol_ex__qiaobian-movecard"] = "巧变：你可以选择两名角色，移动这些角色装备区或判定区的一张牌",

  ["$ol_ex__qiaobian1"] = "顺势而变，则胜矣。",
  ["$ol_ex__qiaobian2"] = "万物变化，固无休息。",
  ["~ol_ex__zhanghe"] = "何处之流矢……",
}

local ol_ex__tuntian = fk.CreateTriggerSkill{
  name = "ol_ex__tuntian",
  anim_type = "special",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and (move.to ~= player.id or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              if (move.moveReason == fk.ReasonDiscard and Fk:getCardById(info.cardId).trueName == "slash") or
              player.phase == Player.NotActive then return true end
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|spade,club,diamond",
    }
    room:judge(judge)
  end,
}
local ol_ex__tuntian_delay = fk.CreateTriggerSkill{
  name = "#ol_ex__tuntian_delay",
  events = {fk.FinishJudge},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.suit ~= Card.Heart and data.reason == ol_ex__tuntian.name
      and player.room:getCardArea(data.card.id) == Card.Processing
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player:addToPile("ol_ex__dengai_field", data.card, true, self.name)
  end,
}
local ol_ex__tuntian_distance = fk.CreateDistanceSkill{
  name = "#ol_ex__tuntian_distance",
  correct_func = function(self, from, to)
    if from:hasSkill(ol_ex__tuntian.name) then
      return -#from:getPile("ol_ex__dengai_field")
    end
  end,
}
local ol_ex__zaoxian = fk.CreateTriggerSkill{
  name = "ol_ex__zaoxian",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("ol_ex__dengai_field") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "ol_ex__jixi", nil)
    player:gainAnExtraTurn()
  end,
}
local ol_ex__jixi = fk.CreateViewAsSkill{
  name = "ol_ex__jixi",
  anim_type = "control",
  pattern = "snatch",
  expand_pile = "ol_ex__dengai_field",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Self:getPileNameOfId(to_select) == "ol_ex__dengai_field"
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("snatch")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return #player:getPile("ol_ex__dengai_field") > 0
  end,
  enabled_at_response = function(self, player)
    return #player:getPile("ol_ex__dengai_field") > 0
  end,
}
ol_ex__tuntian:addRelatedSkill(ol_ex__tuntian_delay)
ol_ex__tuntian:addRelatedSkill(ol_ex__tuntian_distance)
local dengai = General(extension, "ol_ex__dengai", "wei", 4)
dengai:addSkill(ol_ex__tuntian)
dengai:addSkill(ol_ex__zaoxian)
dengai:addRelatedSkill(ol_ex__jixi)

Fk:loadTranslationTable{
  ["ol_ex__dengai"] = "界邓艾",
  ["ol_ex__tuntian"] = "屯田",
  ["#ol_ex__tuntian_delay"] = "屯田",
  [":ol_ex__tuntian"] = "当你于回合外失去牌后，或于回合内因弃置而失去【杀】后，你可以进行判定，若结果不为红桃，你将判定牌置于你的武将牌上，称为“田”；你计算与其他角色的距离-X（X为“田”的数量）。",
  ["ol_ex__zaoxian"] = "凿险",
  [":ol_ex__zaoxian"] = "觉醒技，准备阶段，若“田”的数量大于等于3，你减1点体力上限，然后获得“急袭”。此回合结束后，你获得一个额外回合。",
  ["ol_ex__jixi"] = "急袭",
  [":ol_ex__jixi"] = "你可以将一张“田”当【顺手牵羊】使用。",

  ["ol_ex__dengai_field"] = "田",

  ["$ol_ex__tuntian1"] = "兵农一体，以屯养战。",
  ["$ol_ex__tuntian2"] = "垦田南山，志在西川。",
  ["$ol_ex__zaoxian1"] = "良田厚土，足平蜀道之难！",
  ["$ol_ex__zaoxian2"] = "效仿五丁开川，赢粮直捣黄龙！",
  ["$ol_ex__jixi1"] = "良田为济，神兵天降！",
  ["$ol_ex__jixi2"] = "明至剑阁，暗袭蜀都！",
  ["~ol_ex__dengai"] = "钟会！你为何害我！",
}

local ol_ex__tiaoxin = fk.CreateActiveSkill{
  name = "ol_ex__tiaoxin",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) < 1 + player:getMark("ol_ex__tiaoxin_extra-phase")
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):inMyAttackRange(Self)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local use = room:askForUseCard(target, "slash", "slash", "#tiaoxin-use", true, {must_targets = {player.id}})
    if use then
      room:useCard(use)
    end
    if not (use and use.damageDealt) then
      room:setPlayerMark(player, "ol_ex__tiaoxin_extra-phase", 1)
      if not target:isNude() then
        local card = room:askForCardChosen(player, target, "he", self.name)
        room:throwCard({card}, self.name, target, player)
      end
    end
  end
}
local ol_ex__zhiji = fk.CreateTriggerSkill{
  name = "ol_ex__zhiji",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  can_wake = function(self, event, target, player, data)
    return player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw2"}
    if player:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "draw2" then
      player:drawCards(2)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "ex__guanxing", nil)
  end,
}
local jiangwei = General(extension, "ol_ex__jiangwei", "shu", 4)
jiangwei:addSkill(ol_ex__tiaoxin)
jiangwei:addSkill(ol_ex__zhiji)
jiangwei:addRelatedSkill("ex__guanxing")

Fk:loadTranslationTable{
  ["ol_ex__jiangwei"] = "界姜维",
  ["ol_ex__tiaoxin"] = "挑衅",
  [":ol_ex__tiaoxin"] = "出牌阶段限一次，你可以选择一名攻击范围内含有你的角色，然后除非该角色对你使用一张【杀】且你因其执行此【杀】的效果而受到过伤害，否则你弃置其一张牌，然后本阶段本技能限两次。",
  ["ol_ex__zhiji"] = "志继",
  [":ol_ex__zhiji"] = "觉醒技，准备阶段或结束阶段，若你没有手牌，你回复1点体力或摸两张牌，然后减1点体力上限，获得“观星”。",

  ["$ol_ex__tiaoxin1"] = "会闻用师，观衅而动。",
  ["$ol_ex__tiaoxin2"] = "宜乘其衅会，以挑敌将。",
  ["$ol_ex__zhiji1"] = "丞相遗志，不死不休！",
  ["$ol_ex__zhiji2"] = "大业未成，矢志不渝！",
  ["$ol_ex__guanxing1"] = "星象相弦，此乃吉兆！",
  ["$ol_ex__guanxing2"] = "星之分野，各有所属。",
  ["~ol_ex__jiangwei"] = "星散流离……",
}

local ol_ex__fangquan = fk.CreateTriggerSkill{
  name = "ol_ex__fangquan",
  anim_type = "support",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player == target and data.to == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player:skip(Player.Play)
    return true
  end,
}
local ol_ex__fangquan_delay = fk.CreateTriggerSkill{
  name = "#ol_ex__fangquan_delay",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Discard and player:usedSkillTimes(ol_ex__fangquan.name, Player.HistoryTurn) > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, ol_ex__fangquan.name, "support")
    local tar, card =  room:askForChooseCardAndPlayers(player, table.map(room:getOtherPlayers(player), function (p)
      return p.id end), 1, 1, ".|.|.|hand", "#ol_ex__fangquan-choose", ol_ex__fangquan.name, true)
    if #tar > 0 and card then
      room:throwCard(card, ol_ex__fangquan.name, player, player)
      room:getPlayerById(tar[1]):gainAnExtraTurn()
    end
  end,
}
local ol_ex__ruoyu = fk.CreateTriggerSkill{
  name = "ol_ex__ruoyu$",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return table.every(player.room:getOtherPlayers(player), function(p) return p.hp >= player.hp end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player:isWounded() and player.hp < 3 then
      room:recover({
        who = player,
        num = math.min(3, player.maxHp) - player.hp,
        recoverBy = player,
        skillName = self.name,
      })
    end
    room:handleAddLoseSkills(player, "jijiang|ol_ex__sishu", nil, true, false)
  end,
}
local ol_ex__sishu = fk.CreateTriggerSkill{
  name = "ol_ex__sishu",
  events = {fk.EventPhaseStart},
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
      return p.id end), 1, 1, "#ol_ex__sishu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local tar = player.room:getPlayerById(self.cost_data)
    if tar then
      player.room:setPlayerMark(tar, "@@ol_ex__sishu_effect", 1- tar:getMark("@@ol_ex__sishu_effect"))
    end
  end,
}
ol_ex__fangquan:addRelatedSkill(ol_ex__fangquan_delay)
local liushan = General(extension, "ol_ex__liushan", "shu", 3)
liushan:addSkill("xiangle")
liushan:addSkill(ol_ex__fangquan)
liushan:addSkill(ol_ex__ruoyu)
liushan:addRelatedSkill("jijiang")
liushan:addRelatedSkill(ol_ex__sishu)
Fk:loadTranslationTable{
  ["ol_ex__liushan"] = "界刘禅",
  ["ol_ex__fangquan"] = "放权",
  ["#ol_ex__fangquan_delay"] = "放权",
  [":ol_ex__fangquan"] = "出牌阶段开始前，你可跳过此阶段，然后弃牌阶段开始时，你可弃置一张手牌并选择一名其他角色，其获得一个额外回合。",
  ["ol_ex__ruoyu"] = "若愚",
  [":ol_ex__ruoyu"] = "主公技，觉醒技，准备阶段，若你是体力值最小的角色，你加1点体力上限，回复体力至3点，获得〖激将〗（暂时为标准版）和〖思蜀〗（暂时无法正常适用）。",
  ["ol_ex__sishu"] = "思蜀",
  [":ol_ex__sishu"] = "出牌阶段开始时，你可选择一名角色，其本局游戏【乐不思蜀】的判定结果反转（暂时无法正常适用）。",

  ["#ol_ex__fangquan-choose"] = "放权：弃置一张手牌，令一名角色获得一个额外回合",
  ["#ol_ex__sishu-choose"] = "思蜀：选择一名角色，令其本局游戏【乐不思蜀】的判定结果反转",
  ["@@ol_ex__sishu_effect"] = "思蜀",

  ["$ol_ex__xiangle1"] = "嘿嘿嘿，还是玩耍快乐。",
  ["$ol_ex__xiangle2"] = "美好的日子，应该好好享受。",
  ["$ol_ex__fangquan1"] = "蜀汉有相父在，我可安心。",
  ["$ol_ex__fangquan2"] = "这些事情，你们安排就好。",
  ["$ol_ex__ruoyu1"] = "若愚故泰，巧骗众人。",
  ["$ol_ex__ruoyu2"] = "愚昧者，非真傻也。",
  ["$ol_ex__jijiang1"] = "爱卿爱卿，快来护驾！",
  ["$ol_ex__jijiang2"] = "将军快替我，拦下此贼！",
  ["$ol_ex__sishu1"] = "蜀乐乡土，怎不思念？",
  ["$ol_ex__sishu2"] = "思乡心切，徘徊惶惶。",
  ["~ol_ex__liushan"] = "将军英勇，我……我投降……",
}

local ol_ex__jiang = fk.CreateTriggerSkill{
  name = "ol_ex__jiang",
  anim_type = "drawcard",
  events ={fk.TargetSpecified, fk.TargetConfirmed, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return end
    if (event == fk.TargetSpecified or event == fk.TargetConfirmed) and player == target and
      ((data.card.trueName == "slash" and data.card.color == Card.Red) or data.card.name == "duel") then
      return event == fk.TargetConfirmed or data.firstTarget
    elseif event == fk.AfterCardsMove and (data.extra_data or {}).firstDiscardRedSlashOrDuel then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if ((card.trueName == "slash" and card.color == Card.Red) or card.name == "duel") and
                player.room:getCardArea(info.cardId) == Card.DiscardPile then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.TargetSpecified or event == fk.TargetConfirmed then
      player:drawCards(1, self.name)
    elseif event == fk.AfterCardsMove then
      local room = player.room
      room:loseHp(player, 1, self.name)
      local dummy = Fk:cloneCard("dilu")
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if ((card.trueName == "slash" and card.color == Card.Red) or card.name == "duel") and
                player.room:getCardArea(info.cardId) == Card.DiscardPile then
              dummy:addSubcard(card)
            end
          end
        end
      end
      if #dummy.subcards > 0 then
        room:obtainCard(player, dummy, true, fk.ReasonJustMove)
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardsMove and not player.room:getTag("firstDiscardRedSlashOrDuelRecord") then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if (card.trueName == "slash" and card.color == Card.Red) or card.name == "duel" then
              return true
            end
          end
        end
      end
    elseif event == fk.TurnEnd and player == target then
      return player.room:getTag("firstDiscardRedSlashOrDuelRecord")
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      player.room:setTag("firstDiscardRedSlashOrDuelRecord", true)
      data.extra_data = data.extra_data or {}
      data.extra_data.firstDiscardRedSlashOrDuel = true
    elseif event == fk.TurnEnd then
      player.room:setTag("firstDiscardRedSlashOrDuelRecord", false)
    end
  end,
}

local ol_ex__hunzi = fk.CreateTriggerSkill{
  name = "ol_ex__hunzi",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return player.hp == 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "ex__yingzi|yinghun", nil)
  end,
}
local ol_ex__hunzi_delay = fk.CreateTriggerSkill{
  name = "#ol_ex__hunzi_delay",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target and target.phase == Player.Finish and player:usedSkillTimes(ol_ex__hunzi.name, Player.HistoryTurn) > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, ol_ex__hunzi.name, "support")
    local choices = {"ol_ex__hunzi_draw"}
    if player:isWounded() then
      table.insert(choices, "ol_ex__hunzi_recover")
    end
    local choice = room:askForChoice(player, choices, ol_ex__hunzi.name, "#ol_ex__hunzi-choice")
    if choice == "ol_ex__hunzi_draw" then
      player:drawCards(2, self.name)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = ol_ex__hunzi.name
      })
    end
  end,
}

ol_ex__hunzi:addRelatedSkill(ol_ex__hunzi_delay)
local sunce = General(extension, "ol_ex__sunce", "wu", 4)
sunce:addSkill(ol_ex__jiang)
sunce:addSkill(ol_ex__hunzi)
sunce:addRelatedSkill("ex__yingzi")
sunce:addRelatedSkill("yinghun")

Fk:loadTranslationTable{
  ["ol_ex__sunce"] = "界孙策",
  ["ol_ex__jiang"] = "激昂",
  [":ol_ex__jiang"] = "当你使用【决斗】或红色【杀】指定目标后，或成为【决斗】或红色【杀】的目标后，你可以摸一张牌。每回合首次有包含【决斗】或红色【杀】在内的牌因弃置而置入弃牌堆后，你可以失去1点体力获得其中所有【决斗】和红色【杀】。",
  ["ol_ex__hunzi"] = "魂姿",
  ["#ol_ex__hunzi_delay"] = "魂姿",
  [":ol_ex__hunzi"] = "觉醒技，准备阶段，若你的体力值为1，你减1点体力上限，获得“英姿”和“英魂”。本回合结束阶段，你摸两张牌或回复1点体力。",
  ["ol_ex__zhiba"] = "制霸",
  [":ol_ex__zhiba"] = "主公技，其他吴势力角色的出牌阶段限一次，其可以对你发起拼点，你可以拒绝此拼点。出牌阶段限一次，你可以与一名其他吴势力角色拼点。以此法发起的拼点，若其没赢，你可以获得两张拼点牌。",

  ["#ol_ex__hunzi-choice"] = "魂姿：选择摸两张牌或者回复1点体力",
  ["ol_ex__hunzi_draw"] = "摸两张牌",
  ["ol_ex__hunzi_recover"] = "回复1点体力",

  ["$ol_ex__jiang1"] = "策虽暗稚，窃有微志。",
  ["$ol_ex__jiang2"] = "收合流散，东据吴会。",
  ["$ol_ex__hunzi1"] = "江东新秀，由此崛起。",
  ["$ol_ex__hunzi2"] = "看汝等大展英气！",
  ["$ol_ex__zhiba1"] = "让将军在此恭候多时了。",
  ["$ol_ex__zhiba2"] = "有诸位将军在，此战岂会不胜？",
  ["$ol_ex__yingzi1"] = "得公瑾辅助，策必当一战！",
  ["$ol_ex__yingzi2"] = "公瑾在此，此战无忧！",
  ["$ol_ex__yinghun1"] = "东吴繁盛，望父亲可知。",
  ["$ol_ex__yinghun2"] = "父亲，吾定不负你期望！",
  ["~ol_ex__sunce"] = "汝等，怎能受于吉蛊惑？",
}

local ol_ex__beige = fk.CreateTriggerSkill{
  name = "ol_ex__beige",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and not data.to.dead and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ol_ex__beige-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local judge = {
      who = target,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#ol_ex__beige-discard::"..target.id, true)
    if #card ~= 1 then return end
    local dis_card = Fk:getCardById(card[1])
    local suit = dis_card.suit
    local number = dis_card.number
    room:throwCard(card, self.name, player, player)
    if not player.dead then
      local dummy = Fk:cloneCard("dilu")
      if suit == judge.card.suit and room:getCardArea(judge.card.id) == Card.DiscardPile then
        dummy:addSubcard(judge.card)
      end
      if number == judge.card.number and room:getCardArea(dis_card.id) == Card.DiscardPile then
        dummy:addSubcard(dis_card)
      end
      if #dummy.subcards > 0 then
        room:obtainCard(player, dummy, true, fk.ReasonJustMove)
      end
    end
    if judge.card.suit == Card.Heart then
      if target:isWounded() then
        room:recover{
          who = target,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
      end
    elseif judge.card.suit == Card.Diamond then
      target:drawCards(2, self.name)
    elseif judge.card.suit == Card.Club then
      if data.from and not data.from.dead then
        if #data.from:getCardIds{Player.Hand, Player.Equip} < 3 then
          data.from:throwAllCards("he")
        else
          room:askForDiscard(data.from, 2, 2, true, self.name, false, ".")
        end
      end
    elseif judge.card.suit == Card.Spade then
      if data.from and not data.from.dead then
        data.from:turnOver()
      end
    end
  end,
}
local caiwenji = General(extension, "ol_ex__caiwenji", "qun", 3, 3, General.Female)
caiwenji:addSkill(ol_ex__beige)
caiwenji:addSkill("duanchang")

Fk:loadTranslationTable{
  ["ol_ex__caiwenji"] = "界蔡文姬",
  ["ol_ex__beige"] = "悲歌",
  [":ol_ex__beige"] = "当一名角色受到【杀】造成的伤害后，若你有牌，你可以令其进行一次判定，然后你可以弃置一张牌，根据判定结果执行：红桃，其回复1点体力；方块，其摸两张牌；梅花，伤害来源弃置两张牌；黑桃，伤害来源将武将牌翻面；点数相同，你获得你弃置的牌；花色相同，你获得判定牌。",
 
  ["#ol_ex__beige-invoke"] = "悲歌：你可以令%dest进行判定",
  ["#ol_ex__beige-discard"] = "悲歌：你可以弃置一张牌令%dest根据判定的花色执行对应效果",

  ["$ol_ex__beige1"] = "箜篌鸣九霄，闻者心俱伤。",
  ["$ol_ex__beige2"] = " 琴弹十八拍，听此双泪流。",
  ["$ol_ex__duanchang1"] = "红颜留塞外，愁思欲断肠。",
  ["$ol_ex__duanchang2"] = "莫吟苦辛曲，此生谁忍闻。",
  ["~ol_ex__caiwenji"] = "飘飘外域里，何日能归乡？",
}

return extension
