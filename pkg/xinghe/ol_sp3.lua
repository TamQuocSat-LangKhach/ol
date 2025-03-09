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
  handly_pile = true,
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
              local use = room:askForUseRealCard(to, {cardId}, "huiyun", "#huiyun1-card:::"..name)
              if use then
                room:delay(300)
                if not to.dead and not to:isKongcheng() then
                  room:recastCard(to:getCardIds("h"), to, "huiyun")
                end
              end
            end
          elseif choice == "huiyun2-round" then
            local use = room:askForUseRealCard(to, to:getCardIds("h"), "huiyun", "#huiyun2-card:::"..name)
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
  ["designer:ol__huban"] = "CYC",
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

local macheng = General(extension, "macheng", "shu", 4)
local chenglie = fk.CreateTriggerSkill{
  name = "chenglie",
  anim_type = "control",
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and
      #player.room:getUseExtraTargets(data) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, room:getUseExtraTargets(data), 1, 2,
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

      room:getPlayerById(dat.targets[1]):addToPile("$chenglie", dat.cards, false, self.name, player.id, player.id)

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
    return Self:getTableMark("chenglie_cards")
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and table.contains(Self:getTableMark("chenglie_cards"), to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and table.contains(Self:getTableMark("chenglie_targets"), to_select)
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
              room:obtainCard(player.id, card[1], false, fk.ReasonGive, to.id, "chenglie")
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
        return p and p:getPileNameOfId(id) == "$chenglie"
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
  ["designer:macheng"] = "CYC",
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
  ["$chenglie"] = "骋烈",

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
      local targets, targetRecorded = {}, player:getTableMark("qiejian_prohibit-round")
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
      if not table.contains(player:getTableMark("qiejian_prohibit-round"), target_id) then
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
      room:addTableMarkIfNeed(player, "qiejian_prohibit-round", target.id)
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
    room:swapAllCards(player, {player, tos[1]}, nishou.name)
  end,
}
nishou:addRelatedSkill(nishou_delay)
quhuang:addSkill(qiejian)
quhuang:addSkill(nishou)
Fk:loadTranslationTable{
  ["quhuang"] = "屈晃",
  ["#quhuang"] = "泥头自缚",
  ["illustrator:quhuang"] = "夜小雨",
  ["designer:quhuang"] = "玄蝶既白",

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
      room:obtainCard(to, data.card, true, fk.ReasonJustMove, player.id, self.name)
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
    local mark = player:getTableMark("chuanwu")
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
    local skills = player:getTableMark("chuanwu")
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
  ["cv:zhanghua"] = "苏至豪",

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
        room.logic:getActualDamageEvents(1, function (e)
          if e.data[1].to == target then
            x = e.id
            room:setPlayerMark(target, "kangrui_record-turn", x)
            return true
          end
          return false
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
  handly_pile = true,
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
    local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
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
  after_use = function (self, player, use)
    if not player.dead then
      if use.damageDealt then
        local n = 0
        for _, p in ipairs(player.room.players) do
          if use.damageDealt[p.id] then
            n = n + use.damageDealt[p.id]
          end
        end
        if #use.card.subcards > n then
          player:drawCards(1, self.name)
        end
      else
        player:drawCards(1, self.name)
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    return player:hasSkill(self) and not response
  end,
}
maxiumatie:addSkill("mashu")
maxiumatie:addSkill(kenshang)
Fk:loadTranslationTable{
  ["maxiumatie"] = "马休马铁",
  ["#maxiumatie"] = "颉翥三秦",
  ["illustrator:maxiumatie"] = "alien",
  ["kenshang"] = "垦伤",
  [":kenshang"] = "你可以将至少两张牌当【杀】使用，然后目标可以改为等量的角色。你以此法使用的【杀】结算后，若这些牌数大于此牌造成的伤害，你摸一张牌。",
  ["#kenshang-choose"] = "垦伤：你可以将目标改为指定%arg名角色",
  ["#kenshang_delay"] = "垦伤",

  ["$kenshang1"] = "择兵选将，一击而大白。",
  ["$kenshang2"] = "纵横三辅，垦伤庸富。",
  ["~maxiumatie"] = "我兄弟，愿随父帅赴死。",
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
  handly_pile = true,
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
  enabled_at_play = Util.TrueFunc,
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
      room:invalidateSkill(player, "miuyan", "-round")
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
  ["designer:wangguan"] = "zzcclll朱苦力",
  ["illustrator:wangguan"] = "匠人绘",

  ["miuyan"] = "谬焰",
  [":miuyan"] = "转换技，阳：你可以将一张黑色牌当【火攻】使用，若此牌造成伤害，你获得本阶段展示过的所有手牌；"..
  "阴：你可以将一张黑色牌当【火攻】使用，若此牌未造成伤害，本轮本技能失效。",
  ["shilu"] = "失路",
  [":shilu"] = "锁定技，当你受到伤害后，你摸等同体力值张牌并展示攻击范围内一名其他角色的一张手牌，令此牌视为【杀】。",

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
    local mark = player:getTableMark("@$daili")
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
    local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
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
    local cards = room:askForCardsChosen(player, to, n, n, "he", self.name)
    room:obtainCard(player.id, cards, false, fk.ReasonPrey, player.id, self.name)
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
  ["designer:sunhong"] = "zzcclll朱苦力",
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

local haopu = General(extension, "haopu", "shu", 4)
local zhenying = fk.CreateActiveSkill{
  name = "zhenying",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#zhenying",
  times = function(self)
    return Self.phase == Player.Play and 2 - Self:usedSkillTimes(self.name, Player.HistoryPhase) or -1
  end,
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
      cardsMap[p.id] = table.filter(p:getCardIds("h"), function(id)
        return not p:prohibitDiscard(Fk:getCardById(id))
      end)
    end
    local result = U.askForJointChoice(tos, {"0", "1", "2"}, self.name, "#zhenying-choice")
    local discard_num_map = {}
    for _, p in ipairs(tos) do
      discard_num_map[p.id] = p:getHandcardNum() - tonumber(result[p.id])
    end
    -- local toAsk = {}
    local req = Request:new(tos, "AskForUseActiveSkill")
    for _, p in ipairs(tos) do
      local num = math.min(discard_num_map[p.id], #cardsMap[p.id])
      if num > 0 then
        -- table.insert(toAsk, p)
        local extra_data = {
          num = num,
          min_num = num,
          include_equip = false,
          skillName = self.name,
          pattern = ".",
          reason = self.name,
        }
        -- p.request_data = json.encode({ "discard_skill", "#AskForDiscard:::"..num..":"..num, false, extra_data })
        req:setData(p, { "discard_skill", "#AskForDiscard:::"..num..":"..num, false, extra_data })
        req:setDefaultReply(p, table.random(cardsMap[p.id], discard_num_map[p.id]))
      end
    end
    req.players = table.filter(req.players, function(p) return req.data[p.id] ~= nil end)
    if #req.players > 0 then
      local moveInfos = {}
      req.focus_text = self.name
      -- room:notifyMoveFocus(tos, self.name)
      -- room:doBroadcastRequest("AskForUseActiveSkill", toAsk)
      for _, p in ipairs(req.players) do
        local throw = req:getResult(p)
        if throw.card then
          throw = throw.card.subcards
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
        self.cost_data = {choice = choice}
        return true
      elseif choice == "goude2" then
        local targets = table.map(table.filter(room.alive_players, function(pl)
          return not pl:isKongcheng() end), Util.IdMapper)
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#goude-choose", self.name, true)
        if #to > 0 then
          self.cost_data = {choice = choice, tos = to}
          return true
        end
      elseif choice == "goude3" then
        local use = U.askForUseVirtualCard(room, player, "slash", nil, self.name, "#goude-slash", true, true, false, true, nil, true)
        if use then
          self.cost_data = {choice = choice, extra_data = use}
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data.choice == "draw1" then
      player:drawCards(1, self.name)
    elseif self.cost_data.choice == "goude2" then
      local to = room:getPlayerById(self.cost_data.tos[1])
      local id = room:askForCardChosen(player, to, "h", self.name)
      room:throwCard({id}, self.name, to, player)
    elseif self.cost_data.choice == "goude3" then
      room:useCard(self.cost_data.extra_data)
    elseif self.cost_data.choice == "goude4" then
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

  ["$goude1"] = "蝼蚁尚且偷生，况我大将军乎。",
  ["$goude2"] = "为保身家性命，做奔臣又如何？",
  ["~ol__mengda"] = "丞相援军何其远乎？",
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
    local use = room:askForUseRealCard(player, ids, "saogu", "#saogu-use", {
      expand_pile = ids,
      bypass_times = true,
      extraUse = true,
    }, true, true)
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
    #Self:getTableMark("@[suits]saogu-phase") < 4
  end,
  card_filter = function(self, to_select, selected)
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang and #selected < 2 then
      local card = Fk:getCardById(to_select)
      return card.suit ~= Card.NoSuit and
      not (table.contains(Self:getTableMark("@[suits]saogu-phase"), card.suit) or Self:prohibitDiscard(card))
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
        for _, suit in ipairs(player:getTableMark("@[suits]saogu-phase")) do
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
      local mark = player:getTableMark("@[suits]saogu-phase")
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
      room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
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
Fk:addQmlMark{
  name = "gangshu",
  qml_path = "",
  how_to_show = function(name, value, p)
    local card = Fk:cloneCard("slash")
    local x1 = ""
    if p:getAttackRange() > 499 then
      --FIXME:暂无无限攻击范围机制
      x1 = "∞"
    else
      x1 = tostring(p:getAttackRange())
    end
    local x2 = tostring(p:getMark("gangshu2_fix")+2)
    local x3 = ""
    if gangshuTimesCheck(p, card) then
      x3 = "∞"
    else
      x3 = tostring(card.skill:getMaxUseTime(p, Player.HistoryPhase, card, nil) or "∞")
    end
    return x1 .. " " .. x2 .. " " .. x3
  end,
}
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
        return not gangshuTimesCheck(player, card) and (card.skill:getMaxUseTime(player, Player.HistoryPhase, card, nil) or 5) < 5
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
      if not gangshuTimesCheck(player, card) and (card.skill:getMaxUseTime(player, Player.HistoryPhase, card, nil) or 5) < 5 then
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
    elseif event == fk.CardEffecting then
      room:notifySkillInvoked(player, self.name, "negative")
      room:setPlayerMark(player, "gangshu1_fix", 0)
      room:setPlayerMark(player, "gangshu2_fix", 0)
      room:setPlayerMark(player, "gangshu3_fix", 0)
    elseif event == fk.DrawNCards then
      room:notifySkillInvoked(player, self.name, "drawcard")
      data.n = data.n + player:getMark("gangshu2_fix")
      room:setPlayerMark(player, "gangshu2_fix", 0)
    end
  end,

  on_acquire = function (self, player)
    player.room:setPlayerMark(player, "@[gangshu]", 1)
  end,
  on_lose = function (self, player)
    local room = player.room
    room:setPlayerMark(player, "@[gangshu]", 0)
    room:setPlayerMark(player, "gangshu1_fix", 0)
    room:setPlayerMark(player, "gangshu2_fix", 0)
    room:setPlayerMark(player, "gangshu3_fix", 0)
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
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), Util.IdMapper),
      1, 1, "#jianxuan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
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
  ["@[gangshu]"] = "刚述",
  ["#jianxuan-choose"] = "谏旋：你可以令一名角色摸一张牌",

  ["$gangshu1"] = "羲而立之年，当为立身之事。",
  ["$gangshu2"] = "总六军之要，秉选举之机。",
  ["$jianxuan1"] = "司马氏卧虎藏龙，大兄安能小觑。",
  ["$jianxuan2"] = "兄长以兽为猎，殊不知己亦为猎乎？",
  ["~caoxi"] = "曹氏亡矣，大魏亡矣！",
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
    if data.tos and (data.card:isCommonTrick() or data.card.type == Card.TypeBasic) and #room:getUseExtraTargets(data, true) > 0 then
      local tos = room:askForChoosePlayers(player, room:getUseExtraTargets(data, true), 1, n,
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
  ["designer:ol__qianzhao"] = "玄蝶既白",
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
        local card = Fk:getCardById(id, true)
        if card:isCommonTrick() and not (card.is_derived or card.multiple_targets or card.is_passive) then
          table.insertIfNeed(all_names, card.name)
        end
      end
    end
    local names = U.getViewAsCardNames(Self, "xuanzhu", all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
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
      if data.from == player.id then
        local tos = TargetGroup:getRealTargets(data.tos)
        return table.find(player.room.alive_players, function (p)
          return p ~= player and p:getMark("@@jiane_debuff-turn") == 0 and table.contains(tos, p.id)
        end)
      end
    else
      if player:getMark("@@jiane_buff-turn") > 0 then return false end
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local is_from = false
      room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
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
      local tos = TargetGroup:getRealTargets(data.tos)
      local tos2 = {}
      for _, p in ipairs(room.alive_players) do
        if p ~= player and p:getMark("@@jiane_debuff-turn") == 0 and table.contains(tos, p.id) then
          room:setPlayerMark(p, "@@jiane_debuff-turn", 1)
          table.insert(tos2, p.id)
        end
      end
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return false end
      room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        table.insertTableIfNeed(e.data[1].unoffsetableList, tos2)
        return false
      end, turn_event.id)
    else
      room:notifySkillInvoked(player, self.name, "defensive")
      player:broadcastSkillInvoke(self.name)
      room:setPlayerMark(player, "@@jiane_buff-turn", 1)
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = Util.TrueFunc,
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
  ["illustrator:ol__lukai"] = "空山MBYK",
  ["designer:ol__lukai"] = "扬林",

  ["xuanzhu"] = "玄注",
  [":xuanzhu"] = "转换技，每回合限一次，阳：你可以将一张牌移出游戏，视为使用任意基本牌；"..
  "阴：你可以将一张牌移出游戏，视为使用仅指定唯一角色为目标的普通锦囊牌。"..
  "若移出游戏的牌：不为装备牌，你弃置一张牌；为装备牌，你重铸以此法移出游戏的牌。",
  ["jiane"] = "謇谔",
  [":jiane"] = "锁定技，当你使用的牌对一名角色生效后，你令所有是此牌的目标的其他角色于当前回合内不能抵消牌；"..
  "当一名角色使用的牌被你抵消后，你令你于当前回合内不是牌的合法目标。",

  ["@@jiane_buff-turn"] = "謇谔",
  ["@@jiane_debuff-turn"] = "謇谔",

  ["$xuanzhu1"] = "提笔注太玄，佐国定江山。",
  ["$xuanzhu2"] = "总太玄之要，纵弼国之实。",
  ["$jiane1"] = "臣者，未死于战，则死于谏。",
  ["$jiane2"] = "君有弊，坐视之辈甚于外贼。",
  ["~ol__lukai"] = "注经之人，终寄身于土……",
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
      local targetRecorded = target:getTableMark("qushi_source")
      if not table.contains(targetRecorded, player.id) then
        table.insert(targetRecorded, player.id)
        room:setPlayerMark(target, "qushi_source", targetRecorded)
      end
      target:addToPile("$qushi_pile", card, false, self.name, player.id, {})
    end
  end
}
local qushi_delay = fk.CreateTriggerSkill{
  name = "#qushi_delay",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Finish and
    #player:getPile("$qushi_pile") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getTableMark("qushi_source")
    room:setPlayerMark(player, "qushi_source", 0)
    local cards = player:getPile("$qushi_pile")
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
    room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
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
local qushi_visibility = fk.CreateVisibilitySkill{
  name = "#qushi_visibility",
  card_visible = function(self, player, card)
    if player:getPileNameOfId(card.id) == "$qushi_pile" then
      return false
    end
  end
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
      return U.CardNameBox { choices = names, all_choices = all_names }
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
      return p ~= player and not p:isNude() and player:distanceTo(p) == 1
    end)
    if #targets == 0 then return "" end
    local name = Fk:cloneCard(self.interaction.data).trueName
    targets = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
    "#weijie-choose:::" .. name, self.name, false)
    local target = room:getPlayerById(targets[1])
    local card = Fk:getCardById(room:askForCardChosen(player, target, "he", self.name))
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
qushi:addRelatedSkill(qushi_visibility)
guotu:addSkill(qushi)
guotu:addSkill(weijie)
Fk:loadTranslationTable{
  ["guotu"] = "郭图",
  ["#guotu"] = "凶臣",
  ["illustrator:guotu"] = "厦门塔普",
  ["cv:guotu"] = "杨超然",

  ["qushi"] = "趋势",
  [":qushi"] = "出牌阶段限一次，你可以摸一张牌，然后将一张手牌扣置于一名其他角色的武将牌旁（称为“趋”）。"..
  "武将牌旁有“趋”的角色的结束阶段，其移去所有“趋”，若其于此回合内使用过与移去的“趋”类别相同的牌，"..
  "你摸X张牌（X为于本回合内成为过其使用的牌的目标的角色数且至多为5）。",
  ["weijie"] = "诿解",
  [":weijie"] = "每回合限一次，当你于其他角色的回合内需要使用/打出基本牌时，你可以弃置距离为1的一名角色的一张牌，"..
  "若此牌与你需要使用/打出的牌牌名相同，你视为使用/打出此牌名的牌。",

  ["#qushi-active"] = "发动 趋势，你可以摸一张牌，然后放置一张手牌作为“趋”",
  ["#qushi-choose"] = "趋势：选择作为“趋”的一张手牌以及一名其他角色",
  ["$qushi_pile"] = "趋",
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
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
    (data.card.trueName == "slash" or data.card:isCommonTrick()) and data.firstTarget
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = math.max(1, player:getLostHp())
    local current_targets = AimGroup:getAllTargets(data.tos)
    local targets = room:getUseExtraTargets(data, false, true)
    table.insertTable(targets, current_targets)
    for i = #targets, 1, -1 do
      if targets[i] == player.id then
        table.remove(targets, i)
      end
    end
    local tos = room:askForChoosePlayers(player, targets, 1, x,
    "#pijingl-choose:::" .. tostring(x) .. ":"..data.card:toLogString(), self.name, true, false, "addandcanceltarget_tip", current_targets)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = table.simpleClone(self.cost_data)
    room:sortPlayersByAction(tos)
    local mark = player:getTableMark("pijingl")
    table.insertTableIfNeed(mark, tos)
    room:setPlayerMark(player, "pijingl", mark)
    local current_targets = AimGroup:getAllTargets(data.tos)
    local to
    tos = table.map(tos, function (pid)
      if table.contains(current_targets, pid) then
        AimGroup:cancelTarget(data, pid)
      else
        AimGroup:addTargets(room, data, pid)
      end
      to = room:getPlayerById(pid)
      room:setPlayerMark(to, "@@pijingl", 1)
      return to
    end)
    for _, p in ipairs(tos) do
      if not (p.dead or p:isNude()) then
        room:obtainCard(player, table.random(p:getCardIds("he")), false, fk.ReasonGive, p.id)
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
      local mark = p:getTableMark("pijingl")
      if table.removeOne(mark, player.id) then
        room:setPlayerMark(p, "pijingl", #mark > 0 and mark or 0)
      end
      if p:getMark("@@pijingl") > 0 and table.every(room.alive_players, function (p2)
        return not table.contains(p2:getTableMark("pijingl"), p.id)
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
    return not player.dead and not target.dead and table.contains(player:getTableMark("pijingl"), target.id) and
    (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and data.firstTarget and
    U.isOnlyTarget(player.room:getPlayerById(data.to), data, event)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removeTableMark(player, "pijingl", target.id)
    if table.every(room.alive_players, function (p)
      return not table.contains(p:getTableMark("pijingl"), target.id)
    end) then
      room:setPlayerMark(target, "@@pijingl", 0)
    end
    local choices = {"draw1", "Cancel"}
    if table.contains(room:getUseExtraTargets(data, false, true), player.id) then
      table.insert(choices, "pijingl_target")
    end
    local choice = room:askForChoice(target, choices, "pijingl", "#pijingl-choice::" .. player.id .. ":" .. data.card:toLogString(),
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
  ["pijingl"] = "披荆",
  [":pijingl"] = "每回合限一次，当你使用【杀】或普通锦囊牌指定第一个目标时，"..
  "你可以令任意名其他角色也成为此牌的目标并取消任意名其他目标角色合计至多X名角色（X为你已损失的体力值且至少为1），"..
  "这些角色各随机将一张牌交给你，且下次使用基本牌或普通锦囊牌指定唯一目标时，其可以选择：1.令你也成为此牌的目标；2.摸一张牌。",

  ["#pijingl-choose"] = "是否发动 披荆，选择至多%arg名角色随机交给你一张牌且也成为/取消成为%arg2的目标",
  ["#pijingl-give"] = "披荆：选择一张牌交给%src",
  ["@@pijingl"] = "披荆",
  ["#pijingl-choice"] = "披荆：你可以摸一张牌，或令%dest也成为%arg的目标",
  ["pijingl_target"] = "增加目标",

  ["$pijingl1"] = "今青锋在手，必破敌军于域外。",
  ["$pijingl2"] = "荆楚多锦绣，安能丧于小儿之手！",
}

local caimao = General(extension, "caimao", "wei", 4)
local zuolian = fk.CreateActiveSkill{
  name = "zuolian",
  anim_type = "support",
  card_num = 0,
  min_target_num = 1,
  prompt = function()
    return "#zuolian-active:::" .. Self.hp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected < Self.hp and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    local showMap = {}
    for _, pid in ipairs(effect.tos) do
      local p = room:getPlayerById(pid)
      if not (p.dead or p:isKongcheng()) then
        local id = table.random(p:getCardIds(Player.Hand))
        p:showCards(id)
        table.insert(showMap, {pid, id})
      end
    end
    if not room:askForSkillInvoke(player, self.name, nil, "#zuolian-exchange") then return end
    for _, value in ipairs(showMap) do
      local p = room:getPlayerById(value[1])
      local id = value[2]
      if not p.dead and table.contains(p:getCardIds(Player.Hand), id) then
        local area_name = "Top"
        local slashs = room:getCardsFromPileByRule(".|.|.|.|fire__slash", 1, "discardPile")
        if #slashs == 0 then
          slashs = room:getCardsFromPileByRule(".|.|.|.|fire__slash")
          if #slashs == 0 then
            slashs = room:getCardsFromPileByRule(".|.|.|.|thunder__slash", 1, "discardPile")
            if #slashs == 0 then
              slashs = room:getCardsFromPileByRule(".|.|.|.|thunder__slash")
              if #slashs == 0 then
                break
              end
            else
              area_name = "discardPile"
            end
          end
        else
          area_name = "discardPile"
        end
        room:swapCardsWithPile(p, {id}, slashs, self.name, area_name, true, player.id)
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["zuolian"] = "佐练",
  [":zuolian"] = "出牌阶段限一次，你可以选择至多X名有手牌的角色（X为你的体力值），这些角色各随机展示一张手牌，"..
  "你可以令这些角色各将展示的牌与弃牌堆或牌堆中的火【杀】或雷【杀】交换。",

  ["#zuolian-active"] = "发动 佐练，选择至多%arg名有手牌的角色",
  ["#zuolian-exchange"] = "佐练：是否将展示的牌与火【杀】或雷【杀】交换（优先检索火【杀】）",

  ["$zuolian1"] = "有我操练水军，曹公大可放心！",
  ["$zuolian2"] = "好！儿郎们很有精神！",
}

local peixiu = General(extension, "ol__peixiu", "wei", 4)
Fk:loadTranslationTable{
  ["ol__peixiu"] = "裴秀",
  ["#ol__peixiu"] = "勋德茂著",
  ["~ol__peixiu"] = "",
}

local maozhuo = fk.CreateTriggerSkill{
  name = "maozhuo",
  events = {fk.DamageCaused},
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return
    player == target and
    player:hasSkill(self) and
    player.phase == Player.Play and
    player:usedSkillTimes(self.name) == 0 and
    player:getMark("maozhuo_record-turn") == 0 and
    #table.filter(player.player_skills, function(skill) return skill:isPlayerSkill(player) end) >
      #table.filter(data.to.player_skills, function(skill) return skill:isPlayerSkill(data.to) end) and
    #player.room.logic:getActualDamageEvents(
      1,
      function(e)
        if e.data[1].from == player then
          player.room:setPlayerMark(player, "maozhuo_record-turn", 1)
          return true
        end
        return false
      end,
      Player.HistoryPhase
    ) == 0
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local maozhuoTargetMod = fk.CreateTargetModSkill{
  name = "#maozhuo_targetmod",
  frequency = Skill.Compulsory,
  residue_func = function(self, player, skill, scope)
    if player:hasSkill(maozhuo) and skill.trueName == "slash_skill" then
      return
        #table.filter(
          player.player_skills,
          function(skill) return skill:isPlayerSkill(player) and skill.visible end
        )
    end
  end,
}
local maozhuoMaxCards = fk.CreateMaxCardsSkill{
  name = "#maozhuo_maxcards",
  frequency = Skill.Compulsory,
  correct_func = function(self, player)
    if player:hasSkill(maozhuo) then
      return
        #table.filter(
          player.player_skills,
          function(skill) return skill:isPlayerSkill(player) and skill.visible end
        )
    end
  end,
}
Fk:loadTranslationTable{
  ["maozhuo"] = "茂著",
  [":maozhuo"] = "锁定技，你使用【杀】的次数上限和手牌上限+X（X为你的技能数）；当你于出牌阶段内首次造成伤害时，" ..
  "若受伤角色的技能数少于你，则此伤害+1。",
}

maozhuo:addRelatedSkill(maozhuoTargetMod)
maozhuo:addRelatedSkill(maozhuoMaxCards)
peixiu:addSkill(maozhuo)

local jinlan = fk.CreateActiveSkill{
  name = "jinlan",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  prompt = function()
    local mostSkillNum = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      local skillNum = #table.filter(
        p.player_skills,
        function(skill) return skill:isPlayerSkill(p) and skill.visible end
      )
      if skillNum > mostSkillNum then
        mostSkillNum = skillNum
      end
    end
    return "#jinlan:::" .. mostSkillNum
  end,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 then
      return false
    end

    local mostSkillNum = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      local skillNum = #table.filter(
        p.player_skills,
        function(skill) return skill:isPlayerSkill(p) and skill.visible end
      )
      if skillNum > mostSkillNum then
        mostSkillNum = skillNum
      end
    end
    return player:getHandcardNum() < mostSkillNum
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)

    local mostSkillNum = 0
    for _, p in ipairs(room.alive_players) do
      local skillNum = #table.filter(p.player_skills, function(skill) return skill:isPlayerSkill(p) end)
      if skillNum > mostSkillNum then
        mostSkillNum = skillNum
      end
    end
    player:drawCards(mostSkillNum - player:getHandcardNum(), self.name)
  end,
}
Fk:loadTranslationTable{
  ["jinlan"] = "尽览",
  [":jinlan"] = "出牌阶段限一次，你可以将手牌摸至X张（X为存活角色中技能最多角色的技能数）。",
  ["#jinlan"] = "尽览：你可将手牌摸至%arg张",
}

peixiu:addSkill(jinlan)

local jiangwan = General(extension, "ol__jiangwan", "shu", 3)
Fk:loadTranslationTable{
  ["ol__jiangwan"] = "蒋琬",
  ["#ol__jiangwan"] = "社稷之器",
  ["illustrator:ol__jiangwan"] = "错落宇宙",
  ["designer:ol__jiangwan"] = "玄蝶即白",
  ["~ol__jiangwan"] = "臣既暗弱，加婴疾疢，规方无成……",
}
