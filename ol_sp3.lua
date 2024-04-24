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
      if not to.dead and showMap[to.id] then
        local choice = player.room:askForChoice(player, choices, "huiyun", "#huiyun-choice::"..to.id)
        room:setPlayerMark(player, choice, 1)
        local cards = showMap[to.id]
        for _, cardId in ipairs(cards) do
          if to.dead then break end
          local name = Fk:getCardById(cardId):toLogString()
          if choice == "huiyun3-round" then
            if room:askForSkillInvoke(to, "huiyun", nil, "#huiyun3-draw") then
              to:drawCards(1, "huiyun")
            end
          elseif choice == "huiyun1-round" then
            if table.contains(to:getCardIds("h"), cardId) then
              local use = U.askForUseRealCard(room, to, {cardId}, ".", "huiyun", "#huiyun1-card:::"..name)
              if use then
                room:delay(300)
                if not to.dead and not to:isKongcheng() then
                  room:recastCard(to:getCardIds("h"), to, "huiyun")
                end
              end
            end
          elseif choice == "huiyun2-round" then
            local use = U.askForUseRealCard(room, to, to:getCardIds("h"), ".", "huiyun", "#huiyun2-card:::"..name)
            if use then
              room:delay(300)
              if not to.dead and table.contains(to:getCardIds("h"), cardId) then
                room:recastCard({cardId}, to, "huiyun")
              end
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
      use.extra_data.huiyun[player.id] = use.extra_data.huiyun[player.id] or {}
      table.insert(use.extra_data.huiyun[player.id], data.cardIds[1])
    end
  end,
}
huiyun:addRelatedSkill(huiyun_trigger)
huban:addSkill(huiyun)
Fk:loadTranslationTable{
  ["ol__huban"] = "胡班",
  ["#ol__huban"] = "险误忠良",
  ["designer:ol__huban"] = "cyc",
  ["illustrator:ol__huban"] = "鬼画府",

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
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    if #selected > 0 then return false end
    local to_throw = Fk:getCardById(to_select)
    return to_throw.type == Card.TypeBasic and not Self:prohibitDiscard(to_throw)
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
    if not target.dead then
      local card = room:askForDiscard(target, 1, 1, false, self.name, false, ".|.|.|.|.|basic",
      "#xiaosi-discard:"..player.id, true)
      if #card > 0 then
        table.insert(cards, card[1])
        room:throwCard(card, self.name, target, target)
      else
        if player.dead then return false end
        player:drawCards(1, self.name)
      end
    end
    local extra_data = {bypass_times = true, bypass_distances = true}
    while not player.dead do
      local ids = {}
      for _, id in ipairs(cards) do
        local card = Fk:getCardById(id)
        if room:getCardArea(card) == Card.DiscardPile and
        not player:prohibitUse(card) and player:canUse(card, extra_data) then
          table.insertIfNeed(ids, id)
        end
      end
      if #ids == 0 then return false end
      local use = U.askForUseRealCard(room, player, ids, ".", self.name, "#xiaosi-use",
      {expand_pile = ids, bypass_distances = true}, true)
      if use then
        table.removeOne(cards, use.card:getEffectiveId())
        room:useCard(use)
      else
        break
      end
    end
  end,
}
furong:addSkill(xiaosi)
Fk:loadTranslationTable{
  ["ol__furong"] = "傅肜",
  ["#ol__furong"] = "矢忠不二",
  ["illustrator:ol__furong"] = "君桓文化",

  ["xiaosi"] = "效死",
  [":xiaosi"] = "出牌阶段限一次，你可以弃置一张基本牌并选择一名有手牌的其他角色，其弃置一张基本牌"..
  "（若其不能弃置则你摸一张牌），然后你可以使用这些牌（无距离和次数限制）。",
  ["#xiaosi"] = "效死：弃置一张基本牌，令另一名角色弃置一张基本牌，然后你可以使用这些牌",
  ["#xiaosi-discard"] = "效死：请弃置一张基本牌，%src 可以使用之",
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
    room:moveCardTo(card, Player.Hand, player, fk.ReasonGive, self.name, nil, false, to.id, "@@ol__tongdu-inhand-turn")
  end,
}
local ol__tongdu_trigger = fk.CreateTriggerSkill{
  name = "#ol__tongdu_trigger",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and not player.dead and player.phase == Player.Play then
      local cards = table.filter(player:getCardIds(Player.Hand), function (id)
        return Fk:getCardById(id):getMark("@@ol__tongdu-inhand-turn") > 0
      end)
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ol__tongdu")
    room:notifySkillInvoked(player, "ol__tongdu")
    room:moveCards({
      ids = table.simpleClone(self.cost_data),
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
    room:recastCard(card, target, self.name)
  end,
}
local ol__zhubi_trigger = fk.CreateTriggerSkill{
  name = "#ol__zhubi_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and not player.dead and player.phase == Player.Finish then
      local cards = table.filter(player:getCardIds(Player.Hand), function (id)
        return Fk:getCardById(id):getMark("@@ol__zhubi-inhand") > 0
      end)
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local piles = U.askForArrangeCards(player, "ol__zhubi",
    {"Bottom", room:getNCards(5, "bottom"), "@@ol__zhubi-inhand", self.cost_data}, "#ol__zhubi-exchange")
    U.swapCardsWithPile(player, piles[1], piles[2], "ol__zhubi", "Bottom")
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Card.PlayerHand and
      move.skillName == "ol__zhubi" and move.moveReason == fk.ReasonDraw then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            room:setCardMark(Fk:getCardById(id), "@@ol__zhubi-inhand", 1)
          end
        end
      end
    end
  end,
}
ol__tongdu:addRelatedSkill(ol__tongdu_trigger)
ol__zhubi:addRelatedSkill(ol__zhubi_trigger)
liuba:addSkill(ol__tongdu)
liuba:addSkill(ol__zhubi)
Fk:loadTranslationTable{
  ["ol__liuba"] = "刘巴",
  ["#ol__liuba"] = "清尚之节",
  ["illustrator:ol__liuba"] = "匠人绘",
  ["ol__tongdu"] = "统度",
  [":ol__tongdu"] = "准备阶段，你可以令一名其他角色交给你一张手牌，然后本回合出牌阶段结束时，若此牌仍在你的手牌中，你将此牌置于牌堆顶。",
  ["ol__zhubi"] = "铸币",
  [":ol__zhubi"] = "出牌阶段限X次，你可以令一名角色重铸一张牌，以此法摸的牌称为“币”；有“币”的角色的结束阶段，其观看牌堆底的五张牌，"..
  "然后可以用任意“币”交换其中等量张牌（X为你的体力上限）。",
  ["#ol__tongdu-choose"] = "统度：你可以令一名其他角色交给你一张手牌，出牌阶段结束时你将之置于牌堆顶",
  ["#ol__tongdu-give"] = "统度：你须交给 %src 一张手牌，出牌阶段结束时将之置于牌堆顶",
  ["@@ol__tongdu-inhand-turn"] = "统度",
  ["#ol__zhubi-card"] = "铸币：重铸一张牌，摸到的“币”可以在你的结束阶段和牌堆底牌交换",
  ["@@ol__zhubi-inhand"] = "币",
  ["#ol__zhubi-exchange"] = "铸币：你可以用“币”交换牌堆底的卡牌",

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

    local n = #TargetGroup:getRealTargets(data.tos)
    local ids = room:getNCards(n)

    --FIXME:被拿走的牌会从处理区消失(*꒦ິ⌓꒦ີ*)
    --room:moveCardTo(ids, Card.Processing, player, fk.ReasonJustMove, self.name, nil, true, player.id)
    player:showCards(ids)

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
    local targets = TargetGroup:getRealTargets(data.tos)

    local red_players = {}
    local to_clean = {}

    while #ids > 0 and not player.dead do
      room:setPlayerMark(player, "chenglie_cards", ids)
      room:setPlayerMark(player, "chenglie_targets", targets)
      local _, dat = room:askForUseActiveSkill(player, "chenglie_active", "#chenglie-give", false)
      room:setPlayerMark(player, "chenglie_cards", 0)
      room:setPlayerMark(player, "chenglie_targets", 0)

      if dat == nil then
        dat = {targets = {targets[1]}, cards = {ids[1]}}
      end
      table.removeOne(targets, dat.targets[1])
      table.removeOne(ids, dat.cards[1])
      table.insert(to_clean, dat.cards[1])

      room:getPlayerById(dat.targets[1]):addToPile("chenglie", dat.cards, false, self.name, player.id, player.id)

      if Fk:getCardById(dat.cards[1]).color == Card.Red then
        table.insert(red_players, dat.targets[1])
      end
    end

    if #to_clean > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.chenglie_data = data.extra_data.chenglie_data or {}
      table.insert(data.extra_data.chenglie_data, {player.id, red_players, to_clean})
    end

    if #ids > 0 then
      room:moveCardTo(ids, Card.DiscardPile, nil, fk.ReasonJustMove, nil, nil, true, nil)
    end
  end,
}
local chenglie_active = fk.CreateActiveSkill{
  name = "chenglie_active",
  mute = true,
  card_num = 1,
  target_num = 1,
  expand_pile = function (self)
    return U.getMark(Self, "chenglie_cards")
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and table.contains(U.getMark(Self, "chenglie_cards"), to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and table.contains(U.getMark(Self, "chenglie_targets"), to_select)
  end,
}
local chenglie_delay = fk.CreateTriggerSkill{
  name = "#chenglie_delay",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if not player.dead and data.extra_data and data.extra_data.chenglie_data then
      for _, value in ipairs(data.extra_data.chenglie_data) do
        if value[1] == player.id then
          self.cost_data = {table.simpleClone(value[2]), table.simpleClone(value[3])}
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local red_player = table.simpleClone(self.cost_data[1])
    local to_clean = table.simpleClone(self.cost_data[2])
    local targets = TargetGroup:getRealTargets(data.tos)
    room:sortPlayersByAction(targets)
    local resp_players = {}
    local use_events = room.logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
    local cards = data.cardsResponded
    if cards ~= nil then
      for i = #use_events, 1, -1 do
        local e = use_events[i]
        local use = e.data[1]
        if e.data[1] == data then break end
        --FIXME:还需要更加精准的判断
        if table.contains(cards, use.card) then
          table.insert(resp_players, use.from)
        end
      end
    end
    for _, pid in ipairs(targets) do
      if table.contains(red_player, pid) then
        local to = room:getPlayerById(pid)
        if not to.dead then
          if table.contains(resp_players, pid) then
            if not (to:isNude() or player.dead) then
              local card = room:askForCard(to, 1, 1, true, "chenglie", false, ".", "#chenglie-card:"..player.id)
              room:obtainCard(player.id, card[1], false, fk.ReasonGive, to.id)
            end
          elseif to:isWounded() then
            room:recover{
              who = to,
              num = 1,
              recoverBy = player,
              skillName = "chenglie"
            }
          end
        end
      end
    end
    to_clean = table.filter(to_clean, function(id)
      if room:getCardArea(id) == Card.PlayerSpecial then
        local p = room:getCardOwner(id)
        return p and p:getPileNameOfId(id) == "chenglie"
      end
    end)
    if #to_clean > 0 then
      room:moveCardTo(to_clean, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, nil, nil, true, nil)
    end
  end,
}
Fk:addSkill(chenglie_active)
chenglie:addRelatedSkill(chenglie_delay)
macheng:addSkill("mashu")
macheng:addSkill(chenglie)
Fk:loadTranslationTable{
  ["macheng"] = "马承",
  ["#macheng"] = "孤蹄踏乱",
  ["designer:macheng"] = "cyc",
  ["illustrator:macheng"] = "君桓文化",
  ["chenglie"] = "骋烈",
  [":chenglie"] = "你使用【杀】可以多指定至多两个目标，然后展示牌堆顶与目标数等量张牌，秘密将一张手牌与其中一张牌交换，将之分别暗置于"..
  "目标角色武将牌上直到此【杀】结算结束，其中“骋烈”牌为红色的角色若：响应了此【杀】，其交给你一张牌；未响应此【杀】，其回复1点体力。",
  ["#chenglie-choose"] = "骋烈：你可以为%arg多指定1-2个目标，并执行后续效果",
  ["#chenglie-exchange"] = "骋烈：你可以用一张手牌交换其中一张牌",
  ["chenglie_active"] = "骋烈",
  ["#chenglie"] = "骋烈",
  ["#chenglie_delay"] = "骋烈",
  ["#chenglie-give"] = "骋烈：将这些牌置于目标角色武将牌上直到【杀】结算结束",
  ["#chenglie-card"] = "骋烈：你需交给 %src 一张牌",
  ["#ChenglieResult"] = "%from 的「骋烈」牌为 %arg",

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
      local targets, targetRecorded = {}, U.getMark(player, "qiejian_prohibit-round")
      for _, move in ipairs(data) do
        if move.from and not table.contains(targetRecorded, move.from) then
          local to = player.room:getPlayerById(move.from)
          if to:isKongcheng() and not to.dead and not table.every(move.moveInfo, function (info)
              return info.fromArea ~= Card.PlayerHand end) then
            table.insertIfNeed(targets, move.from)
          end
        end
      end
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(self.cost_data)
    room:sortPlayersByAction(targets)
    for _, target_id in ipairs(targets) do
      if not player:hasSkill(self) then break end
      if not table.contains(U.getMark(player, "qiejian_prohibit-round"), target_id) then
        local skill_target = room:getPlayerById(target_id)
        if skill_target and not skill_target.dead then
          self:doCost(event, skill_target, player, data)
        end
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
      local targetRecorded = U.getMark(player, "qiejian_prohibit-round")
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
    U.swapHandCards(room, player, player, room:getPlayerById(tos[1]), nishou.name)
  end,
}
nishou:addRelatedSkill(nishou_delay)
quhuang:addSkill(qiejian)
quhuang:addSkill(nishou)
Fk:loadTranslationTable{
  ["quhuang"] = "屈晃",
  ["#quhuang"] = "泥头自缚",
  ["illustrator:quhuang"] = "夜小雨",
  ["qiejian"] = "切谏",
  [":qiejian"] = "当一名角色失去手牌后，若其没有手牌，你可以与其各摸一张牌，"..
  "然后选择一项：1.弃置你或其场上的一张牌；2.你本轮内不能对其发动此技能。",
  ["nishou"] = "泥首",
  [":nishou"] = "锁定技，当你装备区里的牌进入弃牌堆后，你选择一项：1.将此牌当【闪电】使用；"..
  "2.本阶段结束时，你与一名全场手牌数最少的角色交换手牌且本阶段内你无法选择此项。",

  ["#qiejian-invoke"] = "是否对 %dest 使用 切谏",
  ["#qiejian-choose"] = "切谏：选择一名角色，弃置其场上一张牌，或点取消则本轮内不能再对 %dest 发动 切谏",
  ["#nishou-choice"] = "泥首：选择将%arg当做【闪电】使用，或在本阶段结束时与手牌数最少的角色交换手牌",
  ["nishou_lightning"] = "将此装备牌当【闪电】使用",
  ["nishou_exchange"] = "本阶段结束时与手牌数最少的角色交换手牌",
  ["#nishou_delay"] = "泥首",
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
    return target == player and player:hasSkill(self) and player:getHandcardNum() > player:getMaxCards() and data.to ~= player.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    if not to.dead and U.isOnlyTarget(to, data, event) and data.firstTarget and U.hasFullRealCard(room, data.card) then
      room:obtainCard(to, data.card, true, fk.ReasonJustMove)
    end
    AimGroup:cancelTarget(data, data.to)
    return true
  end,
}
local jianhe = fk.CreateActiveSkill{
  name = "jianhe",
  anim_type = "offensive",
  prompt = "#jianhe-active",
  min_card_num = 2,
  target_num = 1,
  can_use = Util.TrueFunc,
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
    room:setPlayerMark(target, "jianhe-turn", 1)
    local n = #effect.cards
    room:recastCard(effect.cards, player, self.name)
    if #target:getCardIds("he") >= n then
      local type_name = Fk:getCardById(effect.cards[1]):getTypeString()
      local cards = room:askForCard(target, n, n, true, self.name, true,
      ".|.|.|.|.|"..type_name, "#jianhe-choose:::"..n..":"..type_name)
      if #cards > 0 then
        room:recastCard(cards, target, self.name)
        return
      end
    end
    room:damage{
      from = player,
      to = target,
      damage = 1,
      damageType = fk.ThunderDamage,
      skillName = self.name,
    }
  end
}
local chuanwu = fk.CreateTriggerSkill{
  name = "chuanwu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player:getAttackRange() > 0 then
      local skills = Fk.generals[player.general]:getSkillNameList(true)
      if player.deputyGeneral ~= "" then
        table.insertTableIfNeed(skills, Fk.generals[player.deputyGeneral]:getSkillNameList(true))
      end
      skills = table.filter(skills, function(s) return player:hasSkill(s, true) end)
      if #skills > 0 then
        self.cost_data = skills
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local skills = table.simpleClone(self.cost_data)
    local n = math.min(player:getAttackRange(), #skills)
    if n == 0 then return false end
    skills = table.slice(skills, 1, n + 1)
    local mark = U.getMark(player, "chuanwu")
    table.insertTable(mark, skills)
    player.room:setPlayerMark(player, "chuanwu", mark)
    player.room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"), nil, true, false)
    player:drawCards(n, self.name)
  end,
}
local chuanwu_delay = fk.CreateTriggerSkill{
  name = "#chuanwu_delay",
  events = {fk.TurnEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player:getMark("chuanwu") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("chuanwu")
    room:notifySkillInvoked(player, "chuanwu")
    local skills = U.getMark(player, "chuanwu")
    room:setPlayerMark(player, "chuanwu", 0)
    room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
  end,
}
chuanwu:addRelatedSkill(chuanwu_delay)
zhanghua:addSkill(bihun)
zhanghua:addSkill(jianhe)
zhanghua:addSkill(chuanwu)
Fk:loadTranslationTable{
  ["zhanghua"] = "张华",
  ["#zhanghua"] = "双剑化龙",
  ["designer:zhanghua"] = "玄蝶既白",
  ["illustrator:zhanghua"] = "匠人绘",

  ["bihun"] = "弼昏",
  [":bihun"] = "锁定技，当你使用牌指定其他角色为目标时，若你的手牌数大于手牌上限，你取消之并令唯一目标获得此牌。",
  ["jianhe"] = "剑合",
  [":jianhe"] = "出牌阶段每名角色限一次，你可以重铸至少两张同名牌或至少两张装备牌，令一名角色选择一项：1.重铸等量张与之类型相同的牌；2.受到你造成的1点雷电伤害。",
  ["chuanwu"] = "穿屋",
  [":chuanwu"] = "锁定技，当你造成或受到伤害后，你失去你武将牌上前X个技能直到回合结束（X为你的攻击范围），然后摸等同失去技能数张牌。",
  ["#jianhe-active"] = "发动 剑合，选择至少两张同名牌重铸，并选择一名角色",
  ["#jianhe-choose"] = "剑合：你需重铸%arg张%arg2，否则受到1点雷电伤害",
  ["#chuanwu_delay"] = "穿屋",

  ["$bihun1"] = "辅弼天家，以扶朝纲。",
  ["$bihun2"] = "为国治政，尽忠匡辅。",
  ["$jianhe1"] = "身临朝阙，腰悬太阿。",
  ["$jianhe2"] = "位登三事，当配龙泉。",
  ["$chuanwu1"] = "斩蛇穿屋，其志绥远。",
  ["$chuanwu2"] = "祝融侵库，剑怀远志。",
  ["~zhanghua"] = "桑化为柏，此非不祥乎？",
}

local dongtuna = General(extension, "dongtuna", "qun", 4)
local jianman = fk.CreateTriggerSkill{
  name = "jianman",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local users, names, to = {}, {}, nil
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
        local use = e.data[1]
        if use.card.type == Card.TypeBasic then
          table.insert(users, use.from)
          table.insertIfNeed(names, use.card.name)
          return true
        end
      end, Player.HistoryTurn)
      if #users < 2 then return false end
      local n = 0
      if users[1] == player.id then
        n = n + 1
        to = users[2]
      end
      if users[2] == player.id then
        n = n + 1
        to = users[1]
      end
      self.cost_data = nil
      if n == 2 then
        self.cost_data = names
      elseif n == 1 then
        self.cost_data = to
      end
      return n > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if type(self.cost_data) == "table" then
      U.askForUseVirtualCard(room, player, self.cost_data, nil, self.name, nil, false, true, false, true)
    else
      local to = room:getPlayerById(self.cost_data)
      if not to.dead and not to:isNude() then
        local id = room:askForCardChosen(player, to, "he", self.name)
        room:throwCard({id}, self.name, to, player)
      end
    end
  end,
}
dongtuna:addSkill(jianman)
Fk:loadTranslationTable{
  ["dongtuna"] = "董荼那",
  ["#dongtuna"] = "铅刀拿云",
  ["designer:dongtuna"] = "大宝",
  ["illustrator:dongtuna"] = "monkey",
  ["jianman"] = "鹣蛮",
  [":jianman"] = "锁定技，每回合结束时，若本回合前两张基本牌的使用者：均为你，你视为使用其中的一张牌；仅其中之一为你，你弃置另一名使用者一张牌。",

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
    if player.dead then return false end
    player:gainAnExtraPhase(Player.Play)
  end,
}
local kangrui = fk.CreateTriggerSkill{
  name = "kangrui",
  anim_type = "support",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and not target.dead then
      local room = player.room
      if room.current ~= target then return false end
      local damage_event = room.logic:getCurrentEvent():findParent(GameEvent.Damage, true)
      if damage_event == nil then return false end
      local x = target:getMark("kangrui_record-turn")
      if x == 0 then
        U.getActualDamageEvents(room, 1, function (e)
          if e.data[1].to == target then
            x = e.id
            room:setPlayerMark(target, "kangrui_record-turn", x)
            return true
          end
        end)
      end
      return x == damage_event.id
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, data, "#kangrui-invoke::"..target.id) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    if player.dead or target.dead then return false end
    local choices = {"kangrui_damage"}
    if target:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askForChoice(player, choices, self.name, "#kangrui-choice::"..target.id, false, {"recover", "kangrui_damage"})
    if choice == "recover" then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
      if target.dead then return false end
      room:setPlayerMark(target, "@kangrui-turn", "")
    else
      room:setPlayerMark(target, "@kangrui-turn", "kangrui_adddamage")
    end
  end,
}
local kangrui_delay = fk.CreateTriggerSkill{
  name = "#kangrui_delay",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@kangrui-turn") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@kangrui-turn") == "kangrui_adddamage" then
      if player:hasSkill(kangrui, true) then
        room:notifySkillInvoked(player, "kangrui", "offensive")
        player:broadcastSkillInvoke("kangrui")
      end
      data.damage = data.damage + 1
    end
    room:setPlayerMark(player, "@kangrui-turn", 0)
    room:setPlayerMark(player, "kangrui_minus-turn", 1)
    room:broadcastProperty(player, "MaxCards")
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
  ["#ol__zhangyiy"] = "奉公弗怠",
  ["designer:ol__zhangyiy"] = "朔方的雪",
  ["illustrator:ol__zhangyiy"] = "君桓文化",
  ["dianjun"] = "殿军",
  [":dianjun"] = "锁定技，结束阶段结束时，你受到1点伤害并执行一个额外的出牌阶段。",
  ["kangrui"] = "亢锐",
  [":kangrui"] = "当一名角色于其回合内首次受到伤害后，你可以摸一张牌并令其：1.回复1点体力；2.本回合下次造成的伤害+1。然后当其造成伤害时，其此回合手牌上限改为0。",
  ["#kangrui-invoke"] = "亢锐：你可以摸一张牌，令 %dest 回复1点体力或本回合下次造成伤害+1",
  ["kangrui_damage"] = "本回合下次造成伤害+1",
  ["#kangrui_delay"] = "亢锐",
  ["#kangrui-choice"] = "亢锐：选择令 %dest 执行的一项",
  ["@kangrui-turn"] = "亢锐",
  ["kangrui_adddamage"] = "加伤害",

  ["$dianjun1"] = "大将军勿忧，翼可领后军。",
  ["$dianjun2"] = "诸将速行，某自领军殿后！",
  ["$kangrui1"] = "尔等魍魉，愿试吾剑之利乎？",
  ["$kangrui2"] = "诸君鼓力，克复中原指日可待！",
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
  ["#maxiumatie"] = "颉翥三秦",
  ["illustrator:maxiumatie"] = "alien",
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
    return target == player and player:hasSkill(self)
    and player:getMark("@cuipo-turn") == Fk:translate(data.card.trueName, "zh_CN"):len()
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
  ["#ol__zhujun"] = "钦明神武",
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
  prompt = function ()
    return "miuyan-prompt-".. Self:getSwitchSkillState("miuyan", false, true)
  end,
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
    return target == player and player:hasSkill(miuyan) and table.contains(data.card.skillNames, "miuyan")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState("miuyan", true) == fk.SwitchYang and data.damageDealt then
      local moveInfos = {}
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if player.dead then break end
        if not p:isKongcheng() then
          local cards = {}
          for _, id in ipairs(p.player_cards[Player.Hand]) do
            if Fk:getCardById(id):getMark("miuyan-phase") > 0 then
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

  refresh_events = {fk.CardShown},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(data.cardIds) do
      if table.contains(player.player_cards[Player.Hand], id) then
        room:setCardMark(Fk:getCardById(id), "miuyan-phase", 1)
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
    local targets = table.map(table.filter(room.alive_players, function(p)
      return player:inMyAttackRange(p) and not p:isKongcheng() end), Util.IdMapper)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#shilu-choose", self.name, false)
    local to = room:getPlayerById(tos[1])
    local id = room:askForCardChosen(player, to, "h", self.name)
    to:showCards(id)
    if room:getCardArea(id) == Card.PlayerHand then
      room:setCardMark(Fk:getCardById(id), "@@shilu-inhand", 1)
      to:filterHandcards()
    end
  end,
}
local shilu_filter = fk.CreateFilterSkill{
  name = "#shilu_filter",
  card_filter = function(self, card, player)
    return card:getMark("@@shilu-inhand") > 0 and table.contains(player.player_cards[Player.Hand], card.id)
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
  ["#wangguan"] = "假降误撞",
  ["designer:wangguan"] = "zzccll朱古力",
  ["illustrator:wangguan"] = "匠人绘",

  ["miuyan"] = "谬焰",
  [":miuyan"] = "转换技，阳：你可以将一张黑色牌当【火攻】使用，若此牌造成伤害，你获得本阶段展示过的所有手牌；"..
  "阴：你可以将一张黑色牌当【火攻】使用，若此牌未造成伤害，本轮本技能失效。",
  ["shilu"] = "失路",
  [":shilu"] = "锁定技，当你受到伤害后，你摸等同体力值张牌并展示攻击范围内一名其他角色的一张手牌，令此牌视为【杀】。",
  ["@@miuyan-round"] = "谬焰失效",
  ["miuyan-prompt-yang"] = "将一张黑色牌当【火攻】使用，若造成伤害，获得本阶段展示过的所有手牌",
  ["miuyan-prompt-yin"] = "将一张黑色牌当【火攻】使用，若未造成伤害，本轮“谬焰”失效",
  ["#shilu-choose"] = "失路：展示一名角色的一张手牌，此牌视为【杀】",
  ["@@shilu-inhand"] = "失路",
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
    if player.dead then return end
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
    local mark = U.getMark(player, "@$daili")
    if event == fk.CardShown then
      for _, id in ipairs(data.cardIds) do
        if Fk:getCardById(id):getMark("@@daili") == 0 and table.contains(player:getCardIds("h"), id) then
          table.insert(mark, id)
          room:setCardMark(Fk:getCardById(id, true), "@@daili", 1)
        end
      end
    else
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId, true):getMark("@@daili") > 0 then
              table.removeOne(mark, info.cardId)
              room:setCardMark(Fk:getCardById(info.cardId, true), "@@daili", 0)
            end
          end
        end
      end
    end
    room:setPlayerMark(player, "@$daili", mark)
  end,
}
luoxian:addSkill(daili)
Fk:loadTranslationTable{
  ["luoxian"] = "罗宪",
  ["#luoxian"] = "介然毕命",
  ["designer:luoxian"] = "玄蝶既白",
  ["cv:luoxian"] = "邵晨",
  ["illustrator:luoxian"] = "匠人绘",

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
            moveReason = fk.ReasonPrey,
            proposer = player.id,
            skillName = self.name,
            moveVisible = false,
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
  ["#sunhong"] = "谮诉构争",
  ["designer:sunhong"] = "zzccll朱古力",
  ["illustrator:sunhong"] = "匠人绘",

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
  mute = true,
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
  derived_piles = "xinggu",
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
  ["#zhangshiping"] = "中山大商",
  ["illustrator:zhangshiping"] = "匠人绘",
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
  local mark = U.getMark(p, "zhuyan")
  if #mark == 2 then
    if p:getMark("zhuyan_hp") == 0 then
      local sig = ""
      local n = p:getMark("zhuyan")[1] - p.hp
      if n > 0 then
        sig = "+"
      end
      room:setPlayerMark(p, "@zhuyan1", sig..tostring(n))
    end
    if p:getMark("zhuyan_handcard") == 0 then
      local sig = ""
      local n = p:getMark("zhuyan")[2] - p:getHandcardNum()
      if n > 0 then
        sig = "+"
      end
      room:setPlayerMark(p, "@zhuyan2", sig..tostring(n))
    end
  end
end
local zhuyan_active = fk.CreateActiveSkill{
  name = "zhuyan_active",
  card_num = 0,
  target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = {"zhuyan_hp", "zhuyan_handcard"}}
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #selected > 0 then return false end
    local to = Fk:currentRoom():getPlayerById(to_select)
    return to:getMark(self.interaction.data) == 0 and #U.getMark(to, "zhuyan") == 2
  end,
}
Fk:addSkill(zhuyan_active)
local zhuyan = fk.CreateTriggerSkill{
  name = "zhuyan",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Discard and
    not table.every(player.room.alive_players, function (p)
      return #U.getMark(p, "zhuyan") ~= 2 or (p:getMark("zhuyan_hp") > 0 and p:getMark("zhuyan_handcard") > 0)
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      setZhuyanMark(p)
    end
    local _, dat = room:askForUseActiveSkill(player, "zhuyan_active", "#zhuyan-choose", true, nil, false)
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@zhuyan1", 0)
      room:setPlayerMark(p, "@zhuyan2", 0)
    end
    if dat then
      self.cost_data = {dat.targets[1], dat.interaction}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    local choice = self.cost_data[2]
    if choice == "zhuyan_hp" then
      room:setPlayerMark(to, "zhuyan_hp", 1)
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
      room:setPlayerMark(to, "zhuyan_handcard", 1)
      local n = to:getMark(self.name)[2] - to:getHandcardNum()
      if n > 0 then
        to:drawCards(n, self.name)
      elseif n < 0 then
        room:askForDiscard(to, -n, -n, false, self.name, false)
      end
    end
  end,

  refresh_events = {fk.GameStart , fk.AfterPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    else
      return target == player and player.phase == Player.Finish
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, {player.hp, math.min(player:getHandcardNum(), 5)})
  end,
}
local leijie = fk.CreateActiveSkill{
  name = "leijie",
  anim_type = "control",
  prompt = "#leijie-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local judge = {
      who = target,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if target.dead then return end
    if judge.card.suit == Card.Spade and judge.card.number > 1 and judge.card.number < 10 then
      if player == target or player.dead then return false end
      if room:useVirtualCard("thunder__slash", nil, player, target, self.name, true) and not (player.dead or target.dead) then
        room:useVirtualCard("thunder__slash", nil, player, target, self.name, true)
      end
    else
      room:drawCards(target, 2, self.name)
    end
  end,
}
lushi:addSkill(zhuyan)
lushi:addSkill(leijie)
Fk:loadTranslationTable{
  ["lushi"] = "卢氏",
  ["#lushi"] = "蝉蜕蛇解",
  ["illustrator:lushi"] = "君桓文化",
  ["zhuyan"] = "驻颜",
  [":zhuyan"] = "弃牌阶段结束时，你可以令一名角色将以下项调整至与其上个结束阶段时（若无则改为游戏开始时）相同：体力值；手牌数（至多摸至五张）。"..
  "每名角色每项限一次",
  ["leijie"] = "雷劫",
  [":leijie"] = "出牌阶段限一次，你可以令一名角色判定，若结果为♠2~9，你依次视为对其使用两张雷【杀】，否则其摸两张牌。",
  ["#zhuyan-choose"] = "驻颜：你可以令一名角色将体力值或手牌数调整至与其上个准备阶段相同",
  ["#zhuyan-choice"] = "驻颜：选择令 %dest 调整的一项",
  ["#leijie-active"] = "发动 雷劫，令一名角色判定，若为♠2~9，视为对其使用两张雷【杀】，否则其摸两张牌",

  ["zhuyan_active"] = "驻颜",
  ["@zhuyan1"] = "体力",
  ["@zhuyan2"] = "手牌",
  ["zhuyan_hp"] = "体力值",
  ["zhuyan_handcard"] = "手牌数",

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
    local top_cards = room:getNCards(1)
    local piles = U.askForArrangeCards(player, self.name,
    {"Top", top_cards, player.general, player:getCardIds{Player.Hand, Player.Equip}}, "#tianhou-exchange")
    U.swapCardsWithPile(player, piles[1], piles[2], self.name, "Top")
    top_cards = room:getNCards(1)
    table.insert(room.draw_pile, 1, top_cards[1])
    room:doBroadcastNotify("UpdateDrawPile", #room.draw_pile)
    player:showCards(top_cards)
    local suit = Fk:getCardById(top_cards[1], true).suit
    if suit == Card.NoSuit then return end
    local suits = {Card.Heart, Card.Diamond, Card.Spade, Card.Club}
    local i = table.indexOf(suits, suit)
    local skills = {"tianhou_hot", "tianhou_fog", "tianhou_rain", "tianhou_frost"}
    local skill = skills[i]
    local targets = table.map(room.alive_players, Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, 1,
      "#tianhou-choose:::"..skill..":"..Fk:translate(":"..skill), self.name, false)
    local to = room:getPlayerById(tos[1])
    player.tag[self.name] = {to.id, skill}
    room:handleAddLoseSkills(to, skill, nil, true)
  end,

  refresh_events = {fk.EventPhaseStart, fk.RoundEnd},
  can_refresh = function (self, event, target, player, data)
    if type(player.tag[self.name]) == "table" then
      if event == fk.RoundEnd then
        return player.dead
      else
        return target == player and player.phase == Player.Start
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local mark = player.tag[self.name]
    local p = room:getPlayerById(mark[1])
    room:handleAddLoseSkills(p, "-"..mark[2], nil, true)
    player.tag[self.name] = 0
  end,
}
local tianhou_hot = fk.CreateTriggerSkill{
  name = "tianhou_hot",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Finish and not target.dead and
      table.every(player.room.alive_players, function(p) return target.hp >= p.hp end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(target, 1, self.name)
  end,

  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@tianhou_hot", event == fk.EventAcquireSkill and 1 or 0)
  end,
}
local tianhou_fog = fk.CreateTriggerSkill{
  name = "tianhou_fog",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self) and data.card.trueName == "slash" then
      local to = player.room:getPlayerById(data.to)
      return U.isOnlyTarget(to, data, event) and to:getNextAlive() ~= target and target:getNextAlive() ~= to
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
      data.nullifiedTargets = table.map(room.players, Util.IdMapper)
    end
  end,

  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@tianhou_fog", event == fk.EventAcquireSkill and 1 or 0)
  end,
}
local tianhou_rain = fk.CreateTriggerSkill{
  name = "tianhou_rain",
  mute = true,
  events = {fk.DamageCaused, fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.DamageCaused then
        return target and target ~= player and data.damageType == fk.FireDamage
      else
        if not (target.dead or target:isRemoved()) and data.damageType == fk.ThunderDamage then
          local next_p = target:getNextAlive()
          if next_p == nil or next_p == target then return false end
          local targets = {}
          table.insert(targets, next_p.id)
          for _, p in ipairs(player.room.alive_players) do
            if p ~= target and p ~= next_p and p:getNextAlive() == target then
              table.insert(targets, p.id)
              break
            end
          end
          if #targets > 0 then
            self.cost_data = targets
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.DamageCaused then
      room:notifySkillInvoked(player, self.name, "control")
      return true
    else
      room:notifySkillInvoked(player, self.name, "offensive")
      local targets = table.simpleClone(self.cost_data)
      room:doIndicate(player.id, targets)
      for _, pid in ipairs(targets) do
        local p = room:getPlayerById(pid)
        if not p.dead then
          room:loseHp(p, 1, self.name)
        end
      end
    end
  end,

  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@tianhou_rain", event == fk.EventAcquireSkill and 1 or 0)
  end,
}
local tianhou_frost = fk.CreateTriggerSkill{
  name = "tianhou_frost",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Finish and not target.dead and
      table.every(player.room.alive_players, function(p) return target.hp <= p.hp end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(target, 1, self.name)
  end,

  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@tianhou_frost", event == fk.EventAcquireSkill and 1 or 0)
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
    room:delay(1000)
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
        proposer = player.id
      }
      dummy:addSubcard(get[1])
      local card2 = Fk:getCardById(get[1], true)
      if card.type == card2.type or card.suit == card2.suit or card.number == card2.number or
      Fk:translate(card.trueName, "zh_CN"):len() == Fk:translate(card2.trueName, "zh_CN"):len() then
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
zhouqun:addRelatedSkill(tianhou_hot)
zhouqun:addRelatedSkill(tianhou_fog)
zhouqun:addRelatedSkill(tianhou_rain)
zhouqun:addRelatedSkill(tianhou_frost)
Fk:loadTranslationTable{
  ["ol__zhouqun"] = "周群",
  ["#ol__zhouqun"] = "后圣",
  ["illustrator:ol__zhouqun"] = "鬼画府",
  ["tianhou"] = "天候",
  [":tianhou"] = "锁定技，准备阶段，你观看牌堆顶牌并选择是否用一张牌交换之，然后展示牌堆顶的牌，令一名角色根据此牌花色获得技能直到你下个准备阶段(若你死亡，改为直到本轮结束时)："..
  "<font color='red'>♥</font>〖烈暑〗；<font color='red'>♦</font>〖凝雾〗；♠〖骤雨〗；♣〖严霜〗。"..
  "<font color='grey'><br>♥〖烈暑〗：锁定技，其他角色的结束阶段，若其体力值全场最大，其失去1点体力。"..
  "<br>♦〖凝雾〗：锁定技，当其他角色使用【杀】指定不与其相邻的角色为唯一目标时，其判定，若判定牌点数大于此【杀】，此【杀】无效。"..
  "<br>♠〖骤雨〗：锁定技，防止其他角色造成的火焰伤害。当一名角色受到雷电伤害后，其相邻的角色失去1点体力。"..
  "<br>♣〖严霜〗：锁定技，其他角色的结束阶段，若其体力值全场最小，其失去1点体力。",
  ["chenshuo"] = "谶说",
  [":chenshuo"] = "结束阶段，你可以展示一张手牌。若如此做，展示牌堆顶牌，若两张牌类型/花色/点数/牌名字数中任意项相同且展示牌数不大于3，重复此流程。"..
  "然后你获得以此法展示的牌。",
  ["tianhou_hot"] = "烈暑",
  [":tianhou_hot"] = "锁定技，其他角色的结束阶段，若其体力值全场最大，其失去1点体力。",
  ["tianhou_fog"] = "凝雾",
  [":tianhou_fog"] = "锁定技，当其他角色使用【杀】指定不与其相邻的角色为唯一目标时，其判定，若判定牌点数大于此【杀】，此【杀】无效。",
  ["tianhou_rain"] = "骤雨",
  [":tianhou_rain"] = "锁定技，防止其他角色造成的火焰伤害。当一名角色受到雷电伤害后，其相邻的角色失去1点体力。",
  ["tianhou_frost"] = "严霜",
  [":tianhou_frost"] = "锁定技，其他角色的结束阶段，若其体力值全场最小，其失去1点体力。",
  ["#tianhou-exchange"] = "天候：你可以用一张手牌交换牌堆底部的牌",
  ["#tianhou-choose"] = "天候：令一名角色获得技能<br>〖%arg〗：%arg2",
  ["@@tianhou_hot"] = "烈暑",
  ["@@tianhou_fog"] = "凝雾",
  ["@@tianhou_rain"] = "骤雨",
  ["@@tianhou_frost"] = "严霜",
  ["#chenshuo-invoke"] = "谶说：你可以展示一张手牌，亮出并获得牌堆顶至多三张相同类型/花色/点数/字数的牌",

  ["$tianhou1"] = "雷霆雨露，皆为君恩。",
  ["$tianhou2"] = "天象之所显，世事之所为。",
  ["$chenshuo1"] = "命数玄奥，然吾可言之。",
  ["$chenshuo2"] = "天地神鬼之辩，在吾唇舌之间。",
  ["$tianhou_hot"] = "七月流火，涸我山泽。",
  ["$tianhou_fog"] = "云雾弥野，如夜之幽。",
  ["$tianhou_rain"] = "月离于毕，俾滂沱矣。",
  ["$tianhou_frost"] = "雪瀑寒霜落，霜下可折竹。",
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
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Self:getHandcardNum() >= Fk:currentRoom():getPlayerById(to_select):getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local tos = {player, target}
    local cardsMap = {}
    for _, p in ipairs(tos) do
      local choices = {"0", "1", "2"}
      p.request_data = json.encode({choices, choices, self.name, "#zhenying-choice"})
      cardsMap[p.id] = table.filter(p:getCardIds("h"), function(id)
        return not p:prohibitDiscard(Fk:getCardById(id))
      end)
    end
    room:notifyMoveFocus(tos, self.name)
    room:doBroadcastRequest("AskForChoice", tos)
    local discard_num_map = {}
    for _, p in ipairs(tos) do
      local choice = p.reply_ready and tonumber(p.client_reply) or 2
      discard_num_map[p.id] = p:getHandcardNum() - choice
    end
    local toAsk = {}
    for _, p in ipairs(tos) do
      local num = math.min(discard_num_map[p.id], #cardsMap[p.id])
      if num > 0 then
        table.insert(toAsk, p)
        local extra_data = {
          num = num,
          min_num = num,
          include_equip = false,
          skillName = self.name,
          pattern = ".",
          reason = self.name,
        }
        p.request_data = json.encode({ "discard_skill", "#AskForDiscard:::"..num..":"..num, false, extra_data })
      end
    end
    if #toAsk > 0 then
      local moveInfos = {}
      room:notifyMoveFocus(tos, self.name)
      room:doBroadcastRequest("AskForUseActiveSkill", toAsk)
      for _, p in ipairs(toAsk) do
        local throw
        if p.reply_ready then
          local replyCard = json.decode(p.client_reply).card
          throw = json.decode(replyCard).subcards
        else
          throw = table.random(cardsMap[p.id], discard_num_map[p.id])
        end
        table.insert(moveInfos, {
          ids = throw,
          from = p.id,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonDiscard,
          proposer = p.id,
          skillName = self.name,
        })
      end
      room:moveCards(table.unpack(moveInfos))
    end
    for _, p in ipairs(tos) do
      if not p.dead then
        local num = discard_num_map[p.id]
        if num < 0 then
          p:drawCards(-num, self.name)
        end
      end
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
  ["#haopu"] = "惭恨入地",
  ["designer:haopu"] = "何如",
  ["illustrator:haopu"] = "匠人绘",
  ["zhenying"] = "镇荧",
  [":zhenying"] = "出牌阶段限两次，你可以与一名手牌数不大于你的其他角色同时摸或弃置手牌至至多两张，然后手牌数较少的角色视为对另一名角色使用【决斗】。",
  ["#zhenying"] = "镇荧：与一名手牌数不大于你的其他角色同时选择将手牌调整至 0~2",
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
  ["#ol__mengda"] = "腾挪反复",
  ["designer:ol__mengda"] = "玄蝶既白",
  ["illustrator:ol__mengda"] = "匠人绘",
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
  ["#ol__wenqin"] = "困兽鸱张",
  ["designer:ol__wenqin"] = "玄蝶既白",
  ["illustrator:ol__wenqin"] = "匠人绘",
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
  local extra_data = { bypass_times = true }
  while not player.dead do
    local ids = {}
    for _, id in ipairs(cards) do
      local card = Fk:getCardById(id)
      if card.trueName == "slash" and room:getCardArea(card) == Card.DiscardPile and
        not player:prohibitUse(card) and player:canUse(card, extra_data) then
        table.insertIfNeed(ids, id)
      end
    end
    if #ids == 0 then return end
    local use = U.askForUseRealCard(room, player, ids, ".", "saogu", "#saogu-use", {expand_pile = ids}, true)
    if use then
      table.removeOne(cards, use.card:getEffectiveId())
      room:useCard(use)
    else
      break
    end
  end
end
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
  can_use = function(self)
    return Self:getSwitchSkillState(self.name, false) == fk.SwitchYin or
    #U.getMark(Self, "@[suits]saogu-phase") < 4
  end,
  card_filter = function(self, to_select, selected)
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang and #selected < 2 then
      local card = Fk:getCardById(to_select)
      return card.suit ~= Card.NoSuit and
      not (table.contains(U.getMark(Self, "@[suits]saogu-phase"), card.suit) or Self:prohibitDiscard(card))
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      room:throwCard(effect.cards, "saogu", player, player)
      DoSaogu(player, effect.cards)
    else
      player:drawCards(1, self.name)
    end
  end,
}
local saogu_trigger = fk.CreateTriggerSkill{
  name = "#saogu_trigger",
  anim_type = "support",
  main_skill = saogu,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(saogu) and player.phase == Player.Finish and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    if player:getSwitchSkillState("saogu", false) == fk.SwitchYang then
      targets = table.map(table.filter(room.alive_players, function(p)
        return p ~= player and not p:isNude() end), Util.IdMapper)
    else
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    end
    local to, card = room:askForChooseCardAndPlayers(player, targets, 1, 1, ".", "#saogu-choose", "saogu", true)
    if #to > 0 and card then
      self.cost_data = {to[1], card, player:getSwitchSkillState("saogu", false, true)}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(saogu.name)
    room:throwCard({self.cost_data[2]}, "saogu", player, player)
    local to = room:getPlayerById(self.cost_data[1])
    if not to.dead then
      if self.cost_data[3] == "yang" then
        local suits = {"spade", "heart", "club", "diamond"}
        for _, suit in ipairs(U.getMark(player, "@[suits]saogu-phase")) do
          table.removeOne(suits, U.ConvertSuit(suit, "int", "str"))
        end
        local cards = room:askForDiscard(to, 2, 2, true, "saogu", false,
          ".|.|"..table.concat(suits, ","), "#saogu-yang")
        if #cards > 0 then
          DoSaogu(to, cards)
        end
      else
        to:drawCards(1, "saogu")
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if player.phase == Player.Play or player.phase == Player.Finish then
      return player:hasSkill(saogu, true) or
      (event == fk.EventLoseSkill and player:getMark("@[suits]saogu-phase") ~= 0)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local mark = U.getMark(player, "@[suits]saogu-phase")
      local suit = Card.NoSuit
      local updata_mark = false
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            suit = Fk:getCardById(info.cardId).suit
            if not table.contains(mark, suit) then
              table.insert(mark, suit)
              updata_mark = true
            end
          end
        end
      end
      if updata_mark then
        room:setPlayerMark(player, "@[suits]saogu-phase", mark)
      end
    elseif event == fk.EventAcquireSkill then
      local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase, true)
      if phase_event == nil then return false end
      local end_id = phase_event.id
      local mark = {}
      local suit = Card.NoSuit
      U.getEventsByRule(room, GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              suit = Fk:getCardById(info.cardId, true).suit
              if not table.contains(mark, suit) then
                table.insertIfNeed(mark, suit)
              end
            end
          end
        end
        return false
      end, end_id)
      if #mark > 0 then
        room:setPlayerMark(player, "@[suits]saogu-phase", mark)
      end
    elseif event == fk.EventLoseSkill then
      room:setPlayerMark(player, "@[suits]saogu-phase", 0)
    end
  end,
}
saogu:addRelatedSkill(saogu_trigger)
duanjiong:addSkill(saogu)
Fk:loadTranslationTable{
  ["duanjiong"] = "段颎",
  ["#duanjiong"] = "束马县锋",
  ["designer:duanjiong"] = "绯红的波罗",
  ["illustrator:duanjiong"] = "黯荧岛工作室",

  ["saogu"] = "扫谷",
  [":saogu"] = "转换技，出牌阶段，你可以：阳，弃置两张牌（不能包含你本阶段弃置过的花色），使用其中的【杀】；阴，摸一张牌。"..
  "结束阶段，你可以弃置一张牌，令一名其他角色执行当前项。",
  ["#saogu-yang"] = "扫谷：弃置两张牌，你可以使用其中的【杀】",
  ["#saogu-yin"] = "扫谷：你可以摸一张牌",
  ["#saogu_trigger"] = "扫谷",
  ["@[suits]saogu-phase"] = "扫谷",
  ["#saogu-choose"] = "扫谷：你可以弃置一张牌，令一名其他角色执行“扫谷”当前项",
  ["#saogu-use"] = "扫谷：你可以使用其中的【杀】",

  ["$saogu1"] = "大汉铁骑，必昭卫霍遗风于当年。",
  ["$saogu2"] = "笑驱百蛮，试问谁敢牧马于中原！",
  ["~duanjiong"] = "秋霜落，天下寒……",
}

local caoxi = General(extension, "caoxi", "wei", 3)
local function gangshuTimesCheck(player, card)
  local status_skills = Fk:currentRoom().status_skills[TargetModSkill] or Util.DummyTable
  for _, skill in ipairs(status_skills) do
    if skill:bypassTimesCheck(player, card.skill, Player.HistoryPhase, card) then return true end
  end
  return false
end
local function updateGangshu(player, reset)
  local room = player.room
  local hasGangshu = player:hasSkill("gangshu", true)
  if reset or not hasGangshu then
    room:setPlayerMark(player, "gangshu1_fix", 0)
    room:setPlayerMark(player, "gangshu2_fix", 0)
    room:setPlayerMark(player, "gangshu3_fix", 0)
  end
  if hasGangshu then
    local card = Fk:cloneCard("slash")
    local x1 = player:getAttackRange()
    if x1 > 499 then
      --FIXME:暂无无限攻击范围机制
      x1 = "∞"
    else
      x1 = tostring(x1)
    end
    local x2 = tostring(player:getMark("gangshu2_fix")+2)
    local x3 = ""
    if gangshuTimesCheck(player, card) then
      x3 = "∞"
    else
      x3 = tostring(card.skill:getMaxUseTime(player, Player.HistoryPhase, card, nil))
    end
    local mark = U.getMark(player, "@gangshu")
    if #mark ~= 3 or mark[1] ~= x1 or mark[2] ~= x2 or mark[3] ~= x3 then
      room:setPlayerMark(player, "@gangshu", { x1, x2, x3 })
    end
  else
    room:setPlayerMark(player, "@gangshu", 0)
  end
end
local gangshu = fk.CreateTriggerSkill{
  name = "gangshu",
  events = {fk.CardUseFinished, fk.CardEffecting, fk.DrawNCards},
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.CardUseFinished then
      if target == player and data.card.type ~= Card.TypeBasic then
        if player:getMark("gangshu2_fix") < 3 then return true end
        if player:getAttackRange() < 5 then return true end
        local card = Fk:cloneCard("slash")
        return not gangshuTimesCheck(player, card) and card.skill:getMaxUseTime(player, Player.HistoryPhase, card, nil) < 5
      end
    elseif event == fk.CardEffecting then
      --你使用的以牌为目标的牌生效时，非常抽象的时机
      return data.toCard and data.from == player.id and
      (player:getMark("gangshu1_fix") > 0 or player:getMark("gangshu2_fix") > 0 or player:getMark("gangshu3_fix") > 0)
    elseif event == fk.DrawNCards then
      return target == player and player:getMark("gangshu2_fix") > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      local choices = {"Cancel"}
      if player:getAttackRange() < 5 then
        table.insert(choices, "gangshu1")
      end
      if player:getMark("gangshu2_fix") < 3 then
        table.insert(choices, "gangshu2")
      end
      local card = Fk:cloneCard("slash")
      if not gangshuTimesCheck(player, card) and card.skill:getMaxUseTime(player, Player.HistoryPhase, card, nil) < 5 then
        table.insert(choices, "gangshu3")
      end
      if #choices == 1 then return false end
      local choice = player.room:askForChoice(player, choices, self.name, "#gangshu-choice", false, {"gangshu1", "gangshu2", "gangshu3", "Cancel"})
      if choice == "Cancel" then return false end
      self.cost_data = choice
      return true
    else
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.CardUseFinished then
      room:notifySkillInvoked(player, self.name)
      room:addPlayerMark(player, self.cost_data .. "_fix", 1)
      updateGangshu(player)
    elseif event == fk.CardEffecting then
      room:notifySkillInvoked(player, self.name, "negative")
      updateGangshu(player, true)
    elseif event == fk.DrawNCards then
      room:notifySkillInvoked(player, self.name, "drawcard")
      data.n = data.n + player:getMark("gangshu2_fix")
      room:setPlayerMark(player, "gangshu2_fix", 0)
      updateGangshu(player)
    end
  end,

  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill, fk.AfterCardsMove, fk.AfterSkillEffect},
  can_refresh = Util.TrueFunc,
  on_refresh = function (self, event, target, player, data)
    updateGangshu(player)
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
    local n = 0
    local card = Fk:cloneCard("slash")
    repeat
      to:drawCards(1, self.name)
      if to.dead or player.dead or not player:hasSkill(gangshu, true) then break end
      n = to:getHandcardNum()
    until (n ~= player:getAttackRange() and n ~= player:getMark("gangshu2_fix") + 2 and 
    (gangshuTimesCheck(player, card) or 
    n ~= card.skill:getMaxUseTime(player, Player.HistoryPhase, card, nil)))
  end,
}
gangshu:addRelatedSkill(gangshu_attackrange)
gangshu:addRelatedSkill(gangshu_targetmod)
caoxi:addSkill(gangshu)
caoxi:addSkill(jianxuan)
Fk:loadTranslationTable{
  ["caoxi"] = "曹羲",
  ["#caoxi"] = "魁立倾厦",
  ["designer:caoxi"] = "玄蝶既白",
  ["illustrator:caoxi"] = "匠人绘",
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
local xiaofan = fk.CreateViewAsSkill{
  name = "xiaofan",
  pattern = ".",
  anim_type = "special",
  expand_pile = function (self)
    return table.slice(U.getMark(Self, "xiaofan_view"), 1, #U.getMark(Self, "xiaofan_types-turn") + 2)
  end,
  prompt = function()
    return "#xiaofan:::"..(#U.getMark(Self, "xiaofan_types-turn") + 1)
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 0 and table.contains(U.getMark(Self, "xiaofan_view"), to_select) then
      local card = Fk:getCardById(to_select)
      if Fk.currentResponsePattern == nil then
        return Self:canUse(card) and not Self:prohibitUse(card)
      else
        return Exppattern:Parse(Fk.currentResponsePattern):match(card)
      end
    end
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    return Fk:getCardById(cards[1])
  end,
  after_use = function (self, player, useData)
    local x = #U.getMark(player, "xiaofan_types-turn")
    local areas = {"j", "e", "h"}
    local to_throw = ""
    for i = 1, x, 1 do
      to_throw = to_throw .. areas[i]
    end
    player:throwAllCards(to_throw)
  end,
  enabled_at_play = function(self, player)
    return #U.getMark(player, "xiaofan_view") > 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and #U.getMark(player, "xiaofan_view") > 0
  end,
}
local xiaofan_trigger = fk.CreateTriggerSkill{
  name = "#xiaofan_trigger",
  mute = true,

  refresh_events = {fk.AfterCardsMove, fk.AfterDrawPileShuffle, fk.PreCardUse, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == xiaofan
    else
      return player:hasSkill(xiaofan, true) and (player == target or event ~= fk.PreCardUse)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove or event == fk.AfterDrawPileShuffle then
      local mark = U.getMark(player, "xiaofan_view")
      local draw_pile = room.draw_pile
      local new_mark = {}
      for i = 0, 3, 1 do
        if #draw_pile <= i then break end
        table.insert(new_mark, draw_pile[#draw_pile - i])
      end
      if #new_mark ~= mark then
        room:setPlayerMark(player, "xiaofan_view", new_mark)
      end
      for i = 1, #new_mark, 1 do
        if new_mark[i] ~= new_mark[i] then
          room:setPlayerMark(player, "xiaofan_view", new_mark)
          return false
        end
      end
    elseif event == fk.PreCardUse then
      local mark = U.getMark(player, "xiaofan_types-turn")
      local type_name = data.card:getTypeString()
      if not table.contains(mark, type_name) then
        table.insert(mark, type_name)
        room:setPlayerMark(player, "xiaofan_types-turn", mark)
      end
    elseif event == fk.EventAcquireSkill then
      local draw_pile = room.draw_pile
      local mark = {}
      for i = 0, 2, 1 do
        if #draw_pile <= i then break end
        table.insert(mark, draw_pile[#draw_pile - i])
      end
      room:setPlayerMark(player, "xiaofan_view", mark)

      local mark = U.getMark(player, "xiaofan_types-turn")
      local current_event = room.logic:getCurrentEvent()
      if current_event == nil then return false end
      local start_event = current_event:findParent(GameEvent.Turn, true)
      if start_event == nil then return false end
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        if use.from == player.id then
          table.insertIfNeed(mark, use.card:getTypeString())
        end
        return #mark == 3
      end, Player.HistoryTurn)
      room:setPlayerMark(player, "xiaofan_types-turn", mark)
    elseif event == fk.EventLoseSkill then
      room:setPlayerMark(player, "xiaofan_view", 0)
    end
  end,
}
local tuoshi = fk.CreateTriggerSkill{
  name = "tuoshi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.number == 1 or data.card.number > 10)
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, self.name)
    data.toCard = nil
    data.tos = {}
    player.room:setPlayerMark(player, "@@tuoshi", 1)
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function (self, event, target, player, data)
    if player ~= target or player:getMark("@@tuoshi") == 0 then return false end
    local room = player.room
    return table.find(TargetGroup:getRealTargets(data.tos), function (pid)
      return room:getPlayerById(pid):getHandcardNum() < player:getHandcardNum()
    end)
  end,
  on_refresh = function (self, event, target, player, data)
    data.extraUse = true
    player.room:setPlayerMark(player, "@@tuoshi", 0)
  end,
}
local tuoshi_prohibit = fk.CreateProhibitSkill{
  name = "#tuoshi_prohibit",
  frequency = Skill.Compulsory,
  prohibit_use = function(self, player, card)
    return player:hasSkill(tuoshi) and card and card.trueName == "nullification"
  end,
}
local tuoshi_targetmod = fk.CreateTargetModSkill{
  name = "#tuoshi_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:getMark("@@tuoshi") > 0 and to and to:getHandcardNum() < player:getHandcardNum()
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return player:getMark("@@tuoshi") > 0 and to and to:getHandcardNum() < player:getHandcardNum()
  end,
}
xiaofan:addRelatedSkill(xiaofan_trigger)
tuoshi:addRelatedSkill(tuoshi_prohibit)
tuoshi:addRelatedSkill(tuoshi_targetmod)
pengyang:addSkill(xiaofan)
pengyang:addSkill(tuoshi)
pengyang:addSkill("cunmu")

Fk:loadTranslationTable{
  ["ol__pengyang"] = "彭羕",
  ["#ol__pengyang"] = "翻然轻举",
  ["xiaofan"] = "嚣翻",
  [":xiaofan"] = "当你需要使用牌时，你可以观看牌堆底X+1张牌，然后可以使用其中你需要的牌并弃置你前X区域里的牌："..
  "1.判定区；2.装备区；3.手牌区。（X为本回合你使用过牌的类别数）",
  ["tuoshi"] = "侻失",
  [":tuoshi"] = "锁定技，你不能使用【无懈可击】。"..
  "你使用点数为字母的牌无效并摸一张牌，且下次对手牌数小于你的角色使用牌无距离和次数限制。",
  ["#xiaofan"] = "嚣翻：观看牌堆底%arg张牌，使用其中你需要的牌",
  ["@@tuoshi"] = "侻失",
}

local qianzhao = General(extension, "ol__qianzhao", "wei", 4)
local updataWeifuMark = function (player)
  local room = player.room
  local mark = {}
  local basic = player:getMark("weifu_basic-turn")
  if basic > 0 then
    table.insert(mark, Fk:translate("basic_char")..basic)
  end
  local trick = player:getMark("weifu_trick-turn")
  if trick > 0 then
    table.insert(mark, Fk:translate("trick_char")..trick)
  end
  room:setPlayerMark(player, "@weifu-turn", #mark > 0 and mark or 0)
end
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
    if judge.card.type ~= Card.TypeEquip then
      room:addPlayerMark(player, "weifu_"..judge.card:getTypeString().."-turn")
      updataWeifuMark(player)
    end
    if judge.card.type == Fk:getCardById(effect.cards[1]).type then
      player:drawCards(1, self.name)
    end
  end,
}
local weifu_delay = fk.CreateTriggerSkill{
  name = "#weifu_delay",
  events = {fk.AfterCardTargetDeclared},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and not player.dead and player:getMark("weifu_"..data.card:getTypeString().."-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("weifu_"..data.card:getTypeString().."-turn")
    room:setPlayerMark(player, "weifu_"..data.card:getTypeString().."-turn", 0)
    updataWeifuMark(player)
    if data.tos and (data.card:isCommonTrick() or data.card.type == Card.TypeBasic) and #U.getUseExtraTargets(room, data, true) > 0 then
      local tos = room:askForChoosePlayers(player, U.getUseExtraTargets(room, data, true), 1, n,
      "#weifu-invoke:::"..data.card:toLogString()..":"..n, "weifu", true)
      if #tos > 0 then
        for _, pid in ipairs(tos) do
          table.insert(data.tos, {pid})
        end
        room:sendLog{
          type = "#AddTargetsBySkill",
          from = player.id,
          to = tos,
          arg = "weifu",
          arg2 = data.card:toLogString()
        }
      end
    end
  end,
}
local weifu_targetmod = fk.CreateTargetModSkill{
  name = "#weifu_targetmod",
  bypass_distances =  function(self, player, skill, card, to)
    return card and player:getMark("weifu_"..card:getTypeString().."-turn") > 0
  end,
}
local kuansai = fk.CreateTriggerSkill{
  name = "kuansai",
  anim_type = "control",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.firstTarget and #AimGroup:getAllTargets(data.tos) >= player.hp
    and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
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
        room:moveCardTo(card, Player.Hand, player, fk.ReasonGive, self.name, nil, false, to.id)
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
weifu:addRelatedSkill(weifu_delay)
weifu:addRelatedSkill(weifu_targetmod)
qianzhao:addSkill(weifu)
qianzhao:addSkill(kuansai)
Fk:loadTranslationTable{
  ["ol__qianzhao"] = "牵招",
  ["#ol__qianzhao"] = "雁门无烟",
  ["designer:ol__qianzhao"] = "cyc",
  ["illustrator:ol__qianzhao"] = "匠人绘",
  ["weifu"] = "威抚",
  [":weifu"] = "出牌阶段，你可以弃置一张牌并判定，你本回合下次使用与判定牌类别相同的牌无距离限制且可以多指定一个目标；若弃置牌与判定牌类别相同，你摸一张牌。",
  ["kuansai"] = "款塞",
  [":kuansai"] = "每回合限一次，当一张牌指定目标后，若目标数不小于你的体力值，你可以令其中一个目标选择一项：1.交给你一张牌；2.你回复1点体力。",
  ["#weifu"] = "威抚：你可以弃置一张牌并判定，你使用下一张判定结果类别的牌无距离限制且目标+1",
  ["@weifu-turn"] = "威抚",
  ["#weifu_delay"] = "威抚",
  ["#weifu-invoke"] = "威抚：你可以为%arg额外指定至多 %arg2 个目标",
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
    if player:hasSkill(self) and target == player then
      if event == fk.DamageInflicted then
        return player:getMark("cangxin-turn") == 0
      elseif event == fk.EventPhaseStart then
        return player.phase == Player.Draw
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    room:notifySkillInvoked(player, self.name, event == fk.EventPhaseStart and "drawcard" or "defensive")
    local card_ids = room:getNCards(3, "bottom")
    room:moveCards({
      ids = card_ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      proposer = player.id
    })
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
      room:setPlayerMark(player, "cangxin-turn", 1)
      local to_throw = room:askForCardsChosen(player, player, 0, 3, {
        card_data = {
          { "Bottom", card_ids }
        }
      }, self.name)
      if #to_throw > 0 then
        local x = 0
        for _, id in ipairs(to_throw) do
          if Fk:getCardById(id).suit == Card.Heart then
            x = x + 1
          end
          table.removeOne(card_ids, id)
        end
        data.damage = data.damage - x
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
    room:broadcastProperty(target, "MaxCards")
  end,
}
luyusheng:addSkill(cangxin)
luyusheng:addSkill(runwei)

Fk:loadTranslationTable{
  ["ol__luyusheng"] = "陆郁生",
  ["#ol__luyusheng"] = "义姑",
  ["designer:ol__luyusheng"] = "zzccll朱古力",

  ["cangxin"] = "藏心",
  [":cangxin"] = "锁定技，摸牌阶段开始时，你展示牌堆底三张牌并摸与其中<font color='red'>♥</font>牌数等量张牌。"..
  "当你每回合首次受到伤害时，你展示牌堆底三张牌并弃置其中任意张牌，令伤害值-X（X为以此法弃置的<font color='red'>♥</font>牌数）。",
  ["runwei"] = "润微",
  [":runwei"] = "一名角色的弃牌阶段开始时，若其已受伤，你可以选择：1.令其弃置一张牌，其本回合手牌上限+1；"..
  "2.令其摸一张牌，其本回合手牌上限-1。",

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
    return event == fk.GameStart or (not target.dead and
      player:getMark("@ol__fudao") ~= 0 and tonumber(player:getMark("@ol__fudao")) == target:getHandcardNum())
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
      if player.dead then return end
      local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
      if not player:isKongcheng() and #targets > 0 then
        local tos, cards = U.askForChooseCardsAndPlayers(room, player, 1, 3, targets, 1, 1, nil, "#ol__fudao-give", self.name, true)
        if #tos > 0 then
          local to = room:getPlayerById(tos[1])
          room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
          if player.dead then return end
        end
      end
      room:askForDiscard(player, 1, 999, false, self.name, true, nil, "#ol__fudao-discard")
      if player.dead then return end
      room:setPlayerMark(player, "@ol__fudao", tostring(player:getHandcardNum()))
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
      return target == player and player:hasSkill(self) and not player.dead and
      data.responseToEvent and data.responseToEvent.from and data.responseToEvent.from ~= player.id and
      not player.room:getPlayerById(data.responseToEvent.from).dead
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to
    if event == fk.Damaged then
      to = data.from
    else
      to = room:getPlayerById(data.responseToEvent.from)
    end
    room:doIndicate(player.id, {to.id})
    local choice = player.room:askForChoice(player, {"ol__fengyan_self:" .. to.id, "ol__fengyan_other:" .. to.id}, self.name)
    if choice:startsWith("ol__fengyan_self") then
      player:drawCards(1, self.name)
      if not (to.dead or player.dead or player:isNude()) then
        local c = room:askForCard(player, 1, 1, true, self.name, false, nil, "#ol__fengyan-card::" .. to.id)
        room:moveCardTo(c, Player.Hand, to, fk.ReasonGive, self.name, nil, false, player.id)
      end
    else
      room:drawCards(to, 1, self.name)
      if not to.dead then
        room:askForDiscard(to, 2, 2, true, self.name, false, nil)
      end
    end
  end,
}

dingfuren:addSkill(fudao)
dingfuren:addSkill(fengyan)

Fk:loadTranslationTable{
  ["ol__dingfuren"] = "丁尚涴",
  ["#ol__dingfuren"] = "我心匪席",
  ["cv:ol__dingfuren"] = "闲踏梧桐",
  ["designer:ol__dingfuren"] = "幽蝶化烬",
  ["ol__fudao"] = "抚悼",
  [":ol__fudao"] = "游戏开始时，你摸三张牌，交给一名其他角色至多三张手牌，弃置任意张手牌，然后记录你的手牌数。每回合结束时，若当前回合角色的手牌数为此数值，你可以与其各摸一张牌。",
  ["ol__fengyan"] = "讽言",
  [":ol__fengyan"] = "锁定技，当你受到其他角色造成的伤害后，或当你响应其他角色使用的牌后，你选择一项：1. 你摸一张牌并交给其一张牌；2. 其摸一张牌并弃置两张牌。",

  ["@ol__fudao"] = "抚悼",
  ["#ol__fudao-give"] = "抚悼：可以交给一名其他角色至多三张牌",
  ["#ol__fudao-discard"] = "抚悼：可以弃置任意张手牌",
  ["#ol__fudao-ask"] = "抚悼：你可与 %dest 各摸一张牌",
  ["ol__fengyan_self"] = "你摸一张牌并交给%src一张牌",
  ["ol__fengyan_other"] = "%src摸一张牌并弃置两张牌",
  ["#ol__fengyan-card"] = "讽言：请交给 %dest 一张牌",

  ["$ol__fudao1"] = "冰刃入腹，使肝肠寸断。",
  ["$ol__fudao2"] = "失子之殇，世间再无春秋。",
  ["$ol__fengyan1"] = "何不以曹公之命，换我儿之命乎？",
  ["$ol__fengyan2"] = "亲儿丧于宛城，曹公何颜复还？",
  ["~ol__dingfuren"] = "今生与曹，不复相见……",
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
  ["designer:ol__liwan"] = "对勾对勾w",

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
    local success, dat = player.room:askForUseViewAsSkill(player, "suji_viewas", "#suji:"..target.id, true, {bypass_times = true})
    if success then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = self.cost_data
    local card = Fk.skills["suji_viewas"]:viewAs(dat.cards)
    local use = {from = player.id, tos = table.map(dat.targets, function(p) return {p} end), card = card, extraUse = true}
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
      local targets = U.getUseExtraTargets(room, data, false, true)
      if #targets > 0 then
        local tos = room:askForChoosePlayers(player, targets, 1, target_num, "#langdao-AddTarget:::"..target_num, self.name, true)
        if #tos > 0 then
          for _, pid in ipairs(tos) do
            AimGroup:addTargets(room, data, pid)
          end
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
  ["#zhangyan"] = "飞燕",
  ["designer:zhangyan"] = "廷玉",
  ["illustrator:zhangyan"] = "君桓文化",

  ["suji"] = "肃疾",
  [":suji"] = "已受伤角色的出牌阶段开始时，你可以将一张黑色牌当【杀】使用，若其受到此【杀】伤害，你获得其一张牌。",
  ["suji_viewas"] = "肃疾",
  ["#suji"] = "肃疾：可以将黑色牌当【杀】使用，若%src受到此【杀】伤害，你获得其一张牌",
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

local lvboshe = General(extension, "lvboshe", "qun", 4)
local fushi = fk.CreateViewAsSkill{
  name = "fushi",
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#fushi",
  expand_pile = "fushi",
  derived_piles = "fushi",
  card_filter = function(self, to_select, selected)
    return Self:getPileNameOfId(to_select) == self.name
  end,
  view_as = function(self, cards)
    if #cards == 0 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    card:setMark("fushi_subcards", cards)
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local cards = use.card:getMark("fushi_subcards")
    room:recastCard(cards, player, self.name)
    if player.dead then return end
    local choices = {"fushi1", "fushi2", "fushi3"}
    local n = math.min(#cards, 3)
    local chosen = room:askForChoices(player, choices, n, n, self.name, nil, false, false)
    local targets = TargetGroup:getRealTargets(use.tos)
    if table.contains(chosen, "fushi1") then
      local tos = U.getUseExtraTargets(room, use, false)
      if #tos > 0 then
        tos = room:askForChoosePlayers(player, tos, 1, 1, "#fushi1-choose", self.name, false, true)
        table.insert(targets, tos[1])
        room:sortPlayersByAction(targets)
        use.tos = table.map(targets, function(p) return {p} end)
        room:sendLog{
          type = "#AddTargetsBySkill",
          from = player.id,
          to = tos,
          arg = self.name,
          arg2 = use.card:toLogString()
        }
      end
    end
    use.extra_data = use.extra_data or {}
    if table.contains(chosen, "fushi2") then
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#fushi2-choose", self.name, false, true)
      use.extra_data.fushi2 = tos[1]
    end
    if table.contains(chosen, "fushi3") then
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#fushi3-choose", self.name, false, true)
      use.extra_data.fushi3 = tos[1]
    end
    if #chosen > 1 and table.contains(chosen, "fushi2") and #targets > 1 then
      local yes = true
      for i = 1, #targets - 1, 1 do
        if room:getPlayerById(targets[i]):getNextAlive() ~= room:getPlayerById(targets[i+1]) then
          yes = false
        end
      end
      if yes then
        use.extraUse = true
      end
    end
  end,
  enabled_at_play = function(self, player)
    return #player:getPile(self.name) > 0
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
    if player:hasSkill(self) and data.card.trueName == "slash" and (player == target or player:distanceTo(target) == 1) then
      local room = player.room
      local subcards = data.card:isVirtual() and data.card.subcards or {data.card.id}
      return #subcards > 0 and table.every(subcards, function(id) return room:getCardArea(id) == Card.Processing end)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("fushi")
    room:notifySkillInvoked(player, "fushi", "special")
    player:addToPile("fushi", data.card, true, "fushi")
  end,

  refresh_events = {fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    if target == player and data.card and table.contains(data.card.skillNames, "fushi") then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      return e and e.data[1].extra_data and (e.data[1].extra_data.fushi2 or e.data[1].extra_data.fushi3)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    if not e then return end
    local use = e.data[1]
    if use.extra_data.fushi2 == data.to.id then
      data.damage = data.damage - 1
    end
    if use.extra_data.fushi3 == data.to.id then
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
  ["#lvboshe"] = "醉乡路稳",
  ["illustrator:lvboshe"] = "匠人绘",

  ["fushi"] = "缚豕",
  [":fushi"] = "当一名角色使用【杀】后，若你至其距离小于2，你将之置于你的武将牌上。"..
  "你可以重铸任意张「缚豕」牌，视为使用一张具有以下等量项效果的【杀】"..
  "：1.目标数+1；2.对一个目标造成的伤害-1；3.对一个目标造成的伤害+1。"..
  "若你选择的选项相邻且目标均相邻，此【杀】不计入限制的次数。",
  ["dongdao"] = "东道",
  [":dongdao"] = "转换技，阳：农民回合结束后，你可以令地主执行一个额外回合；"..
  "阴：农民回合结束后，其可以执行一个额外回合。（仅斗地主模式生效）",
  ["#fushi"] = "缚豕：重铸任意张「缚豕」牌，视为使用一张附加等量效果的【杀】",
  ["fushi1"] = "目标+1",
  ["fushi2"] = "对一个目标伤害-1",
  ["fushi3"] = "对一个目标伤害+1",
  ["#fushi1-choose"] = "缚豕：为此【杀】增加一个目标",
  ["#fushi2-choose"] = "缚豕：选择一个目标，此【杀】对其伤害-1",
  ["#fushi3-choose"] = "缚豕：选择一个目标，此【杀】对其伤害+1",
  ["#fushi_trigger"] = "缚豕",
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
---@param player ServerPlayer
local updataHezhongMark = function (player)
  local room = player.room
  local mark = {}
  if player:getMark("hezhong1-turn") > 0 and player:getMark("hezhong1used-turn") == 0 then
    table.insert(mark, ">"..player:getMark("hezhong1-turn"))
  end
  if player:getMark("hezhong2-turn") > 0 and player:getMark("hezhong2used-turn") == 0 then
    table.insert(mark, "&lt;"..player:getMark("hezhong2-turn"))
  end
  room:setPlayerMark(player, "@hezhong-turn", #mark > 0 and table.concat(mark, ";") or 0)
end
local hezhong = fk.CreateTriggerSkill{
  name = "hezhong",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:getHandcardNum() == 1 and player:usedSkillTimes(self.name, Player.HistoryTurn) < 2 then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand then
          return true
        end
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
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
    updataHezhongMark(player)
  end,
}
local hezhong_trigger = fk.CreateTriggerSkill{
  name = "#hezhong_trigger",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.tos and data.card:isCommonTrick() and data.card.number > 0 and
      ((player:getMark("hezhong1-turn") > 0 and player:getMark("hezhong1used-turn") == 0 and data.card.number > player:getMark("hezhong1-turn")) or
      (player:getMark("hezhong2-turn") > 0 and player:getMark("hezhong2used-turn") == 0 and data.card.number < player:getMark("hezhong2-turn")))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("hezhong")
    room:notifySkillInvoked(player, "hezhong", "control")
    local n = 0
    if player:getMark("hezhong1-turn") > 0 and player:getMark("hezhong1used-turn") == 0 and data.card.number > player:getMark("hezhong1-turn") then
      n = n + 1
      room:setPlayerMark(player, "hezhong1used-turn", 1)
    end
    if player:getMark("hezhong2-turn") > 0 and player:getMark("hezhong2used-turn") == 0 and data.card.number < player:getMark("hezhong2-turn") then
      n = n + 1
      room:setPlayerMark(player, "hezhong2used-turn", 1)
    end
    updataHezhongMark(player)
    data.additionalEffect = (data.additionalEffect or 0) + n
  end,
}
hezhong:addRelatedSkill(hezhong_trigger)
feiyi:addSkill(yanru)
feiyi:addSkill(hezhong)
Fk:loadTranslationTable{
  ["ol__feiyi"] = "费祎",
  ["#ol__feiyi"] = "中才之相",
  ["designer:ol__feiyi"] = "廷玉",
  ["illustrator:ol__feiyi"] = "君桓文化",

  ["yanru"] = "晏如",
  [":yanru"] = "出牌阶段各限一次，若你的手牌数为：奇数，你可以摸三张牌，然后弃置至少半数手牌；偶数，你可以弃置至少半数手牌，然后摸三张牌。",
  ["hezhong"] = "和衷",
  [":hezhong"] = "每回合各限一次，当你的手牌数变为1后，你可以展示之并摸一张牌，然后本回合你使用的下一张点数大于/小于此牌点数的普通锦囊牌多结算一次。",

  ["#yanru1"] = "晏如：你可以摸三张牌，然后弃置至少半数手牌",
  ["#yanru2"] = "晏如：你可以弃置至少%arg张手牌，然后摸三张牌",
  ["#yanru-discard"] = "晏如：请弃置至少%arg张手牌",
  ["#hezhong-choice"] = "和衷：令你本回合点数大于或小于%arg的普通锦囊多结算一次",
  ["hezhong1"] = "大于",
  ["hezhong2"] = "小于",
  ["@hezhong-turn"] = "和衷",
  
  ["$yanru1"] = "国有宁日，民有丰年，大同也。",
  ["$yanru2"] = "及臻厥成，天下晏如也。",
  ["$hezhong1"] = "家和而万事兴，国亦如是。",
  ["$hezhong2"] = "你我同殿为臣，理当协力齐心。",
  ["~ol__feiyi"] = "今为小人所伤，皆酒醉之误……",
}

local lukai = General(extension, "ol__lukai", "wu", 3)
local xuanzhu = fk.CreateViewAsSkill{
  name = "xuanzhu",
  anim_type = "switch",
  switch_skill_name = "xuanzhu",
  derived_piles = "xuanzhu",
  pattern = ".",
  interaction = function()
    local all_names = {}
    if Self:getSwitchSkillState("xuanzhu", false) == fk.SwitchYang then
      all_names = U.getAllCardNames("b")
    else
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id)
        if card:isCommonTrick() and not (card.is_derived or card.multiple_targets or card.is_passive) then
          table.insertIfNeed(all_names, card.name)
        end
      end
    end
    local names = U.getViewAsCardNames(Self, "xuanzhu", all_names)
    if #names > 0 then
      return UI.ComboBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:setMark("xuanzhu_subcards", cards)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local cards = use.card:getMark("xuanzhu_subcards")
    if Fk:getCardById(cards[1]).type == Card.TypeEquip then
      use.extra_data = use.extra_data or {}
      use.extra_data.xuanzhu_equip = true
    end
    player:addToPile(self.name, cards, true, self.name)
  end,
  after_use = function(self, player, use)
    if player.dead then return end
    if use.extra_data and use.extra_data.xuanzhu_equip then
      local cards = player:getPile(self.name)
      if #cards > 0 then
        player.room:recastCard(cards, player)
      end
    else
      player.room:askForDiscard(player, 1, 1, true, self.name, false)
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  enabled_at_response = function(self, player, response)
    if not response and player:usedSkillTimes(self.name) == 0 and Fk.currentResponsePattern then
      local all_names = {}
      if player:getSwitchSkillState("xuanzhu", false) == fk.SwitchYang then
        all_names = U.getAllCardNames("b")
      else
        for _, id in ipairs(Fk:getAllCardIds()) do
          local card = Fk:getCardById(id)
          if card:isCommonTrick() and not (card.is_derived or card.multiple_targets or card.is_passive) then
            table.insertIfNeed(all_names, card.name)
          end
        end
      end
      return #U.getViewAsCardNames(player, "xuanzhu", all_names) > 0
    end
  end,
}
local jiane = fk.CreateTriggerSkill{
  name = "jiane",
  events = {fk.CardEffecting, fk.CardEffectCancelledOut},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.CardEffecting then
      return target and target ~= player and not target.dead and data.from == player.id and target:getMark("@@jiane_debuff-turn") == 0
    else
      if player:getMark("@@jiane_buff-turn") > 0 then return false end
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local is_from = false
      U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        if use.responseToEvent == data then
          if use.from == player.id then
            is_from = true
          end
          return true
        end
      end, use_event.id)
      return is_from
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardEffecting then
      room:notifySkillInvoked(player, self.name, "control")
      player:broadcastSkillInvoke(self.name)
      room:doIndicate(player.id, {target.id})
      room:setPlayerMark(target, "@@jiane_debuff-turn", 1)
    else
      room:notifySkillInvoked(player, self.name, "defensive")
      player:broadcastSkillInvoke(self.name)
      room:setPlayerMark(player, "@@jiane_buff-turn", 1)
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    data.unoffsetableList = data.unoffsetableList or {}
    for _, p in ipairs(player.room.alive_players) do
      if p:getMark("@@jiane_debuff-turn") > 0 then
        table.insert(data.unoffsetableList, p.id)
      end
    end
  end,
}
local jiane_prohibit = fk.CreateProhibitSkill{
  name = "#jiane_prohibit",
  is_prohibited = function(self, from, to, card)
    return to:getMark("@@jiane_buff-turn") > 0
  end,
}
jiane:addRelatedSkill(jiane_prohibit)
lukai:addSkill(xuanzhu)
lukai:addSkill(jiane)
Fk:loadTranslationTable{
  ["ol__lukai"] = "陆凯",
  ["#ol__lukai"] = "节概梗梗",

  ["xuanzhu"] = "玄注",
  [":xuanzhu"] = "转换技，每回合限一次，阳：你可以将一张牌移出游戏，视为使用任意基本牌；阴：你可以将一张牌移出游戏，视为使用仅指定唯一角色为目标的普通锦囊牌。"..
  "若移出游戏的牌：不为装备牌，你弃置一张牌；为装备牌，你重铸以此法移出游戏的牌。",
  ["jiane"] = "謇谔",
  [":jiane"] = "锁定技，当你使用的牌对其他角色生效后，你令其于当前回合内不能抵消牌；当一名角色使用的牌被你抵消后，你令你于当前回合内不是牌的合法目标。",

  ["@@jiane_buff-turn"] = "謇谔",
  ["@@jiane_debuff-turn"] = "謇谔",

  ["$xuanzhu1"] = "提笔注太玄，佐国定江山。",
  ["$xuanzhu2"] = "总太玄之要，纵弼国之实。",
  ["$jiane1"] = "臣者，未死于战，则死于谏。",
  ["$jiane2"] = "君有弊，坐视之辈甚于外贼。",
  ["~ol__lukai"] = "注经之人，终寄身于土……",
}

local caoyu = General(extension, "caoyu", "wei", 3)
local gongjie = fk.CreateTriggerSkill{
  name = "gongjie",
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player:isNude() then return false end
    local room = player.room
    local turn_event = room.logic:getCurrentEvent()
    if not turn_event then return false end
    local x = player:getMark("gongjie-turn")
    if x == 0 then
      room.logic:getEventsOfScope(GameEvent.Turn, 1, function (e)
        x = e.id
        room:setPlayerMark(player, "gongjie-turn", x)
        return true
      end, Player.HistoryRound)
    end
    return turn_event.id == x
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), function (p) return p.id end)
    local x = math.min(#player:getCardIds("he"), #targets)
    local tos = room:askForChoosePlayers(player, targets, 1, x, "#gongjie-choose:::" .. tostring(x), self.name, true)
    if #tos > 0 then
      room:sortPlayersByAction(tos)
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(self.cost_data)
    local to = nil
    local suits = {}
    local mark = U.getMark(player, "gongjie_targets")
    table.insertTableIfNeed(mark, targets)
    room:setPlayerMark(player, "gongjie_targets", mark)
    for _, pid in ipairs(targets) do
      if player.dead or player:isNude() then break end
      to = room:getPlayerById(pid)
      if not to.dead then
        local cid = room:askForCardChosen(to, player, "he", self.name)
        local suit = Fk:getCardById(cid).suit
        if suit ~= Card.NoSuit then
          table.insertIfNeed(suits, suit)
        end
        room:obtainCard(pid, cid, false, fk.ReasonPrey)
      end
    end
    if not player.dead and #suits > 0 then
      room:drawCards(player, #suits, self.name)
    end
  end,
}
local xiangxu = fk.CreateTriggerSkill{
  name = "xiangxu",
  events = {fk.AfterCardsMove, fk.TurnEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return end
    if event == fk.AfterCardsMove and player:getMark("@@xiangxu-turn") == 0 then
      local x = player:getHandcardNum()
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return table.every(player.room.alive_players, function (p)
                return p:getHandcardNum() >= x
              end)
            end
          end
        end
        if move.to == player.id and move.toArea == Card.PlayerHand then
          return table.every(player.room.alive_players, function (p)
            return p:getHandcardNum() >= x
          end)
        end
      end
    elseif event == fk.TurnEnd and player:getMark("@@xiangxu-turn") > 0 and not target.dead then
      local x, y = player:getHandcardNum(), target:getHandcardNum()
      return x > y or (x < y and x < 5)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      return true
    else
      local x, y = player:getHandcardNum(), target:getHandcardNum()
      if x > y then
        local n = x - y
        local prompt = "#xiangxu-discard:::"..tostring(n)
        if n > 1 then
          prompt = prompt .. ":" .. "xiangxu_recover"
        end
        local cards = player.room:askForDiscard(player, n, n, false, self.name, true, ".", prompt, true)
        if #cards > 0 then
          self.cost_data = cards
          return true
        end
      else
        local n = math.min(y, 5) - x
        if player.room:askForSkillInvoke(player, self.name, nil, "#xiangxu-draw:::"..tostring(n)) then
          self.cost_data = {}
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      player.room:setPlayerMark(player, "@@xiangxu-turn", 1)
    else
      local mark = U.getMark(player, "xiangxu_targets")
      if not table.contains(mark, target.id) then
        table.insert(mark, target.id)
      end
      local room = player.room
      room:setPlayerMark(player, "xiangxu_targets", mark)
      player:broadcastSkillInvoke(self.name)
      if #self.cost_data > 0 then
        room:notifySkillInvoked(player, self.name, "support")
        room:throwCard(self.cost_data, self.name, player, player)
        if #self.cost_data > 1 and not player.dead and player:isWounded() then
          room:recover{
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name,
          }
        end
      else
        room:notifySkillInvoked(player, self.name, "drawcard")
        local n = math.min(target:getHandcardNum(), 5) - player:getHandcardNum()
        player:drawCards(n, self.name)
      end
    end
  end,
}
local xiangzuo = fk.CreateTriggerSkill{
  name = "xiangzuo",
  anim_type = "support",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying and not player:isNude() and
    player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local gongjie_targets = U.getMark(player, "gongjie_targets")
    local xiangxu_targets = U.getMark(player, "xiangxu_targets")
    for _, p in ipairs(room.alive_players) do
      if table.contains(gongjie_targets, p.id) and table.contains(gongjie_targets, p.id) then
        room:setPlayerMark(p, "@@xiangzuo", 1)
      end
    end
    local tos, cards = U.askForChooseCardsAndPlayers(room, player, 1, 999,
    table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1, ".",
    "#xiangzuo-invoke", self.name, true, false)
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@@xiangzuo", 0)
    end
    if #tos > 0 and #cards > 0 then
      self.cost_data = {tos, cards}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1][1])
    local cards = table.simpleClone(self.cost_data[2])
    room:moveCardTo(cards, Player.Hand, to, fk.ReasonGive, self.name, nil, false, player.id)
    if not player.dead and player:isWounded() and table.contains(U.getMark(player, "gongjie_targets"), to.id) and
    table.contains(U.getMark(player, "xiangxu_targets"), to.id) then
      room:recover({
        who = player,
        num = #cards,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
caoyu:addSkill(gongjie)
caoyu:addSkill(xiangxu)
caoyu:addSkill(xiangzuo)
Fk:loadTranslationTable{
  ["caoyu"] = "曹宇",
  ["#caoyu"] = "大魏燕王",
  ["designer:caoyu"] = "廷玉",

  ["gongjie"] = "恭节",
  [":gongjie"] = "每轮的第一个回合开始后，你可以令任意名角色各获得你一张牌，然后你摸X张牌（X为被获得牌的花色数）。",
  ["xiangxu"] = "相胥",
  [":xiangxu"] = "当你得到/失去手牌后，若你是手牌数最小的角色，你于本回合结束时可以将手牌调整至与当前回合角色相同（至多摸至五张），"..
  "若你以此法弃置了至少两张牌，你回复1点体力。",
  ["xiangzuo"] = "襄胙",
  [":xiangzuo"] = "限定技，当你进入濒死状态时，你可以将任意张牌交给一名角色，若你对其发动过〖恭节〗和〖相胥〗，你回复等量体力。",

  ["#gongjie-choose"] = "你可以发动 恭节，令至多%arg名角色获得你的牌",
  ["@@xiangxu-turn"] = "相胥",
  ["#xiangxu-discard"] = "你可以发动 相胥，弃置%arg张手牌",
  ["xiangxu_recover"] = "，并回复1点体力",
  ["#xiangxu-draw"] = "你可以发动 相胥，摸%arg张牌",
  ["#xiangzuo-invoke"] = "你可以发动 襄胙，将任意张牌交给一名角色",
  ["@@xiangzuo"] = "可回复体力",

  ["$gongjie1"] = "身负浩然之气，当以恭节待人。",
  ["$gongjie2"] = "生于帝王之家，不可忘恭失节。",
  ["$xiangxu1"] = "今之大魏，非一家一姓之国。",
  ["$xiangxu2"] = "宇内同庆，奏凯歌于长垣。",
  ["$xiangzuo1"] = "怀济沧海之心，徒拔剑而茫然。",
  ["$xiangzuo2"] = "执三尺之青锋，卫大魏之宗庙。",
  ["~caoyu"] = "满园秋霜落，一人叹奈何……",
}

local liyi = General(extension, "liyi", "wu", 4)
local chanshuang = fk.CreateActiveSkill{
  name = "chanshuang",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#chanshuang-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local tos = {player, target}
    local all_choices = {"chanshuang_recast", "chanshuang_useslash", "chanshuang_discard"}
    for _, p in ipairs(tos) do
      local choices = {"chanshuang_useslash"}
      local cards = player:getCardIds("he")
      if #cards > 0 then
        table.insert(choices, "chanshuang_recast")
        if #table.filter(cards, function (id)
          return not p:prohibitDiscard(Fk:getCardById(id))
        end) > 1 then
          table.insert(choices, "chanshuang_discard")
        end
      end
      p.request_data = json.encode({choices, all_choices, self.name, "#chanshuang-choice"})
    end
    room:notifyMoveFocus(tos, self.name)
    room:doBroadcastRequest("AskForChoice", tos)
    local choice_map = {}
    for _, p in ipairs(tos) do
      choice_map[p.id] = p.reply_ready and p.client_reply or "chanshuang_useslash"
    end
    for _, p in ipairs(tos) do
      if not p.dead then
        local choice = choice_map[p.id]
        if choice == "chanshuang_recast" then
          if not p:isNude() then
            local card = room:askForCard(p, 1, 1, true, self.name, false, ".", "#chanshuang-card")
            room:recastCard(card, p)
          end
        elseif choice == "chanshuang_useslash" then
          local use = room:askForUseCard(p, "slash", "slash", "#chanshuang-useslash", true,
          {bypass_times = true})
          if use then
            use.extraUse = true
            room:useCard(use)
          end
        elseif choice == "chanshuang_discard" then
          room:askForDiscard(p, 2, 2, true, self.name, false, ".")
        end
      end
    end
  end,
}
local chanshuang_trigger = fk.CreateTriggerSkill{
  name = "#chanshuang_trigger",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Finish then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return false end
      local x = 0
      local use = nil
      U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
        use = e.data[1]
        if use.from == player.id and use.card.trueName == "slash" then
          x = 1
          return true
        end
      end, turn_event.id)
      local choices = {}
      U.getEventsByRule(room, GameEvent.MoveCards, 1, function (e)
        local a, b = 0, 0
        for _, move in ipairs(e.data) do
          if move.from == player.id then
            if move.moveReason == fk.ReasonRecast then
              a = a + #move.moveInfo
              --因为存在奇怪的重铸判定区牌/武将牌上的牌的技能，故不作来源区域的判定(¯―¯٥)
            elseif move.moveReason == fk.ReasonDiscard then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  b = b + 1
                end
              end
            end
          end
        end
        if a == 1 then
          table.insertIfNeed(choices, "a")
        end
        if b == 2 then
          table.insertIfNeed(choices, "b")
        end
        return #choices == 2
      end, turn_event.id)
      x = x + #choices
      if x > 0 then
        self.cost_data = x
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "chanshuang")
    player:broadcastSkillInvoke("chanshuang")
    local x = self.cost_data
    if not player:isNude() then
      local card = room:askForCard(player, 1, 1, true, "chanshuang", false, ".", "#chanshuang-card")
      room:recastCard(card, player)
      if player.dead then return false end
    end
    if x > 1 then
      local use = room:askForUseCard(player, "slash", "slash", "#chanshuang-useslash", true,
      {bypass_times = true})
      if use then
        use.extraUse = true
        room:useCard(use)
      end
      if player.dead then return false end
    end
    if x > 2 then
      room:askForDiscard(player, 2, 2, true, "chanshuang", false, ".")
    end
  end,
}
local zhanjin = fk.CreateTriggerSkill{
  name = "zhanjin",
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:getEquipment(Card.SubtypeWeapon) == nil and
    #player:getAvailableEquipSlots(Card.SubtypeWeapon) > 0 and data.from == player.id
    and data.card.trueName == "slash" and not player.room:getPlayerById(data.to).dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askForDiscard(player, 2, 2, true, self.name, true, ".", "#axe-invoke::"..data.to, true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, "axe", player, player)
    return true
    --FIXME：在这里return true其实是错误的做法
  end,
}
local zhanjin_attackrange = fk.CreateAttackRangeSkill{
  name = "#zhanjin_attackrange",
  fixed_func = function (self, from)
    if from:hasSkill(zhanjin) and from:getEquipment(Card.SubtypeWeapon) == nil and
    #from:getAvailableEquipSlots(Card.SubtypeWeapon) > 0 then
      return 3
    end
  end,
}
chanshuang:addRelatedSkill(chanshuang_trigger)
zhanjin:addRelatedSkill(zhanjin_attackrange)
liyi:addSkill(chanshuang)
liyi:addSkill(zhanjin)
Fk:loadTranslationTable{
  ["liyi"] = "李异",
  ["#liyi"] = "兼人之勇",
  --["illustrator:liyi"] = "",
  ["chanshuang"] = "缠双",
  [":chanshuang"] = "出牌阶段限一次，你可以与一名其他角色同时选择一项执行："..
  "1.重铸一张牌；2.使用一张【杀】；3.弃置两张牌。结束阶段，你依次执行上述前X项（X为你本回合以任意方式执行过的项数）。",
  ["zhanjin"] = "蘸金",
  [":zhanjin"] = "锁定技，若你的装备区里没有武器牌且你的武器栏未被废除，你视为装备着【贯石斧】。",

  ["#chanshuang-active"] = "发动 缠双，选择一名其他角色",
  ["#chanshuang-choice"] = "缠双：选择一项执行",
  ["chanshuang_recast"] = "重铸一张牌",
  ["chanshuang_useslash"] = "使用一张杀",
  ["chanshuang_discard"] = "弃置两张牌",
  ["#chanshuang-card"] = "缠双：选择一张牌重铸",
  ["#chanshuang-useslash"] = "缠双：你可以使用一张【杀】",
  ["#chanshuang_trigger"] = "缠双",

  ["$chanshuang1"] = "武艺精熟，勇冠三军。",
  ["$chanshuang2"] = "以一敌二，易如反掌。",
  ["$zhanjin1"] = "寒光纵横，血战八方！",
  ["$zhanjin2"] = "蘸金霜刃，力贯山河！",
  ["~liyi"] = "此人竟如此勇猛……",
}

local tianchou = General(extension, "tianchou", "qun", 4)
local shandao = fk.CreateActiveSkill{
  name = "shandao",
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  prompt = "#shandao-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.simpleClone(effect.tos)
    room:sortPlayersByAction(targets)
    local tos = {}
    for _, id in ipairs(targets) do
      local target = room:getPlayerById(id)
      table.insert(tos, target)
      if not (target.dead or target:isNude()) then
        local card = room:askForCardChosen(player, target, "he", self.name)
        room:moveCards({
          ids = {card},
          from = target.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = self.name,
        })
        if player.dead then return false end
      end
    end
    tos = table.filter(tos, function (p)
      return not p.dead
    end)
    room:useVirtualCard("amazing_grace", {}, player, tos, self.name)
    if player.dead then return false end
    local others = table.filter(room.alive_players, function (p)
      return not table.contains(targets, p.id) and p ~= player
    end)
    room:useVirtualCard("archery_attack", {}, player, others, self.name)
  end,
}
tianchou:addSkill(shandao)
Fk:loadTranslationTable{
  ["tianchou"] = "田畴",
  ["#tianchou"] = "乱世族隐",
  --["illustrator:tianchou"] = "",
  ["shandao"] = "善刀",
  [":shandao"] = "出牌阶段限一次，你可以将任意名角色的各一张牌置于牌堆顶，视为对这些角色使用一张【五谷丰登】，"..
  "然后视为对除这些角色外的其他角色使用一张【万箭齐发】。",
  ["#shandao-active"] = "发动 善刀，选择任意数量有牌的角色",

  ["$shandao1"] = "君子藏器，待天时而动。",
  ["$shandao2"] = "善刀而藏之，可解充栋之牛。",
  ["~tianchou"] = "吾罪大矣，何堪封侯之荣……",
}

local hujinding = General(extension, "ol__hujinding", "shu", 3, 3, General.Female)
local qingyuan = fk.CreateTriggerSkill{
  name = "qingyuan",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.Damaged, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove then
        if player:getMark("qingyuan-turn") > 0 then return false end
        local mark = U.getMark(player, "qingyuan_target")
        if #mark == 0 then return false end
        local room = player.room
        for _, move in ipairs(data) do
          if move.to and table.contains(mark, move.to) and move.toArea == Card.PlayerHand then
            local p = room:getPlayerById(move.to)
            if not p.dead then
              local targets = table.filter(mark, function (pid)
                p = room:getPlayerById(pid)
                return not (p.dead or p:isKongcheng())
              end)
              if #targets > 0 then
                self.cost_data = targets
                return true
              end
            end
          end
        end
      elseif event == fk.Damaged then
        local room = player.room
        local mark = player:getMark("qingyuan_damage")
        if mark == 0 then
          U.getActualDamageEvents(room, 1, function (e)
            local damage = e.data[1]
            if damage.to == player then
              mark = e.id
              room:setPlayerMark(player, "qingyuan_damage", mark)
              return true
            end
          end, Player.HistoryGame)
        end
        return room.logic:getCurrentEvent().id == mark
      elseif event == fk.GameStart then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      room:addPlayerMark(player, "qingyuan-turn")
      local to = table.random(self.cost_data)
      room:doIndicate(player.id, {to})
      local cards = room:getPlayerById(to):getCardIds{Player.Hand}
      if #cards == 0 then return false end
      room:obtainCard(player.id, table.random(cards), false, fk.ReasonPrey)
    else
      local mark = U.getMark(player, "qingyuan_target")
      local tos = table.map(table.filter(room.alive_players, function(p)
        return p ~= player and not table.contains(mark, p.id)
      end), Util.IdMapper)
      if #tos == 0 then return false end
      local tos = room:askForChoosePlayers(player, tos, 1, 1, "#qingyuan-choose", self.name, false)
      table.insert(mark, tos[1])
      room:setPlayerMark(player, "qingyuan_target", mark)
      room:setPlayerMark(room:getPlayerById(tos[1]), "@@qingyuan", 1)
    end
  end,

  refresh_events = {fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@@qingyuan") > 0 and table.every(player.room.alive_players, function(p)
      return not table.contains(U.getMark(p, "qingyuan_target"), player.id)
    end)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@qingyuan", 0)
  end,
}
local chongshen = fk.CreateViewAsSkill{
  name = "chongshen",
  anim_type = "defensive",
  prompt = "#chongshen-viewas",
  pattern = "jink",
  card_filter = function(self, to_select, selected)
    if #selected ~= 0 then return false end
    local card = Fk:getCardById(to_select)
    return card.color == Card.Red and card:getMark("@@chongshen-inhand-round") > 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("jink")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
}
local chongshen_record = fk.CreateTriggerSkill{
  name = "#chongshen_record",

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(chongshen, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            room:setCardMark(Fk:getCardById(id), "@@chongshen-inhand-round", 1)
          end
        end
      end
    end
  end,
}

chongshen:addRelatedSkill(chongshen_record)
hujinding:addSkill(qingyuan)
hujinding:addSkill(chongshen)

Fk:loadTranslationTable{
  ["ol__hujinding"] = "胡金定",
  ["#ol__hujinding"] = "怀子求怜",
  ["qingyuan"] = "轻缘",
  [":qingyuan"] = "锁定技，游戏开始时，你选择一名其他角色；当你首次受到伤害后，你再选择一名其他角色。"..
  "每回合限一次，当以此法选择的角色获得牌后，你获得其中随机一名角色的随机一张手牌。",
  ["chongshen"] = "重身",
  [":chongshen"] = "你可以将一张你于当前轮次内得到的红色牌当【闪】使用。",

  ["#qingyuan-choose"] = "轻缘：选择一名其他角色",
  ["@@qingyuan"] = "轻缘",
  ["#chongshen-viewas"] = "发动 重身，将一张本轮获得的红色牌当做【闪】使用",
  ["@@chongshen-inhand-round"] = "重身",

  ["$qingyuan1"] = "男儿重义气，自古轻别离。",
  ["$qingyuan2"] = "缘轻义重，倚东篱而叹长生。",
  ["$chongshen1"] = "妾死则矣，腹中稚婴何辜？",
  ["$chongshen2"] = "身怀六甲，君忘好生之德乎？",
  ["~ol__hujinding"] = "君无愧于天下，可有悔于妻儿？",
}

local guotu = General(extension, "guotu", "qun", 3)
local qushi = fk.CreateActiveSkill{
  name = "qushi",
  anim_type = "control",
  prompt = "#qushi-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:drawCards(player, 1, self.name)
    if player:isKongcheng() then return false end
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    if #targets == 0 then return false end
    local target, card = room:askForChooseCardAndPlayers(player, targets, 1, 1, ".|.|.|hand", "#qushi-choose", self.name, false)
    if #target > 0 and card then
      target = room:getPlayerById(target[1])
      local targetRecorded = U.getMark(target, "qushi_source")
      if not table.contains(targetRecorded, player.id) then
        table.insert(targetRecorded, player.id)
        room:setPlayerMark(target, "qushi_source", targetRecorded)
      end
      target:addToPile("qushi_pile", card, false, self.name, player.id, {})
    end
  end
}
local qushi_delay = fk.CreateTriggerSkill{
  name = "#qushi_delay",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Finish and
    #player:getPile("qushi_pile") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = U.getMark(player, "qushi_source")
    room:setPlayerMark(player, "qushi_source", 0)
    local cards = player:getPile("qushi_pile")
    local card_types = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(card_types, Fk:getCardById(id).type)
    end
    room:moveCards{
      from = player.id,
      ids = cards,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = "qushi",
      proposer = player.id,
    }
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if turn_event == nil then return false end
    local players = {}
    local cant_trigger = true
    --FIXME:可能需要根据放置此牌的角色单独判定类别，暂不作考虑
    U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
      local use = e.data[1]
      if use.from == player.id then
        if table.contains(card_types, use.card.type) then
          cant_trigger = false
        end
        table.insertTableIfNeed(players, TargetGroup:getRealTargets(use.tos))
      end
      return false
    end, turn_event.id)
    local n = math.min(#players, 5)
    if cant_trigger or n == 0 then return false end
    room:sortPlayersByAction(targets)
    for _, pid in ipairs(targets) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        p:drawCards(n, "qushi")
      end
    end
  end,
}
local weijie = fk.CreateViewAsSkill{
  name = "weijie",
  anim_type = "defensive",
  prompt = "#weijie-viewas",
  pattern = ".|.|.|.|.|basic",
  interaction = function()
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(Self, "weijie", all_names)
    if #names > 0 then
      return UI.ComboBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p ~= player and not p:isKongcheng() and player:distanceTo(p) == 1
    end)
    if #targets == 0 then return "" end
    local name = Fk:cloneCard(self.interaction.data).trueName
    targets = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
    "#weijie-choose:::" .. name, self.name, false)
    local target = room:getPlayerById(targets[1])
    local card = Fk:getCardById(room:askForCardChosen(player, target, "h", self.name))
    room:throwCard({card.id}, self.name, target, player)
    if card.trueName ~= name then return "" end
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    if player:usedSkillTimes(self.name) > 0 then return false end
    local a, b = false, false
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p ~= player then
        if p.phase ~= Player.NotActive then
          a = true
        end
        if not p:isKongcheng() and player:distanceTo(p) == 1 then
          b = true
        end
      end
    end
    return a and b
  end,
}
qushi:addRelatedSkill(qushi_delay)
guotu:addSkill(qushi)
guotu:addSkill(weijie)
Fk:loadTranslationTable{
  ["guotu"] = "郭图",
  ["#guotu"] = "凶臣",
  ["cv:guotu"] = "杨超然",

  ["qushi"] = "趋势",
  [":qushi"] = "出牌阶段限一次，你可以摸一张牌，然后将一张手牌扣置于一名其他角色的武将牌旁（称为“趋”）。"..
  "武将牌旁有“趋”的角色的结束阶段，其移去所有“趋”，若其于此回合内使用过与移去的“趋”类别相同的牌，"..
  "你摸X张牌（X为于本回合内成为过其使用的牌的目标的角色数且至多为5）。",
  ["weijie"] = "诿解",
  [":weijie"] = "当你于其他角色的回合内需要使用/打出基本牌时，若你于此回合内未发动过此技能，"..
  "你可以弃置距离为1的一名角色的一张牌，若此牌与你需要使用/打出的牌牌名相同，你视为使用/打出此牌名的牌。",

  ["#qushi-active"] = "发动 趋势，你可以摸一张牌，然后放置一张手牌作为“趋”",
  ["#qushi-choose"] = "趋势：选择作为“趋”的一张手牌以及一名其他角色",
  ["qushi_pile"] = "趋",
  ["#qushi_delay"] = "趋势",
  ["#weijie-viewas"] = "发动 诿解，视为使用或打出一张基本牌",
  ["#weijie-choose"] = "诿解：弃置与你距离为1的一名角色的一张牌，若此牌为【%arg】，视为你使用或打出之",

  ["$qushi1"] = "将军天人之姿，可令四海归心。",
  ["$qushi2"] = "小小锦上之花，难表一腔敬意。",
  ["$weijie1"] = "败战之罪在你，休要多言！",
  ["$weijie2"] = "纵汝舌灿莲花，亦难逃死罪。",
  ["~guotu"] = "工于心计而不成事，匹夫怀其罪……",
}

local liupan = General(extension, "liupan", "qun", 4)
local pijingl = fk.CreateTriggerSkill{
  name = "pijingl",
  anim_type = "offensive",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
    data.card.color == Card.Black and (data.card.trueName == "slash" or data.card:isCommonTrick()) and data.firstTarget and
    U.isOnlyTarget(player.room:getPlayerById(data.to), data, event) then
      local targets = U.getUseExtraTargets(player.room, data, false, true)
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = math.max(1, player:getLostHp())
    local tos = room:askForChoosePlayers(player, self.cost_data, 1, x,
    "#pijingl-choose:::" .. tostring(x) .. ":"..data.card:toLogString(), self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = table.simpleClone(self.cost_data)
    room:sortPlayersByAction(tos)
    local mark = U.getMark(player, "pijingl")
    table.insertTableIfNeed(mark, tos)
    room:setPlayerMark(player, "pijingl", mark)
    local to
    tos = table.map(tos, function (pid)
      AimGroup:addTargets(room, data, pid)
      to = room:getPlayerById(pid)
      room:setPlayerMark(to, "@@pijingl", 1)
      return to
    end)
    for _, p in ipairs(tos) do
      if not (p.dead or p:isNude()) then
        local cards = room:askForCard(p, 1, 1, true, self.name, false, ".", "#pijingl-give:"..player.id)
        room:obtainCard(player, cards[1], false, fk.ReasonGive, p.id)
        if player.dead then break end
      end
    end
  end,

  refresh_events = {fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    return player == target
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      local mark = U.getMark(p, "pijingl")
      if table.removeOne(mark, player.id) then
        room:setPlayerMark(p, "pijingl", #mark > 0 and mark or 0)
      end
      if p:getMark("@@pijingl") > 0 and table.every(room.alive_players, function (p2)
        return not table.contains(U.getMark(p2, "pijingl"), p.id)
      end) then
        room:setPlayerMark(p, "@@pijingl", 0)
      end
    end
  end,
}
local pijingl_delay = fk.CreateTriggerSkill{
  name = "#pijingl_delay",
  events = {fk.TargetSpecifying},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and not target.dead and table.contains(U.getMark(player, "pijingl"), target.id) and
    (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and data.firstTarget and
    U.isOnlyTarget(player.room:getPlayerById(data.to), data, event)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "pijingl")
    table.removeOne(mark, target.id)
    room:setPlayerMark(player, "pijingl", mark)
    if table.every(room.alive_players, function (p)
      return not table.contains(U.getMark(p, "pijingl"), target.id)
    end) then
      room:setPlayerMark(target, "@@pijingl", 0)
    end
    local choices = {"draw1", "Cancel"}
    if table.contains(U.getUseExtraTargets(room, data, true, true), player.id) then
      table.insert(choices, "pijingl_target")
    end
    local choice = room:askForChoice(target, choices, "", "#pijingl-choice::" .. player.id .. ":" .. data.card:toLogString(),
    false, {"draw1", "pijingl_target", "Cancel"})
    if choice == "draw1" then
      room:drawCards(target, 1, self.name)
    elseif choice == "pijingl_target" then
      room:doIndicate(target.id, {player.id})
      AimGroup:addTargets(room, data, player.id)
    end
  end,
}
pijingl:addRelatedSkill(pijingl_delay)
liupan:addSkill(pijingl)

Fk:loadTranslationTable{
  ["liupan"] = "刘磐",
  ["#liupan"] = "骁隽悍勇",

  ["pijingl"] = "披荆",
  [":pijingl"] = "当你使用黑色【杀】或黑色普通锦囊牌指定唯一目标时，若你于当前回合内未发动过此技能，"..
  "你可以令至多X名角色也成为此牌的目标（X为你已损失的体力值且至少为1），这些角色各将一张牌交给你。"..
  "这些角色下次使用基本牌或普通锦囊牌指定唯一目标时，其可以选择：1.令你也成为此牌的目标；2.摸一张牌。",
  ["#pijingl-choose"] = "是否发动 披荆，选择至多%arg名角色交给你一张牌且也成为%arg的目标",
  ["#pijingl-give"] = "披荆：选择一张牌交给%src",
  ["@@pijingl"] = "披荆",
  ["#pijingl_delay"] = "披荆",
  ["#pijingl-choice"] = "披荆：你可以摸一张牌，或令%dest也成为%arg的目标",
  ["pijingl_target"] = "增加目标",
}
Fk:addPoxiMethod{
  name = "yichengl",
  card_filter = function(to_select, selected, data)
    return table.contains(data[2], to_select)
  end,
  feasible = function(selected)
    return true
  end,
}
local liupi = General(extension, "ol__liupi", "qun", 4)
local yichengl = fk.CreateActiveSkill{
  name = "yichengl",
  prompt = function()
    return "#yichengl-active:::" .. tostring(Self.maxHp)
  end,
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cards = room:getNCards(player.maxHp)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      proposer = player.id,
    })
    local n = 0
    for _, id in ipairs(cards) do
      n = n + Fk:getCardById(id).number
    end
    local cardmap = U.askForArrangeCards(player, self.name,
    {cards, player:getCardIds(Player.Hand), "Top", "$Hand"}, "#yichengl-exchange:::" .. tostring(n), false)
    local topile = table.filter(cardmap[1], function (id)
      return not table.contains(cards, id)
    end)
    if #topile > 0 then
      room:moveCardTo(topile, Card.Processing, nil, fk.ReasonPut, self.name, "", true, player.id)
      topile = table.filter(cards, function (id)
        return not table.contains(cardmap[1], id)
      end)
      if player.dead then
        room:moveCardTo(topile, Card.DiscardPile, nil, fk.ReasonJustMove, self.name, "", true)
      else
        room:moveCardTo(topile, Card.PlayerHand, player, fk.ReasonJustMove, self.name, "", true, player.id)
        if not player.dead then
          for _, id in ipairs(cardmap[1]) do
            n = n - Fk:getCardById(id).number
          end
          if n < 0 then
            local handcards = player:getCardIds(Player.Hand)
            local top = U.askForArrangeCards(player, self.name,
            {cardmap[1], handcards, "Top", "$Hand"}, "#yichengl-exchange2", false, nil, nil, nil, "", "yichengl")[2]
            if #top > 0 then
              top = table.reverse(top)
              room:moveCards({
                ids = top,
                from = player.id,
                toArea = Card.DrawPile,
                moveReason = fk.ReasonPut,
                skillName = self.name,
                proposer = player.id,
                moveVisible = true,
              })
              if player.dead then
                room:moveCardTo(cardmap[1], Card.DiscardPile, nil, fk.ReasonJustMove, self.name, "", true)
              else
                room:moveCardTo(cardmap[1], Card.PlayerHand, player, fk.ReasonJustMove, self.name, "", true, player.id)
              end
              return
            end
          end
        end
      end
    end
    local top = cardmap[1]
    room:sendLog{
      type = "#PutKnownCardtoDrawPile",
      from = player.id,
      card = top
    }
    top = table.reverse(top)
    room:moveCards({
      ids = top,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = self.name,
      proposer = player.id,
      moveVisible = true,
    })
  end
}
liupi:addSkill(yichengl)
Fk:loadTranslationTable{
  ["ol__liupi"] = "刘辟",
  ["#ol__liupi"] = "易城报君",

  ["yichengl"] = "易城",
  [":yichengl"] = "出牌阶段限一次，你可以展示牌堆顶X张牌（X为你的体力上限），然后可以用任意张手牌交换其中等量张，"..
  "若展示牌点数之和因此增加，你可以用所有手牌交换展示牌。",
  ["#yichengl-active"] = "发动 易城，展示牌堆顶%arg张牌，并可以用手牌交换其中的牌",
  ["#yichengl-exchange"] = "易城：你可以用任意张手牌替换等量的牌堆顶牌，点数和超过%arg可全部交换",
  ["#yichengl-exchange2"] = "易城：你可以用所有手牌交换展示的牌，请排列手牌在牌堆顶的位置",
}

local sunce = General(extension, "ol_sp__sunce", "qun", 4)
local liantao = fk.CreateTriggerSkill{
  name = "liantao",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1,
    "#liantao-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    local choice = room:askForChoice(to, {"red", "black"}, self.name, "#liantao-choice:"..player.id)
    local duel = Fk:cloneCard("duel")
    duel.skillName = self.name
    local cards
    local id
    local draw3 = true
    local event_id = room.logic.current_event_id
    local events
    local breakloop = false
    local damage
    local x = 0
    while true do
      cards = table.filter(player:getCardIds(Player.Hand), function(id)
        duel.subcards = {}
        duel:addSubcard(id)
        return duel:getColorString() == choice and player:canUseTo(duel, to)
      end)
      if #cards == 0 then break end
      id = room:askForCard(player, 1, 1, false, self.name, false, tostring(Exppattern{ id = cards }),
      "#liantao-duel::" .. to.id .. ":" .. choice)[1]
      local use = {
        from = player.id,
        tos = { { to.id } },
        card = Fk:cloneCard("duel")
      }
      use.card.skillName = self.name
      use.card:addSubcard(id)
      room:useCard(use)
      if use.damageDealt then
        draw3 = false
      end
      if player.dead then return false end
      events = room.logic.event_recorder[GameEvent.Damage] or Util.DummyTable
      for i = #events, 1, -1 do
        local e = events[i]
        if e.id <= event_id then break end
        damage = e.data[1]
        if damage.dealtRecorderId and damage.from == player and damage.card == use.card then
          x = x + damage.damage
        end
      end
      if target.dead then break end
      events = room.logic.event_recorder[GameEvent.Dying] or Util.DummyTable
      for i = #events, 1, -1 do
        local e = events[i]
        if e.id <= event_id then break end
        if e.data[1].who == player.id or e.data[1].who == to.id then
          breakloop = true
          break
        end
      end
      if breakloop then break end
      event_id = room.logic.current_event_id
    end
    if draw3 then
      room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 3)
      room:setPlayerMark(player, "liantao_prohibit-turn", 1)
      room:drawCards(player, 3, self.name)
    elseif x > 0 then
      room:drawCards(player, x, self.name)
    end
  end,
}
local liantao_prohibit = fk.CreateProhibitSkill{
  name = "#liantao_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("liantao_prohibit-turn") > 0 and card.trueName == "slash"
  end,
}
liantao:addRelatedSkill(liantao_prohibit)
sunce:addSkill(liantao)
Fk:loadTranslationTable{
  ["ol_sp__sunce"] = "孙策",
  ["#ol_sp__sunce"] = "壮武命世",

  ["liantao"] = "连讨",
  [":liantao"] = "出牌阶段开始时，你可以令一名其他角色选择一种颜色，然后你依次将此颜色的手牌当【决斗】对其使用直到你或其进入濒死状态，"..
  "然后你摸X张牌（X为你以此法造成过的伤害值）。若没有角色以此法受到过伤害，你摸三张牌，于此回合内手牌上限+3且不能使用【杀】。",
  ["#liantao-choose"] = "是否发动 连讨，选择一名其他角色",
  ["#liantao-choice"] = "连讨：选择%from即将对你使用【决斗】的颜色",
  ["#liantao-duel"] = "连讨：选择一张%arg手牌当【决斗】对%dest使用",

  ["$liantao1"] = "沙场百战疾，争衡天下间。",
  ["$liantao2"] = "征战无休，决胜千里。",
  ["~ol_sp__sunce"] = "身受百创，力难从心……",
}


return extension
