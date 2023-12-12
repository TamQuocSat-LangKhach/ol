local extension = Package("ol_sp3")
extension.extensionName = "ol"
local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_sp3"] = "OL专属3",
}

local huban = General(extension, "ol__huban", "wei", 4)
local huiyun = fk.CreateViewAsSkill{
  name = "huiyun",
  anim_type = "support",
  pattern = "fire_attack",
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    use.extra_data = use.extra_data or {}
    use.extra_data.huiyun_user = player.id
  end,
}
local huiyun_trigger = fk.CreateTriggerSkill{
  name = "#huiyun_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return not player.dead and table.contains(data.card.skillNames, "huiyun")
    and data.extra_data and data.extra_data.huiyun_user == player.id
    and (player:getMark("huiyun1-round") == 0 or player:getMark("huiyun2-round") == 0 or player:getMark("huiyun3-round") == 0)
    and table.find(TargetGroup:getRealTargets(data.tos), function(pid) return not player.room:getPlayerById(pid).dead end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local showMap = data.extra_data and data.extra_data.huiyun or {}
    for _, pid in ipairs(TargetGroup:getRealTargets(data.tos)) do
      local choices = {}
      for i = 1, 3, 1 do
        local mark = "huiyun"..tostring(i).."-round"
        if player:getMark(mark) == 0 then
          table.insert(choices, mark)
        end
      end
      if player.dead or #choices == 0 then break end
      local to = room:getPlayerById(pid)
      if not to.dead then
        local choice = player.room:askForChoice(player, choices, "huiyun", "#huiyun-choice::"..to.id)
        room:setPlayerMark(player, choice, 1)
        local show = showMap[to.id]
        local name = show and Fk:getCardById(show):toLogString() or ""
        if choice == "huiyun3-round" then
          if room:askForSkillInvoke(to, "huiyun", nil, "#huiyun3-draw") then
            to:drawCards(1, "huiyun")
          end
        elseif choice == "huiyun1-round" then
          if show and table.contains(to:getCardIds("h"), show) then
            local use = U.askForUseRealCard(room, to, {show}, ".", "huiyun", "#huiyun1-card:::"..name)
            if use then
              room:delay(500)
              if not to.dead and not to:isKongcheng() then
                room:recastCard(to:getCardIds("h"), to, "huiyun")
              end
            end
          end
        elseif choice == "huiyun2-round" then
          local use = U.askForUseRealCard(room, to, to:getCardIds("h"), ".", "huiyun", "#huiyun2-card:::"..name)
          if use then
            room:delay(500)
            if show and table.contains(to:getCardIds("h"), show) then
              room:recastCard({show}, to, "huiyun")
            end
          end
        end
      end
    end
  end,

  refresh_events = {fk.CardShown},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        return table.contains(use.card.skillNames, "huiyun")
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data[1]
      use.extra_data = use.extra_data or {}
      use.extra_data.huiyun = use.extra_data.huiyun or {}
      use.extra_data.huiyun[player.id] = data.cardIds[1]
    end
  end,
}
huiyun:addRelatedSkill(huiyun_trigger)
huban:addSkill(huiyun)
Fk:loadTranslationTable{
  ["ol__huban"] = "胡班",
  ["huiyun"] = "晖云",
  [":huiyun"] = "你可以将一张牌当【火攻】使用，然后你于此牌结算结束后，对每个目标依次选择一项（每个选项每轮限一次），令其选择是否执行：1.使用展示牌，然后重铸所有手牌；2.使用一张手牌，然后重铸展示牌；3.摸一张牌。",
  ["#huiyun-choice"] = "晖云：选择一项令 %dest 角色选择是否执行",
  ["huiyun1-round"] = "使用展示牌，然后重铸所有手牌",
  ["huiyun2-round"] = "使用一张手牌，然后重铸展示牌",
  ["huiyun3-round"] = "摸一张牌",
  ["#huiyun1-card"] = "晖云：你可以使用%arg，然后重铸所有手牌",
  ["#huiyun2-card"] = "晖云：你可以使用一张手牌，然后重铸%arg",
  ["#huiyun3-draw"] = "晖云：你可以摸一张牌",

  ["$huiyun1"] = "舍身饲离火，不负万古名。",
  ["$huiyun2"] = "义士今犹在，青笺气干云。",
  ["~ol__huban"] = "无耻鼠辈，吾耻与为伍！",
}

local furong = General(extension, "ol__furong", "shu", 4)
local xiaosi = fk.CreateActiveSkill{
  name = "xiaosi",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#xiaosi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeBasic
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = {}
    table.insert(cards, effect.cards[1])
    room:throwCard(effect.cards, self.name, player, player)
    if table.find(target:getCardIds("h"), function(id) return Fk:getCardById(id).type == Card.TypeBasic end) then
      local card = room:askForDiscard(target, 1, 1, false, self.name, false, ".|.|.|.|.|basic", "#xiaosi-discard:"..player.id, true)
      if #card > 0 then
        table.insert(cards, card[1])
        room:throwCard(card, self.name, target, target)
      elseif not player.dead then
        player:drawCards(1, self.name)
      end
    elseif not player.dead then
      player:drawCards(1, self.name)
    end
    cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.DiscardPile end)
    if #cards == 0 or player.dead then return end
    while not player.dead do
      local ids = {}
      for _, id in ipairs(cards) do
        local card = Fk:getCardById(id)
        if room:getCardArea(card) == Card.DiscardPile and not player:prohibitUse(card) and player:canUse(card) then
          table.insertIfNeed(ids, id)
        end
      end
      if player.dead or #ids == 0 then return end
      local fakemove = {
        toArea = Card.PlayerHand,
        to = player.id,
        moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.Void} end),
        moveReason = fk.ReasonJustMove,
      }
      room:notifyMoveCards({player}, {fakemove})
      room:setPlayerMark(player, "xiaosi_cards", ids)
      local success, dat = room:askForUseActiveSkill(player, "xiaosi_viewas", "#xiaosi-use", true)
      room:setPlayerMark(player, "xiaosi_cards", 0)
      fakemove = {
        from = player.id,
        toArea = Card.Void,
        moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.PlayerHand} end),
        moveReason = fk.ReasonJustMove,
      }
      room:notifyMoveCards({player}, {fakemove})
      if success then
        table.removeOne(cards, dat.cards[1])
        local card = Fk.skills["xiaosi_viewas"]:viewAs(dat.cards)
        room:useCard{
          from = player.id,
          tos = table.map(dat.targets, function(id) return {id} end),
          card = card,
          extraUse = true,
        }
      else
        break
      end
    end
  end,
}
local xiaosi_viewas = fk.CreateViewAsSkill{
  name = "xiaosi_viewas",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      local ids = Self:getMark("xiaosi_cards")
      return type(ids) == "table" and table.contains(ids, to_select)
    end
  end,
  view_as = function(self, cards)
    if #cards == 1 then
      local card = Fk:getCardById(cards[1])
      card.skillName = "xiaosi"
      return card
    end
  end,
}
local xiaosi_targetmod = fk.CreateTargetModSkill{
  name = "#xiaosi_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "xiaosi")
  end,
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, "xiaosi")
  end,
}
Fk:addSkill(xiaosi_viewas)
xiaosi:addRelatedSkill(xiaosi_targetmod)
furong:addSkill(xiaosi)
Fk:loadTranslationTable{
  ["ol__furong"] = "傅肜",
  ["xiaosi"] = "效死",
  [":xiaosi"] = "出牌阶段限一次，你可以弃置一张基本牌，令一名有手牌的其他角色弃置一张基本牌（若其不能弃置则你摸一张牌），然后你可以使用这些牌"..
  "（无距离和次数限制）。",
  ["#xiaosi"] = "效死：弃置一张基本牌，令另一名角色弃置一张基本牌，然后你可以使用这些牌",
  ["#xiaosi-discard"] = "效死：请弃置一张基本牌，%src 可以使用之",
  ["xiaosi_viewas"] = "效死",
  ["#xiaosi-use"] = "效死：你可以使用这些牌（无距离次数限制）",

  ["$xiaosi1"] = "既抱必死之心，焉存偷生之意。",
  ["$xiaosi2"] = "为国效死，死得其所。",
  ["~ol__furong"] = "吴狗！何有汉将军降者！",
}

local liuba = General(extension, "ol__liuba", "shu", 3)
local ol__tongdu = fk.CreateTriggerSkill{
  name = "ol__tongdu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      not table.every(player.room:getOtherPlayers(player), function(p) return p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isKongcheng() end), Util.IdMapper), 1, 1, "#ol__tongdu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCard(to, 1, 1, false, self.name, false, ".", "#ol__tongdu-give:"..player.id)
    room:obtainCard(player.id, card[1], false, fk.ReasonGive)
    room:setPlayerMark(player, "ol__tongdu-turn", card[1])
  end,
}
local ol__tongdu_trigger = fk.CreateTriggerSkill{
  name = "#ol__tongdu_trigger",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:usedSkillTimes("ol__tongdu", Player.HistoryTurn) > 0 and
      player:getMark("ol__tongdu-turn") ~= 0 and player.room:getCardOwner(player:getMark("ol__tongdu-turn")) == player and
      player.room:getCardArea(player:getMark("ol__tongdu-turn")) == Card.PlayerHand
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ol__tongdu")
    room:notifySkillInvoked(player, "ol__tongdu")
    local id = player:getMark("ol__tongdu-turn")
    room:moveCards({
      ids = {id},
      from = player.id,
      fromArea = Card.PlayerHand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = "ol__tongdu",
    })
  end,
}
local ol__zhubi = fk.CreateActiveSkill{
  name = "ol__zhubi",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < player.maxHp
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local card = room:askForCard(target, 1, 1, true, self.name, false, ".", "#ol__zhubi-card")
    room:moveCards({
      ids = card,
      from = target.id,
      toArea = Card.DiscardPile,
      skillName = self.name,
      moveReason = fk.ReasonPutIntoDiscardPile,
      proposer = target.id
    })
    room:sendLog{
      type = "#RecastBySkill",
      from = target.id,
      card = card,
      arg = self.name,
    }
    local id = target:drawCards(1, self.name)[1]
    if room:getCardOwner(id) == target and room:getCardArea(id) == Card.PlayerHand then
      local mark = target:getMark(self.name)
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, id)
      room:setPlayerMark(target, self.name, mark)
    end
  end
}
local ol__zhubi_trigger = fk.CreateTriggerSkill{
  name = "#ol__zhubi_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self, true) and target.phase == Player.Finish and target:getMark("ol__zhubi") ~= 0 then
      for _, id in ipairs(target:getMark("ol__zhubi")) do
        if player.room:getCardOwner(id) == target and player.room:getCardArea(id) == Card.PlayerHand then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ol__tongdu")
    room:notifySkillInvoked(player, "ol__tongdu")
    local ids = {}
    for _, id in ipairs(target:getMark("ol__zhubi")) do
      if room:getCardOwner(id) == target and room:getCardArea(id) == Card.PlayerHand then
        table.insert(ids, id)
      end
    end
    local piles = room:askForExchange(target, {room:getNCards(5, "bottom"), ids}, {"Bottom", "ol__zhubi"}, "ol__zhubi")
    local cards1, cards2 = {}, {}
    for _, id in ipairs(piles[1]) do
      if room:getCardArea(id) == target.Hand then
        table.insert(cards1, id)
      end
    end
    for _, id in ipairs(piles[2]) do
      if room:getCardArea(id) ~= target.Hand then
        table.insert(cards2, id)
      end
    end
    local move1 = {
      ids = cards1,
      from = target.id,
      fromArea = Card.PlayerHand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = "ol__zhubi",
      drawPilePosition = -1,
    }
    local move2 = {
      ids = cards2,
      to = target.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      skillName = "ol__zhubi",
    }
    room:moveCards(move1, move2)
    ids = {}
    for _, id in ipairs(target:getMark("ol__zhubi")) do
      if room:getCardOwner(id) == target and room:getCardArea(id) == Card.PlayerHand then
        table.insertIfNeed(ids, id)
      end
    end
    if #ids == 0 then
      room:setPlayerMark(target, "ol__zhubi", 0)
    else
      room:setPlayerMark(target, "ol__zhubi", ids)
    end
  end,
}
ol__tongdu:addRelatedSkill(ol__tongdu_trigger)
ol__zhubi:addRelatedSkill(ol__zhubi_trigger)
liuba:addSkill(ol__tongdu)
liuba:addSkill(ol__zhubi)
Fk:loadTranslationTable{
  ["ol__liuba"] = "刘巴",
  ["ol__tongdu"] = "统度",
  [":ol__tongdu"] = "准备阶段，你可以令一名其他角色交给你一张手牌，然后本回合出牌阶段结束时，若此牌仍在你的手牌中，你将此牌置于牌堆顶。",
  ["ol__zhubi"] = "铸币",
  [":ol__zhubi"] = "出牌阶段限X次，你可以令一名角色重铸一张牌，以此法摸的牌称为“币”；有“币”的角色的结束阶段，其观看牌堆底的五张牌，"..
  "然后可以用任意“币”交换其中等量张牌（X为你的体力上限）。",
  ["#ol__tongdu-choose"] = "统度：你可以令一名其他角色交给你一张手牌，出牌阶段结束时你将之置于牌堆顶",
  ["#ol__tongdu-give"] = "统度：你须交给 %src 一张手牌，出牌阶段结束时将之置于牌堆顶",
  ["#ol__zhubi-card"] = "铸币：重铸一张牌，摸到的“币”可以在你的结束阶段和牌堆底牌交换",

  ["$ol__tongdu1"] = "上下调度，臣工皆有所为。",
  ["$ol__tongdu2"] = "统筹部划，不糜国利分毫。",
  ["$ol__zhubi1"] = "钱货之通者，在乎币。",
  ["$ol__zhubi2"] = "融金为料，可铸五铢。",
  ["~ol__liuba"] = "恨未见，铸兵为币之日……",
}

local macheng = General(extension, "macheng", "shu", 4)
local chenglie = fk.CreateTriggerSkill{
  name = "chenglie",
  anim_type = "control",
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and
      #U.getUseExtraTargets(player.room, data, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, U.getUseExtraTargets(room, data, false), 1, 2,
    "#chenglie-choose:::"..data.card:toLogString(), self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    table.insertTable(data.tos, table.map(self.cost_data, function(p) return {p} end))
    data.extra_data = data.extra_data or {}
    data.extra_data.chenglie = player.id
    local n = #TargetGroup:getRealTargets(data.tos)
    local ids = room:getNCards(n)
    room:moveCardTo(ids, Card.Processing, player, fk.ReasonJustMove, self.name, nil, true, player.id)
    local results = U.askForExchange(player, "Top", "$Hand", ids, player:getCardIds("h"), "#chenglie-exchange", 1)
    if #results > 0 then
      local id1, id2 = results[1], results[2]
      if room:getCardOwner(results[2]) == player then
        id1, id2 = results[2], results[1]
      end
      local move1 = {
        ids = {id1},
        from = player.id,
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        skillName = self.name,
        moveVisible = false,
      }
      local move2 = {
        ids = {id2},
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonExchange,
        skillName = self.name,
        moveVisible = false,
      }
      room:moveCards(move1, move2)
      table.insert(ids, id1)
      table.removeOne(ids, id2)
    end
    if player.dead and #ids > 0 then
      room:moveCardTo(ids, Card.DiscardPile, player, fk.ReasonJustMove, nil, nil, true, nil)
    end
    local fakemove = {
      toArea = Card.PlayerHand,
      to = player.id,
      moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.Processing} end),
      moveReason = fk.ReasonJustMove,
    }
    room:notifyMoveCards({player}, {fakemove})
    for _, id in ipairs(ids) do
      room:setCardMark(Fk:getCardById(id), "chenglie", 1)
    end
    room:setPlayerMark(player, "chenglie-tmp", TargetGroup:getRealTargets(data.tos))
    while table.find(ids, function(id) return Fk:getCardById(id):getMark("chenglie") > 0 end) do
      room:askForUseActiveSkill(player, "chenglie_active", "#chenglie-give", false)
    end
    room:setPlayerMark(player, "chenglie-tmp", 0)
  end,
}
local chenglie_active = fk.CreateActiveSkill{
  name = "chenglie_active",
  mute = true,
  card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Fk:getCardById(to_select):getMark("chenglie") > 0
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and table.contains(Self:getMark("chenglie-tmp"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:doIndicate(player.id, {target.id})
    local mark = player:getMark("chenglie-tmp")
    table.removeOne(mark, target.id)
    room:setPlayerMark(player, "chenglie-tmp", mark)
    room:setCardMark(Fk:getCardById(effect.cards[1]), "chenglie", 0)
    local fakemove = {
      from = player.id,
      toArea = Card.Void,
      moveInfo = table.map(effect.cards, function(id) return {cardId = id, fromArea = Card.PlayerHand} end),
      moveReason = fk.ReasonJustMove,
    }
    room:notifyMoveCards({player}, {fakemove})
    target:addToPile("chenglie", effect.cards[1], false, "chenglie")
  end,
}
local chenglie_trigger = fk.CreateTriggerSkill{
  name = "#chenglie_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.extra_data and data.extra_data.chenglie and data.extra_data.chenglie == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do  --这要是插结完全管不了
      if #p:getPile("chenglie") > 0 then
        local id = p:getPile("chenglie")[1]
        room:moveCards({
          from = p.id,
          ids = p:getPile("chenglie"),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = "chenglie",
        })
        if Fk:getCardById(id).color == Card.Red then
          if data.extra_data.chenglie_cancelled and data.extra_data.chenglie_cancelled[p.id] and not p:isNude() and not player.dead then
            local card = room:askForCard(p, 1, 1, true, "chenglie", false, ".", "#chenglie-card:"..player.id)
            room:obtainCard(player.id, card[1], false, fk.ReasonGive)
          else
            if p:isWounded() then
              room:recover{
              who = p,
              num = 1,
              recoverBy = player,
              skillName = "chenglie",
              }
            end
          end
        end
      end
    end
  end,

  refresh_events = {fk.CardEffectCancelledOut},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.extra_data and data.extra_data.chenglie and data.extra_data.chenglie == player.id
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data.chenglie_cancelled = data.extra_data.chenglie_cancelled or {}
    data.extra_data.chenglie_cancelled[data.to] = true
  end,
}
Fk:addSkill(chenglie_active)
chenglie:addRelatedSkill(chenglie_trigger)
macheng:addSkill("mashu")
macheng:addSkill(chenglie)
Fk:loadTranslationTable{
  ["macheng"] = "马承",
  ["chenglie"] = "骋烈",
  [":chenglie"] = "你使用【杀】可以多指定至多两个目标，然后展示牌堆顶与目标数等量张牌，秘密将一张手牌与其中一张牌交换，将之分别暗置于"..
  "目标角色武将牌上直到此【杀】结算结束，其中“骋烈”牌为红色的角色若：响应了此【杀】，其交给你一张牌；未响应此【杀】，其回复1点体力。",
  ["#chenglie-choose"] = "骋烈：你可以为%arg多指定至多两个目标，并执行后续效果",
  ["#chenglie-exchange"] = "骋烈：你可以用一张手牌交换其中一张牌",
  ["chenglie_active"] = "骋烈",
  ["#chenglie-give"] = "骋烈：将这些牌置于目标角色武将牌上直到【杀】结算结束",
  ["#chenglie-card"] = "骋烈：你需交给 %src 一张牌",

  ["$chenglie1"] = "铁蹄踏南北，烈马惊黄沙！",
  ["$chenglie2"] = "策马逐金雕，跨鞍寻天狼！",
  ["~macheng"] = "儿有辱父祖之威名……",
}

local quhuang = General(extension, "quhuang", "wu", 3)
local qiejian = fk.CreateTriggerSkill{
  name = "qiejian",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local targetRecorded = type(player:getMark("qiejian_prohibit-round")) == "table" and player:getMark("qiejian_prohibit-round") or {}
      for _, move in ipairs(data) do
        if move.from and not table.contains(targetRecorded, move.from) then
          local to = player.room:getPlayerById(move.from)
          if to:isKongcheng() and not to.dead and not table.every(move.moveInfo, function (info)
              return info.fromArea ~= Card.PlayerHand end) then
            return true
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    local targetRecorded = type(player:getMark("qiejian_prohibit-round")) == "table" and player:getMark("qiejian_prohibit-round") or {}
    for _, move in ipairs(data) do
      if move.from and not table.contains(targetRecorded, move.from) then
        local to = player.room:getPlayerById(move.from)
        if to:isKongcheng() and not to.dead and not table.every(move.moveInfo, function (info)
            return info.fromArea ~= Card.PlayerHand end) then
          table.insertIfNeed(targets, move.from)
        end
      end
    end
    room:sortPlayersByAction(targets)
    for _, target_id in ipairs(targets) do
      if not player:hasSkill(self) then break end
      local skill_target = room:getPlayerById(target_id)
      if skill_target and not skill_target.dead and skill_target:isKongcheng() then
        self:doCost(event, skill_target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#qiejian-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:drawCards(player, 1, self.name)
    if not target.dead then
      room:drawCards(target, 1, self.name)
    end
    if player.dead or target.dead then return false end
    local tos = {}
    if #player:getCardIds{Player.Equip, Player.Judge} > 0 then
      table.insert(tos, player.id)
    end
    if player ~= target and #target:getCardIds{Player.Equip, Player.Judge} > 0 then
      table.insert(tos, target.id)
    end
    if #tos > 0 then
      tos = room:askForChoosePlayers(player, tos, 1, 1, "#qiejian-choose::" .. target.id, self.name, true, true)
    end
    if #tos > 0 then
      local to = room:getPlayerById(tos[1])
      local id = room:askForCardChosen(player, to, 'ej', self.name)
      room:throwCard({id}, self.name, to, player)
    else
      local targetRecorded = type(player:getMark("qiejian_prohibit-round")) == "table" and player:getMark("qiejian_prohibit-round") or {}
      table.insertIfNeed(targetRecorded, target.id)
      room:setPlayerMark(player, "qiejian_prohibit-round", targetRecorded)
    end
  end,
}
local nishouchoicefilter = function(player, id)
  local room = player.room
  local choices = {}
  if player:getMark("@@nishou_exchange-phase") == 0 and room.current and room.current.phase <= Player.Finish and
      room.current.phase >= Player.Start then
    table.insert(choices, "nishou_exchange")
  end
  if room:getCardArea(id) == Card.DiscardPile then
    local card = Fk:cloneCard("lightning")
    card:addSubcard(id)
    if not player:hasDelayedTrick("lightning") and not player:prohibitUse(card) and not player:isProhibited(player, card) then
      table.insert(choices, "nishou_lightning")
    end
  end
  return choices
end
local nishou = fk.CreateTriggerSkill{
  name = "nishou",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip and #nishouchoicefilter(player, info.cardId) > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local card_ids = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            table.insertIfNeed(card_ids, info.cardId)
          end
        end
      end
    end
    for _, id in ipairs(card_ids) do
      if not player:hasSkill(self) then break end
      if #nishouchoicefilter(player, id) > 0 then
        self.cost_data = id
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = self.cost_data
    local choices = nishouchoicefilter(player, id)
    if #choices == 0 then return false end
    local choice = room:askForChoice(player, choices, self.name, "#nishou-choice:::" .. Fk:getCardById(id):toLogString())
    if choice == "nishou_lightning" then
      local card = Fk:cloneCard("lightning")
      card:addSubcard(id)
      room:useCard{
        from = player.id,
        tos = {{player.id}},
        card = card,
      }
    else
      room:addPlayerMark(player, "@@nishou_exchange-phase", 1)
    end
  end,
}
local function swapHandCards(room, from, tos, skillname)
  local target1 = room:getPlayerById(tos[1])
  local target2 = room:getPlayerById(tos[2])
  local cards1 = table.clone(target1.player_cards[Player.Hand])
  local cards2 = table.clone(target2.player_cards[Player.Hand])
  local moveInfos = {}
  if #cards1 > 0 then
    table.insert(moveInfos, {
      from = tos[1],
      ids = cards1,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = from,
      skillName = skillname,
    })
  end
  if #cards2 > 0 then
    table.insert(moveInfos, {
      from = tos[2],
      ids = cards2,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = from,
      skillName = skillname,
    })
  end
  if #moveInfos > 0 then
    room:moveCards(table.unpack(moveInfos))
  end
  moveInfos = {}
  if not target2.dead then
    local to_ex_cards = table.filter(cards1, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #to_ex_cards > 0 then
      table.insert(moveInfos, {
        ids = to_ex_cards,
        fromArea = Card.Processing,
        to = tos[2],
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonExchange,
        proposer = from,
        skillName = skillname,
      })
    end
  end
  if not target1.dead then
    local to_ex_cards = table.filter(cards2, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #to_ex_cards > 0 then
      table.insert(moveInfos, {
        ids = to_ex_cards,
        fromArea = Card.Processing,
        to = tos[1],
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonExchange,
        proposer = from,
        skillName = skillname,
      })
    end
  end
  if #moveInfos > 0 then
    room:moveCards(table.unpack(moveInfos))
  end
  table.insertTable(cards1, cards2)
  local dis_cards = table.filter(cards1, function (id)
    return room:getCardArea(id) == Card.Processing
  end)
  if #dis_cards > 0 then
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(dis_cards)
    room:moveCardTo(dummy, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skillname)
  end
end
local nishou_delay = fk.CreateTriggerSkill{
  name = "#nishou_delay",
  events = {fk.EventPhaseEnd},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@nishou_exchange-phase") > 0 and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = {}
    local x = player:getHandcardNum()
    for _, p in ipairs(room.alive_players) do
      local y = p:getHandcardNum()
      if y < x then
        x = y
        tos = {}
        table.insert(tos, p.id)
      elseif y == x then
        table.insert(tos, p.id)
      end
    end
    local cancelable = table.removeOne(tos, player.id)
    if #tos == 0 then return false end
    tos = room:askForChoosePlayers(player, tos, 1, 1, "#nishou-choose", nishou.name, cancelable, true)
    if #tos == 0 then return false end
    swapHandCards(room, player.id, {player.id, tos[1]}, nishou.name)
  end,
}
nishou:addRelatedSkill(nishou_delay)
quhuang:addSkill(qiejian)
quhuang:addSkill(nishou)
Fk:loadTranslationTable{
  ["quhuang"] = "屈晃",
  ["qiejian"] = "切谏",
  [":qiejian"] = "当一名角色失去最后的手牌后，你可以与其各摸一张牌，然后选择一项：1.弃置你或其场上的一张牌；2.你本轮不能对其发动此技能。",
  ["nishou"] = "泥首",
  ["#nishou_delay"] = "泥首",
  [":nishou"] = "锁定技，当你装备区里的牌进入弃牌堆后，你选择一项：1.将此牌当【闪电】使用；2.本阶段结束时，你与一名全场手牌数最少的角色交换手牌且本阶段内你无法选择此项。",

  ["#qiejian-invoke"] = "是否对 %dest 使用 切谏",
  ["#qiejian-choose"] = "切谏：选择一名角色，弃置其场上一张牌，或点取消则本轮内不能再对 %dest 发动 切谏",
  ["#nishou-choice"] = "泥首：选择将%arg当做【闪电】使用，或在本阶段结束时与手牌数最少的角色交换手牌",
  ["nishou_lightning"] = "将此装备牌当【闪电】使用",
  ["nishou_exchange"] = "本阶段结束时与手牌数最少的角色交换手牌",
  ["@@nishou_exchange-phase"] = "泥首",
  ["#nishou-choose"] = "泥首：你需与手牌数最少的角色交换手牌",

  ["$qiejian1"] = "东宫不稳，必使众人生异。",
  ["$qiejian2"] = "今三方鼎持，不宜擅动储君。",
  ["$nishou1"] = "臣以泥涂首，足证本心。",
  ["$nishou2"] = "人生百年，终埋一抔黄土。",
  ["~quhuang"] = "臣死谏于斯，死得其所……",
}

local zhanghua = General(extension, "zhanghua", "jin", 3)
local bihun = fk.CreateTriggerSkill{
  name = "bihun",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and #player.player_cards[Player.Hand] > player:getMaxCards() and data.firstTarget and
      #AimGroup:getAllTargets(data.tos) > 0 and
      not table.every(AimGroup:getAllTargets(data.tos), function(id) return id == player.id end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #AimGroup:getAllTargets(data.tos) == 1 and AimGroup:getAllTargets(data.tos)[1] ~= player.id and room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(AimGroup:getAllTargets(data.tos)[1], data.card, true, fk.ReasonJustMove)
    end
    for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
      AimGroup:cancelTarget(data, id)
    end
  end,
}
local jianhe = fk.CreateActiveSkill{
  name = "jianhe",
  anim_type = "offensive",
  min_card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      return true
    else
      if Fk:getCardById(selected[1]).type == Card.TypeEquip then
        return Fk:getCardById(to_select).type == Card.TypeEquip
      end
      return Fk:getCardById(to_select).trueName == Fk:getCardById(selected[1]).trueName
    end
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):getMark("jianhe-turn") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addPlayerMark(target, "jianhe-turn", 1)
    local n = #effect.cards
    room:recastCard(effect.cards, player, self.name)
    if #target:getCardIds{Player.Hand, Player.Equip} < n then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    else
      local type = Fk:getCardById(effect.cards[1]):getTypeString()
      local cards = room:askForCard(target, n, n, true, self.name, true, ".|.|.|.|.|"..type, "#jianhe-choose:::"..n..":"..type)
      if #cards > 0 then
        room:recastCard(cards, target, self.name)
      else
        room:damage{
          from = player,
          to = target,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = self.name,
        }
      end
    end
  end
}
local chuanwu = fk.CreateTriggerSkill{
  name = "chuanwu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local skills = table.map(Fk.generals[player.general].skills, function(s) return s.name end)
    for i = #skills, 1, -1 do
      if not player:hasSkill(skills[i], true) then
        table.removeOne(skills, skills[i])
      end
    end
    local to_lose = {}
    player.tag[self.name] = player.tag[self.name] or {}
    local n = math.min(player:getAttackRange(), #skills)
    for i = 1, n, 1 do
      if player:hasSkill(skills[i], true) then
        table.insert(to_lose, skills[i])
        table.insert(player.tag[self.name], skills[i])
      end
    end
    player.room:handleAddLoseSkills(player, "-"..table.concat(to_lose, "|-"), nil, true, false)
    player:drawCards(n, self.name)
  end,
}
local chuanwu_record = fk.CreateTriggerSkill{
  name = "#chuanwu_record",

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player.tag["chuanwu"]
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, table.concat(player.tag["chuanwu"], "|"), nil, true, false)
    player.tag["chuanwu"] = {}
  end,
}
chuanwu:addRelatedSkill(chuanwu_record)
zhanghua:addSkill(bihun)
zhanghua:addSkill(jianhe)
zhanghua:addSkill(chuanwu)
Fk:loadTranslationTable{
  ["zhanghua"] = "张华",
  ["bihun"] = "弼昏",
  [":bihun"] = "锁定技，当你使用牌指定其他角色为目标时，若你的手牌数大于手牌上限，你取消之并令唯一目标获得此牌。",
  ["jianhe"] = "剑合",
  [":jianhe"] = "出牌阶段每名角色限一次，你可以重铸至少两张同名牌或至少两张装备牌，令一名角色选择一项：1.重铸等量张与之类型相同的牌；2.受到你造成的1点雷电伤害。",
  ["chuanwu"] = "穿屋",
  [":chuanwu"] = "锁定技，当你造成或受到伤害后，你失去你武将牌上前X个技能直到回合结束（X为你的攻击范围），然后摸等同失去技能数张牌。",
  ["#jianhe-choose"] = "剑合：你需重铸%arg张%arg2，否则受到1点雷电伤害",

  ["$bihun1"] = "辅弼天家，以扶朝纲。",
  ["$bihun2"] = "为国治政，尽忠匡辅。",
  ["$jianhe1"] = "身临朝阙，腰悬太阿。",
  ["$jianhe2"] = "位登三事，当配龙泉。",
  ["$chuanwu1"] = "祝融侵库，剑怀远志。",
  ["$chuanwu2"] = "斩蛇穿屋，其志绥远。",
  ["~zhanghua"] = "桑化为柏，此非不祥乎？",
}

local dongtuna = General(extension, "dongtuna", "qun", 4)
local jianman = fk.CreateTriggerSkill{
  name = "jianman",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      player.tag[self.name] = player.tag[self.name] or {}
      if #player.tag[self.name] < 2 then
        player.tag[self.name] = {}
        return
      end
      local n = 0
      if player.tag[self.name][1][1] == player.id then
        n = n + 1
      end
      if player.tag[self.name][2][1] == player.id then
        n = n + 1
      end
      self.cost_data = {}
      if n == 2 then
        for i = 1, 2, 1 do
          if player.tag[self.name][i][2].name ~= "jink" then
            table.insertIfNeed(self.cost_data, player.tag[self.name][i][2].name)
          end
        end
      elseif n == 1 then
        if player.tag[self.name][1][1] == player.id then
          self.cost_data = player.tag[self.name][2][1]
        else
          self.cost_data = player.tag[self.name][1][1]
        end
      else
        player.tag[self.name] = {}
        return
      end
      player.tag[self.name] = {}
      return self.cost_data
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if type(self.cost_data) == "number" then
      room:doIndicate(player.id, {self.cost_data})
      local to = room:getPlayerById(self.cost_data)
      if to:isNude() then return end
      local card = room:askForCardChosen(player, to, "he", self.name)
      room:throwCard(card, self.name, to, player)
    else
      local name = room:askForChoice(player, self.cost_data, self.name, "#jianman-choice")
      local targets = {}
      if string.find(name, "slash") then
        targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
          return not player:isProhibited(p, Fk:cloneCard(name)) end), Util.IdMapper)
      else
        targets = {player.id}
      end
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#jianman-choose:::"..name, self.name, false)
        if #to > 0 then
          to = to[1]
        else
          to = table.random(targets)
        end
        room:useVirtualCard(name, nil, player, room:getPlayerById(to), self.name, true)
      end
    end
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.type == Card.TypeBasic and not table.contains(data.card.skillNames, self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.tag[self.name] = player.tag[self.name] or {}
    table.insert(player.tag[self.name], {target.id, data.card})
  end,
}
dongtuna:addSkill(jianman)
Fk:loadTranslationTable{
  ["dongtuna"] = "董荼那",
  ["jianman"] = "鹣蛮",
  [":jianman"] = "锁定技，每回合结束时，若本回合前两张基本牌的使用者：均为你，你视为使用其中的一张牌；仅其中之一为你，你弃置另一名使用者一张牌。",
  ["#jianman-choice"] = "选择视为使用的牌名",
  ["#jianman-choose"] = "鹣蛮：选择视为使用【%arg】的目标",

  ["$jianman1"] = "鹄巡山野，见腐羝而聒鸣！",
  ["$jianman2"] = "我蛮夷也，进退可无矩。",
  ["~dongtuna"] = "孟获小儿，安敢杀我！",
}

local zhangyi = General(extension, "ol__zhangyiy", "shu", 4)
local dianjun = fk.CreateTriggerSkill{
  name = "dianjun",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = player,
      damage = 1,
      skillName = self.name,
    }
    player:gainAnExtraPhase(Player.Play)
  end,
}
local kangrui = fk.CreateTriggerSkill{
  name = "kangrui",
  anim_type = "support",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase ~= Player.NotActive and not target.dead then
      if target:getMark("kangrui-turn") == 0 then
        player.room:addPlayerMark(target, "kangrui-turn", 1)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#kangrui-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    local choice = room:askForChoice(player, {"recover", "kangrui_damage"}, self.name, "#kangrui-choice::"..target.id)
    if choice == "recover" then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    else
      room:addPlayerMark(target, "kangrui_damage-turn", 1)
    end
  end,
}
local kangrui_delay = fk.CreateTriggerSkill{
  name = "#kangrui_delay",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("kangrui_damage-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.damage = data.damage + 1
    room:setPlayerMark(player, "kangrui_minus-turn", 1)
    room:setPlayerMark(player, "kangrui_damage-turn", 0)
  end,
}
local kangrui_maxcards = fk.CreateMaxCardsSkill{
  name = "#kangrui_maxcards",
  fixed_func = function(self, player)
    if player:getMark("kangrui_minus-turn") > 0 then
      return 0
    end
  end
}
kangrui:addRelatedSkill(kangrui_maxcards)
kangrui:addRelatedSkill(kangrui_delay)
zhangyi:addSkill(dianjun)
zhangyi:addSkill(kangrui)
Fk:loadTranslationTable{
  ["ol__zhangyiy"] = "张翼",
  ["dianjun"] = "殿军",
  [":dianjun"] = "锁定技，结束阶段结束时，你受到1点伤害并执行一个额外的出牌阶段。",
  ["kangrui"] = "亢锐",
  [":kangrui"] = "当一名角色于其回合内首次受到伤害后，你可以摸一张牌并令其：1.回复1点体力；2.本回合下次造成的伤害+1，然后当其造成伤害时，其此回合手牌上限改为0。",
  ["#kangrui-invoke"] = "亢锐：你可以摸一张牌，令 %dest 回复1点体力或本回合下次造成伤害+1",
  ["kangrui_damage"] = "本回合下次造成伤害+1，造成伤害后本回合手牌上限改为0",
  ["#kangrui_delay"] = "亢锐",
  ["#kangrui-choice"] = "亢锐：选择令 %dest 执行的一项",

  ["$dianjun1"] = "大将军勿忧，翼可领后军。",
  ["$dianjun2"] = "诸将速行，某自领军殿后！",
  ["$kangrui1"] = "尔等魍魉，愿试吾剑之利乎！",
  ["$kangrui2"] = "诸君努力，克复中原指日可待！",
  ["~ol__zhangyiy"] = "伯约不见疲惫之国力乎？",
}

local maxiumatie = General(extension, "maxiumatie", "qun", 4)
local kenshang = fk.CreateViewAsSkill{
  name = "kenshang",
  pattern = "slash",
  card_filter = Util.TrueFunc,
  view_as = function(self, cards)
    if #cards < 2 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    c:addSubcards(cards)
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not player:isProhibited(p, use.card) end), Util.IdMapper)
    local n = math.min(#targets, #use.card.subcards)
    local tos = room:askForChoosePlayers(player, targets, n, n, "#kenshang-choose:::"..n, self.name, true)
    if #tos == n then
      table.forEach(TargetGroup:getRealTargets(use.tos), function (id)
        TargetGroup:removeTarget(use.tos, id)
      end)
      for _, id in ipairs(tos) do
        TargetGroup:pushTargets(use.tos, id)
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    return player:hasSkill(self) and not response
  end,
}
local kenshang_delay = fk.CreateTriggerSkill{
  name = "#kenshang_delay",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and table.contains(data.card.skillNames, "kenshang") and data.damageDealt then
      local n = 0
      for _, p in ipairs(player.room.players) do
        if data.damageDealt[p.id] then
          n = n + data.damageDealt[p.id]
        end
      end
      return #data.card.subcards > n
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, "kenshang")
  end,
}
kenshang:addRelatedSkill(kenshang_delay)
maxiumatie:addSkill("mashu")
maxiumatie:addSkill(kenshang)
Fk:loadTranslationTable{
  ["maxiumatie"] = "马休马铁",
  ["kenshang"] = "垦伤",
  [":kenshang"] = "你可以将至少两张牌当【杀】使用，然后目标可以改为等量的角色。你以此法使用的【杀】结算后，若这些牌数大于此牌造成的伤害，你摸一张牌。",
  ["#kenshang-choose"] = "垦伤：你可以将目标改为指定%arg名角色",

  ["$kenshang1"] = "择兵选将，一击而大白。",
  ["$kenshang2"] = "纵横三辅，垦伤庸富。",
  ["~maxiumatie"] = "我兄弟，愿随父帅赴死。",
}

local zhujun = General(extension, "ol__zhujun", "qun", 4)
local cuipo = fk.CreateTriggerSkill{
  name = "cuipo",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("@cuipo-turn") == #Fk:translate(data.card.trueName)/3
  end,
  on_use = function(self, event, target, player, data)
    if data.card.is_damage_card then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    else
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@cuipo-turn", 1)
  end,
}
zhujun:addSkill(cuipo)
Fk:loadTranslationTable{
  ["ol__zhujun"] = "朱儁",
  ["cuipo"] = "摧破",
  [":cuipo"] = "锁定技，当你每回合使用第X张牌时（X为此牌牌名字数），若为【杀】或伤害锦囊牌，此牌伤害+1，否则你摸一张牌。",
  ["@cuipo-turn"] = "摧破",

  ["$cuipo1"] = "虎贲冯河，何惧千城！",
  ["$cuipo2"] = "长锋在手，万寇辟易。",
  ["~ol__zhujun"] = "李郭匹夫，安敢辱我！",
}

local wangguan = General(extension, "wangguan", "wei", 3)
local miuyan = fk.CreateViewAsSkill{
  name = "miuyan",
  anim_type = "switch",
  switch_skill_name = "miuyan",
  pattern = "fire_attack",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@@miuyan-round") == 0
  end,
}
local miuyan_trigger = fk.CreateTriggerSkill{
  name = "#miuyan_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("miuyan") and table.contains(data.card.skillNames, "miuyan")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState("miuyan", true) == fk.SwitchYang and data.damageDealt then
      local moveInfos = {}
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if not p:isKongcheng() then
          local cards = {}
          for _, id in ipairs(p.player_cards[Player.Hand]) do
            if Fk:getCardById(id):getMark("miuyan") > 0 then
              table.insertIfNeed(cards, id)
            end
          end
          if #cards > 0 then
            table.insert(moveInfos, {
              from = p.id,
              ids = cards,
              to = player.id,
              toArea = Card.PlayerHand,
              moveReason = fk.ReasonPrey,
              proposer = player.id,
              skillName = "miuyan",
            })
          end
        end
      end
      if #moveInfos > 0 then
        room:moveCards(table.unpack(moveInfos))
      end
    elseif player:getSwitchSkillState("miuyan", true) == fk.SwitchYin and not data.damageDealt then
      room:setPlayerMark(player, "@@miuyan-round", 1)
    end
  end,

  refresh_events = {fk.CardShown, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardShown then
      for _, id in ipairs(data.cardIds) do
        room:setCardMark(Fk:getCardById(id), "miuyan", 1)
      end
    else
      for _, id in ipairs(Fk:getAllCardIds()) do
        room:setCardMark(Fk:getCardById(id), "miuyan", 0)
      end
    end
  end,
}
local shilu = fk.CreateTriggerSkill{
  name = "shilu",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(player.hp, self.name)
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return player:inMyAttackRange(p) and not p:isKongcheng() end), Util.IdMapper)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#shilu-choose", self.name, false)
    local to
    if #tos > 0 then
      to = room:getPlayerById(tos[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    local id = room:askForCardChosen(player, to, "h", self.name)
    to:showCards(id)
    if room:getCardArea(id) == Card.PlayerHand then
      room:setCardMark(Fk:getCardById(id), "@@shilu", 1)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
  local room = player.room
    for _, move in ipairs(data) do
      if move.toArea ~= Card.Processing then
        for _, info in ipairs(move.moveInfo) do
          room:setCardMark(Fk:getCardById(info.cardId), "@@shilu", 0)
        end
      end
    end
  end,
}
local shilu_filter = fk.CreateFilterSkill{
  name = "#shilu_filter",
  card_filter = function(self, card, player)
    return card:getMark("@@shilu") > 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
}
miuyan:addRelatedSkill(miuyan_trigger)
shilu:addRelatedSkill(shilu_filter)
wangguan:addSkill(miuyan)
wangguan:addSkill(shilu)
Fk:loadTranslationTable{
  ["wangguan"] = "王瓘",
  ["miuyan"] = "谬焰",
  [":miuyan"] = "转换技，阳：你可以将一张黑色牌当【火攻】使用，若此牌造成伤害，你获得本阶段展示过的所有手牌；"..
  "阴：你可以将一张黑色牌当【火攻】使用，若此牌未造成伤害，本轮本技能失效。",
  ["shilu"] = "失路",
  [":shilu"] = "锁定技，当你受到伤害后，你摸等同体力值张牌并展示攻击范围内一名其他角色的一张手牌，令此牌视为【杀】。",
  ["@@miuyan-round"] = "谬焰失效",
  ["#shilu-choose"] = "失路：展示一名角色的一张手牌，此牌视为【杀】",
  ["@@shilu"] = "失路",
  ["#shilu_filter"] = "失路",

  ["$miuyan1"] = "未时引火，必大败蜀军。",
  ["$miuyan2"] = "我等诈降，必欺姜维于不意。",
  ["$shilu1"] = "吾计不成，吾命何归？",
  ["$shilu2"] = "烟尘四起，无处寻路。",
  ["~wangguan"] = "我本魏将，将军救我！！",
}

local luoxian = General(extension, "luoxian", "shu", 4)
local daili = fk.CreateTriggerSkill{
  name = "daili",
  anim_type = "drawcard",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (player:isKongcheng() or
      #table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@daili") > 0 end) % 2 == 0)
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
    local cards = player:drawCards(3, self.name)
    player:showCards(cards)
  end,

  refresh_events = {fk.CardShown, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardShown then
      return target == player and player:hasSkill(self, true)
    else
      return player:getMark("@$daili") ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@$daili")
    if event == fk.CardShown then
      if mark == 0 then mark = {} end
      for _, id in ipairs(data.cardIds) do
        if Fk:getCardById(id):getMark("@@daili") == 0 then
          table.insert(mark, Fk:getCardById(id, true).name)
          room:setCardMark(Fk:getCardById(id, true), "@@daili", 1)
        end
      end
      room:setPlayerMark(player, "@$daili", mark)
    else
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId, true):getMark("@@daili") > 0 then
              table.removeOne(mark, Fk:getCardById(info.cardId, true).name)
              room:setCardMark(Fk:getCardById(info.cardId, true), "@@daili", 0)
            end
          end
        end
      end
      room:setPlayerMark(player, "@$daili", mark)
    end
  end,
}
luoxian:addSkill(daili)
Fk:loadTranslationTable{
  ["luoxian"] = "罗宪",
  ["daili"] = "带砺",
  [":daili"] = "每回合结束时，若你有偶数张展示过的手牌，你可以翻面，摸三张牌并展示之。",
  ["@$daili"] = "带砺",
  ["@@daili"] = "带砺",

  ["$daili1"] = "国朝倾覆，吾宁当为降虏乎！",
  ["$daili2"] = "弃百姓之所仰，君子不为也。",
  ["~luoxian"] = "汉亡矣，命休矣……",
}

local sunhong = General(extension, "sunhong", "wu", 3)
local xianbi = fk.CreateActiveSkill{
  name = "xianbi",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and #Self.player_cards[Player.Hand] ~= #target.player_cards[Player.Equip] and target:getMark("zenrun") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = #player.player_cards[Player.Hand] - #target.player_cards[Player.Equip]
    if n < 0 then
      player:drawCards(-n, self.name)
    else
      local cards = room:askForDiscard(player, n, n, false, self.name, false, ".", "#xianbi-discard:::"..n)
      for _, id in ipairs(cards) do
        local get = {}
        local card = Fk:getCardById(id, true)
        table.insertTable(get, room:getCardsFromPileByRule(".|.|.|.|.|"..card:getTypeString().."|^"..id, 1, "discardPile"))
        if #get > 0 then
          room:moveCards({
            ids = get,
            to = player.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonJustMove,
            proposer = player.id,
            skillName = self.name,
          })
        end
      end
    end
  end,
}
local zenrun = fk.CreateTriggerSkill{
  name = "zenrun",
  events = {fk.BeforeDrawCard},
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = data.num
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p:getMark(self.name) == 0 and #p:getCardIds{Player.Hand, Player.Equip} >= n end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#zenrun-choose:::"..n, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local n = data.num
    data.num = 0
    local dummy = Fk:cloneCard("dilu")
    local cards = room:askForCardsChosen(player, to, n, n, "he", self.name)
    dummy:addSubcards(cards)
    room:obtainCard(player.id, dummy, false, fk.ReasonPrey)
    local choice = room:askForChoice(to, {"zenrun_draw", "zenrun_forbid"}, self.name, "#zenrun-choice:"..player.id)
    if choice == "zenrun_draw" then
      to:drawCards(n, self.name)
    else
      room:addPlayerMark(to, self.name, 1)
    end
  end,
}
sunhong:addSkill(xianbi)
sunhong:addSkill(zenrun)
Fk:loadTranslationTable{
  ["sunhong"] = "孙弘",
  ["xianbi"] = "险诐",
  [":xianbi"] = "出牌阶段限一次，你可以将手牌调整至与一名角色装备区里的牌数相同，然后每因此弃置一张牌，你随机获得弃牌堆中另一张类型相同的牌。",
  ["zenrun"] = "谮润",
  [":zenrun"] = "每阶段限一次，当你摸牌时，你可以改为获得一名其他角色等量张牌，然后其选择一项："..
  "1.摸等量的牌；2.本局游戏中你发动〖险诐〗和〖谮润〗不能指定其为目标。",
  ["#xianbi-discard"] = "险诐：弃置%arg张手牌，然后随机获得弃牌堆中相同类别的牌",
  ["#zenrun-choose"] = "谮润：你可以将摸牌改为获得一名其他角色%arg张牌，然后其选择摸等量牌或你本局不能对其发动技能",
  ["#zenrun-choice"] = "谮润：选择 %src 令你执行的一项",
  ["zenrun_draw"] = "你摸等量牌",
  ["zenrun_forbid"] = "其本局不能对你发动〖险诐〗和〖谮润〗",

  ["$xianbi1"] = "宦海如薄冰，求生逐富贵。",
  ["$xianbi2"] = "吾不欲为鱼肉，故为刀俎。",
  ["$zenrun1"] = "据图谋不轨，今奉诏索命。",
  ["$zenrun2"] = "休妄论芍陂之战，当诛之。",
  ["~sunhong"] = "诸葛公何至于此……",
}

local zhangshiping = General(extension, "zhangshiping", "shu", 3)
local hongji = fk.CreateTriggerSkill{
  name = "hongji",
  events = {fk.EventPhaseStart},
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Start then
      local room = player.room
      if player:getMark("hongji1used-round") == 0 and table.every(room.alive_players, function (p)
        return p:getHandcardNum() >= target:getHandcardNum()
      end) then
        return true
      end
      if player:getMark("hongji2used-round") == 0 and table.every(room.alive_players, function (p)
        return p:getHandcardNum() <= target:getHandcardNum()
      end) then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel"}
    if player:getMark("hongji1used-round") == 0 and table.every(room.alive_players, function (p)
      return p:getHandcardNum() >= target:getHandcardNum()
    end) then
      table.insert(choices, "hongji1")
    end
    if player:getMark("hongji2used-round") == 0 and table.every(room.alive_players, function (p)
      return p:getHandcardNum() <= target:getHandcardNum()
    end) then
      table.insert(choices, "hongji2")
    end
    local choice = room:askForChoice(player, choices, self.name, "#hongji-invoke::" .. target.id, false, {"hongji1", "hongji2", "Cancel"})
    if choice ~= "Cancel" then
      room:doIndicate(player.id, {target.id})
      room:addPlayerMark(player, choice .. "used-round")
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(target, self.cost_data.."-turn", 1)
  end,
}
local hongji_delay = fk.CreateTriggerSkill{
  name = "#hongji_delay",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and ((player.phase == Player.Draw and player:getMark("hongji1-turn") > 0) or
    (player.phase == Player.Play and player:getMark("hongji2-turn") > 0))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if player.phase == Player.Draw then
      player.room:setPlayerMark(player, "hongji1-turn", 0)
      player:gainAnExtraPhase(Player.Draw)
    else
      player.room:setPlayerMark(player, "hongji2-turn", 0)
      player:gainAnExtraPhase(Player.Play)
    end
  end,
}
local xinggu = fk.CreateTriggerSkill{
  name = "xinggu",
  anim_type = "support",
  events = {fk.GameStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      else
        return target == player and player.phase == Player.Finish and #player:getPile(self.name) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    else
      local _, ret = player.room:askForUseActiveSkill(player, "xinggu_active", "#xinggu-invoke", true)
      if ret then
        self.cost_data = ret
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local cards = {}
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).sub_type == Card.SubtypeOffensiveRide or Fk:getCardById(id).sub_type == Card.SubtypeDefensiveRide then
          table.insertIfNeed(cards, id)
        end
      end
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(table.random(cards, 3))
      player:addToPile(self.name, dummy, true, self.name)
    else
      local ret = self.cost_data
      room:moveCards({
        ids = ret.cards,
        from = player.id,
        to = ret.targets[1],
        toArea = Card.PlayerEquip,
        moveReason = fk.ReasonPut,
        fromSpecialName = "xinggu",
      })
      if player.dead then return false end
      local card = room:getCardsFromPileByRule(".|.|diamond")
      if #card > 0 then
        room:moveCards({
          ids = card,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
  end,
}
local xinggu_active = fk.CreateActiveSkill{
  name = "xinggu_active",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  expand_pile = "xinggu",
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Self:getPileNameOfId(to_select) == "xinggu"
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and #cards == 1 and to_select ~= Self.id and
      Fk:currentRoom():getPlayerById(to_select):getEquipment(Fk:getCardById(cards[1]).sub_type) == nil
  end,
}
Fk:addSkill(xinggu_active)
hongji:addRelatedSkill(hongji_delay)
zhangshiping:addSkill(hongji)
zhangshiping:addSkill(xinggu)
Fk:loadTranslationTable{
  ["zhangshiping"] = "张世平",
  ["hongji"] = "鸿济",
  [":hongji"] = "每轮各限一次，每名角色的准备阶段，若其手牌数为全场最少/最多，你可以令其于本回合摸牌/出牌阶段后额外执行一个摸牌/出牌阶段。",
  --两个条件均满足的话只能选择其中一个发动
  --测不出来鸿济生效的时机（不会和开始时或者结束时自选），只知道跳过此阶段之后不能获得额外阶段
  --暂定摸牌/出牌结束时，获得一个额外摸牌/出牌阶段
  ["xinggu"] = "行贾",
  [":xinggu"] = "游戏开始时，你将随机三张坐骑牌置于你的武将牌上。结束阶段，你可以将其中一张牌置于一名其他角色的装备区，"..
  "然后你获得牌堆中一张<font color='red'>♦</font>牌。",

  ["#hongji-invoke"] = "你可以发动 鸿济，令 %dest 获得一个额外的阶段",
  ["hongji1"] = "令其获得额外摸牌阶段",
  ["hongji2"] = "令其获得额外出牌阶段",
  ["#hongji_delay"] = "鸿济",
  ["#xinggu-invoke"] = "行贾：你可以将一张“行贾”坐骑置入一名其他角色的装备区，然后获得一张<font color='red'>♦</font>牌",
  ["xinggu_active"] = "行贾",

  ["$hongji1"] = "玄德公当世人杰，奇货可居。",
  ["$hongji2"] = "张某慕君高义，愿鼎力相助。",
  ["$xinggu1"] = "乱世烽烟，贾者如火中取栗尔。	",
  ["$xinggu2"] = "天下动荡，货行千里可易千金。",
  ["~zhangshiping"] = "奇货犹在，其人老矣……",
}

local lushi = General(extension, "lushi", "qun", 3, 3, General.Female)
local function setZhuyanMark(p)  --FIXME：先用个mark代替贴脸文字
  local room = p.room
  if p:getMark("zhuyan1") == 0 then
    local sig = ""
    local n = p:getMark("zhuyan")[1] - p.hp
    if n > 0 then
      sig = "+"
    end
    room:setPlayerMark(p, "@zhuyan1", sig..tostring(n))
  end
  if p:getMark("zhuyan2") == 0 then
    local sig = ""
    local n = p:getMark("zhuyan")[2] - p:getHandcardNum()
    if n > 0 then
      sig = "+"
    end
    room:setPlayerMark(p, "@zhuyan2", sig..tostring(n))
  end
end
local zhuyan = fk.CreateTriggerSkill{
  name = "zhuyan",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(table.filter(player.room.alive_players, function(p)
      return p:getMark("zhuyan1") == 0 or p:getMark("zhuyan2") == 0 end), Util.IdMapper)
    if #targets == 0 then return end
    for _, id in ipairs(targets) do
      local p = player.room:getPlayerById(id)
      setZhuyanMark(p)
    end
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#zhuyan-choose", self.name, true)
    for _, id in ipairs(targets) do
      local p = player.room:getPlayerById(id)
      player.room:setPlayerMark(p, "@zhuyan1", 0)
      player.room:setPlayerMark(p, "@zhuyan2", 0)
    end
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    setZhuyanMark(to)
    local choices = {}
    if to:getMark("zhuyan1") == 0 then
      table.insert(choices, "@zhuyan1")
    end
    if to:getMark("zhuyan2") == 0 then
      table.insert(choices, "@zhuyan2")
    end
    local choice = room:askForChoice(player, choices, self.name, "#zhuyan-choice::"..to.id)
    room:setPlayerMark(to, "@zhuyan1", 0)
    room:setPlayerMark(to, "@zhuyan2", 0)
    if choice == "@zhuyan1" then
      room:setPlayerMark(to, "zhuyan1", 1)
      local n = to:getMark(self.name)[1] - to.hp
      if n > 0 then
        if to:isWounded() then
          room:recover({
            who = to,
            num = math.min(to:getLostHp(), n),
            recoverBy = player,
            skillName = self.name
          })
        end
      elseif n < 0 then
        room:loseHp(to, -n, self.name)
      end
    else
      room:setPlayerMark(to, "zhuyan2", 1)
      local n = to:getMark(self.name)[2] - to:getHandcardNum()
      if n > 0 then
        to:drawCards(n, self.name)
      elseif n < 0 then
        room:askForDiscard(to, -n, -n, false, self.name, false)
      end
    end
  end,

  refresh_events = {fk.GameStart , fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    else
      return target == player and player.phase == Player.Start
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, {player.hp, math.min(player:getHandcardNum(), 5)})
  end,
}
local leijie = fk.CreateTriggerSkill{
  name = "leijie",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), Util.IdMapper), 1, 1, "#leijie-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local judge = {
      who = to,
      reason = self.name,
      pattern = ".|2~9|spade",
    }
    room:judge(judge)
    if judge.card.suit == Card.Spade and judge.card.number >= 2 and judge.card.number <= 9 then
      room:damage{
        to = to,
        damage = 2,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    else
      to:drawCards(2, self.name)
    end
  end,
}
lushi:addSkill(zhuyan)
lushi:addSkill(leijie)
Fk:loadTranslationTable{
  ["lushi"] = "卢氏",
  ["zhuyan"] = "驻颜",
  [":zhuyan"] = "结束阶段，你可以令一名角色将以下项调整至与其上个准备阶段结束时（若无则改为游戏开始时）相同：体力值；手牌数（至多摸至五张）。"..
  "每名角色每项限一次",
  ["leijie"] = "雷劫",
  [":leijie"] = "准备阶段，你可以令一名角色判定，若结果为♠2~9，其受到2点雷电伤害，否则其摸两张牌。",
  ["#zhuyan-choose"] = "驻颜：你可以令一名角色将体力值或手牌数调整至与其上个准备阶段相同",
  ["#zhuyan-choice"] = "驻颜：选择令 %dest 调整的一项",
  ["#leijie-choose"] = "雷劫：令一名角色判定，若为♠2~9，其受到2点雷电伤害，否则其摸两张牌",

  ["@zhuyan1"] = "体力",
  ["@zhuyan2"] = "手牌",

  ["$zhuyan1"] = "心有灵犀，面如不老之椿。",
  ["$zhuyan2"] = "驻颜有术，此间永得芳容。",
  ["$leijie1"] = "雷劫锻体，清瘴涤魂。",
  ["$leijie2"] = "欲得长生，必受此劫。",
  ["~lushi"] = "人世寻大道，何其愚也……",
}

local zhouqun = General(extension, "ol__zhouqun", "shu", 4)
local tianhou = fk.CreateTriggerSkill{
  name = "tianhou",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and (player:hasSkill(self) or player:getMark(self.name) ~= 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark(self.name) ~= 0 then
      local p = room:getPlayerById(player:getMark(self.name)[1])
      if p:hasSkill(player:getMark(self.name)[2], true, true) then
        room:handleAddLoseSkills(p, "-"..player:getMark(self.name)[2], nil, true, false)
      end
    end
    if not player:hasSkill(self) then return end
    local piles = room:askForExchange(player, {room:getNCards(1), player:getCardIds{Player.Hand, Player.Equip}},
      {"Top", player.general}, self.name)
    if room:getCardOwner(piles[1][1]) == player then
      local cards1, cards2 = {piles[1][1]}, {}
      for _, id in ipairs(piles[2]) do
        if room:getCardArea(id) ~= Player.Hand then
          table.insert(cards2, id)
          break
        end
      end
      local move1 = {
        ids = cards1,
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
      local move2 = {
        ids = cards2,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
      room:moveCards(move1, move2)
    else
      table.insert(room.draw_pile, 1, piles[1][1])
    end
    local card = room:getNCards(1)
    room:moveCards({
      ids = card,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    room:sendFootnote(card, {
      type = "##ShowCard",
      from = player.id,
    })
    local suits = {Card.Heart, Card.Diamond, Card.Spade, Card.Club}
    local i = table.indexOf(suits, Fk:getCardById(card[1], true).suit)
    local targets = table.map(room.alive_players, Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1,
      "#tianhou-choose:::".."tianhou"..i..":"..Fk:translate(":tianhou"..i), self.name, false)
    if #to > 0 then
      to = room:getPlayerById(to[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    room:moveCards({
      ids = card,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    room:setPlayerMark(player, self.name, {to.id, "tianhou"..i})
    room:handleAddLoseSkills(to, "tianhou"..i, nil, true, false)
  end,
}
local tianhou1 = fk.CreateTriggerSkill{
  name = "tianhou1",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Finish and not target.dead and
      table.every(player.room:getOtherPlayers(target), function(p) return target.hp >= p.hp end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(target, 1, self.name)
  end,
}
local tianhou2 = fk.CreateTriggerSkill{
  name = "tianhou2",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self) and data.card.trueName == "slash" and #AimGroup:getAllTargets(data.tos) == 1 then
      local to = player.room:getPlayerById(AimGroup:getAllTargets(data.tos)[1])
      return to:getNextAlive() ~= target and target:getNextAlive() ~= to
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = data.card.number
    local pattern = ".|14"
    if n < 13 then
      pattern = ".|"..tostring(n + 1).."~13"
    end
    local judge = {
      who = target,
      reason = self.name,
      pattern = pattern,
    }
    room:judge(judge)
    if judge.card.number > data.card.number then
      data.nullifiedTargets = table.map(room.alive_players, Util.IdMapper)
    end
  end,
}
local tianhou3 = fk.CreateTriggerSkill{
  name = "tianhou3",
  anim_type = "offensive",
  events = {fk.DamageCaused, fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.DamageCaused then
        return target ~= player and data.damageType == fk.FireDamage
      else
        return data.damageType == fk.ThunderDamage
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      return true
    else
      local room = player.room
      for _, p in ipairs(room:getOtherPlayers(data.to)) do
        if not p.dead and p:getMark("tianhou_lose") > 0 then
          room:loseHp(p, 1, self.name)
        end
      end
    end
  end,

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.damageType == fk.ThunderDamage
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if target:getNextAlive() == p or p:getNextAlive() == target then
        room:setPlayerMark(p, "tianhou_lose", 1)
      else
        room:setPlayerMark(p, "tianhou_lose", 0)
      end
    end
  end,
}
local tianhou4 = fk.CreateTriggerSkill{
  name = "tianhou4",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Finish and not target.dead and
      table.every(player.room:getOtherPlayers(target), function(p) return target.hp <= p.hp end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(target, 1, self.name)
  end,
}
local chenshuo = fk.CreateTriggerSkill{
  name = "chenshuo",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForCard(player, 1, 1, false, self.name, true, ".", "#chenshuo-invoke")
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:showCards(self.cost_data)
    if player.dead then return end
    local card = Fk:getCardById(self.cost_data[1])
    local dummy = Fk:cloneCard("dilu")
    for i = 1, 3, 1 do
      local get = room:getNCards(1)
      room:moveCards{
        ids = get,
        toArea = Card.Processing,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
      dummy:addSubcard(get[1])
      local card2 = Fk:getCardById(get[1], true)
      if card.type == card2.type or card.suit == card2.suit or card.number == card2.number or
        #Fk:translate(card.trueName) == #Fk:translate(card2.trueName) then
        room:setCardEmotion(get[1], "judgegood")
        room:delay(1000)
      else
        room:setCardEmotion(get[1], "judgebad")
        room:delay(1000)
        break
      end
    end
    room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
  end,
}
zhouqun:addSkill(tianhou)
zhouqun:addSkill(chenshuo)
zhouqun:addRelatedSkill(tianhou1)
zhouqun:addRelatedSkill(tianhou2)
zhouqun:addRelatedSkill(tianhou3)
zhouqun:addRelatedSkill(tianhou4)
Fk:loadTranslationTable{
  ["ol__zhouqun"] = "周群",
  ["tianhou"] = "天候",
  [":tianhou"] = "锁定技，准备阶段，你观看牌堆顶牌并选择是否用一张牌交换之，然后展示牌堆顶的牌，令一名角色根据此牌花色获得技能直到你下个准备阶段："..
  "<font color='red'>♥</font>〖烈暑〗；<font color='red'>♦</font>〖凝雾〗；♠〖骤雨〗；♣〖严霜〗。",
  ["chenshuo"] = "谶说",
  [":chenshuo"] = "结束阶段，你可以展示一张手牌。若如此做，展示牌堆顶牌，若两张牌类型/花色/点数/牌名字数中任意项相同且展示牌数不大于3，重复此流程。"..
  "然后你获得以此法展示的牌。",
  ["tianhou1"] = "烈暑",
  [":tianhou1"] = "锁定技，其他角色的结束阶段，若其体力值全场最大，其失去1点体力。",
  ["tianhou2"] = "凝雾",
  [":tianhou2"] = "锁定技，当其他角色使用【杀】指定不与其相邻的角色为唯一目标时，其判定，若判定牌点数大于此【杀】，此【杀】无效。",
  ["tianhou3"] = "骤雨",
  [":tianhou3"] = "锁定技，防止其他角色造成的火焰伤害。当一名角色受到雷电伤害后，其相邻的角色失去1点体力。",
  ["tianhou4"] = "严霜",
  [":tianhou4"] = "锁定技，其他角色的结束阶段，若其体力值全场最小，其失去1点体力。",
  ["#tianhou-choose"] = "天候：令一名角色获得技能<br>〖%arg〗：%arg2",
  ["#chenshuo-invoke"] = "谶说：你可以展示一张手牌，亮出并获得牌堆顶至多三张相同类型/花色/点数/字数的牌",

  ["$tianhou1"] = "雷霆雨露，皆为君恩。",
  ["$tianhou2"] = "天象之所显，世事之所为。",
  ["$chenshuo1"] = "命数玄奥，然吾可言之。",
  ["$chenshuo2"] = "天地神鬼之辩，在吾唇舌之间。",
  ["$tianhou11"] = "七月流火，涸我山泽。",
  ["$tianhou21"] = "云雾弥野，如夜之幽。",
  ["$tianhou31"] = "月离于毕，俾滂沱矣。",
  ["$tianhou41"] = "雪瀑寒霜落，霜下可折竹。",
  ["~ol__zhouqun"] = "知万物而不知己命，大谬也……",
}

Fk:loadTranslationTable{
  ["ol__liuyan"] = "刘焉",
  ["pianan"] = "偏安",
  [":pianan"] = "锁定技，游戏开始时和你的弃牌阶段结束时，你弃置不为【闪】的手牌并从牌堆或弃牌堆获得【闪】至你的体力值。",
  ["yinji"] = "殷积",
  [":yinji"] = "锁定技，结束阶段，若你不是体力值唯一最大的角色，你回复1点体力或增加1点体力上限。",
  ["kuisi"] = "窥伺",
  [":kuisi"] = "锁定技，你跳过摸牌阶段，改为观看牌堆顶的4张牌并使用其中任意张，若你以此法使用的牌数不为2或3，你减少1点体力上限。",
}

local haopu = General(extension, "haopu", "shu", 4)
local zhenying = fk.CreateActiveSkill{
  name = "zhenying",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#zhenying",
  can_use = function(self, player)
    return player:usedCardTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Self:getHandcardNum() >= Fk:currentRoom():getPlayerById(to_select):getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local tos = {player, target}
    for _, p in ipairs(tos) do
      local choices = {"0", "1", "2"}
      p.request_data = json.encode({choices, choices, self.name, "#zhenying-choice"})
    end
    room:notifyMoveFocus(tos, self.name)
    room:doBroadcastRequest("AskForChoice", tos)
    for _, p in ipairs(tos) do
      local n
      if p.reply_ready then
        n = p:getHandcardNum() - tonumber(p.client_reply)
      else
        n = p:getHandcardNum() - 2
      end
      room:setPlayerMark(p, "zhenying-tmp", n)
      if n > 0 then
        local extraData = {
          num = n,
          min_num = n,
          include_equip = false,
          pattern = ".",
          reason = self.name,
        }
        p.request_data = json.encode({ "choose_cards_skill", "#zhenying-discard:::"..n, true, extraData })
      end
    end
    room:notifyMoveFocus(tos, self.name)
    room:doBroadcastRequest("AskForUseActiveSkill", tos)
    for _, p in ipairs(tos) do
      local n = p:getMark("zhenying-tmp")
      if n < 0 then
        p:drawCards(-n, self.name)
      elseif n > 0 then
        if p.reply_ready then
          local replyCard = json.decode(p.client_reply).card
          room:throwCard(json.decode(replyCard).subcards, self.name, p, p)
        else
          room:throwCard(table.random(p:getCardIds("h"), n), self.name, p, p)
        end
      end
      room:setPlayerMark(p, "zhenying-tmp", 0)
    end
    if not player.dead and not target.dead and player:getHandcardNum() ~= target:getHandcardNum() then
      local from, to = player, target
      if player:getHandcardNum() > target:getHandcardNum() then
        from, to = target, player
      end
      room:useVirtualCard("duel", nil, from, to, self.name)
    end
  end,
}
haopu:addSkill(zhenying)
Fk:loadTranslationTable{
  ["haopu"] = "郝普",
  ["zhenying"] = "镇荧",
  [":zhenying"] = "出牌阶段限两次，你可以与一名手牌数不大于你的其他角色同时摸或弃置手牌至至多两张，然后手牌数较少的角色视为对另一名角色使用【决斗】。",
  ["#zhenying"] = "镇荧：与一名角色同时选择将手牌调整至0~2",
  ["#zhenying-choice"] = "镇荧：选择你要调整至的手牌数",
  ["#zhenying-discard"] = "镇荧：请弃置%arg张手牌",

  ["$zhenying1"] = "吾闻世间有忠义，今欲为之。",
  ["$zhenying2"] = "吴虽兵临三郡，普宁死不降。",
  ["~haopu"] = "徒做奔臣，死无其所……",
}

local mengda = General(extension, "ol__mengda", "shu", 4)
mengda.subkingdom = "wei"
local goude = fk.CreateTriggerSkill{
  name = "goude",
  anim_type = "control",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local room = player.room
      for _, p in ipairs(room.alive_players) do
        if p.kingdom == player.kingdom then
          local events = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
            for _, move in ipairs(e.data) do
              if move.to == p.id and move.toArea == Player.Hand and move.moveReason == fk.ReasonDraw and #move.moveInfo == 1 then
                return true
              elseif move.moveReason == fk.ReasonDiscard and move.proposer == p.id and #move.moveInfo == 1 then
                for _, info in ipairs(move.moveInfo) do
                  if info.fromArea == Card.PlayerHand then
                    return true
                  end
                end
              end
            end
          end, Player.HistoryTurn)
          if #events > 0 then return true end
          events = room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
            local use = e.data[1]
            return use.from == p.id and use.card.trueName == "slash" and use.card:getEffectiveId() == nil
          end, Player.HistoryTurn)
          if #events > 0 then return true end
          events = room.logic:getEventsOfScope(GameEvent.ChangeProperty, 1, function(e)
            local dat = e.data[1]
            return dat.from == p and dat.results and dat.results["kingdomChange"]
          end, Player.HistoryTurn)
          if #events > 0 then return true end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel", "draw1", "goude2", "goude3", "goude4"}
    if table.every(room.alive_players, function(pl) return pl:isKongcheng() end) then
      table.removeOne(choices, "goude2")
    end
    for _, p in ipairs(room.alive_players) do
      if p.kingdom == player.kingdom then
        local events
        if table.contains(choices, "draw1") then
          events = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
            for _, move in ipairs(e.data) do
              if move.to == p.id and move.toArea == Player.Hand and move.moveReason == fk.ReasonDraw and #move.moveInfo == 1 then
                return true
              end
            end
          end, Player.HistoryTurn)
          if #events > 0 then
            table.removeOne(choices, "draw1")
          end
        end
        if table.contains(choices, "goude2") then
          events = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
            for _, move in ipairs(e.data) do
              if move.to == p.id and move.toArea == Player.Hand and move.moveReason == fk.ReasonDraw and #move.moveInfo == 1 then
                return true
              end
              if move.moveReason == fk.ReasonDiscard and move.proposer == p.id and #move.moveInfo == 1 then
                for _, info in ipairs(move.moveInfo) do
                  if info.fromArea == Card.PlayerHand then
                    return true
                  end
                end
              end
            end
          end, Player.HistoryTurn)
          if #events > 0 then
            table.removeOne(choices, "goude2")
          end
        end
        if table.contains(choices, "goude3") then
          events = room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
            local use = e.data[1]
            return use.from == p.id and use.card.trueName == "slash" and use.card:getEffectiveId() == nil
          end, Player.HistoryTurn)
          if #events > 0 then
            table.removeOne(choices, "goude3")
          end
        end
        if table.contains(choices, "goude4") then
          events = room.logic:getEventsOfScope(GameEvent.ChangeProperty, 1, function(e)
            local dat = e.data[1]
            return dat.from == p and dat.results and dat.results["kingdomChange"]
          end, Player.HistoryTurn)
          if #events > 0 then
            table.removeOne(choices, "goude4")
          end
        end
      end
    end
    if #choices == 1 then return end
    local choice
    while choice ~= "Cancel" do
      choice = room:askForChoice(player, choices, self.name, "#goude-choice", false, {"Cancel", "draw1", "goude2", "goude3", "goude4"})
      if choice == "draw1" or choice == "goude4" then
        self.cost_data = {choice}
        return true
      elseif choice == "goude2" then
        local targets = table.map(table.filter(room.alive_players, function(pl)
          return not pl:isKongcheng() end), function(pl) return pl.id end)
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#goude-choose", self.name, true)
        if #to > 0 then
          self.cost_data = {choice, to[1]}
          return true
        end
      elseif choice == "goude3" then
        local success, dat = room:askForUseActiveSkill(player, "goude_viewas", "#goude-slash", true)
        if success then
          self.cost_data = {choice, dat}
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data[1] == "draw1" then
      player:drawCards(1, self.name)
    elseif self.cost_data[1] == "goude2" then
      local to = room:getPlayerById(self.cost_data[2])
      local id = room:askForCardChosen(player, to, "h", self.name)
      room:throwCard({id}, self.name, to, player)
    elseif self.cost_data[1] == "goude3" then
      local card = Fk.skills["goude_viewas"]:viewAs(self.cost_data[2].cards)
      room:useCard{
        from = player.id,
        tos = table.map(self.cost_data[2].targets, function(id) return {id} end),
        card = card,
        extraUse = true,
      }
    elseif self.cost_data[1] == "goude4" then
      local allKingdoms = {"wei", "shu", "wu", "qun", "jin"}
      local exceptedKingdoms = {player.kingdom}
      for _, kingdom in ipairs(exceptedKingdoms) do
        table.removeOne(allKingdoms, kingdom)
      end
      local kingdom = room:askForChoice(player, allKingdoms, "AskForKingdom", "#ChooseInitialKingdom")
      room:changeKingdom(player, kingdom, true)
    end
  end,
}
local goude_viewas = fk.CreateViewAsSkill{
  name = "goude_viewas",
  pattern = "slash",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard("slash")
    card.skillName = "goude"
    return card
  end,
}
Fk:addSkill(goude_viewas)
mengda:addSkill(goude)
Fk:loadTranslationTable{
  ["ol__mengda"] = "孟达",
  ["goude"] = "苟得",
  [":goude"] = "每回合结束时，若有势力相同的角色此回合执行过以下效果，你可以执行另一项：1.摸一张牌；2.弃置一名角色一张手牌；"..
  "3.视为使用一张【杀】；4.变更势力。",
  ["#goude-choice"] = "苟得：你可以选择执行一项",
  ["goude2"] = "弃置一名角色一张手牌",
  ["goude3"] = "视为使用一张【杀】",
  ["goude4"] = "变更势力",
  ["#goude-choose"] = "苟得：选择一名角色，弃置其一张手牌",
  ["#goude-slash"] = "苟得：视为使用一张【杀】",
  ["goude_viewas"] = "苟得",

  ["$goude1"] = "蝼蚁尚且偷生，况我大将军乎。",
  ["$goude2"] = "为保身家性命，做奔臣又如何？",
  ["~ol__mengda"] = "丞相援军何其远乎？",
}

local wenqin = General(extension, "ol__wenqin", "wei", 4)
wenqin.subkingdom = "wu"
local guangao = fk.CreateTriggerSkill{
  name = "guangao",
  anim_type = "control",
  events = {fk.AfterCardTargetDeclared, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.card.trueName == "slash" then
      if event == fk.AfterCardTargetDeclared then
        local orig_tos = TargetGroup:getRealTargets(data.tos)
        if target == player then
          return table.find(player.room:getOtherPlayers(player), function(p)
          return not table.contains(orig_tos, p.id) and not player:isProhibited(p, data.card)
          and data.card.skill:modTargetFilter(p.id, orig_tos, data.from, data.card, true)
          end)
        else
          return not table.contains(orig_tos, player.id) and not target:isProhibited(player, data.card)
          and data.card.skill:modTargetFilter(player.id, orig_tos, data.from, data.card, true)
        end
      else
        return data.extra_data and data.extra_data.guangao and table.contains(data.extra_data.guangao, player.id) and
          player:getHandcardNum() % 2 == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event ~= fk.AfterCardTargetDeclared then return true end
    local room = player.room
    if target == player then
      local orig_tos = TargetGroup:getRealTargets(data.tos)
      local targets = table.filter(room:getOtherPlayers(player), function(p)
        return not table.contains(TargetGroup:getRealTargets(data.tos), p.id) and not player:isProhibited(p, data.card)
        and data.card.skill:modTargetFilter(p.id, orig_tos, data.from, data.card, true)
      end)
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#guangao-choose:::"..data.card:toLogString(), self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
    else
      if room:askForSkillInvoke(target, self.name, nil, "#guangao2-invoke:"..player.id) then
        self.cost_data = player.id
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardTargetDeclared then
      local toId = self.cost_data
      room:doIndicate(target.id, {toId})
      table.insert(data.tos, {toId})
      room:sendLog{
        type = "#AddTargetsBySkill",
        from = target.id,
        to = {toId},
        arg = self.name,
        arg2 = data.card:toLogString()
      }
      data.extra_data = data.extra_data or {}
      data.extra_data.guangao = data.extra_data.guangao or {}
      table.insertIfNeed(data.extra_data.guangao, player.id)
    else
      player:drawCards(1, self.name)
      local targets = AimGroup:getAllTargets(data.tos)
      local tos = room:askForChoosePlayers(player, targets, 1, #targets, "#guangao-cancel:::"..data.card:toLogString(), self.name, true)
      if #tos > 0 then
        for _, id in ipairs(tos) do
          table.insertIfNeed(data.nullifiedTargets, id)
        end
      end
    end
  end,
}
local huiqi = fk.CreateTriggerSkill{
  name = "huiqi",
  frequency = Skill.Wake,
  anim_type = "offensive",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    local events = room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      local use = e.data[1]
      for _, id in ipairs(TargetGroup:getRealTargets(use.tos)) do
        table.insertIfNeed(targets, id)
      end
    end, Player.HistoryTurn)
    return #targets == 3 and table.contains(targets, player.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:handleAddLoseSkills(player, "xieju", nil, true, false)
  end,
}
local xieju = fk.CreateActiveSkill{
  name = "xieju",
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  prompt = "#xieju",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player:getMark("xieju-turn") ~= 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return Self:getMark("xieju-turn") ~= 0 and table.contains(Self:getMark("xieju-turn"), to_select)
  end,
  on_use = function(self, room, effect)
    for _, id in ipairs(effect.tos) do
      local target = room:getPlayerById(id)
      if not target.dead and not target:isNude() then
        local success, dat = room:askForUseViewAsSkill(target, "xieju_viewas", "#xieju-slash", true, {bypass_times = true})
        if success then
          local card = Fk.skills["xieju_viewas"]:viewAs(dat.cards)
          room:useCard{
            from = target.id,
            tos = table.map(dat.targets, function(p) return {p} end),
            card = card,
            extraUse = true,
          }
        end
      end
    end
  end,
}
local xieju_record = fk.CreateTriggerSkill{
  name = "#xieju_record",

  refresh_events = {fk.TargetConfirmed},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill("xieju", true)
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("xieju-turn")
    if mark == 0 then mark = {} end
    for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
      table.insertIfNeed(mark, id)
    end
    player.room:setPlayerMark(player, "xieju-turn", mark)
  end,
}
local xieju_viewas = fk.CreateViewAsSkill{
  name = "xieju_viewas",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card:addSubcard(cards[1])
    card.skillName = "xieju"
    return card
  end,
}
xieju:addRelatedSkill(xieju_record)
Fk:addSkill(xieju_viewas)
wenqin:addSkill(guangao)
wenqin:addSkill(huiqi)
wenqin:addRelatedSkill(xieju)
Fk:loadTranslationTable{
  ["ol__wenqin"] = "文钦",
  ["guangao"] = "犷骜",
  [":guangao"] = "你使用【杀】可以额外指定一个目标；其他角色使用【杀】可以额外指定你为目标（均有距离限制）。以此法使用的【杀】指定目标后，"..
  "若你的手牌数为偶数，你摸一张牌，令此【杀】对任意名角色无效。",
  ["huiqi"] = "彗企",
  [":huiqi"] = "觉醒技，每个回合结束时，若本回合仅有包括你的三名角色成为过牌的目标，你回复1点体力并获得〖偕举〗。",
  ["xieju"] = "偕举",
  [":xieju"] = "出牌阶段限一次，你可以选择令任意名本回合成为过牌的目标的角色，这些角色依次可以将一张黑色牌当【杀】使用。",
  ["#guangao-choose"] = "犷骜：你可以为此%arg额外指定一个目标",
  ["#guangao2-invoke"] = "犷骜：此%arg可以额外指定 %src 为目标",
  ["#guangao-cancel"] = "犷骜：你可以令此%arg对任意名角色无效",
  ["#xieju"] = "偕举：选择任意名角色，这些角色可以将一张黑色牌当【杀】使用",
  ["#xieju-slash"] = "偕举：你可以将一张黑色牌当【杀】使用",
  ["xieju_viewas"] = "偕举",
  ["#AddTargetsBySkill"] = "用于 %arg 的效果，%from 使用的 %arg2 增加了目标 %to",

  ["$guangao1"] = "策马觅封侯，长驱万里之数。",
  ["$guangao2"] = "大丈夫行事，焉能畏首畏尾。",
  ["$huiqi1"] = "今大星西垂，此天降清君侧之证。",
  ["$huiqi2"] = "彗星竟于西北，此罚天狼之兆。",
  ["$xieju1"] = "今举大义，誓与仲恭共死。",
  ["$xieju2"] = "天降大任，当与志士同忾。",
  ["~ol__wenqin"] = "天不佑国魏！天不佑族文！",
}


local duanjiong = General(extension, "duanjiong", "qun", 4)
local function DoSaogu(player, cards)
  local room = player.room
  room:throwCard(cards, "saogu", player, player)
  while not player.dead do
    local ids = {}
    for _, id in ipairs(cards) do
      local card = Fk:getCardById(id)
      if card.trueName == "slash" and room:getCardArea(card) == Card.DiscardPile and
        not player:prohibitUse(card) and player:canUse(card) then
        table.insertIfNeed(ids, id)
      end
    end
    if player.dead or #ids == 0 then return end
    local fakemove = {
      toArea = Card.PlayerHand,
      to = player.id,
      moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.Void} end),
      moveReason = fk.ReasonJustMove,
    }
    room:notifyMoveCards({player}, {fakemove})
    room:setPlayerMark(player, "saogu_cards", ids)
    local success, dat = room:askForUseActiveSkill(player, "saogu_viewas", "#saogu-use", true)
    room:setPlayerMark(player, "saogu_cards", 0)
    fakemove = {
      from = player.id,
      toArea = Card.Void,
      moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.PlayerHand} end),
      moveReason = fk.ReasonJustMove,
    }
    room:notifyMoveCards({player}, {fakemove})
    if success then
      table.removeOne(cards, dat.cards[1])
      local card = Fk.skills["saogu_viewas"]:viewAs(dat.cards)
      room:useCard{
        from = player.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
        extraUse = true,
      }
    else
      break
    end
  end
end
local saogu_viewas = fk.CreateViewAsSkill{
  name = "saogu_viewas",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      local ids = Self:getMark("saogu_cards")
      return type(ids) == "table" and table.contains(ids, to_select)
    end
  end,
  view_as = function(self, cards)
    if #cards == 1 then
      local card = Fk:getCardById(cards[1])
      card.skillName = "saogu"
      return card
    end
  end,
}
local saogu_targetmod = fk.CreateTargetModSkill{
  name = "#saogu_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "saogu")
  end,
}
local saogu = fk.CreateActiveSkill{
  name = "saogu",
  anim_type = "switch",
  switch_skill_name = "saogu",
  card_num = function(self)
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return 2
    else
      return 0
    end
  end,
  target_num = 0,
  prompt = function(self)
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return "#saogu-yang"
    else
      return "#saogu-yin"
    end
  end,
  can_use = Util.TrueFunc,
  card_filter = function(self, to_select, selected)
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      local card = Fk:getCardById(to_select)
      if #selected < 2 and not Self:prohibitDiscard(card) then
        return Self:getMark("saogu-phase") == 0 or not table.contains(Self:getMark("saogu-phase"), card:getSuitString(true))
      end
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      DoSaogu(player, effect.cards)
    else
      player:drawCards(1, self.name)
    end
  end,
}
local saogu_trigger = fk.CreateTriggerSkill{
  name = "#saogu_trigger",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("saogu") and player.phase == Player.Finish and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
    if player:getSwitchSkillState("saogu", false) == fk.SwitchYang then
      targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return #p:getCardIds("he") > 1 end), Util.IdMapper)
    end
    local to, card = room:askForChooseCardAndPlayers(player, targets, 1, 1, ".", "#saogu-choose", "saogu", true)
    if #to > 0 and card then
      self.cost_data = {to[1], card, player:getSwitchSkillState("saogu", false, true)}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard({self.cost_data[2]}, "saogu", player, player)
    local to = room:getPlayerById(self.cost_data[1])
    if not to.dead then
      if self.cost_data[3] == "yang" then
        if to:isNude() then return end
        local suits = table.map(player:getMark("saogu-phase"), function(str) return string.sub(str, 5, #str) end)
        local cards = room:askForDiscard(to, math.min(#to:getCardIds("he"), 2), 2, true, "saogu", false,
          ".|.|^("..table.concat(suits, ",")..")", "#saogu-yang", true)
        if #cards > 0 then
          DoSaogu(to, cards)
        end
      else
        to:drawCards(1, "saogu")
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},  --TODO: 获得技能时鸽！
  can_refresh = function(self, event, target, player, data)
    if player.phase == Player.Play or player.phase == Player.Finish then
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("saogu-phase")
    if mark == 0 then mark = {} end
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(mark, Fk:getCardById(info.cardId):getSuitString(true))
        end
      end
    end
    room:setPlayerMark(player, "saogu-phase", mark)
    if player:hasSkill("saogu", true) then
      room:setPlayerMark(player, "@saogu-phase", mark)
    end
  end,
}
Fk:addSkill(saogu_viewas)
saogu:addRelatedSkill(saogu_trigger)
saogu:addRelatedSkill(saogu_targetmod)
duanjiong:addSkill(saogu)
Fk:loadTranslationTable{
  ["duanjiong"] = "段颎",
  ["saogu"] = "扫谷",
  [":saogu"] = "转换技，出牌阶段，你可以：阳，弃置两张牌（不能包含你本阶段弃置过的花色），使用其中的【杀】；阴，摸一张牌。"..
  "结束阶段，你可以弃置一张牌，令一名其他角色执行当前项。",
  ["#saogu-yang"] = "扫谷：弃置两张牌，你可以使用其中的【杀】",
  ["#saogu-yin"] = "扫谷：你可以摸一张牌",
  ["#saogu_trigger"] = "扫谷",
  ["@saogu-phase"] = "扫谷",
  ["#saogu-choose"] = "扫谷：你可以弃置一张牌，令一名其他角色执行“扫谷”当前项",
  ["saogu_viewas"] = "扫谷",
  ["#saogu-use"] = "扫谷：你可以使用其中的【杀】",

  ["$saogu1"] = "大汉铁骑，必昭卫霍遗风于当年。",
  ["$saogu2"] = "笑驱百蛮，试问谁敢牧马于中原！",
  ["~duanjiong"] = "秋霜落，天下寒……",
}

local caoxi = General(extension, "caoxi", "wei", 3)
local function SetGangshu(player, choice)
  local room = player.room
  room:setPlayerMark(player, "gangshu1", math.min(player:getAttackRange(), 5))
  room:setPlayerMark(player, "gangshu2", 2 + player:getMark("gangshu2_fix"))
  local card = Fk:cloneCard("slash")
  local n = card.skill:getMaxUseTime(player, Player.HistoryPhase, card, nil)
  n = math.min(n, 5)
  if player:hasSkill("#crossbow_skill") then
    n = 5
  end
  room:setPlayerMark(player, "gangshu3", n)
  room:setPlayerMark(player, "@gangshu", string.format("%d-%d-%d",
    player:getMark("gangshu1"),
    player:getMark("gangshu2"),
    player:getMark("gangshu3")))
end
local gangshu = fk.CreateTriggerSkill{
  name = "gangshu",
  anim_type = "special",
  events = {fk.CardUseFinished},
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card.type ~= Card.TypeBasic then
      for i = 1, 3, 1 do
        if player:getMark("gangshu"..i) < 5 then
          return true
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local all_choices = {"gangshu1", "gangshu2", "gangshu3"}
    local choices = table.filter(all_choices, function(mark) return player:getMark(mark) < 5 end)
    local choice = room:askForChoice(player, choices, self.name, "#gangshu-choice", false, all_choices)
    room:addPlayerMark(player, choice.."_fix", 1)
    SetGangshu(player, choice)
  end,

  refresh_events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.CardUseFinished, fk.DrawNCards, fk.AfterCardsMove},
  can_refresh = function (self, event, target, player, data)
    if player:hasSkill(self, true) then
      if event == fk.GameStart then
        return true
      elseif event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.to == player.id and move.toArea == Card.PlayerEquip then
            return true
          end
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      elseif target == player then
        if event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
          return data == self
        elseif event == fk.CardUseFinished then
          return data.responseToEvent
        elseif event == fk.DrawNCards then
          return player:getMark("gangshu3_fix") > 0
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventAcquireSkill or event == fk.AfterCardsMove then
      SetGangshu(player)
    elseif event == fk.EventLoseSkill then
      for _, mark in ipairs({"gangshu1", "gangshu2", "gangshu3", "gangshu1_fix", "gangshu2_fix", "gangshu3_fix", "@gangshu"}) do
        room:setPlayerMark(player, mark, 0)
      end
    elseif event == fk.CardUseFinished then
      for _, mark in ipairs({"gangshu1_fix", "gangshu2_fix", "gangshu3_fix"}) do
        room:setPlayerMark(player, mark, 0)
      end
      SetGangshu(player)
    elseif event == fk.DrawNCards then
      data.n = data.n + player:getMark("gangshu2_fix")
      room:setPlayerMark(player, "gangshu2_fix", 0)
      SetGangshu(player)
    end
  end,
}
local gangshu_attackrange = fk.CreateAttackRangeSkill{
  name = "#gangshu_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("gangshu1_fix")
  end,
}
local gangshu_targetmod = fk.CreateTargetModSkill{
  name = "#gangshu_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("gangshu3_fix") > 0 and scope == Player.HistoryPhase then
      return player:getMark("gangshu3_fix")
    end
  end,
}
local jianxuan = fk.CreateTriggerSkill{
  name = "jianxuan",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), Util.IdMapper),
      1, 1, "#jianxuan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    to:drawCards(1, self.name)
    while table.find({player:getMark("gangshu1"), player:getMark("gangshu2"), player:getMark("gangshu3")}, function(n)
      return n == to:getHandcardNum() end) and not to.dead do
      to:drawCards(1, self.name)
    end
  end,
}
gangshu:addRelatedSkill(gangshu_attackrange)
gangshu:addRelatedSkill(gangshu_targetmod)
caoxi:addSkill(gangshu)
caoxi:addSkill(jianxuan)
Fk:loadTranslationTable{
  ["caoxi"] = "曹羲",
  ["gangshu"] = "刚述",
  [":gangshu"] = "当你使用非基本牌后，你可以令你以下一项数值+1直到你抵消牌（至多增加至5）：攻击范围；下个摸牌阶段摸牌数；出牌阶段使用【杀】次数上限。",
  ["jianxuan"] = "谏旋",
  [":jianxuan"] = "当你受到伤害后，你可以令一名角色摸一张牌，若其手牌数与〖刚述〗中的任意项相同，其重复此流程。",
  ["gangshu1"] = "攻击范围",
  ["gangshu2"] = "下个摸牌阶段摸牌数",
  ["gangshu3"] = "出牌阶段使用【杀】次数",
  ["#gangshu-choice"] = "刚述：选择你要增加的一项",
  ["@gangshu"] = "刚述",
  ["#jianxuan-choose"] = "谏旋：你可以令一名角色摸一张牌",

  ["$gangshu1"] = "羲而立之年，当为立身之事。",
  ["$gangshu2"] = "总六军之要，秉选举之机。",
  ["$jianxuan1"] = "司马氏卧虎藏龙，大兄安能小觑。",
  ["$jianxuan2"] = "兄长以兽为猎，殊不知己亦为猎乎？",
  ["~caoxi"] = "曹氏亡矣，大魏亡矣！",
}

local pengyang = General(extension, "ol__pengyang", "shu", 3)
local qifan = fk.CreateTriggerSkill{
  name = "qifan",
  anim_type = "special",
  events = {fk.PreCardUse},
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(self, true) then
      local cards = data.card:isVirtual() and data.card.subcards or {data.card.id}
      if #cards == 0 then return end
      local yes = false
      local use = player.room.logic:getCurrentEvent()
      use:searchEvents(GameEvent.MoveCards, 1, function(e)
        if e.parent and e.parent.id == use.id then
          for _, move in ipairs(e.data) do
            if move.moveReason == fk.ReasonUse then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.DrawPile then
                  yes = true
                end
              end
            end
          end
        end
      end)
      return yes
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local mark = player:getMark(self.name)
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, data.card.type)
    room:setPlayerMark(player, self.name, mark)
    local areas = {"j", "e", "h"}
    for i = 1, #mark, 1 do
      if player.dead then return end
      player:throwAllCards(areas[i])
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self, true) then
      for _, move in ipairs(data) do
        if move.toArea == Card.DrawPile then
          return true
        end
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.DrawPile then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local n = 0
    if player:getMark(self.name) ~= 0 then
      n = n + #player:getMark(self.name)
    end
    local ids = {}
    local length = #player.room.draw_pile
    if length <= n then
      ids = table.simpleClone(player.room.draw_pile)
    else
      for i = length, length - n, -1 do
        table.insert(ids, player.room.draw_pile[i])
      end
    end
    player.special_cards["qifan&"] = table.simpleClone(ids)  --FIXME: 似乎不应该是这种手感……
    player:doNotify("ChangeSelf", json.encode {
      id = player.id,
      handcards = player:getCardIds("h"),
      special_cards = player.special_cards,
    })
  end,
}
local qifan_prohibit = fk.CreateProhibitSkill{
  name = "#qifan_prohibit",
  prohibit_response = function(self, player, card)
    return #player:getPile("qifan&") > 0 and table.contains(player:getPile("qifan&"), card:getEffectiveId())
  end,
}
local tuoshi = fk.CreateTriggerSkill{
  name = "tuoshi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.number == 1 or data.card.number > 10)
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(2, self.name)
    player.room:setPlayerMark(player, "@@tuoshi", 1)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@tuoshi") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@tuoshi", 0)
  end,
}
local tuoshi_prohibit = fk.CreateProhibitSkill{
  name = "#tuoshi_prohibit",
  frequency = Skill.Compulsory,
  prohibit_use = function(self, player, card)
    return player:hasSkill("tuoshi") and card and card.trueName == "nullification"
  end,
}
local tuoshi_targetmod = fk.CreateTargetModSkill{
  name = "#tuoshi_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:getMark("@@tuoshi") > 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return player:getMark("@@tuoshi") > 0
  end,
}
qifan:addRelatedSkill(qifan_prohibit)
tuoshi:addRelatedSkill(tuoshi_prohibit)
tuoshi:addRelatedSkill(tuoshi_targetmod)
pengyang:addSkill(qifan)
pengyang:addSkill(tuoshi)
pengyang:addSkill("cunmu")
Fk:loadTranslationTable{
  ["ol__pengyang"] = "彭羕",
  ["qifan"] = "器翻",
  [":qifan"] = "当你需要使用牌时，你可以观看牌堆底X+1张牌，使用其中你需要的牌，然后依次弃置你以下前X个区域内所有牌（X为你以此法使用过的类别数）："..
  "判定区、装备区、手牌区。",
  ["tuoshi"] = "侻失",
  [":tuoshi"] = "锁定技，你不能使用【无懈可击】；当你使用点数为字母的牌后，你摸两张牌且使用下一张牌无距离次数限制。",
  ["qifan&"] = "器翻",
  ["@@tuoshi"] = "侻失",
}

local qianzhao = General(extension, "ol__qianzhao", "wei", 4)
local weifu = fk.CreateActiveSkill{
  name = "weifu",
  anim_type = "offensive",
  card_num = 1,
  target_num = 0,
  prompt = "#weifu",
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if player.dead then return end
    room:setPlayerMark(player, "@weifu-turn", judge.card:getTypeString())
    if judge.card.type == Fk:getCardById(effect.cards[1]).type then
      player:drawCards(1, self.name)
    end
  end,
}
local weifu_trigger = fk.CreateTriggerSkill{
  name = "#weifu_trigger",
  events = {fk.AfterCardTargetDeclared},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and not player.dead and player:getMark("@weifu-turn") == data.card:getTypeString()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@weifu-turn", 0)
    if data.tos and (data.card:isCommonTrick() or data.card.type == Card.TypeBasic) and #U.getUseExtraTargets(room, data, true) > 0 then
      local tos = room:askForChoosePlayers(player, U.getUseExtraTargets(room, data, true), 1, 1,
        "#weifu-invoke:::"..data.card:toLogString(), "weifu", true)
      if #tos == 1 then
        table.insert(data.tos, tos)
      end
    end
  end,
}
local weifu_targetmod = fk.CreateTargetModSkill{
  name = "#weifu_targetmod",
  bypass_distances =  function(self, player, skill, card, to)
    return player:getMark("@weifu-turn") ~= 0 and card and player:getMark("@weifu-turn") == card:getTypeString()
  end,
}
local kuansai = fk.CreateTriggerSkill{
  name = "kuansai",
  anim_type = "control",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.firstTarget and #AimGroup:getAllTargets(data.tos) > player.hp and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, AimGroup:getAllTargets(data.tos), 1, 1, "#kuansai-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if to:isNude() then
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      end
    else
      local cancelable = true
      if not player:isWounded() then
        cancelable = false
      end
      local card = room:askForCard(to, 1, 1, true, self.name, cancelable, ".", "#kuansai-give:"..player.id)
      if #card > 0 then
        room:obtainCard(player, card[1], true, fk.ReasonGive)
      else
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      end
    end
  end,
}
weifu:addRelatedSkill(weifu_trigger)
weifu:addRelatedSkill(weifu_targetmod)
qianzhao:addSkill(weifu)
qianzhao:addSkill(kuansai)
Fk:loadTranslationTable{
  ["ol__qianzhao"] = "牵招",
  ["weifu"] = "威抚",
  [":weifu"] = "出牌阶段，你可以弃置一张牌并判定，你本回合下次使用与判定牌类别相同的牌无距离限制且可以多指定一个目标；若弃置牌与判定牌类别相同，"..
  "你摸一张牌。",
  ["kuansai"] = "款塞",
  [":kuansai"] = "每回合限一次，当一张牌指定目标后，若目标数大于你的体力值，你可以令其中一个目标选择一项：1.交给你一张牌；2.你回复1点体力。",
  ["#weifu"] = "威抚：你可以弃置一张牌并判定，你使用下一张判定结果类别的牌无距离限制且目标+1",
  ["@weifu-turn"] = "威抚",
  ["#weifu-invoke"] = "威抚：你可以为%arg额外指定一个目标",
  ["#kuansai-choose"] = "款塞：你可以令其中一个目标选择交给你一张牌或令你回复体力",
  ["#kuansai-give"] = "款塞：交给 %src 一张牌，否则其回复1点体力",
  
  ["$weifu1"] = "蛮人畏威，当束甲抚之。",
  ["$weifu2"] = "以威为抚，可定万世之太平。",
  ["$kuansai1"] = "君既以礼相待，我何干戈相向。",
  ["$kuansai2"] = "我备美酒，待君玉帛。",
  ["~ol__qianzhao"] = "玄德兄，弟……来迟矣……",
}

local luyusheng = General(extension, "ol__luyusheng", "wu", 3, 3, General.Female)
local cangxin = fk.CreateTriggerSkill{
  name = "cangxin",
  events = {fk.EventPhaseStart, fk.DamageInflicted},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and (event == fk.DamageInflicted or player.phase == Player.Draw)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    room:notifySkillInvoked(player, self.name, event == fk.EventPhaseStart and "drawcard" or "defensive")
    local card_ids = room:getNCards(3, "bottom")
    room:moveCards({
      ids = card_ids,
      toArea = Card.Processing,
      skillName = self.name,
      moveReason = fk.ReasonJustMove,
    })
    local break_event = false
    if event == fk.EventPhaseStart then
      room:delay(1500)
      local x = 0
      for _, id in ipairs(card_ids) do
        if Fk:getCardById(id).suit == Card.Heart then
          x = x + 1
        end
      end
      if x > 0 then
        room:drawCards(player, x, self.name)
      end
    elseif event == fk.DamageInflicted then
      local to_throw = room:askForCardsChosen(player, player, 0, 3, {
        card_data = {
          { "Bottom", card_ids }
        }
      }, self.name)
      if #to_throw > 0 then
        for _, id in ipairs(to_throw) do
          if Fk:getCardById(id).suit == Card.Heart then
            break_event = true
          end
          table.removeOne(card_ids, id)
        end
        room:moveCards({
          ids = to_throw,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = self.name,
        })
      end
    end
    if #card_ids > 0 then
      room:moveCards({
        ids = card_ids,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        drawPilePosition = -1,
      })
    end
    return break_event
  end,
}
local runwei = fk.CreateTriggerSkill{
  name = "runwei",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target.dead and target:isWounded() and target.phase == Player.Discard
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"runwei1", "Cancel"}
    if not player:isNude() then
      table.insert(choices, "runwei2")
    end
    local choice = room:askForChoice(player, choices, self.name, "#runwei-choice::" .. target.id, false, {"runwei1", "runwei2", "Cancel"})
    if choice ~= "Cancel" then
      self.cost_data = choice
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "runwei1" then
      room:drawCards(target, 1, self.name)
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, 1)
    elseif self.cost_data == "runwei2" then
      room:askForDiscard(target, 1, 1, true, self.name, false)
      room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, 1)
    end
  end,
}
luyusheng:addSkill(cangxin)
luyusheng:addSkill(runwei)

Fk:loadTranslationTable{
  ["ol__luyusheng"] = "陆郁生",
  ["cangxin"] = "藏心",
  [":cangxin"] = "锁定技，摸牌阶段开始时，你展示牌堆底三张牌并摸与其中<font color='red'>♥</font>牌数等量张牌。"..
  "当你受到伤害时，你展示牌堆底三张牌并弃置其中任意张牌，若弃置了<font color='red'>♥</font>牌，防止此伤害。",
  ["runwei"] = "润微",
  [":runwei"] = "已受伤角色的弃牌阶段开始时，你可令其弃置一张牌且其本回合手牌上限+1，或令其摸一张牌且其本回合手牌上限-1。",

  ["#runwei-choice"] = "你可以发动 润微，令%dest执行一项",
  ["runwei1"] = "令其摸一张牌且手牌上限-1",
  ["runwei2"] = "令其弃置一张牌且手牌上限+1",

  ["$cangxin1"] = "",
  ["$cangxin2"] = "",
  ["$runwei1"] = "",
  ["$runwei2"] = "",
  ["~ol__luyusheng"] = "",
}

local dingfuren = General(extension, "ol__dingfuren", "wei", 3, 3, General.Female)
local fudao = fk.CreateTriggerSkill{
  name = "ol__fudao",
  anim_type = "drawcard",
  events = {fk.GameStart, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return end
    return event == fk.GameStart or (player:getMark("_ol__fudao") == target:getHandcardNum() and player:getMark("@ol__fudao") ~= 0)
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    else
      return player.room:askForSkillInvoke(player, self.name, data, "#ol__fudao-ask::" .. target.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.GameStart then
      local room = player.room
      player:drawCards(3, self.name)
      if player.dead or player:isNude() then return end
      local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
      local tos, cards = room:askForChooseCardsAndPlayers(player, 1, 3, targets, 1, 1, nil, "#ol__fudao-give", self.name, false)
      local to = room:getPlayerById(tos[1])
      room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
      if player.dead then return false end
      room:askForDiscard(player, 1, 999, false, self.name, true, nil, "#ol__fudao-discard")
      if player.dead then return false end
      room:setPlayerMark(player, "@ol__fudao", tostring(player:getHandcardNum())) -- 0
      room:setPlayerMark(player, "_ol__fudao", player:getHandcardNum())
    else
      target:drawCards(1, self.name)
      if not player.dead then
        player:drawCards(1, self.name)
      end
    end
  end,
}

local fengyan = fk.CreateTriggerSkill{
  name = "ol__fengyan",
  events = {fk.Damaged, fk.CardRespondFinished, fk.CardUseFinished},
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if event == fk.Damaged then
      return player:hasSkill(self) and target == player and data.from and data.from ~= player
    else
      return target == player and player:hasSkill(self) and not player.dead and data.responseToEvent and data.responseToEvent.from and data.responseToEvent.from ~= player.id and not player.room:getPlayerById(data.responseToEvent.from).dead
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to
    if event == fk.Damaged then
      to = data.from.id
    else
      to = data.responseToEvent.from
    end
    local choice = player.room:askForChoice(player, {"ol__fengyan_self:" .. to, "ol__fengyan_other:" .. to}, self.name)
    self.cost_data = {choice, to}
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data[1]
    local target = room:getPlayerById(self.cost_data[2])
    if choice:startsWith("ol__fengyan_self") then
      player:drawCards(1, self.name)
      if target and not target.dead and not player:isNude() then
        local c = room:askForCard(player, 1, 1, true, self.name, false, nil, "#ol__fengyan-card::" .. target.id)[1]
        room:moveCardTo(c, Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id)
      end
    else
      room:doIndicate(player.id, {target.id})
      target:drawCards(1, self.name)
      if not target.dead then
        room:askForDiscard(target, 2, 2, true, self.name, false, nil)
      end
    end
  end,
}

dingfuren:addSkill(fudao)
dingfuren:addSkill(fengyan)

Fk:loadTranslationTable{
  ["ol__dingfuren"] = "丁尚涴",
  ["ol__fudao"] = "抚悼",
  [":ol__fudao"] = "游戏开始时，你摸三张牌，交给一名其他角色至多三张牌，弃置任意张手牌，然后记录你的手牌数。每回合结束时，若当前回合角色的手牌数为此数值，你可以与其各摸一张牌。",
  ["ol__fengyan"] = "讽言",
  [":ol__fengyan"] = "锁定技，当你受到其他角色造成的伤害后，或当你响应其他角色使用的牌后，你选择一项：1. 你摸一张牌并交给其一张牌；2. 其摸一张牌并弃置两张牌。",

  ["@ol__fudao"] = "抚悼",
  ["#ol__fudao-give"] = "抚悼：请交给一名其他角色至多三张牌",
  ["#ol__fudao-discard"] = "抚悼：请弃置任意张手牌",
  ["#ol__fudao-ask"] = "抚悼：你可与 %dest 各摸一张牌",
  ["ol__fengyan_self"] = "你摸一张牌并交给%src一张牌",
  ["ol__fengyan_other"] = "%src摸一张牌并弃置两张牌",
  ["#ol__fengyan-card"] = "讽言：请交给 %dest 一张牌",
}

local liwan = General(extension, "ol__liwan", "wei", 3, 3, General.Female)
local lianju = fk.CreateTriggerSkill{
  name = "lianju",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player ~= target or player.phase ~= Player.Finish then return false end
    local room = player.room
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
    if turn_event == nil then return false end
    local end_id = turn_event.id
    local card = nil
    U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
      local use = e.data[1]
      if use.from == player.id then
        card = use.card
        return true
      end
      return false
    end, end_id)
    if card ~= nil and #room:getSubcardsByRule(card, { Card.DiscardPile }) > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    local card = self.cost_data
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, true), Util.IdMapper),
    1, 1, "#lianju-choose:::" .. card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = {card, to[1]}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tar = room:getPlayerById(self.cost_data[2])
    local card = self.cost_data[1]
    local cards = room:getSubcardsByRule(card, { Card.DiscardPile })
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, tar, fk.ReasonPrey, self.name, nil, true, player.id)
    end
    room:setPlayerMark(player, "@lianju", card.trueName)
    local mark = U.getMark(tar, "@@lianju")
    table.insert(mark, player.id)
    room:setPlayerMark(tar, "@@lianju", mark)
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@lianju") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@lianju", 0)
  end,
}
local lianju_viewas = fk.CreateViewAsSkill{
  name = "lianju_viewas",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard(Self:getMark("lianju"))
    card.skillName = "lianju"
    return card
  end,
}
Fk:addSkill(lianju_viewas)
local lianju_delay = fk.CreateTriggerSkill{
  name = "#lianju_delay",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and not (target.dead or player.dead) and
    table.contains(U.getMark(target, "@@lianju"), player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
    if turn_event == nil then return false end
    local end_id = turn_event.id
    local card = nil
    U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
      local use = e.data[1]
      if use.from == target.id then
        card = use.card
        return true
      end
      return false
    end, end_id)
    if card == nil then return false end
    local cards = room:getSubcardsByRule(card, { Card.DiscardPile })
    if #cards == 0 or not room:askForSkillInvoke(target, "#lianju_delay", nil,
    "#lianju-supply:" .. player.id .. "::" .. card:toLogString()) then return false end
    room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, self.name, nil, true, player.id)
    if player.dead then return false end
    if card.trueName == player:getMark("@lianju") then
      room:loseHp(player, 1, "lianju")
    else
      local to_use = Fk:cloneCard(card.name)
      to_use.skillName = "lianju"
      if not player:canUse(to_use) or player:prohibitUse(to_use) then return false end
      room:setPlayerMark(player, "lianju", card.name)
      local success, dat = player.room:askForUseViewAsSkill(player, "lianju_viewas", "#lianju-use:::"..card.name, true)
      room:setPlayerMark(player, "lianju",0)
      if success then
        room:useCard{
          from = player.id,
          tos = table.map(dat.targets, function(p) return {p} end),
          card = to_use,
          extraUse = true,
        }
      end
    end
  end,
}
local silv = fk.CreateTriggerSkill{
  name = "silv",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local name = player:getMark("@lianju")
      if type(name) ~= "string" then return false end
      local silvgetCheck = function(move_data)
        for _, move in ipairs(move_data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId).trueName == name then
                return true
              end
            end
          end
        end
      end
      local silvloseCheck = function(move_data)
        for _, move in ipairs(move_data) do
          if move.to == player.id and move.toArea == Player.Hand then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId).trueName == name then
                return true
              end
            end
          end
        end
      end
      local branches = {}
      if player:getMark("silv1-turn") == 0 and silvgetCheck(data) then
        table.insert(branches, "silv1-turn")
      end
      if player:getMark("silv2-turn") == 0 and silvloseCheck(data) then
        table.insert(branches, "silv2-turn")
      end
      if #branches > 0 then
        self.cost_data = branches
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, name in ipairs(self.cost_data) do
      room:setPlayerMark(player, name, 1)
    end
    room:drawCards(player, #self.cost_data, self.name)
  end,
}
lianju:addRelatedSkill(lianju_delay)
liwan:addSkill(lianju)
liwan:addSkill(silv)

Fk:loadTranslationTable{
  ["ol__liwan"] = "李婉",
  ["lianju"] = "联句",
  [":lianju"] = "结束阶段，你可以令一名其他角色获得弃牌堆中你本回合最后使用的牌并记录之，"..
  "然后其下个结束阶段可以令你获得弃牌堆中其此回合最后使用的牌，若两者牌名相同，你失去1点体力；牌名不同，你视为使用之。",
  ["silv"] = "思闾",
  [":silv"] = "锁定技，每回合每项各限一次，当你获得或失去与〖联句〗最后记录牌同名的牌后，你摸一张牌。",

  ["#lianju-choose"] = "你可以发动 联句，令一名其他角色获得你使用过的 %arg",
  ["@lianju"] = "联句",
  ["@@lianju"] = "联句",
  ["#lianju_delay"] = "联句",
  ["#lianju-supply"] = "联句：你可以令 %src 获得你使用过的 %arg",
  ["#lianju-use"] = "联句：你可以视为使用【%arg】",

  ["$lianju1"] = "",
  ["$lianju2"] = "",
  ["$silv1"] = "",
  ["$silv2"] = "",
  ["~ol__liwan"] = "",
}
local zhangyan = General(extension, "zhangyan", "qun", 4)
local suji = fk.CreateTriggerSkill{
  name = "suji",
  events = {fk.EventPhaseStart},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Play and target:isWounded()
  end,
  on_cost = function (self, event, target, player, data)
    local success, dat = player.room:askForUseViewAsSkill(player, "suji_viewas", "#suji:"..target.id, true)
    if success then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = self.cost_data
    local card = Fk.skills["suji_viewas"]:viewAs(dat.cards)
    local use = {from = player.id, tos = table.map(dat.targets, function(p) return {p} end), card = card}
    if target ~= player then use.extraUse = true end
    room:useCard(use)
    if use.damageDealt and use.damageDealt[target.id] and not player.dead and not target:isNude() then
      local id = room:askForCardChosen(player, target, "he", self.name)
      room:obtainCard(player, id, false, fk.ReasonPrey)
    end
  end,
}
zhangyan:addSkill(suji)
local suji_viewas = fk.CreateViewAsSkill{
  name = "suji_viewas",
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card:addSubcard(cards[1])
    card.skillName = "suji"
    return card
  end,
}
Fk:addSkill(suji_viewas)
local langdao = fk.CreateTriggerSkill{
  name = "langdao",
  anim_type = "offensive",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash"
    and data.tos and #AimGroup:getAllTargets(data.tos) == 1
    and #U.getMark(player, "langdao_removed") < 3
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#langdao-invoke:"..data.to)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    local mark = U.getMark(player, "langdao_removed")
    for _, n in ipairs({"AddDamage1","AddTarget1","disresponsive"}) do
      if not table.contains(mark, n) then
        table.insert(choices, n)
      end
    end
    if #choices == 0 then return end
    local content = {}
    for _, p in ipairs({player, room:getPlayerById(data.to)}) do
      local choice = room:askForChoice(p, choices, self.name)
      table.insert(content, choice)
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.langdao = content
    local target_num,damage_num = 0,0
    for _, c in ipairs(content) do
      if c == "AddDamage1" then
        damage_num = damage_num + 1
      elseif c == "AddTarget1" then
        target_num = target_num + 1
      else
        data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
      end
    end
    if target_num > 0 then
      local targets = {}
      local current_targets = TargetGroup:getRealTargets(data.tos)
      for _, p in ipairs(room.alive_players) do
        if not table.contains(current_targets, p.id) and not player:isProhibited(p, data.card) then
          if data.card.skill:modTargetFilter(p.id, {}, player.id, data.card, true) then
            table.insert(targets, p.id)
          end
        end
      end
      if #targets > 0 then
        local tos = room:askForChoosePlayers(player, targets, 1, target_num, "#langdao-AddTarget:::"..target_num, self.name, true)
        if #tos > 0 then
          TargetGroup:pushTargets(data.targetGroup, tos)
          room:sendLog{
            type = "#AddTargetsBySkill",
            from = player.id,
            to = tos,
            arg = self.name,
            arg2 = data.card:toLogString()
          }
        end
      end
    end
    data.additionalDamage = (data.additionalDamage or 0) + damage_num
    local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local _data = e.data[1]
      _data.additionalDamage = (_data.additionalDamage or 0) + damage_num
    end
  end,
  refresh_events = {fk.CardUseFinished},
  can_refresh = function (self, event, target, player, data)
    if player == target and data.extra_data and data.extra_data.langdao then
      local _event = player.room.logic:getEventsOfScope(GameEvent.Death, 1, function (e)
        local death = e.data[1]
        return death and death.damage and death.damage.card == data.card
      end, Player.HistoryPhase)
      return #_event == 0
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "langdao_removed")
    for _, c in ipairs(data.extra_data.langdao) do
      table.insertIfNeed(mark, c)
    end
    room:setPlayerMark(player, "langdao_removed", mark)
  end,
}
zhangyan:addSkill(langdao)
Fk:loadTranslationTable{
  ["zhangyan"] = "张燕",
  ["suji"] = "肃疾",
  [":suji"] = "已受伤角色的出牌阶段开始时，你可以将一张黑色牌当【杀】使用，若其受到此【杀】伤害，你获得其一张牌。",
  ["suji_viewas"] = "肃疾",
  ["#suji"] = "肃疾：你可以将一张黑色牌当【杀】使用，若%src受到此【杀】伤害，你获得其一张牌",
  ["langdao"] = "狼蹈",
  [":langdao"] = "当你使用【杀】指定唯一目标时，你可以与其同时选择一项，令此【杀】：伤害值+1/目标数+1/不能被响应。若未杀死角色，你移除此次被选择的项。",
  ["#langdao-invoke"] = "是否对%src发动“狼蹈”",
  ["#langdao-AddTarget"] = "狼蹈：你可为此【杀】增加至多%arg个目标",
  ["AddDamage1"] = "伤害值+1",
  ["AddTarget1"] = "目标数+1",
  ["disresponsive"] = "无法响应",
  
  ["$suji1"] = "飞燕如风，非快不得破。",
  ["$suji2"] = "载疾风之势，摧万仞之城。",
  ["$langdao1"] = "虎踞黑山，望天下百城。",
  ["$langdao2"] = "狼顾四野，视幽冀为饵。",
  ["~zhangyan"] = "草莽之辈，难登大雅之堂……",
}

local ol__puyuan = General(extension, "ol__puyuan", "shu", 4)  --TODO: 需要大改，慢慢来叭
local ol__puyuan_weapons = {"py_halberd", "py_blade", "py_sword", "py_double_halberd", "py_chain", "py_fan"}
local ol__puyuan_armors = {"py_belt", "py_robe", "py_cloak", "py_diagram", "py_plate", "py_armor"}
local ol__puyuan_treasures = {"py_hat", "py_coronet", "py_threebook", "py_mirror", "py_map", "py_tactics"}
local shengong = fk.CreateActiveSkill{
  name = "shengong",
  anim_type = "support",
  can_use = function(self, player)
    return player:getMark("shengong_weapon-phase") == 0 or player:getMark("shengong_armor-phase") == 0 or player:getMark("shengong_treasure-phase") == 0
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    if #selected == 0 and not Self:prohibitDiscard(card) then
      return (card.sub_type == Card.SubtypeWeapon and Self:getMark("shengong_weapon-phase") == 0)
      or (card.sub_type == Card.SubtypeArmor and Self:getMark("shengong_armor-phase") == 0)
      or ((card.sub_type == Card.SubtypeTreasure or card.sub_type == Card.SubtypeDefensiveRide or card.sub_type == Card.SubtypeOffensiveRide) and Self:getMark("shengong_treasure-phase") == 0)
    end
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    local card = Fk:getCardById(effect.cards[1])
    local list,cards = {},{}
    if card.sub_type == Card.SubtypeWeapon then
      room:addPlayerMark(player, "shengong_weapon-phase")
      list = ol__puyuan_weapons
    elseif card.sub_type == Card.SubtypeArmor then
      room:addPlayerMark(player, "shengong_armor-phase")
      list = ol__puyuan_armors
    else
      room:addPlayerMark(player, "shengong_treasure-phase")
      list = ol__puyuan_treasures
    end
    for _, id in ipairs(room.void) do
      local name = Fk:getCardById(id).name
      if table.contains(list, name) then
        table.insert(cards, id)
      end
    end
    if player.dead or #cards == 0 then return end
    local throw = {}
    local good,bad = 0,0
    for _, p in ipairs(room:getAlivePlayers()) do
      local choice = (p == player) and "shengong_good" or
      room:askForChoice(p, {"shengong_good","shengong_bad"},self.name,"#shengong-help:"..player.id)
      local show = room:getNCards(1)
      table.insertIfNeed(throw, show[1])
      room:moveCards({ ids = show, toArea = Card.Processing, moveReason = fk.ReasonPut })
      local num = Fk:getCardById(show[1]).number
      room:sendLog{ type = "#shengongChoice", from = p.id, arg = choice, arg2 = num }
      if choice == "shengong_good" then
        room:setCardEmotion(show[1], "judgegood")
        good = good + num
      else
        room:setCardEmotion(show[1], "judgebad")
        bad = bad + num
      end
    end
    room:moveCards({ ids = throw, toArea = Card.DiscardPile, moveReason = fk.ReasonPutIntoDiscardPile })
    local choose_num = 1
    local result = "shengongFail"
    if bad == 0 then
      choose_num = 3
      result = "shengongPerfect"
    elseif good >= bad then
      choose_num = 2
      result = "shengongSuccess"
    end
    room:sendLog{ type = "#shengongResult", from = player.id, arg = good, arg2 = bad, arg3 = result }
    local get = room:askForCardChosen(player, player, {card_data = {{self.name, table.random(cards, choose_num) }}}, self.name)
    room:setCardMark(Fk:getCardById(get), MarkEnum.DestructIntoDiscard, 1)
    local targets = table.filter(room.alive_players, function(p) return U.canMoveCardIntoEquip(p, get) end)
    if #targets > 0 then
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#shengong-put:::"..Fk:getCardById(get).name, self.name, false)
      local to = room:getPlayerById(tos[1])
      U.moveCardIntoEquip(room, to, get, self.name)
    end
  end,
}
local shengong_trigger = fk.CreateTriggerSkill{
  name = "#shengong_trigger",
  mute = true,
  main_skill = shengong,
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target.phase == Player.Finish and player:hasSkill(shengong) then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 999, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.Void then
            for _, info in ipairs(move.moveInfo) do
              local name = Fk:getCardById(info.cardId).name
              if table.contains(ol__puyuan_weapons, name) or table.contains(ol__puyuan_armors, name) or table.contains(ol__puyuan_treasures, name) then
                n = n + 1
              end
            end
          end
        end
        return false
      end, Player.HistoryTurn)
      if n > 0 then
        self.cost_data = n
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(shengong.name)
    player:drawCards(self.cost_data, shengong.name)
  end,
}
shengong:addRelatedSkill(shengong_trigger)
ol__puyuan:addSkill(shengong)
local qisi = fk.CreateTriggerSkill{
  name = "qisi",
  events = {fk.GameStart, fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self)
    else
      return player:hasSkill(self) and target == player and data.n > 0
    end
  end,
  on_cost = function (self, event, target, player, data)
    return event == fk.GameStart or player.room:askForSkillInvoke(player, self.name, nil, "#qisi-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local equipMap = {}
      for _, id in ipairs(room.draw_pile) do
        local sub_type = Fk:getCardById(id).sub_type
        if Fk:getCardById(id).type == Card.TypeEquip and player:hasEmptyEquipSlot(sub_type) then
          local list = equipMap[tostring(sub_type)] or {}
          table.insert(list, id)
          equipMap[tostring(sub_type)] = list
        end
      end
      local types = {}
      for k, _ in pairs(equipMap) do
        table.insert(types, k)
      end
      if #types == 0 then return end
      types = table.random(types, 2)
      local put = {}
      for _, t in ipairs(types) do
        table.insert(put, table.random(equipMap[t]))
      end
      U.moveCardIntoEquip(room, player, put, self.name, false, player)
    else
      data.n = data.n - 1
      local choices = {"weapon", "armor", "equip_horse", "treasure"}
      local StrToSubtypeList = {["weapon"]={Card.SubtypeWeapon},["armor"]={Card.SubtypeArmor},["treasure"]={Card.SubtypeTreasure},["equip_horse"]={Card.SubtypeOffensiveRide,Card.SubtypeDefensiveRide}}
      local choice = room:askForChoice(player, choices, self.name)
      local list = StrToSubtypeList[choice]
      local piles = table.simpleClone(room.draw_pile)
      table.insertTable(piles, room.discard_pile)
      local cards = {}
      for _, id in ipairs(piles) do
        if table.contains(list, Fk:getCardById(id).sub_type) then
          table.insert(cards, id)
        end
      end
      if #cards == 0 then return end
      room:obtainCard(player, table.random(cards), false, fk.ReasonPrey)
    end
  end,
}
ol__puyuan:addSkill(qisi)
Fk:loadTranslationTable{
  ["ol__puyuan"] = "蒲元",
  ["shengong"] = "神工",
  [":shengong"] = "①出牌阶段各限一次，你可以弃置一张武器/防具/〔坐骑或宝物牌〕，进行一次“锻造”，选择一张武器/防具/宝物牌置于一名角色的装备区（替换原装备）。②当以此法获得的装备牌进入弃牌堆时，销毁之，然后此回合结束阶段，你摸一张牌。",
  ["#shengong-help"] = "神工：选择助力或妨害 %src 的锻造",
  ["shengong_good"] = "助力锻造",
  ["shengong_bad"] = "妨害锻造",
  ["#shengong-put"] = "将 %arg 置于一名角色装备区（替换原装备）",
  ["#shengong_trigger"] = "神工",
  ["#shengongChoice"] = "%from 选择 %arg，点数：%arg2",
  ["#shengongResult"] = "%from 发动了“神工”，助力锻造点数：%arg，妨害锻造点数：%arg2，结果：%arg3",
  ["shengongPerfect"] = "完美锻造",
  ["shengongSuccess"] = "锻造成功",
  ["shengongFail"] = "锻造失败",
  ["qisi"] = "奇思",
  [":qisi"] = "①游戏开始时，将两张不同副类别的装备牌并置入你的装备区。②摸牌阶段，你可以少摸一张牌，声明一种武器、防具、坐骑或宝物牌并从牌堆或弃牌堆中获得之。",
  ["#qisi-invoke"] = "你可以少摸一张牌，声明一种武器、防具、坐骑或宝物牌并从牌堆或弃牌堆中获得之",

  ["$shengong1"] = "技艺若神，大巧不工。",
  ["$shengong2"] = "千锤百炼，始得神兵。",
  ["$qisi1"] = "匠作之道，当佐奇思。",
  ["$qisi2"] = "世无同刃，不循凡矩。",
  ["~ol__puyuan"] = "锻兵万千，不及造屋二三……",
}

local lvboshe = General(extension, "lvboshe", "qun", 4)
local fushi = fk.CreateViewAsSkill{
  name = "fushi",
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#fushi",
  expand_pile = "fushi",
  card_filter = function(self, to_select, selected)
    return Self:getPileNameOfId(to_select) == self.name
  end,
  view_as = function(self, cards)
    if #cards == 0 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    card:addSubcards(cards)  --FIXME: 为增强体验用的坏方法
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local cards = table.simpleClone(use.card.subcards)
    local n = math.min(#cards, 3)
    use.card:clearSubcards()
    room:recastCard(cards, player, self.name)
    if not player.dead then
      local all_choices = {"fushi1", "fushi2", "fushi3", "Cancel"}
      local choices = table.simpleClone(all_choices)
      local chosen = {}
      while #chosen < n do
        if #U.getUseExtraTargets(room, use, false) == 0 then
          table.removeOne(choices, "fushi1")
        end
        local choice = room:askForChoice(player, choices, self.name, "#fushi-choice:::"..n, false, all_choices)
        if choice == "Cancel" then
          break
        else
          table.insert(chosen, choice)
          table.removeOne(choices, choice)
          if choice == "fushi1" then
            local to = room:askForChoosePlayers(player, U.getUseExtraTargets(room, use, false), 1, 1, "#fushi1-choose", self.name, false)
            if #to > 0 then
              to = to[1]
            else
              to = table.random(U.getUseExtraTargets(room, use, false))
            end
            TargetGroup:pushTargets(use.tos, to)
          elseif choice == "fushi2" then
            local to = room:askForChoosePlayers(player, TargetGroup:getRealTargets(use.tos), 1, 1, "#fushi2-choose", self.name, false)
            if #to > 0 then
              to = to[1]
            else
              to = table.random(TargetGroup:getRealTargets(use.tos))
            end
            use.extra_data = use.extra_data or {}
            use.extra_data.fushi2 = to
          elseif choice == "fushi3" then
            local to = room:askForChoosePlayers(player, TargetGroup:getRealTargets(use.tos), 1, 1, "#fushi3-choose", self.name, false)
            if #to > 0 then
              to = to[1]
            else
              to = table.random(TargetGroup:getRealTargets(use.tos))
            end
            use.extra_data = use.extra_data or {}
            use.extra_data.fushi3 = to
          end
        end
        if #chosen > 1 and table.contains(chosen, "fushi2") and #TargetGroup:getRealTargets(use.tos) > 1 then
          room:sortPlayersByAction(TargetGroup:getRealTargets(use.tos))
          local tos = table.simpleClone(TargetGroup:getRealTargets(use.tos))
          local yes = true
          for i = 1, #tos - 1, 1 do
            if room:getPlayerById(tos[i]):getNextAlive() ~= room:getPlayerById(tos[i+1]) then
              yes = false
            end
          end
          if yes then
            use.extraUse = true
          end
        end
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    return not response and #player:getPile(self.name) > 0
  end,
}
local fushi_trigger = fk.CreateTriggerSkill{
  name = "#fushi_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.card.trueName == "slash" and player:distanceTo(target) <= 1 then
      local room = player.room
      local subcards = data.card:isVirtual() and data.card.subcards or {data.card.id}
      return #subcards > 0 and table.every(subcards, function(id) return room:getCardArea(id) == Card.Processing end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "fushi", nil)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("fushi")
    room:notifySkillInvoked(player, "fushi", "special")
    player:addToPile("fushi", data.card, true, "fushi")
  end,

  refresh_events = {fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    if target == player and data.card and table.contains(data.card.skillNames, "fushi") then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      return e and e.data[1].extra_data and (e.data[1].extra_data.fushi2 or e.data[1].extra_data.fushi3)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    local use = e.data[1]
    if use.extra_data.fushi2 and use.extra_data.fushi2 == data.to.id then
      data.damage = data.damage - 1
    end
    if use.extra_data.fushi3 and use.extra_data.fushi3 == data.to.id then
      data.damage = data.damage + 1
    end
  end,
}
local dongdao = fk.CreateTriggerSkill{
  name = "dongdao",
  anim_type = "switch",
  switch_skill_name = "dongdao",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player.room.settings.gameMode == "m_1v2_mode" and player:hasSkill(self) and target.role == "rebel"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return player.room:askForSkillInvoke(player, self.name, nil, "#dongdao_yang-invoke::"..room:getLord().id)
    else
      return player.room:askForSkillInvoke(target, self.name, nil, "#dongdao_yin-invoke:"..player.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      room:doIndicate(player.id, {room:getLord().id})
      room:getLord():gainAnExtraTurn(true)
    else
      room:doIndicate(target.id, {player.id})
      target:gainAnExtraTurn(true)
    end
  end,
}
fushi:addRelatedSkill(fushi_trigger)
lvboshe:addSkill(fushi)
lvboshe:addSkill(dongdao)
Fk:loadTranslationTable{
  ["lvboshe"] = "吕伯奢",
  ["fushi"] = "缚豕",
  [":fushi"] = "当一名角色使用【杀】后，若你与其距离1以内，你将之置于你的武将牌上。你可以重铸任意张“缚豕”牌，视为使用一张具有以下等量项效果的"..
  "【杀】：1.目标数+1；2.对一个目标造成的伤害-1；3.对一个目标造成的伤害+1。若你选择的选项相邻且目标均相邻，此【杀】无次数限制。",
  ["dongdao"] = "东道",
  [":dongdao"] = "转换技，阳：农民回合结束后，你可以令地主执行一个额外回合；阴：农民回合结束后，其可以执行一个额外回合。（仅斗地主模式生效）",
  ["#fushi"] = "缚豕：重铸任意张“缚豕”牌，视为使用一张附加等量效果的【杀】",
  ["#fushi-choice"] = "缚豕：为此【杀】选择%arg项效果",
  ["fushi1"] = "目标+1",
  ["fushi2"] = "对一个目标伤害-1",
  ["fushi3"] = "对一个目标伤害+1",
  ["#fushi1-choose"] = "缚豕：为此【杀】增加一个目标",
  ["#fushi2-choose"] = "缚豕：选择一个目标，此【杀】对其伤害-1",
  ["#fushi3-choose"] = "缚豕：选择一个目标，此【杀】对其伤害+1",
  ["#dongdao_yang-invoke"] = "东道：你可以令 %dest 执行一个额外回合",
  ["#dongdao_yin-invoke"] = "东道：你可以发动 %src 的“东道”，执行一个额外回合",

  ["$fushi1"] = "缚豕待宰，要让阿瞒吃个肚儿溜圆。",
  ["$fushi2"] = "今儿个呀，咱们吃油汪汪的猪肉！",
  ["$dongdao1"] = "阿瞒远道而来，老夫当尽地主之谊！",
  ["$dongdao2"] = "我乃嵩兄故交，孟德来此可无忧虑。",
  ["~lvboshe"] = "阿瞒，我沽酒回来……呃！",
}

local feiyi = General(extension, "ol__feiyi", "shu", 3)
local yanru = fk.CreateActiveSkill{
  name = "yanru",
  anim_type = "drawcard",
  min_card_num = 0,
  target_num = 0,
  prompt = function (self, selected_cards, selected_targets)
    if Self:getHandcardNum() % 2 == 0 then
      return "#yanru2:::"..(Self:getHandcardNum() // 2)
    else
      return "#yanru1"
    end
  end,
  can_use = function(self, player)
    if player:getHandcardNum() % 2 == 0 then
      return not player:isKongcheng() and player:getMark("yanru2-phase") == 0
    else
      return player:getMark("yanru1-phase") == 0
    end
  end,
  card_filter = function (self, to_select, selected, selected_targets)
    if Self:getHandcardNum() % 2 == 0 then
      return Fk:currentRoom():getCardArea(to_select) == Player.Hand and not Self:prohibitDiscard(Fk:getCardById(to_select))
    else
      return false
    end
  end,
  target_filter = Util.FalseFunc,
  feasible = function (self, selected, selected_cards)
    if Self:getHandcardNum() % 2 == 0 then
      return #selected_cards >= (Self:getHandcardNum() // 2)
    else
      return true
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:getHandcardNum() % 2 == 0 then
      room:setPlayerMark(player, "yanru2-phase", 1)
      room:throwCard(effect.cards, self.name, player, player)
      if not player.dead then
        player:drawCards(3, self.name)
      end
    else
      room:setPlayerMark(player, "yanru1-phase", 1)
      player:drawCards(3, self.name)
      if not player.dead and not player:isKongcheng() then
        room:askForDiscard(player, player:getHandcardNum() // 2, 999, false, self.name, false, ".",
          "#yanru-discard:::"..(player:getHandcardNum() // 2))
      end
    end
  end,
}
local hezhong = fk.CreateTriggerSkill{
  name = "hezhong",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:getHandcardNum() == 1 and player:usedSkillTimes(self.name, Player.HistoryTurn) < 2 then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
        if move.to == player.id and move.toArea == Card.PlayerHand then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = Fk:getCardById(player:getCardIds("h")[1]).number
    player:showCards(player:getCardIds("h"))
    if player.dead then return end
    player:drawCards(1, self.name)
    if player.dead then return end
    local choices = {}
    for i = 1, 2, 1 do
      if player:getMark("hezhong"..i.."-turn") == 0 then
        table.insert(choices, "hezhong"..i)
      end
    end
    local choice = room:askForChoice(player, choices, self.name, "#hezhong-choice:::"..n, false, {"hezhong1", "hezhong2"})
    room:setPlayerMark(player, choice.."-turn", n)
  end,
}
local hezhong_trigger = fk.CreateTriggerSkill{
  name = "#hezhong_trigger",
  main_skill = hezhong,  --大概不是延时效果？
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("hezhong") and data.tos and data.card:isCommonTrick() and data.card.number > 0 and
      ((player:getMark("hezhong1-turn") > 0 and data.card.number > player:getMark("hezhong1-turn")) or
      (player:getMark("hezhong2-turn") > 0 and data.card.number < player:getMark("hezhong2-turn")))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    if player:getMark("hezhong1-turn") > 0 and data.card.number > player:getMark("hezhong1-turn") and
      player:getMark("hezhong1used-turn") == 0 then
      if room:askForSkillInvoke(player, "hezhong", nil, "#hezhong-invoke:::"..data.card:toLogString()) then
        n = n + 1
      end
    end
    if player:getMark("hezhong2-turn") > 0 and data.card.number < player:getMark("hezhong2-turn") and
      player:getMark("hezhong2used-turn") == 0 then
      if room:askForSkillInvoke(player, "hezhong", nil, "#hezhong-invoke:::"..data.card:toLogString()) then
        n = n + 1
      end
    end
    if n > 0 then
      self.cost_data = n
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("hezhong")
    room:notifySkillInvoked(player, "hezhong", "control")
    data.extra_data = data.extra_data or {}
    data.extra_data.hezhong = (data.extra_data.hezhong or 0) + self.cost_data
  end,
}
local hezhong_delay = fk.CreateTriggerSkill{
  name = "#hezhong_delay",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.extra_data and data.extra_data.hezhong and
      data.extra_data.hezhong > 0 and not data.extra_data.hezhong_using
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.extra_data.hezhong_using = true
    data.extra_data.hezhong = data.extra_data.hezhong - 1
    if data.card.name == "amazing_grace" then
      room.logic:trigger(fk.CardUseFinished, player, data)
      table.forEach(room.players, function(p) room:closeAG(p) end)  --手动五谷
      if data.extra_data and data.extra_data.AGFilled then
        local toDiscard = table.filter(data.extra_data.AGFilled, function(id) return room:getCardArea(id) == Card.Processing end)
        if #toDiscard > 0 then
          room:moveCards({
            ids = toDiscard,
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonPutIntoDiscardPile,
          })
        end
      end
      data.extra_data.AGFilled = nil

      local toDisplay = room:getNCards(#TargetGroup:getRealTargets(data.tos))
      room:moveCards({
        ids = toDisplay,
        toArea = Card.Processing,
        moveReason = fk.ReasonPut,
      })
      table.forEach(room.players, function(p) room:fillAG(p, toDisplay) end)
      data.extra_data = data.extra_data or {}
      data.extra_data.AGFilled = toDisplay
    end
    player.room:doCardUseEffect(data)
    data.extra_data.hezhong_using = false
  end,
}
hezhong:addRelatedSkill(hezhong_trigger)
hezhong:addRelatedSkill(hezhong_delay)
feiyi:addSkill(yanru)
feiyi:addSkill(hezhong)
Fk:loadTranslationTable{
  ["ol__feiyi"] = "费祎",
  ["yanru"] = "晏如",
  [":yanru"] = "出牌阶段各限一次，若你的手牌数为：奇数，你可以摸三张牌，然后弃置至少半数手牌；偶数，你可以弃置至少半数手牌，然后摸三张牌。",
  ["hezhong"] = "和衷",
  [":hezhong"] = "每回合各限一次，当你的手牌数变为1后，你可以展示之并摸一张牌，然后本回合你使用点数大于/小于此牌点数的普通锦囊牌多结算一次。",
  --FIXME: 真是服了这nt蝶描述，心变佬有兴趣就改叭
  ["#yanru1"] = "晏如：你可以摸三张牌，然后弃置至少半数手牌",
  ["#yanru2"] = "晏如：你可以弃置至少%arg张手牌，然后摸三张牌",
  ["#yanru-discard"] = "晏如：请弃置至少%arg张手牌",
  ["#hezhong-choice"] = "和衷：令你本回合点数大于或小于%arg的锦囊牌多结算一次",
  ["hezhong1"] = "大于",
  ["hezhong2"] = "小于",
  ["#hezhong-invoke"] = "和衷：是否令%arg多结算一次？",
}

--local lukai = General(extension, "ol__lukai", "wu", 3)
Fk:loadTranslationTable{
  ["ol__lukai"] = "陆凯",
}

return extension
