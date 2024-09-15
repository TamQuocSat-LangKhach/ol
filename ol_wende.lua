local extension = Package("ol_wende")
extension.extensionName = "ol"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_wende"] = "OL-文德武备",
  ["jin"] = "晋",
}

Fk:appendKingdomMap("god", {"jin"})

local simayi = General(extension, "ol__simayi", "jin", 3)
local buchen = fk.CreateTriggerSkill{
  name = "buchen",
  events = {"fk.GeneralAppeared"},
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasShownSkill(self) then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      local to = turn_event.data[1]
      if to ~= player and not to.dead and not to:isNude() then
        self.cost_data = to
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#buchen-invoke:"..self.cost_data.id)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {self.cost_data.id})
    local id = room:askForCardChosen(player, self.cost_data, "he", self.name)
    room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
  end,
}
buchen.isHiddenSkill = true
local yingshis = fk.CreateActiveSkill{
  name = "yingshis",
  frequency = Skill.Compulsory,  --锁定主动技（
  card_num = 999,
  target_num = 0,
  expand_pile = function() return Self:getTableMark("yingshis") end,
  card_filter = function (self, to_select)
    return table.contains(Self:getTableMark("yingshis"), to_select)
  end,
  can_use = Util.TrueFunc,
}
local yingshis_trigger = fk.CreateTriggerSkill{
  name = "#yingshis_trigger",
  refresh_events = {fk.StartPlayCard},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(yingshis)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local ids = {}
    for i = 1, player.maxHp, 1 do
      if i > #room.draw_pile then break end
      table.insert(ids, room.draw_pile[i])
    end
    player.room:setPlayerMark(player, "yingshis", ids)
  end,
}
yingshis:addRelatedSkill(yingshis_trigger)
local xiongzhi = fk.CreateActiveSkill{
  name = "xiongzhi",
  anim_type = "offensive",
  frequency = Skill.Limited,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 0,
  prompt = "#xiongzhi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    while not player.dead do
      local cards = room:getNCards(1)
      player:showCards(cards)
      if not U.askForUseRealCard(room, player, cards, ".", self.name, "#xiongzhi-use:::"..Fk:getCardById(cards[1]):toLogString(), {expand_pile = cards, bypass_times = false, extraUse = false}) then
        table.insert(room.draw_pile, 1, cards[1])
        break
      end
    end
  end,
}
local xiongzhi_viewas = fk.CreateViewAsSkill{
  name = "xiongzhi_viewas",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:getCardById(Self:getMark("xiongzhi-tmp")[1])
    if Self:canUse(card) and not Self:prohibitUse(card) then
      return card
    end
  end,
}
local quanbian = fk.CreateTriggerSkill{
  name = "quanbian",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play and data.card.suit ~= Card.NoSuit and
      U.IsUsingHandcard(player, data) then
      local card_suit = data.card.suit
      local room = player.room
      local logic = room.logic
      local current_event = logic:getCurrentEvent()
      local mark_name = "quanbian_" .. data.card:getSuitString() .. "-phase"
      local mark = player:getMark(mark_name)
      if mark == 0 then
        logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data[1]
          if use.from == player.id and use.card.suit == card_suit then
            mark = e.id
            room:setPlayerMark(player, mark_name, mark)
            return true
          end
          return false
        end, Player.HistoryPhase)
        logic:getEventsOfScope(GameEvent.RespondCard, 1, function (e)
          local use = e.data[1]
          if use.from == player.id and use.card.suit == card_suit then
            mark = math.max(e.id, mark)
            room:setPlayerMark(player, mark_name, mark)
            return true
          end
          return false
        end, Player.HistoryPhase)
      end
      return mark == current_event.id
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local mark = player:getMark("@quanbian-phase")
    if mark == 0 then mark = {} end
    table.insert(mark, data.card:getSuitString(true))
    player.room:setPlayerMark(player, "@quanbian-phase", mark)
    self:doCost(event, target, player, data)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_cards = room:getNCards(player.maxHp)
    local suits = {"spade", "club", "heart", "diamond"}
    table.remove(suits, data.card.suit)
    local cardmap = room:askForArrangeCards(player, self.name, {all_cards, "Top", "toObtain"}, "", true, 0,
    {#all_cards, 1}, {0, 0}, ".|.|"..table.concat(suits, ","))
    for i = #cardmap[1], 1, -1 do
      table.insert(room.draw_pile, 1, cardmap[1][i])
    end
    if #cardmap[2] > 0 then
      room:obtainCard(player, cardmap[2][1], false, fk.ReasonPrey)
    end
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.card.type ~= Card.TypeEquip and
      U.IsUsingHandcard(player, data)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "quanbian-phase", 1)
  end,
}
local quanbian_prohibit = fk.CreateProhibitSkill{
  name = "#quanbian_prohibit",
  prohibit_use = function(self, player, card)
    if player:hasSkill(quanbian) and player.phase == Player.Play and player:getMark("quanbian-phase") >= player.maxHp
    and card and card.type ~= Card.TypeEquip then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
}
quanbian:addRelatedSkill(quanbian_prohibit)
Fk:addSkill(xiongzhi_viewas)
simayi:addSkill(buchen)
simayi:addSkill(yingshis)
simayi:addSkill(xiongzhi)
simayi:addSkill(quanbian)
Fk:loadTranslationTable{
  ["ol__simayi"] = "司马懿",
  ["#ol__simayi"] = "通权达变",
  ["illustrator:ol__simayi"] = "六道目",
  ["buchen"] = "不臣",
  [":buchen"] = "隐匿。你于其他角色的回合登场后，你可获得其一张牌。",
  ["yingshis"] = "鹰视",
  [":yingshis"] = "锁定技，牌堆顶的X张牌于你出牌阶段空闲时对你可见（X为你的体力上限）。",
  ["xiongzhi"] = "雄志",
  [":xiongzhi"] = "限定技，出牌阶段，你可展示牌堆顶牌并使用之。你可重复此流程直到牌堆顶牌不能被使用。",
  ["quanbian"] = "权变",
  [":quanbian"] = "当你于出牌阶段首次使用或打出一种花色的手牌时，你可从牌堆顶X张牌中获得一张与此牌花色不同的牌，将其余牌以任意顺序置于牌堆顶。"..
  "出牌阶段，你至多使用X张非装备手牌。（X为你的体力上限）",
  ["#yingshis_trigger"] = "鹰视",
  ["#xiongzhi"] = "雄志：你可以重复展示牌堆顶牌并使用之(有次数限制)",
  ["xiongzhi_viewas"] = "雄志",
  ["#xiongzhi-use"] = "雄志：是否使用%arg？",
  ["@quanbian-phase"] = "权变",
  ["#quanbian-get"] = "权变：获得一张花色不同的牌",
  ["#buchen-invoke"] = "不臣:你可获得 %src 一张牌",

  ["$buchen1"] = "螟蛉之光，安敢同日月争辉？",
  ["$buchen2"] = "巍巍隐帝，岂可为臣？",
  ["$yingshis1"] = "鹰扬千里，明察秋毫。",
  ["$yingshis2"] = "鸢飞戾天，目入百川。",
  ["$xiongzhi1"] = "烈士雄心，志存高远。",
  ["$xiongzhi2"] = "乱世之中，唯我司马！",
  ["$quanbian1"] = "筹权谋变，步步为营。",
  ["$quanbian2"] = "随机应变，谋国窃权。",
  ["~ol__simayi"] = "虎入骷冢，司马难兴。",
}

local zhangchunhua = General(extension, "ol__zhangchunhua", "jin", 3, 3, General.Female)
local xuanmu = fk.CreateTriggerSkill{
  name = "xuanmu",
  mute = true,
  events = {"fk.GeneralAppeared"},
  frequency = Skill.Compulsory,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasShownSkill(self) and player.phase == Player.NotActive
  end,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@xuanmu-turn", 1)
  end,
}
xuanmu.isHiddenSkill = true
local xuanmu_delay = fk.CreateTriggerSkill{
  name = "#xuanmu_delay",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@@xuanmu-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:broadcastSkillInvoke("xuanmu")
    return true
  end,
}
xuanmu:addRelatedSkill(xuanmu_delay)
local ol__huishi = fk.CreateTriggerSkill{
  name = "ol__huishi",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw and #player.room.draw_pile % 10 > 1
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ol__huishi-invoke:::"..#player.room.draw_pile % 10)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = #room.draw_pile % 10
    if x == 0 then return true end
    local card_ids = room:getNCards(x)
    local y = x // 2
    local rusult = room:askForGuanxing(player, card_ids, {x-y, x}, {y, y}, self.name, true, {"Bottom", "toObtain"})
    for i = #rusult.top, 1, -1 do
      table.insert(room.draw_pile, rusult.top[i])
    end
    room:moveCardTo(rusult.bottom, Player.Hand, player, fk.ReasonPrey, self.name, "", false, player.id)
    return true
  end,
}
local qingleng = fk.CreateTriggerSkill{
  name = "qingleng",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Finish and
      ((#target.player_cards[Player.Hand] + target.hp) >= #player.room.draw_pile % 10) and
      not player:isNude() and not player:isProhibited(target, Fk:cloneCard("ice__slash"))
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForCard(player, 1, 1, true, self.name, true, ".", "#qingleng-invoke::"..target.id)
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:useVirtualCard("ice__slash", {self.cost_data}, player, target, self.name, true)
    if target:getMark(self.name) == 0 then
      if not player.dead then
        player:drawCards(1, self.name)
      end
      if not target.dead then
        room:addPlayerMark(target, self.name, 1)
      end
    end
  end,
}
zhangchunhua:addSkill(xuanmu)
zhangchunhua:addSkill(ol__huishi)
zhangchunhua:addSkill(qingleng)
Fk:loadTranslationTable{
  ["ol__zhangchunhua"] = "张春华",
  ["#ol__zhangchunhua"] = "宣穆皇后",
  ["illustrator:ol__zhangchunhua"] = "六道目",
  ["xuanmu"] = "宣穆",
  [":xuanmu"] = "隐匿。锁定技，你于其他角色的回合登场时，防止你受到的伤害直到回合结束。",
  ["ol__huishi"] = "慧识",
  [":ol__huishi"] = "摸牌阶段，你可以放弃摸牌，改为观看牌堆顶的X张牌，获得其中的一半（向下取整），然后将其余牌置入牌堆底。（X为牌堆数量的个位数）",
  ["qingleng"] = "清冷",
  [":qingleng"] = "其他角色回合结束时，若其体力值与手牌数之和不小于X，你可将一张牌当无距离限制的冰【杀】对其使用。"..
  "你对一名没有成为过〖清冷〗目标的角色发动〖清冷〗时，摸一张牌。（X为牌堆数量的个位数）",
  ["#ol__huishi-invoke"] = "慧识：你可以放弃摸牌，改为观看牌堆顶%arg张牌并获得其中的一半，其余置于牌堆底",
  ["#qingleng-invoke"] = "清冷：你可以将一张牌当冰【杀】对 %dest 使用",
  ["#xuanmu_delay"] = "宣穆",
  ["@@xuanmu-turn"] = "宣穆",

  ["$xuanmu1"] = "四门穆穆，八面莹澈。",
  ["$xuanmu2"] = "天色澄穆，心明清静。",
  ["$ol__huishi1"] = "你的想法，我已知晓。",
  ["$ol__huishi2"] = "妾身慧眼，已看透太多。",
  ["$qingleng1"] = "冷冷清清，寂落沉沉。",
  ["$qingleng2"] = "冷月葬情，深雪埋伤。",
  ["~ol__zhangchunhua"] = "冷眸残情，孤苦为一人。",
}

local lisu = General(extension, "ol__lisu", "qun", 3)
local qiaoyan = fk.CreateTriggerSkill{
  name = "qiaoyan",
  anim_type = "defensive",
  derived_piles = "ol__lisu_zhu",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.NotActive and
      data.from and data.from ~= player and not data.from.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player:getPile("ol__lisu_zhu") == 0 then
      player:drawCards(1, self.name)
      if player:isNude() or player.dead then return end
      local card = room:askForCard(player, 1, 1, true, self.name, false, ".", "#qiaoyan-card")
      player:addToPile("ol__lisu_zhu", card[1], true, self.name)
      return true
    else
      room:obtainCard(data.from.id, player:getPile("ol__lisu_zhu")[1], true, fk.ReasonPrey)
    end
  end,
}
local ol__xianzhu = fk.CreateTriggerSkill{
  name = "ol__xianzhu",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and #player:getPile("ol__lisu_zhu") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1,
      "#ol__xianzhu-choose:::"..Fk:getCardById(player:getPile("ol__lisu_zhu")[1]):toLogString(), self.name, false)
    local to = room:getPlayerById(tos[1])
    room:obtainCard(to.id, player:getPile("ol__lisu_zhu")[1], false, fk.ReasonPrey)
    if to == player or player.dead or #room.alive_players < 3 then return end
    local targets = table.filter(room:getOtherPlayers(to), function(p)
      return player:inMyAttackRange(p) and not to:isProhibited(p, Fk:cloneCard("slash")) 
    end)
    if #targets == 0 then return end
    local victim = #targets == 1 and targets[1] or room:getPlayerById(room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#ol__xianzhu-slash::"..to.id, self.name, false)[1])
    room:useVirtualCard("slash", nil, to, victim, self.name, true)
  end,
}
lisu:addSkill(qiaoyan)
lisu:addSkill(ol__xianzhu)
Fk:loadTranslationTable{
  ["ol__lisu"] = "李肃",
  ["#ol__lisu"] = "巧言令色",
  ["illustrator:ol__lisu"] = "君桓文化",
  ["qiaoyan"] = "巧言",
  [":qiaoyan"] = "锁定技，在你的回合外，当其他角色对你造成伤害时，若你：没有“珠”，你防止此伤害并摸一张牌，然后将一张牌置于你的武将牌上，称为“珠”；"..
  "有“珠”，其获得“珠”。",
  ["ol__xianzhu"] = "献珠",
  [":ol__xianzhu"] = "锁定技，出牌阶段开始时，你令一名角色获得“珠”；若不为你，其视为对你攻击范围内你指定的一名角色使用一张【杀】。",
  ["ol__lisu_zhu"] = "珠",
  ["#qiaoyan-card"] = "巧言：将一张牌置为“珠”",
  ["#ol__xianzhu-choose"] = "献珠：令一名角色获得“珠”（%arg）",
  ["#ol__xianzhu-slash"] = "献珠：选择你攻击范围内一名角色，视为 %dest 对其使用【杀】",

  ["$qiaoyan1"] = "此事不宜迟，在于速决。",
  ["$qiaoyan2"] = "公若到彼，贵不可言。",
  ["$ol__xianzhu1"] = "馈珠之恩，望将军莫忘。",
  ["$ol__xianzhu2"] = "愿以珠为礼，与卿交好，而休刀兵。",
  ["~ol__lisu"] = "忘恩负义之徒！",
}

local simazhou = General(extension, "simazhou", "jin", 4)
local caiwang = fk.CreateViewAsSkill{
  name = "caiwang",
  anim_type = "control",
  pattern = "jink,nullification,slash",
  prompt = function()
    if Fk.currentResponsePattern == nil then
      return "#caiwang-slash"
    else
      if Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("jink")) and Self:getHandcardNum() == 1 then
        return "#caiwang-jink"
      elseif Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("nullification")) and #Self:getCardIds("e") == 1 then
        return "#caiwang-nullification"
      elseif Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("slash")) and #Self:getCardIds("j") == 1 then
        return "#caiwang-slash"
      end
    end
  end,
  interaction = function()
    local names = {}
    if Fk.currentResponsePattern == nil then
      local card = Fk:cloneCard("slash")
      if #Self:getCardIds("j") == 1 and Self:canUse(card) and not Self:prohibitUse(card) then
        table.insertIfNeed(names, "slash")
      end
    elseif Fk.currentResponsePattern then
      if Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("jink")) then  --FIXME：奇正相生
        if Self:getHandcardNum() == 1 then
          table.insertIfNeed(names, "jink")
        end
      end
      if Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("nullification")) then
        if #Self:getCardIds("e") == 1 then
          table.insertIfNeed(names, "nullification")
        end
      end
      if Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("slash")) then
        if #Self:getCardIds("j") == 1 then
          table.insertIfNeed(names, "slash")
        end
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    if self.interaction.data == "jink" then
      card:addSubcard(Self.player_cards[Player.Hand][1])
    elseif self.interaction.data == "nullification" then
      card:addSubcard(Self.player_cards[Player.Equip][1])
    elseif self.interaction.data == "slash" then
      card:addSubcard(Self.player_cards[Player.Judge][1])
    end
    if #card.subcards ~= 1 then return end
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return #player.player_cards[Player.Judge] == 1
  end,
  enabled_at_response = function(self, player, response)
    if Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(self.pattern) then
      if Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("nullification")) then
        return #player.player_cards[Player.Equip] == 1
      elseif Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("jink")) then
        return player:getHandcardNum() == 1
      else
        return #player.player_cards[Player.Judge] == 1
      end
    end
  end,
}
local caiwang_trigger = fk.CreateTriggerSkill{
  name = "#caiwang_trigger",
  mute = true,
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.responseToEvent then
      if (event == fk.CardUseFinished and data.toCard and data.toCard.color == data.card.color) or
        (event == fk.CardRespondFinished and data.responseToEvent.card and data.responseToEvent.card.color == data.card.color) then
        local to
        if data.responseToEvent.from == player.id then
          to = target.id
        elseif target == player then
          to = data.responseToEvent.from
        end
        return to and to ~= player.id and not player.room:getPlayerById(to):isNude()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#caiwang-discard"
    local to
    if data.responseToEvent.from == player.id then
      to = target.id
    elseif target == player then
      to = data.responseToEvent.from
    end
    if player:getMark("naxiang") ~= 0 and table.contains(player:getMark("naxiang"), to) then
      prompt = "#caiwang-prey"
    end
    if player.room:askForSkillInvoke(player, "caiwang", nil, prompt.."::"..to) then
      self.cost_data = {to, prompt}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("caiwang")
    room:notifySkillInvoked(player, "caiwang", "control")
    local to = room:getPlayerById(self.cost_data[1])
    room:doIndicate(player.id, {to.id})
    local id = room:askForCardChosen(player, to, "he", "caiwang")
    if self.cost_data[2][10] == "d" then
      room:throwCard({id}, "caiwang", to, player)
    else
      room:obtainCard(player, id, false, fk.ReasonPrey)
    end
  end,
}
local naxiang = fk.CreateTriggerSkill{
  name = "naxiang",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and data.from ~= data.to and not (data.from.dead or data.to.dead)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local p = data.to
    if event == fk.Damaged then
      p = data.from
    end
    room:setPlayerMark(p, "@@naxiang", 1)
    local mark = player:getMark(self.name)
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, p.id)
    room:setPlayerMark(player, self.name, mark)
  end,

  refresh_events = {fk.TurnStart, fk.EventLoseSkill, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:getMark(self.name) ~= 0 then
      if event == fk.EventLoseSkill then
        return data == self
      else
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getMark(self.name)) do
      local p = room:getPlayerById(id)
      if not p.dead and not table.find(room:getOtherPlayers(player), function(to)
        return to:getMark(self.name) ~= 0 and table.contains(to:getMark(self.name), p.id) end) then
        room:setPlayerMark(p, "@@naxiang", 0)
      end
    end
    room:setPlayerMark(player, self.name, 0)
  end,
}
caiwang:addRelatedSkill(caiwang_trigger)
simazhou:addSkill(caiwang)
simazhou:addSkill(naxiang)
Fk:loadTranslationTable{
  ["simazhou"] = "司马伷",
  ["#simazhou"] = "琅琊武王",
  ["illustrator:simazhou"] = "凝聚永恒",
  ["caiwang"] = "才望",
  [":caiwang"] = "当你使用/打出牌响应其他角色使用的牌后，或其他角色使用/打出牌响应你使用的牌后，若两张牌颜色相同，你可以弃置其一张牌。<br>"..
  "你可以将最后一张手牌当【闪】使用或打出；将最后一张你装备区里的牌当【无懈可击】使用；将最后一张你判定区的牌当【杀】使用或打出。",
  ["naxiang"] = "纳降",
  [":naxiang"] = "锁定技，当其他角色对你造成伤害或受到你的伤害后，你对其发动〖才望〗的“弃置”修改为“获得”直到你的回合开始。",
  ["#caiwang-discard"] = "才望：你可以弃置 %dest 一张牌",
  ["#caiwang-prey"] = "才望：你可以获得 %dest 一张牌",
  ["#caiwang-jink"] = "才望：你可以将最后一张手牌当【闪】使用或打出",
  ["#caiwang-nullification"] = "才望：你可以将最后一张装备当【无懈可击】使用",
  ["#caiwang-slash"] = "才望：你可以将最后一张判定区内的牌当【杀】使用或打出",
  ["@@naxiang"] = "纳降",

  ["$caiwang1"] = "才气不俗，声望四海。",
  ["$caiwang2"] = "绥怀之称，监守邺城。",
  ["$naxiang1"] = "奉命伐吴，得胜纳降。",
  ["$naxiang2"] = "进军逼江，震慑吴贼。",
  ["~simazhou"] = "恩赐重物，病身难消受……",
}

local cheliji = General(extension, "cheliji", "qun", 4)
local chexuan_cart = {{"wheel_cart", Card.Spade, 5}, {"caltrop_cart", Card.Club, 5}, {"grain_cart", Card.Heart, 5}}
local chexuan = fk.CreateActiveSkill{
  name = "chexuan",
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
    and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_num = 0,
  can_use = function(self, player)
    return not player:isNude() and #player:getEquipments(Card.SubtypeTreasure) == 0 and
    player:hasEmptyEquipSlot(Card.SubtypeTreasure)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead or not player:hasEmptyEquipSlot(Card.SubtypeTreasure) then return end
    local carts = table.filter(U.prepareDeriveCards(room, chexuan_cart, "chexuan_derivecards"), function (id)
      return room:getCardArea(id) == Card.Void
    end)
    if #carts == 0 then return end
    room:setPlayerMark(player, "chexuan_cards", carts)
    local success, dat = room:askForUseActiveSkill(player, "chexuan_select", "#chexuan-put", false, Util.DummyTable, true)
    room:setPlayerMark(player, "chexuan_cards", 0)
    local cardId = success and dat.cards[1] or table.random(carts)
    room:setCardMark(Fk:getCardById(cardId), MarkEnum.DestructOutMyEquip, 1)
    U.moveCardIntoEquip(room, player, cardId, self.name, true, player)
  end,
}
local chexuan_select = fk.CreateActiveSkill{
  name = "chexuan_select",
  card_num = 1,
  target_num = 0,
  expand_pile = function (self)
    return Self:getTableMark("chexuan_cards")
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and table.contains(Self:getTableMark("chexuan_cards"), to_select)
  end,
}
Fk:addSkill(chexuan_select)
local chexuan_trigger = fk.CreateTriggerSkill{
  name = "#chexuan_trigger",
  mute = true,
  main_skill = chexuan,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:hasEmptyEquipSlot(Card.SubtypeTreasure) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId).sub_type == Card.SubtypeTreasure then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, chexuan.name, nil, "#chexuan-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, chexuan.name)
    player:broadcastSkillInvoke(chexuan.name)
    local judge = {  who = player, reason = chexuan.name, pattern = ".|.|spade,club" }
    room:judge(judge)
    if judge.card.color == Card.Black and not player.dead and player:hasEmptyEquipSlot(Card.SubtypeTreasure) then
      local carts = table.filter(U.prepareDeriveCards(room, chexuan_cart, "chexuan_derivecards"), function (id)
        return room:getCardArea(id) == Card.Void
      end)
      if #carts > 0 then
        local put = table.random(carts)
        room:setCardMark(Fk:getCardById(put), MarkEnum.DestructOutMyEquip, 1)
        U.moveCardIntoEquip(room, player, put, chexuan.name, true, player)
      end
    end
  end,
}
chexuan:addRelatedSkill(chexuan_trigger)
cheliji:addSkill(chexuan)
local qiangshou = fk.CreateDistanceSkill{
  name = "qiangshou",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    if from:hasSkill(self) and #from:getEquipments(Card.SubtypeTreasure) > 0 then
      return -1
    end
  end,
}
cheliji:addSkill(qiangshou)
Fk:loadTranslationTable{
  ["cheliji"] = "彻里吉",
  ["#cheliji"] = "高凉铁骨",
  ["illustrator:cheliji"] = "YanBai",
  ["chexuan"] = "车悬",
  [":chexuan"] = "①出牌阶段，若你的装备区里没有宝物牌，你可以弃置一张黑色牌，选择一张“舆”置入你的装备区（此牌离开装备区时销毁）。②当你不因使用装备牌失去装备区里的宝物牌后，你可以判定，若结果为黑色，将一张随机的“舆”置入你的装备区。",
  ["#chexuan_trigger"] = "车悬",
  ["chexuan_select"] = "车悬",
  ["#chexuan-put"] = "车悬：选择一种“舆”置入你的装备区",
  ["#chexuan-invoke"] = "车悬：你可以判定，若结果为黑色，将一张随机的“舆”置入你的装备区",
  ["qiangshou"] = "羌首",
  [":qiangshou"] = "锁定技，若你的装备区里有宝物牌，你至其他角色的距离-1。",

  ["$chexuan1"] = "兵车疾动，以悬敌首！",
  ["$chexuan2"] = "层层布设，以多胜强！",
  ["~cheliji"] = "元气已伤，不如归去……",
}

local huaxin = General(extension, "ol__huaxin", "wei", 3)
local ol__caozhao = fk.CreateActiveSkill{
  name = "ol__caozhao",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#ol__caozhao-invoke",
  interaction = function()
    local names = {}
    local mark = Self:getMark("@$ol__caozhao")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if (card.type == Card.TypeBasic or card:isCommonTrick()) and not card.is_derived then
        if mark == 0 or (not table.contains(mark, card.trueName)) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    return UI.ComboBox {choices = names}
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and self.interaction.data and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and self.interaction.data and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select).hp <= Self.hp
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:sendLog{
      type = "#ol__caozhao",
      from = player.id,
      arg = self.interaction.data,
    }
    local mark = player:getMark("@$ol__caozhao")
    if mark == 0 then mark = {} end
    table.insert(mark, Fk:cloneCard(self.interaction.data).trueName)
    room:setPlayerMark(player, "@$ol__caozhao", mark)
    player:showCards(effect.cards)
    if player.dead then return end
    local id = effect.cards[1]
    local choice = room:askForSkillInvoke(target, self.name, nil,
      "#ol__caozhao-choice:"..player.id.."::"..Fk:getCardById(id, true):toLogString()..":"..self.interaction.data)
    if choice then
      room:setCardMark(Fk:getCardById(id), "@@ol__caozhao", self.interaction.data)
      local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper),
        1, 1, "#ol__caozhao-choose", self.name, true)
      if #to > 0 then
        room:obtainCard(to[1], id, true, fk.ReasonGive)
      end
    else
      room:loseHp(target, 1, self.name)
    end
  end,
}
local ol__caozhao_record = fk.CreateTriggerSkill{
  name = "#ol__caozhao_record",

  refresh_events = {fk.AfterCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
  local room = player.room
    for _, move in ipairs(data) do
      if move.toArea ~= Card.PlayerHand and move.toArea ~= Card.Processing then
        for _, info in ipairs(move.moveInfo) do
          room:setCardMark(Fk:getCardById(info.cardId), "@@ol__caozhao", 0)
        end
      end
    end
  end,
}
local ol__caozhao_filter = fk.CreateFilterSkill{
  name = "#ol__caozhao_filter",
  card_filter = function(self, card, player)
    return card:getMark("@@ol__caozhao") ~= 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    return Fk:cloneCard(card:getMark("@@ol__caozhao"), card.suit, card.number)
  end,
}
local ol__xibing = fk.CreateTriggerSkill{
  name = "ol__xibing",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and data.from ~= player and
      ((not data.from.dead and #data.from:getCardIds("he") > 1) or #player:getCardIds("he") > 1)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    if not data.from.dead and #data.from:getCardIds("he") > 1 then
      table.insert(targets, data.from.id)
    end
    if #player:getCardIds("he") > 1 then
      table.insert(targets, player.id)
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#ol__xibing-invoke::"..data.from.id, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cards = room:askForCardsChosen(player, to, 2, 2, "he", self.name)
    room:throwCard(cards, self.name, to, player)
    local p = nil
    if player:getHandcardNum() > data.from:getHandcardNum() then
      p = data.from
    elseif player:getHandcardNum() < data.from:getHandcardNum() then
      p = player
    end
    if not p or p.dead then return end
    p:drawCards(2, self.name)
    local mark = player:getMark("ol__xibing-turn")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, p.id)
    room:setPlayerMark(player, "ol__xibing-turn", mark)
  end,
}
local ol__xibing_prohibit = fk.CreateProhibitSkill{
  name = "#ol__xibing_prohibit",
  is_prohibited = function(self, from, to, card)
    return to:getMark("ol__xibing-turn") ~= 0 and table.contains(to:getMark("ol__xibing-turn"), from.id)
  end,
}
ol__caozhao:addRelatedSkill(ol__caozhao_record)
ol__caozhao:addRelatedSkill(ol__caozhao_filter)
ol__xibing:addRelatedSkill(ol__xibing_prohibit)
huaxin:addSkill(ol__caozhao)
huaxin:addSkill(ol__xibing)
Fk:loadTranslationTable{
  ["ol__huaxin"] = "华歆",
  ["#ol__huaxin"] = "渊清玉洁",
  ["illustrator:ol__huaxin"] = "猎枭",
  ["ol__caozhao"] = "草诏",
  [":ol__caozhao"] = "出牌阶段限一次，你可展示一张手牌并声明一种未以此法声明过的基本牌或普通锦囊牌，令一名体力值不大于你的其他角色选择一项："..
  "令此牌视为你声明的牌，或其失去1点体力。然后若此牌声明成功，你可以将之交给一名其他角色。",
  ["ol__xibing"] = "息兵",
  [":ol__xibing"] = "当你受到其他角色造成的伤害后，你可以弃置你或其两张牌，然后手牌数少的角色摸两张牌，以此法摸牌的角色不能使用牌指定你为目标直到回合结束。",
  ["#ol__caozhao-invoke"] = "草诏：选择要声明的牌，然后选择展示的手牌和目标角色",
  ["#ol__caozhao"] = "%from 声明了 %arg",
  ["#ol__caozhao-choice"] = "草诏：令 %src 将%arg视为【%arg2】，或点“取消”你失去1点体力",
  ["@$ol__caozhao"] = "草诏",
  ["@@ol__caozhao"] = "草诏",
  ["#ol__caozhao-choose"] = "草诏：你可以将这张牌交给一名其他角色",
  ["#ol__caozhao_filter"] = "草诏",
  ["#ol__xibing-invoke"] = "息兵：你可以弃置你或 %dest 两张牌，然后手牌数少的角色摸两张牌",

  ["$ol__caozhao1"] = "草诏所宣，密勿从事。",
  ["$ol__caozhao2"] = "惩恶扬功，四方之纲。",
  ["$ol__xibing1"] = "讲信修睦，息兵不功。",
  ["$ol__xibing2"] = "天时未至，周武还师。",
  ["~ol__huaxin"] = "死国，甚无谓也！",
}

local chengjichengcui = General(extension, "chengjichengcui", "wei", 6)
chengjichengcui.subkingdom = "jin"
local tousui = fk.CreateViewAsSkill{
  name = "tousui",
  pattern = "slash",
  prompt = "#tousui-invoke",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    return card
  end,
  before_use = function (self, player, use)
    local room = player.room
    if player:isNude() then return "" end
    local cards = room:askForCard(player, 1, 999, true, "tousui", false, ".", "#tousui-card")
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = "tousui",
        proposer = player.id,
        drawPilePosition = -1,
      })
      use.extra_data = use.extra_data or {}
      use.extra_data.tousui = #cards
    end
  end,
  enabled_at_play = function(self, player)
    return not player:isNude()
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:isNude()
  end,
}
local tousui_trigger = fk.CreateTriggerSkill{
  name = "#tousui_trigger",
  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "tousui") and (data.extra_data or {}).tousui
  end,
  on_refresh = function(self, event, target, player, data)
    data.fixedResponseTimes = data.fixedResponseTimes or {}
    data.fixedResponseTimes["jink"] = data.extra_data.tousui
  end,
}
local chuming = fk.CreateTriggerSkill{
  name = "chuming",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused, fk.DamageInflicted, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if event ~= fk.TurnEnd then
      if target == player and player:hasSkill(self) then
        if event == fk.DamageCaused then
          return data.to ~= player
        else
          return data.from and data.from ~= player
        end
      end
    else
      return player:getMark("chuming-turn") ~= 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event ~= fk.TurnEnd then
      if not data.card or #Card:getIdList(data.card) == 0 then
        if event == fk.DamageCaused then
          player:broadcastSkillInvoke(self.name, 2)
          room:notifySkillInvoked(player, self.name, "offensive", {data.to.id})
        else
          player:broadcastSkillInvoke(self.name, 1)
          room:notifySkillInvoked(player, self.name, "negative", {data.from.id})
        end
        data.damage = data.damage + 1
      else
        local toId = (event == fk.DamageCaused) and data.to.id or data.from.id
        player:broadcastSkillInvoke(self.name)
        room:notifySkillInvoked(player, self.name, "negative", {toId})
        room:addTableMark(player, "chuming-turn", {toId, Card:getIdList(data.card)})
      end
    else
      local infos = table.simpleClone(player:getMark("chuming-turn"))
      for _, info in ipairs(infos) do
        if player.dead then return end
        local from = room:getPlayerById(info[1])
        if not from.dead and table.every(info[2], function(id) return room:getCardArea(id) == Card.DiscardPile end) then
          local names = {}
          local other_targets = {}
          for i, name in ipairs({"dismantlement", "collateral"}) do
            local card = Fk:cloneCard(name)
            card:addSubcards(info[2])
            if from:canUseTo(card, player) then
              if i == 1 then
                table.insert(names, name)
              else
                Self = from -- for targetFilter check
                for _, p in ipairs(room.alive_players) do
                  if p ~= player and card.skill:targetFilter(p.id, {player.id}, {}, card) then
                    table.insert(other_targets, p.id)
                  end
                end
                if #other_targets > 0 then
                  table.insert(names, name)
                end
              end
            end
          end
          if #names > 0 then
            local success, dat = room:askForUseActiveSkill(from, "chuming_viewas", "#chuming-invoke::"..player.id, false,
            {chuming_info = {player.id, names}})
            local tos, name = {}, nil
            if dat then
              tos = dat.targets
              name = dat.interaction
            else
              name = table.random(names)
              if name == "collateral" then
                table.insert(tos, table.random(other_targets))
              end
            end
            table.insert(tos, 1, player.id)
            local card = Fk:cloneCard(name)
            card:addSubcards(info[2])
            card.skillName = self.name
            local use = {
              from = from.id,
              tos = table.map(tos, function(p) return {p} end),
              card = card,
            }
            room:useCard(use)
          end
        end
      end
    end
  end,
}
local chuming_viewas = fk.CreateActiveSkill{
  name = "chuming_viewas",
  card_num = 0,
  min_target_num = 0,
  max_target_num = 1,
  interaction = function(self)
    return UI.ComboBox {choices = self.chuming_info[2]}
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if self.interaction.data == "collateral" then
      if #selected == 0 then
        local room = Fk:currentRoom()
        return room:getPlayerById(self.chuming_info[1]):inMyAttackRange(room:getPlayerById(to_select))
      end
    else
      return false
    end
  end,
  feasible = function (self, selected, selected_cards)
    if self.interaction.data == "collateral" then
      return #selected == 1
    else
      return #selected == 0
    end
  end,
}
tousui:addRelatedSkill(tousui_trigger)
Fk:addSkill(chuming_viewas)
chengjichengcui:addSkill(tousui)
chengjichengcui:addSkill(chuming)
Fk:loadTranslationTable{
  ["chengjichengcui"] = "成济成倅",
  ["#chengjichengcui"] = "袒忿半瓦",
  ["designer:chengjichengcui"] = "玄蝶既白",
  ["illustrator:chengjichengcui"] = "君桓文化",

  ["tousui"] = "透髓",
  [":tousui"] = "你可以将任意张牌置于牌堆底，视为使用一张需要等量张【闪】抵消的【杀】。",
  ["chuming"] = "畜鸣",
  [":chuming"] = "锁定技，当你对其他角色造成伤害或受到其他角色造成的伤害时，若此伤害：没有对应的实体牌，此伤害+1；有对应的实体牌，"..
  "其本回合结束时将造成伤害的牌当【借刀杀人】或【过河拆桥】对你使用。",
  ["#tousui-invoke"] = "透髓：选择【杀】的目标，然后将任意张牌置于牌堆底",
  ["#tousui-card"] = "透髓：将至少一张牌置于牌堆底，最后选的牌在牌堆底",
  ["chuming_viewas"] = "畜鸣",
  ["#chuming-invoke"] = "畜鸣：选择对 %dest 使用的牌（若为【借刀杀人】则选择被杀的目标）",

  ["$tousui1"] = "区区黄口孺帝，能有何作为？",
  ["$tousui2"] = "昔年沙场茹血，今欲饮帝血！",
  ["$chuming1"] = "明公为何如此待我兄弟？",
  ["$chuming2"] = "栖佳木之良禽，其鸣亦哀乎？",
  ["~chengjichengcui"] = "今为贼子贾充所害！",
}

local zhanghuyuechen = General(extension, "zhanghuyuechen", "jin", 4)
local xijue = fk.CreateTriggerSkill{
  name = "xijue",
  anim_type = "offensive",
  events = {fk.GameStart, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        self.cost_data = 4
        return true
      else
        if target == player then
          local room = player.room
          local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
          if turn_event == nil then return false end
          local n = 0
          room.logic:getActualDamageEvents(1, function(e)
            local damage = e.data[1]
            if damage.from == player then
              n = n + damage.damage
            end
            return false
          end, nil, turn_event.id)
          if n > 0 then
            self.cost_data = n
            return true
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@zhanghuyuechen_jue", self.cost_data)
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@zhanghuyuechen_jue", 0)
  end,
}
local xijue_tuxi = fk.CreateTriggerSkill{
  name = "#xijue_tuxi",
  anim_type = "control",
  main_skill = xijue,
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    return (target == player and player:hasSkill(xijue) and data.n > 0 and player:getMark("@zhanghuyuechen_jue") > 0 and
      not table.every(player.room:getOtherPlayers(player, false), function (p) return p:isKongcheng() end))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isKongcheng() end), Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, data.n, "#xijue_tuxi-invoke", "ex__tuxi", true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@zhanghuyuechen_jue", 1)
    player:broadcastSkillInvoke("ex__tuxi")
    local targets = table.simpleClone(self.cost_data)
    room:sortPlayersByAction(targets)
    for _, id in ipairs(targets) do
      if player.dead then break end
      local p = room:getPlayerById(id)
      if not (p.dead or p:isKongcheng()) then
        local c = room:askForCardChosen(player, p, "h", "ex__tuxi")
        room:obtainCard(player.id, c, false, fk.ReasonPrey)
      end
    end
    data.n = data.n - #targets
  end,
}
local xijue_xiaoguo = fk.CreateTriggerSkill{
  name = "#xijue_xiaoguo",
  anim_type = "offensive",
  main_skill = xijue,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and not target.dead and player:hasSkill(xijue) and not player:isKongcheng() and
    player:getMark("@zhanghuyuechen_jue") > 0 and target.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, false, "xiaoguo", true, ".|.|.|.|.|basic", "#xijue_xiaoguo-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@zhanghuyuechen_jue", 1)
    player:broadcastSkillInvoke("xiaoguo")
    room:doIndicate(player.id, {target.id})
    room:throwCard(self.cost_data, "xiaoguo", player, player)
    if target.dead then return false end
    if #room:askForDiscard(target, 1, 1, true, "xiaoguo", true, ".|.|.|.|.|equip", "#xiaoguo-discard:"..player.id) > 0 then
      player:drawCards(1, "xiaoguo")
    else
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = "xiaoguo",
      }
    end
  end,
}
xijue:addRelatedSkill(xijue_tuxi)
xijue:addRelatedSkill(xijue_xiaoguo)
zhanghuyuechen:addSkill(xijue)
zhanghuyuechen:addRelatedSkill("ex__tuxi")
zhanghuyuechen:addRelatedSkill("xiaoguo")
Fk:loadTranslationTable{
  ["zhanghuyuechen"] = "张虎乐綝",
  ["#zhanghuyuechen"] = "不辱门庭",
  ["designer:zhanghuyuechen"] = "张浩",
  ["illustrator:zhanghuyuechen"] = "凝聚永恒",

  ["xijue"] = "袭爵",
  [":xijue"] = "游戏开始时，你获得4个“爵”标记；回合结束时，你获得X个“爵”标记（X为你本回合造成的伤害值）。你可以移去1个“爵”标记发动〖突袭〗或〖骁果〗。",
  ["@zhanghuyuechen_jue"] = "爵",
  ["#xijue_tuxi-invoke"] = "袭爵：你可以移去1个“爵”标记发动〖突袭〗",
  ["#xijue_xiaoguo-invoke"] = "袭爵：你可以移去1个“爵”标记对 %dest 发动〖骁果〗",
  ["#xijue_tuxi"] = "突袭",
  ["#xijue_xiaoguo"] = "骁果",

  ["$xijue1"] = "承爵于父，安能辱之！",
  ["$xijue2"] = "虎父安有犬子乎？",
  ["$ex__tuxi_zhanghuyuechen1"] = "动如霹雳，威震宵小！",
  ["$ex__tuxi_zhanghuyuechen2"] = "行略如风，摧枯拉朽！",
  ["$xiaoguo_zhanghuyuechen1"] = "大丈夫生于世，当沙场效忠！",
  ["$xiaoguo_zhanghuyuechen2"] = "骁勇善战，刚毅果断！",
  ["~zhanghuyuechen"] = "儿有辱……父亲威名……",
}

local xiahouhui = General(extension, "xiahouhui", "jin", 3, 3, General.Female)
local baoqie = fk.CreateTriggerSkill{
  name = "baoqie",
  frequency = Skill.Compulsory,
  events = {"fk.GeneralAppeared"},
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasShownSkill(self) and #player.room:getCardsFromPileByRule(".|.|.|.|.|treasure") > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local ids = room:getCardsFromPileByRule(".|.|.|.|.|treasure")
    if #ids > 0 then
      room:moveCardTo(ids, Player.Hand, player, fk.ReasonPrey, self.name)
      local cid = ids[1]
      local card = Fk:getCardById(cid)
      if not player.dead and table.contains(player:getCardIds("h"), cid) and card.type == Card.TypeEquip and
      player:canUseTo(card, player) and room:askForSkillInvoke(player, self.name, nil, "#baoqie-use:::"..card:toLogString()) then
        room:useCard{from = player.id, tos = {{player.id}}, card = card}
      end
    end
  end,
}
baoqie.isHiddenSkill = true
local yishi = fk.CreateTriggerSkill{
  name = "yishi",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      local room = player.room
      local tos, cards = {}, {}
      for _, move in ipairs(data) do
        if move.from and move.from ~= player.id and move.moveReason == fk.ReasonDiscard
        and room:getPlayerById(move.from).phase == Player.Play and not room:getPlayerById(move.from).dead then
          tos = {move.from}
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and room:getCardArea(info.cardId) == Card.DiscardPile then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
      if #cards> 0 then
        self.cost_data = {cards = cards, tos = tos}
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#yishi-invoke::"..self.cost_data.tos[1])
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local cards = self.cost_data.cards
    local give = cards[1]
    if #cards > 1 then
      give = room:askForCardChosen(player, to, { card_data = { { "yishi", cards } } }, self.name, "#yishi-card:"..to.id)
    end
    room:moveCardTo(give, Player.Hand, to, fk.ReasonPrey, self.name)
    if player.dead then return end
    cards = table.filter(cards, function (id)
      return id ~= give and room:getCardArea(id) == Card.DiscardPile
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, self.name)
    end
  end,
}
local shidu = fk.CreateActiveSkill{
  name = "shidu",
  anim_type = "control",
  prompt = "#shidu-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player and not (player.dead or target.dead) then
      local cards = target:getCardIds(Player.Hand)
      if #cards > 0 then
        room:obtainCard(player, cards, false, fk.ReasonPrey)
        if player.dead or target.dead then return end
      end
      local n = #player:getCardIds(Player.Hand)
      if n > 1 then
        cards = room:askForCard(player, (n//2), (n//2), false, self.name, false, ".",
        "#shidu-give::".. target.id .. ":"..tostring(n//2))
        room:obtainCard(target, cards, false, fk.ReasonGive)
      end
    end
  end,
}
xiahouhui:addSkill(baoqie)
xiahouhui:addSkill(yishi)
xiahouhui:addSkill(shidu)
Fk:loadTranslationTable{
  ["xiahouhui"] = "夏侯徽",
  ["#xiahouhui"] = "景怀皇后",
  ["illustrator:xiahouhui"] = "凝聚永恒",
  ["baoqie"] = "宝箧",
  [":baoqie"] = "隐匿。锁定技，当你登场后，你从牌堆或弃牌堆获得一张宝物牌，然后你可以使用之。",
  ["yishi"] = "宜室",
  [":yishi"] = "每回合限一次，当一名其他角色于其出牌阶段弃置手牌后，你可以令其获得其中的一张牌，然后你获得其余的牌。",
  ["shidu"] = "识度",
  [":shidu"] = "出牌阶段限一次，你可以与一名角色拼点，若你赢，你获得其所有手牌，然后你交给其你的一半手牌（向下取整）。",
  ["#shidu-active"] = "发动 识度，与一名角色拼点，若你赢，你获得其所有手牌并交给其一半的手牌",
  ["#yishi-invoke"] = "宜室：你可以令 %dest 收回一张弃置的牌，你获得其余的牌",
  ["#yishi-card"] = "宜室：选择一张牌还给 %src",
  ["#shidu-give"] = "识度：选择%arg张手牌交还给%dest",
  ["#baoqie-use"] = "宝箧：你可以使用 %arg",

  ["$baoqie1"] = "宝箧藏玺，时局变动。",
  ["$baoqie2"] = "曹亡宝箧，尽露锋芒。",
  ["$yishi1"] = "家庭和顺，夫妻和睦。",
  ["$yishi2"] = "之子于归，宜其室家。",
  ["$shidu1"] = "鉴识得体，气度雅涵。",
  ["$shidu2"] = "宽容体谅，宽人益己。",
  ["~xiahouhui"] = "夫君，你怎么对我如此狠心……",
}

local simashi = General(extension, "ol__simashi", "jin", 3, 4)
local taoyin = fk.CreateTriggerSkill{
  name = "taoyin",
  events = {"fk.GeneralAppeared"},
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasShownSkill(self) then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      local to = turn_event.data[1]
      if to ~= player and not to.dead then
        self.cost_data = to
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#taoyin-invoke:"..self.cost_data.id)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = self.cost_data
    room:doIndicate(player.id, {to.id})
    room:addPlayerMark(to, MarkEnum.MinusMaxCardsInTurn, 2)
    room:broadcastProperty(to, "MaxCards")
  end,
}
taoyin.isHiddenSkill = true
local yimie = fk.CreateTriggerSkill{
  name = "yimie",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to.hp > data.damage and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yimie-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    local x = data.to.hp - data.damage
    if x > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.yimie = (data.extra_data.yimie or 0) + x
      data.damage = data.to.hp
    end
  end,
}

local yimie_delay = fk.CreateTriggerSkill{
  name = "#yimie_delay",
  events = {fk.Damage},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return data.to == player and not player.dead and player:isWounded() and
    data.extra_data and data.extra_data.yimie
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = data.extra_data.yimie,
      skillName = yimie.name
    }
  end,
}
local tairan = fk.CreateTriggerSkill{
  name = "tairan",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if player.phase == Player.Finish then
        return player:isWounded() or player:getHandcardNum() < player.maxHp
      elseif player.phase == Player.Play then
        return player:getMark("tairan_hp") > 0 or table.find(player:getCardIds(Player.Hand), function (id)
          local card = Fk:getCardById(id)
          return card:getMark("@@tairan-inhand") > 0 and not player:prohibitDiscard(card)
        end)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Finish then
      if player:isWounded() then
        local n = player:getLostHp()
        room:recover({
          who = player,
          num = n,
          recoverBy = player,
          skillName = self.name
        })
        room:setPlayerMark(player, "tairan_hp", n)
      end
      if player:getHandcardNum() < player.maxHp then
        player:drawCards(player.maxHp - player:getHandcardNum(), self.name, nil, "@@tairan-inhand")
      end
    else
      local n = player:getMark("tairan_hp")
      if n > 0 then
        room:setPlayerMark(player, "tairan_hp", 0)
        room:loseHp(player, n, self.name)
      end
      if not player.dead then
        local card = nil
        local cards = table.filter(player:getCardIds(Player.Hand), function (id)
          card = Fk:getCardById(id)
          return card:getMark("@@tairan-inhand") > 0 and not player:prohibitDiscard(card)
        end)
        if #cards > 0 then
          room:throwCard(cards, self.name, player, player)
        end
      end
    end
  end,
}
local ruilue = fk.CreateTriggerSkill{
  name = "ruilue$",

  refresh_events = {fk.AfterPropertyChange, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self
    elseif event == fk.Deathed then
      return target:hasSkill(self, true, true)
    elseif event == fk.AfterPropertyChange then
      return target == player
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local attached = player.kingdom == "jin" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(self, true)
    end)
    if attached and not player:hasSkill("ruilue&", true, true) then
      room:handleAddLoseSkills(player, "ruilue&", nil, false, true)
    elseif not attached and player:hasSkill("ruilue&", true, true) then
      room:handleAddLoseSkills(player, "-ruilue&", nil, false, true)
    end
  end,
}
local ruilue_active = fk.CreateActiveSkill{
  name = "ruilue&",
  mute = true,
  card_num = 1,
  target_num = 0,
  prompt = "#ruilue",
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player.kingdom == "jin" then
      return table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill(ruilue) and p ~= player end)
    end
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and (Fk:getCardById(to_select).is_damage_card)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.filter(room.alive_players, function(p) return p:hasSkill(ruilue) and p ~= player end)
    local target
    if #targets == 1 then
      target = targets[1]
    else
      target = room:getPlayerById(room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, nil, self.name, false)[1])
    end
    if not target then return false end
    target:broadcastSkillInvoke("ruilue")
    room:notifySkillInvoked(target, "ruilue", "support")
    room:doIndicate(effect.from, {target.id})
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, self.name, nil, true, player.id)
  end,
}
Fk:addSkill(ruilue_active)
yimie:addRelatedSkill(yimie_delay)
simashi:addSkill(taoyin)
simashi:addSkill(yimie)
simashi:addSkill(tairan)
simashi:addSkill(ruilue)
Fk:loadTranslationTable{
  ["ol__simashi"] = "司马师",
  ["#ol__simashi"] = "晋景王",
  ["illustrator:ol__simashi"] = "拉布拉卡",
  ["taoyin"] = "韬隐",
  [":taoyin"] = "隐匿。你于其他角色的回合登场后，你可以令其本回合的手牌上限-2。",
  ["yimie"] = "夷灭",
  [":yimie"] = "每回合限一次，当你对一名其他角色造成伤害时，你可失去1点体力，令此伤害值+X（X为其体力值减去伤害值）。伤害结算后，其回复X点体力。",
  ["tairan"] = "泰然",
  [":tairan"] = "锁定技，回合结束时，你回复体力至体力上限，将手牌摸至体力上限；出牌阶段开始时，你失去上次以此法回复的体力值，弃置以此法获得的手牌。",
  ["ruilue"] = "睿略",
  [":ruilue"] = "主公技，其他晋势力角色的出牌阶段限一次，该角色可以将一张【杀】或伤害锦囊牌交给你。",
  ["ruilue&"] = "睿略",
  [":ruilue&"] = "出牌阶段限一次，你可以将一张【杀】或伤害锦囊牌交给司马师。",
  ["#ruilue"] = "睿略：你可以将一张伤害牌交给司马师",
  ["#yimie_delay"] = "夷灭",
  ["#yimie-invoke"] = "夷灭：你可以失去1点体力，令你对 %arg 造成的伤害增加至其体力值！",
  ["@@tairan-inhand"] = "泰然",
  ["#taoyin-invoke"] = "韬隐：你可以令 %src 本回合的手牌上限-2",

  ["$taoyin1"] = "司马氏善谋、善忍，善置汝于绝境！",
  ["$taoyin2"] = "隐忍数载，亦不坠青云之志！",
  ["$yimie1"] = "汝大逆不道，当死无赦！",
  ["$yimie2"] = "斩草除根，灭其退路！",
  ["$tairan1"] = "撼山易，撼我司马氏难。",
  ["$tairan2"] = "云卷云舒，处之泰然。",
  ["$ruilue1"] = "司马当兴，其兴在吾。",
  ["$ruilue2"] = "吾承父志，故知军事、通谋略。",
  ["~ol__simashi"] = "子上，这是为兄给你打下的江山……",
}

local yanghuiyu = General(extension, "ol__yanghuiyu", "jin", 3, 3, General.Female)
local huirong = fk.CreateTriggerSkill{
  name = "huirong",
  frequency = Skill.Compulsory,
  events = {"fk.GeneralAppeared"},
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasShownSkill(self) and
      table.find(player.room.alive_players, function (p)
        return p:getHandcardNum() > p.hp or p:getHandcardNum() < math.min(p.hp, 5)
      end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p:getHandcardNum() > p.hp or p:getHandcardNum() < math.min(p.hp, 5)
    end)
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#huirong-choose", self.name, false)
    local to = room:getPlayerById(tos[1])
    local n = to:getHandcardNum() - math.max(to.hp, 0)
    if n > 0 then
      room:askForDiscard(to, n, n, false, self.name, false)
    else
      n = math.min(5-to:getHandcardNum(), -n)
      if n > 0 then
        to:drawCards(n, self.name)
      end
    end
  end,
}
huirong.isHiddenSkill = true
local ciwei = fk.CreateTriggerSkill{
  name = "ciwei",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target ~= player and target.phase ~= Player.NotActive and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and not player:isNude() then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local mark = U.getMark(target, "ciwei_record-turn")
      if table.contains(mark, use_event.id) then
        return #mark > 1 and mark[2] == use_event.id
      end
      if #mark > 1 then return false end
      mark = {}
      room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
        local use = e.data[1]
        if use.from == target.id then
          table.insert(mark, e.id)
          return true
        end
        return false
      end, Player.HistoryTurn)
      room:setPlayerMark(target, "ciwei_record-turn", mark)
      return #mark > 1 and mark[2] == use_event.id
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askForDiscard(player, 1, 1, true, self.name, true, ".",
    "#ciwei-invoke::"..target.id..":"..data.card:toLogString(), true)
    if #cards > 0 then
      self.cost_data = cards
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    data.tos = {}
    room:sendLog{ type = "#CardNullifiedBySkill", from = target.id, arg = self.name, arg2 = data.card:toLogString() }
  end,
}
local caiyuan = fk.CreateTriggerSkill{
  name = "caiyuan",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      local end_id = player:getMark("caiyuan_record-turn")
      if end_id < 0 then return false end
      local room = player.room
      if end_id == 0 then
        local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
        if turn_event == nil then return false end
        U.getEventsByRule(room, GameEvent.Turn, 1, function(e)
          if e.data[1] == player and e.id ~= turn_event.id then
            end_id = e.id
            return true
          end
          return false
        end, end_id)
      end
      if end_id == 0 then
        room:setPlayerMark(player, "caiyuan_record-turn", -1)
        return false
      end
      U.getEventsByRule(room, GameEvent.ChangeHp, 1, function(e)
        if e.data[1] == player and e.data[2] < 0 then
          end_id = -1
          room:setPlayerMark(player, "caiyuan_record-turn", -1)
          return true
        end
        return false
      end, end_id)
      if end_id > 0 then
        room:setPlayerMark(player, "caiyuan_record-turn", room.logic.current_event_id)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
yanghuiyu:addSkill(huirong)
yanghuiyu:addSkill(ciwei)
yanghuiyu:addSkill(caiyuan)
Fk:loadTranslationTable{
  ["ol__yanghuiyu"] = "羊徽瑜",
  ["#ol__yanghuiyu"] = "景献皇后",
  ["illustrator:ol__yanghuiyu"] = "Jzeo",
  ["huirong"] = "慧容",
  [":huirong"] = "隐匿。锁定技，你登场时，令一名角色将手牌摸或弃至体力值（至多摸至五张）。",
  ["ciwei"] = "慈威",
  [":ciwei"] = "其他角色于其回合内使用第二张牌时，若此牌为基本牌或普通锦囊牌，你可弃置一张牌令此牌无效（取消所有目标）。",
  ["caiyuan"] = "才媛",
  [":caiyuan"] = "锁定技，回合结束前，若你于上回合结束至今未扣减过体力，你摸两张牌。",
  ["#ciwei-invoke"] = "慈威：你可以弃置一张牌，取消 %dest 使用的%arg",
  ["#huirong-choose"] = "慧容:令一名角色将手牌摸或弃至体力值（至多摸至五张）",

  ["$huirong1"] = "红尘洗练，慧容不改。",
  ["$huirong2"] = "花貌易改，福惠长存。",
  ["$ciwei1"] = "乃家乃邦，是则是效。",
  ["$ciwei2"] = "其慈有威，不舒不暴。",
  ["$caiyuan1"] = "柳絮轻舞，撷芳赋诗。",
  ["$caiyuan2"] = "秀媛才德，知书达理。",
  ["~ol__yanghuiyu"] = "韶华易老，佳容不再……",
}

local shibao = General(extension, "shibao", "jin", 4)
local zhuosheng = fk.CreateTriggerSkill{
  name = "zhuosheng",
  anim_type = "special",
  events = {fk.AfterCardTargetDeclared, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and (data.extra_data or {}).zhuosheng then
      if event == fk.AfterCardTargetDeclared then
        return data.card:isCommonTrick() and data.tos
      else
        return data.card.type == Card.TypeEquip
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardTargetDeclared then
      local room = player.room
      local targets = {}
      if #TargetGroup:getRealTargets(data.tos) > 1 then
        table.insertTable(targets, TargetGroup:getRealTargets(data.tos))
      end
      table.insertTable(targets, U.getUseExtraTargets(room, data, false))
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#zhuosheng-choose:::"..data.card:toLogString(), self.name, true)
      if #tos > 0 then
        self.cost_data = tos
        return true
      end
    else
      return player.room:askForSkillInvoke(player, self.name, nil, "#zhuosheng-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AfterCardTargetDeclared then
      if table.contains(TargetGroup:getRealTargets(data.tos), self.cost_data[1]) then
        TargetGroup:removeTarget(data.tos, self.cost_data[1])
      else
        table.insert(data.tos, self.cost_data)
      end
    else
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    if event == fk.PreCardUse then
      return player:hasSkill(self) and player.phase == Player.Play and target == player and
        data.card:getMark("@@zhuosheng-inhand-round") > 0
    else
      return player:hasSkill(self, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand and move.skillName ~= self.name then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
              room:setCardMark(Fk:getCardById(id), "@@zhuosheng-inhand-round", 1)
            end
          end
        end
      end
    elseif event == fk.PreCardUse then
      data.extra_data = data.extra_data or {}
      data.extra_data.zhuosheng = true
      if data.card.type == Card.TypeBasic then
        data.extraUse = true
      end
    end
  end,
}
local zhuosheng_targetmod = fk.CreateTargetModSkill{
  name = "#zhuosheng_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(self) and player.phase == Player.Play and card and
      card.type == Card.TypeBasic and card:getMark("@@zhuosheng-inhand-round") > 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(self) and player.phase == Player.Play and card and
      card.type == Card.TypeBasic and card:getMark("@@zhuosheng-inhand-round") > 0
  end,
}
zhuosheng:addRelatedSkill(zhuosheng_targetmod)
shibao:addSkill(zhuosheng)
Fk:loadTranslationTable{
  ["shibao"] = "石苞",
  ["#shibao"] = "乐陵郡公",
  ["illustrator:shibao"] = "凝聚永恒",
  ["zhuosheng"] = "擢升",
  [":zhuosheng"] = "出牌阶段，当你使用本轮非以本技能获得的牌时，根据类型执行以下效果：1.基本牌，无距离和次数限制；"..
  "2.普通锦囊牌，可以令此牌目标+1或-1；3.装备牌，你可以摸一张牌。",
  ["@@zhuosheng-inhand-round"] = "擢升",
  ["#zhuosheng-choose"] = "擢升：你可以为此%arg增加或减少一个目标",
  ["#zhuosheng-invoke"] = "擢升：你可以摸一张牌",

  ["$zhuosheng1"] = "才经世务，干用之绩。",
  ["$zhuosheng2"] = "器量之远，当至公辅。",
  ["~shibao"] = "寒门出身，难以擢升。",
}

local simazhao = General(extension, "ol__simazhao", "jin", 3)
local tuishi = fk.CreateTriggerSkill{
  name = "tuishi",
  events = {"fk.GeneralAppeared"},
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasShownSkill(self) and player.phase == Player.NotActive
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@tuishi-turn", 1)
  end,
}
tuishi.isHiddenSkill = true
local tuishi_delay = fk.CreateTriggerSkill{
  name = "#tuishi_delay",
  events = {fk.EventPhaseStart},
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    if not target.dead and target.phase == Player.Finish and player:getMark("@@tuishi-turn") > 0 then
      return table.find(player.room.alive_players, function (p)
        return target:inMyAttackRange(p)
      end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function (p) return target:inMyAttackRange(p) end)
    local tos = player.room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#tuishi-choose:"..target.id, self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("tuishi")
    local use = room:askForUseCard(target, "slash", "slash", "#tuishi-slash:"..self.cost_data..":"..player.id, true, 
    {exclusive_targets = {self.cost_data}})
    if use then
      use.extraUse = true
      room:useCard(use)
    else
      room:damage { from = player, to = target, damage = 1, skillName = "tuishi" }
    end
  end,
}
tuishi:addRelatedSkill(tuishi_delay)
local choufa = fk.CreateActiveSkill{
  name = "choufa",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#choufa",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = room:askForCardChosen(player, target, "h", self.name)
    target:showCards(card)
    if not target.dead then
      for _, id in ipairs(target:getCardIds("h")) do
        if Fk:getCardById(id).type ~= Fk:getCardById(card).type then
          room:setCardMark(Fk:getCardById(id), "@@choufa-inhand", 1)
          Fk:filterCard(id, target)
        end
      end
    end
  end,
}
local choufa_trigger = fk.CreateTriggerSkill{
  name = "#choufa_trigger",

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player == target and not player:isKongcheng()
  end,
  on_refresh = function(self, event, target, player, data)
    U.clearHandMark(player, "@@choufa-inhand")
    player:filterHandcards()
  end,
}
local choufa_filter = fk.CreateFilterSkill{
  name = "#choufa_filter",
  card_filter = function(self, card, player)
    return card:getMark("@@choufa-inhand") > 0
  end,
  view_as = function(self, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
}
local zhaoran = fk.CreateTriggerSkill{
  name = "zhaoran",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhaoran-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@zhaoran-phase", {})
    player:showCards(player:getCardIds("h"))
  end,
}
local zhaoran_trigger = fk.CreateTriggerSkill{
  name = "#zhaoran_trigger",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes("zhaoran", Player.HistoryPhase) > 0 then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              if not table.find(player:getCardIds("h"), function(id)
                return Fk:getCardById(id).suit == Fk:getCardById(info.cardId).suit end) and
                not table.contains(player:getMark("@zhaoran-phase"), Fk:getCardById(info.cardId):getSuitString(true)) then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local suits = {}
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            if not table.find(player:getCardIds("h"), function(id)
              return Fk:getCardById(id).suit == Fk:getCardById(info.cardId).suit end) and
              not table.contains(player:getMark("@zhaoran-phase"), Fk:getCardById(info.cardId):getSuitString(true)) then
              table.insertIfNeed(suits, Fk:getCardById(info.cardId):getSuitString(true))
            end
          end
        end
      end
    end
    local mark = player:getMark("@zhaoran-phase")
    table.insertTableIfNeed(mark, suits)
    player.room:setPlayerMark(player, "@zhaoran-phase", mark)
    for i = 1, #suits, 1 do
      self:doCost(event, target, player, suits)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.every(room:getOtherPlayers(player), function(p) return p:isNude() end) then
      player:broadcastSkillInvoke("zhaoran")
      room:notifySkillInvoked(player, "zhaoran", "drawcard")
      player:drawCards(1, "zhaoran")
    else
      local targets = table.map(table.filter(room:getOtherPlayers(player), function (p)
        return not p:isNude() end), Util.IdMapper)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhaoran-discard", "zhaoran", true)
      player:broadcastSkillInvoke("zhaoran")
      if #to > 0 then
        room:notifySkillInvoked(player, "zhaoran", "control")
        local id = room:askForCardChosen(player, room:getPlayerById(to[1]), "he", "zhaoran")
        room:throwCard({id}, "zhaoran", room:getPlayerById(to[1]), player)
      else
        room:notifySkillInvoked(player, "zhaoran", "drawcard")
        player:drawCards(1, "zhaoran")
      end
    end
  end,
}
local chengwu = fk.CreateAttackRangeSkill{
  name = "chengwu$",
  frequency = Skill.Compulsory,
  within_func = function (self, from, to)
    if from:hasSkill(self) then
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.kingdom == "jin" and from ~= p and p:inMyAttackRange(to) then
          return true
        end
      end
    end
  end,
}
choufa:addRelatedSkill(choufa_trigger)
choufa:addRelatedSkill(choufa_filter)
zhaoran:addRelatedSkill(zhaoran_trigger)
simazhao:addSkill(tuishi)
simazhao:addSkill(choufa)
simazhao:addSkill(zhaoran)
simazhao:addSkill(chengwu)
Fk:loadTranslationTable{
  ["ol__simazhao"] = "司马昭",
  ["#ol__simazhao"] = "晋文帝",
  ["illustrator:ol__simazhao"] = "君桓文化",
  ["tuishi"] = "推弑",
  [":tuishi"] = "隐匿。当你于其他角色的回合内登场后，你可以于此回合结束阶段令其选择一项：1.对其攻击范围内你选择的一名角色使用【杀】；2.受到1点伤害。",
  ["choufa"] = "筹伐",
  [":choufa"] = "出牌阶段限一次，你可展示一名其他角色的一张手牌，其手牌中与此牌不同类型的牌均视为【杀】直到其回合结束。",
  ["zhaoran"] = "昭然",
  --[":zhaoran"] = "出牌阶段开始时，你可令你的手牌对所有角色可见直到此阶段结束。若如此做，当你于本阶段失去任意花色的最后一张手牌时（每种花色限一次），"..
  [":zhaoran"] = "出牌阶段开始时，你可展示所有手牌。若如此做，当你于本阶段失去任意花色的最后一张手牌时（每种花色限一次），"..
  "你摸一张牌或弃置一名其他角色的一张牌。",
  ["chengwu"] = "成务",
  [":chengwu"] = "主公技，锁定技，其他晋势力角色攻击范围内的角色均视为在你的攻击范围内。",
  ["#choufa"] = "筹伐：展示一名其他角色一张手牌，本回合其手牌中不为此类别的牌均视为【杀】",
  ["@@choufa-inhand"] = "筹伐",
  ["#choufa_filter"] = "筹伐",
  ["#zhaoran-invoke"] = "昭然：你可以展示所有手牌，本阶段你失去一种花色最后的手牌后摸一张牌或弃置一名角色一张牌",
  ["@zhaoran-phase"] = "昭然",
  ["#zhaoran_trigger"] = "昭然",
  ["#zhaoran-discard"] = "昭然：弃置一名其他角色一张牌，或点“取消”摸一张牌",
  ["#tuishi-choose"] = "推弑：你可选择一名角色，若 %src 未对其使用【杀】，你对 %src 造成1点伤害",
  ["#tuishi_delay"] = "推弑",
  ["@@tuishi-turn"] = "推弑",
  ["#tuishi-slash"] = "推弑：你需对 %src 使用【杀】，否则 %dest 对你造成1点伤害",

  ["$tuishi1"] = "此僚怀异，召汝讨贼。",
  ["$tuishi2"] = "推令既出，焉敢不从？",
  ["$choufa1"] = "秣马厉兵，筹伐不臣！",
  ["$choufa2"] = "枕戈待旦，秣马征平。",
  ["$zhaoran1"] = "行昭然于世，赦众贼以威。",
  ["$zhaoran2"] = "吾之心思，路人皆知。",
  ["$chengwu1"] = "令行禁止，政通无虞。",
  ["$chengwu2"] = "上下一体，大业可筹。",
  ["~ol__simazhao"] = "司马三代，一梦成空……",
}

local xuangongzhu = General(extension, "xuangongzhu", "jin", 3, 3, General.Female)
local gaoling = fk.CreateTriggerSkill{
  name = "gaoling",
  anim_type = "support",
  events = {"fk.GeneralAppeared"},
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasShownSkill(self) then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      return turn_event.data[1] ~= player and table.find(player.room.alive_players, function (p)
        return p:isWounded()
      end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function (p) return p:isWounded() end)
    local tos = player.room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#gaoling-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:recover {
      num = 1,
      skillName = self.name,
      who = room:getPlayerById(self.cost_data.tos[1]),
      recoverBy = player,
    }
  end,
}
gaoling.isHiddenSkill = true
local qimei = fk.CreateTriggerSkill{
  name = "qimei",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
    1, 1, "#qimei-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local mark =  U.getMark(to, "@@qimei")
    table.insert(mark, player.id)
    room:setPlayerMark(to, "@@qimei", mark)
    room:setPlayerMark(player, "qimei_couple", to.id)
  end,

  refresh_events = {fk.BuryVictim, fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return not player.dead and (type(player:getMark("@@qimei")) == "table" or player == target)
  end,
  on_refresh = function(self, event, target, player, data)
    if player == target then
      player.room:setPlayerMark(player, "qimei_couple", 0)
    else
      local mark = player:getMark("@@qimei")
      table.removeOne(mark, target.id)
      player.room:setPlayerMark(player, "@@qimei", #mark > 0 and mark or 0)
    end
  end,
}
local qimei_delay = fk.CreateTriggerSkill{
  name = "#qimei_delay",
  events = {fk.AfterCardsMove, fk.HpChanged},
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    local mark_id = player:getMark("qimei_couple")
    if mark_id == 0 then return false end
    local room = player.room
    local to = room:getPlayerById(mark_id)
    if to == nil or to.dead then return false end
    if event == fk.AfterCardsMove then
      if player:getHandcardNum() ~= to:getHandcardNum() then return false end
      local tos = {player.id, mark_id}
      for _, move in ipairs(data) do
        if move.from and table.contains(tos, move.from) and table.find(move.moveInfo, function (info)
          return info.fromArea == Card.PlayerHand
        end) then
          table.removeOne(tos, move.from)
        end
        if move.to and table.contains(tos, move.to) and move.toArea == Card.PlayerHand then
          table.removeOne(tos, move.to)
        end
      end
      if #tos == 2 then return false end
      if #tos == 0 then
        tos = {player.id, mark_id}
      end
      local mark =  player:getTableMark("qimei_used-turn")
      tos = table.filter(tos, function (id)
        return not table.contains(mark, id)
      end)
      if #tos == 0 then return false end
      self.cost_data = tos
      return true
    elseif event == fk.HpChanged then
      if player.hp ~= to.hp then return false end
      local mark =  player:getTableMark("qimei_used-turn")
      if target == player then
        if not table.contains(mark, mark_id) then
          self.cost_data = {mark_id}
          return true
        end
      elseif target == to then
        if not table.contains(mark, player.id) then
          self.cost_data = {player.id}
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = table.simpleClone(self.cost_data)
    room:sortPlayersByAction(tos)
    room:doIndicate(player.id, tos)
    player:broadcastSkillInvoke(qimei.name)
    local mark = player:getTableMark("qimei_used-turn")
    table.insertTable(mark, tos)
    room:setPlayerMark(player, "qimei_used-turn", mark)
    for _, pid in ipairs(tos) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        room:drawCards(p, 1, qimei.name)
      end
    end
  end,
}
local zhuijix = fk.CreateTriggerSkill{
  name = "zhuijix",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"zhuiji_draw-phase"}
    if player:isWounded() then
      table.insert(choices, 1, "zhuiji_recover-phase")
    end
    local choice = room:askForChoice(player, choices, self.name)
    room:addPlayerMark(player, choice, 1)
    if choice == "zhuiji_recover-phase" then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    else
      player:drawCards(2, self.name)
    end
  end,
}
local zhuijix_trigger = fk.CreateTriggerSkill{
  name = "#zhuijix_trigger",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:usedSkillTimes("zhuijix", Player.HistoryPhase) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("zhuijix")
    room:notifySkillInvoked(player, "zhuijix", "negative")
    if player:getMark("zhuiji_recover-phase") > 0 then
      room:setPlayerMark(player, "zhuiji_recover-phase", 0)
      room:askForDiscard(player, 2, 2, true, "zhuijix", false)
    end
    if player:getMark("zhuiji_draw-phase") > 0 then
      room:setPlayerMark(player, "zhuiji_draw-phase", 0)
      room:loseHp(player, 1, "zhuijix")
    end
  end,
}
qimei:addRelatedSkill(qimei_delay)
zhuijix:addRelatedSkill(zhuijix_trigger)
xuangongzhu:addSkill(gaoling)
xuangongzhu:addSkill(qimei)
xuangongzhu:addSkill(zhuijix)
Fk:loadTranslationTable{
  ["xuangongzhu"] = "宣公主",
  ["#xuangongzhu"] = "高陵公主",
  ["designer:xuangongzhu"] = "世外高v狼",
  ["illustrator:xuangongzhu"] = "凡果",
  ["gaoling"] = "高陵",
  [":gaoling"] = "隐匿。当你于其他角色的回合内登场时，你可以令一名角色回复1点体力。",
  ["qimei"] = "齐眉",
  [":qimei"] = "准备阶段，你可以选择一名其他角色，直到你的下个回合开始（每回合每项限一次），当你或该角色的手牌数或体力值变化后，若双方的此数值相等，"..
  "另一方摸一张牌。",
  ["zhuijix"] = "追姬",
  [":zhuijix"] = "出牌阶段开始时，你可以选择一项：1.回复1点体力，并于此阶段结束时弃置两张牌；2.摸两张牌，并于此阶段结束时失去1点体力。",
  ["#qimei-choose"] = "齐眉：指定一名其他角色为“齐眉”角色，双方手牌数或体力值变化后可摸牌",
  ["@@qimei"] = "齐眉",
  ["#qimei_delay"] = "齐眉",
  ["zhuiji_recover-phase"] = "回复1点体力，此阶段结束时弃两张牌",
  ["zhuiji_draw-phase"] = "摸两张牌，此阶段结束时失去1点体力",
  ["#gaoling-choose"] = "高陵:可以令一名角色回复1点体力",

  ["$gaoling1"] = "天家贵胄，福泽四海。",
  ["$gaoling2"] = "宣王之女，恩惠八方。",
  ["$qimei1"] = "辅车相依，比翼双飞。",
  ["$qimei2"] = "情投意合，相濡以沫。",
  ["$zhuijix1"] = "不过是些微代价罢了。",
  ["$zhuijix2"] = "哼，以为这就能难倒我吗？",
  ["~xuangongzhu"] = "元凯，我去也……",
}

local wangyuanji = General(extension, "ol__wangyuanji", "jin", 3, 3, General.Female)
local shiren = fk.CreateTriggerSkill{
  name = "shiren",
  events = {"fk.GeneralAppeared"},
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasShownSkill(self) then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      local to = turn_event.data[1]
      if to ~= player and not to.dead and not to:isKongcheng() then
        self.cost_data = to
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#shiren-invoke:"..self.cost_data.id)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    Fk.skills["yanxi"]:onUse(room, {from = player.id, tos = {self.cost_data.id}})
  end,
}
shiren.isHiddenSkill = true
local yanxi = fk.CreateActiveSkill{
  name = "yanxi",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  prompt = "#yanxi-prompt",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:getNCards(2)
    for i = #cards, 1, -1 do
      table.insert(room.draw_pile, 1, cards[i])
    end
    room:doBroadcastNotify("UpdateDrawPile", #room.draw_pile)
    local id = table.random(target.player_cards[Player.Hand])
    table.insert(cards, id)
    table.shuffle(cards)
    local id2 = room:askForCardChosen(player, target, {
      card_data = {
        { "$Hand", cards }
      }
    }, self.name, "#yanxi-card")
    if id2 ~= id then
      cards = {id2}
    end
    room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, self.name, nil, false, player.id, "@@yanxi-inhand-turn")
  end,
}
local yanxi_maxcards = fk.CreateMaxCardsSkill{
  name = "#yanxi_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@yanxi-inhand-turn") > 0
  end,
}
yanxi:addRelatedSkill(yanxi_maxcards)
wangyuanji:addSkill(shiren)
wangyuanji:addSkill(yanxi)
Fk:loadTranslationTable{
  ["ol__wangyuanji"] = "王元姬",
  ["#ol__wangyuanji"] = "文明皇后",
  ["illustrator:ol__wangyuanji"] = "六道目",
  ["shiren"] = "识人",
  [":shiren"] = "隐匿。你于其他角色的回合登场后，若当前回合角色有手牌，你可以对其发动〖宴戏〗。",
  ["yanxi"] = "宴戏",
  [":yanxi"] = "出牌阶段限一次，你将一名其他角色的随机一张手牌与牌堆顶的两张牌混合后展示，你猜测哪张牌来自其手牌。若猜对，你获得三张牌；"..
  "若猜错，你获得选中的牌。你以此法获得的牌本回合不计入手牌上限。",

  ["@@yanxi-inhand-turn"] = "宴戏",
  ["#yanxi-prompt"] = "宴戏:将一名其他角色的一张手牌与牌堆顶的两张牌混合后，猜测哪张来自其手牌",
  ["#yanxi-card"] = "宴戏:选择你认为来自其手牌的一张牌",
  ["#shiren-invoke"] = "识人：你可以对 %src 发动〖宴戏〗",

  ["$shiren1"] = "宠过必乱，不可大任。",
  ["$shiren2"] = "开卷有益，识人有法",
  ["$yanxi1"] = "宴会嬉趣，其乐融融。",
  ["$yanxi2"] = "宴中趣玩，得遇知己。",
  ["~ol__wangyuanji"] = "祖父已逝，哀凄悲戚。",
}

local duyu = General(extension, "ol__duyu", "jin", 4)
local sanchen = fk.CreateActiveSkill{
  name = "sanchen",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):getMark("sanchen-turn") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if player:hasSkill("zhaotao", true) and player:usedSkillTimes("zhaotao", Player.HistoryGame) == 0 then
      room:addPlayerMark(player, "@sanchen")
    end
    room:addPlayerMark(target, "sanchen-turn", 1)
    target:drawCards(3, self.name)
    local cards = room:askForDiscard(target, 3, 3, true, self.name, false, ".", "#sanchen-discard:"..player.id)
    local typeMap = {}
    for _, id in ipairs(cards) do
      typeMap[tostring(Fk:getCardById(id).type)] = (typeMap[tostring(Fk:getCardById(id).type)] or 0) + 1
    end
    for _, v in pairs(typeMap) do
      if v >= 2 then return end
    end
    target:drawCards(1, self.name)
    player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
  end,
}
local zhaotao = fk.CreateTriggerSkill{
  name = "zhaotao",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:usedSkillTimes("sanchen", Player.HistoryGame) > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@sanchen", 0)
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "pozhu", nil)
  end,
}
local pozhu = fk.CreateViewAsSkill{
  name = "pozhu",
  anim_type = "offensive",
  pattern = "unexpectation",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("unexpectation")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function (self, player)
    return player:getMark("pozhu-turn") == 0
  end,
}
local pozhu_record = fk.CreateTriggerSkill{
  name = "#pozhu_record",

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "pozhu")
  end,
  on_refresh = function(self, event, target, player, data)
    if not data.damageDealt then
      player.room:addPlayerMark(player, "pozhu-turn", 1)
    end
  end,
}
pozhu:addRelatedSkill(pozhu_record)
duyu:addSkill(sanchen)
duyu:addSkill(zhaotao)
duyu:addRelatedSkill(pozhu)
Fk:loadTranslationTable{
  ["ol__duyu"] = "杜预",
  ["#ol__duyu"] = "文成武德",
  ["designer:ol__duyu"] = "张浩",
  ["illustrator:ol__duyu"] = "君桓文化",

  ["sanchen"] = "三陈",
  [":sanchen"] = "出牌阶段限一次，你可令一名角色摸三张牌然后弃置三张牌。若其未因此次〖三陈〗的效果而弃置至少两张类别相同的牌，则其摸一张牌，且本技能视为未发动过（本回合不能再指定其为目标）。",
  ["zhaotao"] = "昭讨",
  [":zhaotao"] = "觉醒技，准备阶段开始时，若你本局游戏发动过至少3次〖三陈〗，你减1点体力上限，获得〖破竹〗。",
  ["pozhu"] = "破竹",
  [":pozhu"] = "出牌阶段，你可将一张手牌当【出其不意】使用，若此【出其不意】未造成伤害，此技能无效直到回合结束。",
  ["#sanchen-discard"] = "三陈：弃置三张牌，若类别各不相同则你摸一张牌且 %src 可以再发动“三陈”",
  ["@sanchen"] = "三陈",

  ["$sanchen1"] = "陈书弼国，当一而再、再而三。",
  ["$sanchen2"] = "勘除弼事，三陈而就。",
  ["$zhaotao1"] = "奉诏伐吴，定鼎东南！",
  ["$zhaotao2"] = "三陈方得诏，一股下孙吴！",
  ["$pozhu1"] = "攻其不备，摧枯拉朽！",
  ["$pozhu2"] = "势如破竹，铁锁横江亦难挡！",
  ["~ol__duyu"] = "金瓯尚缺，死难瞑目……",
}

local weiguan = General(extension, "weiguan", "jin", 3)
local zhongyun = fk.CreateTriggerSkill{
  name = "zhongyun",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.HpRecover, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      if player:hasSkill(self) and player.hp == player:getHandcardNum() and player:getMark("zhongyun2-turn") == 0 then
        for _, move in ipairs(data) do
          if move.to == player.id and move.toArea == Card.PlayerHand then
            return true
          end
          for _, info in ipairs(move.moveInfo) do
            if move.from == player.id and info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    else
      return target == player and player:hasSkill(self) and player.hp == player:getHandcardNum() and
      player:getMark("zhongyun1-turn") == 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      room:setPlayerMark(player, "zhongyun2-turn", 1)
      local targets = table.filter(room:getOtherPlayers(player), function (p) return not p:isNude() end)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#zhongyun-discard", self.name, true)
        if #to > 0 then
          local id = room:askForCardChosen(player, room:getPlayerById(to[1]), "he", self.name)
          room:throwCard({id}, self.name, room:getPlayerById(to[1]), player)
          return
        end
      end
      player:drawCards(1, self.name)
    else
      room:setPlayerMark(player, "zhongyun1-turn", 1)
      local targets = table.filter(room:getOtherPlayers(player), function (p) return player:inMyAttackRange(p) end)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#zhongyun-damage", self.name,
        player:isWounded())
        if #to > 0 then
          room:damage{
            from = player,
            to = room:getPlayerById(to[1]),
            damage = 1,
            skillName = self.name,
          }
          return
        end
      end
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    end
  end,
}
local shenpin = fk.CreateTriggerSkill{
  name = "shenpin",
  anim_type = "control",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not player:isNude() and data.card.color ~= Card.NoColor
  end,
  on_cost = function(self, event, target, player, data)
    local pattern = data.card.color == Card.Black and "heart,diamond" or "spade,club"
    local card = player.room:askForCard(player, 1, 1, true, self.name, true, ".|.|"..pattern, "#shenpin-invoke::"..target.id)
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(Fk:getCardById(self.cost_data), player, data, self.name, false)
  end,
}
weiguan:addSkill(zhongyun)
weiguan:addSkill(shenpin)
Fk:loadTranslationTable{
  ["weiguan"] = "卫瓘",
  ["#weiguan"] = "兰陵郡公",
  ["illustrator:weiguan"] = "Karneval",
  ["zhongyun"] = "忠允",
  [":zhongyun"] = "锁定技，每回合各限一次，当你受到伤害或回复体力后，若你的体力值与你的手牌数相等，你回复1点体力或对你攻击范围内的一名角色造成1点伤害；"..
  "当你获得或失去手牌后，若你的体力值与你的手牌数相等，你摸一张牌或弃置一名其他角色的一张牌。",
  ["shenpin"] = "神品",
  [":shenpin"] = "当一名角色的判定牌生效前，你可以打出一张与判定牌颜色不同的牌代替之。",
  ["#zhongyun-damage"] = "忠允：对攻击范围内一名角色造成1点伤害，或点“取消”回复1点体力",
  ["#zhongyun-discard"] = "忠允：弃置一名其他角色的一张牌，或点“取消”摸一张牌",
  ["#shenpin-invoke"] = "神品：你可以打出一张不同颜色的牌代替 %dest 的判定",

  ["$zhongyun1"] = "秉公行事，无所亲疏。",
  ["$zhongyun2"] = "明晰法理，通晓人情。",
  ["$shenpin1"] = "考其遗法，肃若神明。",
  ["$shenpin2"] = "气韵生动，出于天成。",
  ["~weiguan"] = "辞荣善终，不可求……",
}

local zhongyan = General(extension, "zhongyan", "jin", 3, 3, General.Female)
local bolan_skills = {
  --ol official skills
  "quhu", "qiangxi", "qice", "daoshu", "ol_ex__tiaoxin", "qiangwu", "tianyi", "ex__zhiheng", "ex__jieyin", "ex__guose",
  "lijian", "qingnang", "lihun", "mingce", "mizhao", "sanchen", "gongxin", "ex__chuli",
  --standard
  "ex__kurou", "ex__yijue", "fanjian", "ex__fanjian", "dimeng", "jijie", "poxi", "jueyan", "zhiheng","feijun", "tiaoxin",
  --sp
  "quji", "dahe", "tanhu", "fenxun","xueji", "re__anxu",
  --yjcm
  "nos__xuanhuo", "xinzhan", "nos__jujian", "ganlu", "xianzhen", "anxu", "gongqi", "huaiyi", "zhige", "anguo", "mingjian", "mieji",
  "duliang","junxing",
  --ol
  "ziyuan", "lianzhu", "shanxi", "lianji", "jianji", "liehou", "xianbi", "shidu", "yanxi", "xuanbei", "yushen", "bolong", "fuxun", "qiuxin", "ol_ex__dimeng", "juguan", "ol__xuehen", "ol__fenxun", "weikui", "ol__caozhao", "ol_ex__changbiao","qingyix","qin__qihuo",
  "lilun","chongxin","xiaosi", "ol__mouzhu",
  --mobile
  "wuyuan", "zhujian", "duansuo", "poxiang", "hannan", "shihe", "wisdom__qiai", "shameng", "zundi", "mobile__shangyi", "yangjie",
  "m_ex__anxu", "beizhu", "mobile__zhouxuan", "mobile__yizheng", "guli", "m_ex__xianzhen", "m_ex__ganlu", "m_ex__mieji", "yingba",
  "qiaosi", "pingcai","guanxu","guangu","shandao", "mou__zhiheng", "m_ex__junxing","mobile__yinju","dingzhou","guanzong","huiyao",
  --mougong
  "mou__qixi", "mou__lijian",
  --overseas
  "os__jimeng", "os__beini", "os__yuejian", "os__waishi", "os__weipo", "os__shangyi", "os__jinglue", "os__zhanyi", "os__daoji",
  "os_ex__gongqi", "os__gongxin", "os__zhuidu", "os__danlie","os__mutao",
  --tenyear
  "guolun", "kuiji", "ty__jianji", "caizhuang", "xinyou", "tanbei", "lueming", "ty__songshu", "ty__mouzhu", "libang", "nuchen",
  "weiwu", "ty__qingcheng", "ty__jianshu", "qiangzhiz", "ty__fenglue", "boyan", "ty_ex__mingce", "ty_ex__anxu",
  "ty_ex__mingjian", "ty_ex__quji", "jianzheng", "ty_ex__jixu", "ty__kuangfu", "yingshui", "weimeng", "tunan", "ty_ex__ganlu",
  "ty_ex__gongqi","huahuo","qiongying","jichun","xiaowu","mansi","kuizhen","zigu","ty_ex__wurong","jiuxianc","ty__lianji",
  "ty__xiongsuan","channi","ty__lianzhu","ty__beini","minsi","zhuren","cuijian", "changqu","ty__jiaohao","qingtan","yanjiao",
  "liangyan",
  --jsrg
  "js__yizheng", "shelun", "lunshi", "chushi", "pingtao","js__lianzhu","js__jinfa","duxing","yangming",
  --offline
  "miaojian", "xuepin", "ofl__shameng", "lifengs", "duyi", "mixin",
  --mini,
  "mini_yanshi","mini_jifeng","mini__jieyin","mini__qiangwu","mini_zhujiu",
  --wandian
  "wd__liangce", "wd__kenjian", "wd__zongqin", "wd__suli",
  --tuguo
  "tg__bode",
  --brainhole
  "n_qunzhi","n_kaoda","n_tuguo","n_subian",
  --qsgs
  "qyt__jueji",
}
---@param room Room
local getBolanSkills = function(room)
  local mark = room:getTag("BolanSkills")
  if mark then
    return mark
  else
    local all_skills = {}
    for _, g in ipairs(room.general_pile) do
      for _, s in ipairs(Fk.generals[g]:getSkillNameList()) do
        table.insert(all_skills, s)
      end
    end
    local skills = table.filter(bolan_skills, function(s) return table.contains(all_skills, s) end)
    room:setTag("BolanSkills", skills)
    return skills
  end
end
local bolan = fk.CreateTriggerSkill{
  name = "bolan",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = table.filter(getBolanSkills(room), function (skill_name)
      return not player:hasSkill(skill_name, true)
    end)
    if #skills > 0 then
      local choice = room:askForChoice(player, table.random(skills, 3), self.name, "#bolan-choice::"..player.id, true)
      room:handleAddLoseSkills(player, choice)
      room.logic:getCurrentEvent():findParent(GameEvent.Phase):addCleaner(function()
        room:handleAddLoseSkills(player, "-"..choice)
      end)
    end
  end,

  refresh_events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return target == player and data == self and
        not table.find(player.room:getOtherPlayers(player), function(p) return p:hasSkill(self, true) end)
    else
      return target == player and player:hasSkill(self, true, true) and
        not table.find(player.room:getOtherPlayers(player), function(p) return p:hasSkill(self, true) end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        room:handleAddLoseSkills(p, "bolan&", nil, false, true)
      end
    else
      for _, p in ipairs(room:getOtherPlayers(player, true, true)) do
        room:handleAddLoseSkills(p, "-bolan&", nil, false, true)
      end
    end
  end,
}
local bolan_active = fk.CreateActiveSkill{
  name = "bolan&",
  anim_type = "special",
  card_num = 0,
  target_num = 0,
  prompt = "#bolan-other",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = table.find(room:getOtherPlayers(player), function(p)
      return p:hasSkill(bolan, true)
    end)
    if not target then return end
    target:broadcastSkillInvoke("bolan")
    room:doIndicate(player.id, {target.id})
    room:loseHp(player, 1, "bolan")
    if player.dead or target.dead then return end
    local skills = table.filter(getBolanSkills(room), function (skill_name)
      return not player:hasSkill(skill_name, true)
    end)
    if #skills > 0 then
      local choice = room:askForChoice(target, table.random(skills, 3), self.name, "#bolan-choice::"..player.id, true)
      room:handleAddLoseSkills(player, choice, nil)
      room.logic:getCurrentEvent():findParent(GameEvent.Phase):addCleaner(function()
        room:handleAddLoseSkills(player, "-"..choice)
      end)
    end
  end,
}
local yifa = fk.CreateTriggerSkill{
  name = "yifa",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and data.firstTarget and
      table.contains(AimGroup:getAllTargets(data.tos), player.id) and (data.card.trueName == "slash" or
      (data.card.color == Card.Black and data.card:isCommonTrick()))
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(target, "@yifa", 1)
    player.room:broadcastProperty(target, "MaxCards")
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@yifa") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@yifa", 0)
    player.room:broadcastProperty(player, "MaxCards")
  end,
}
local yifa_maxcards = fk.CreateMaxCardsSkill{
  name = "#yifa_maxcards",
  correct_func = function(self, player)
    return -player:getMark("@yifa")
  end,
}
Fk:addSkill(bolan_active)
yifa:addRelatedSkill(yifa_maxcards)
zhongyan:addSkill(bolan)
zhongyan:addSkill(yifa)
Fk:loadTranslationTable{
  ["zhongyan"] = "钟琰",
  ["#zhongyan"] = "聪慧弘雅",
  ["illustrator:zhongyan"] = "明暗交界",
  ["bolan"] = "博览",
  [":bolan"] = "出牌阶段开始时，你可以从随机三个“出牌阶段限一次”的技能中选择一个获得直到本阶段结束；其他角色的出牌阶段限一次，其可以失去1点体力，令你从随机三个“出牌阶段限一次”的技能中选择一个，其获得之直到此阶段结束。"..
  "<br><font color='red'>村：“博览”技能池为多服扩充版，且不会出现房间禁卡",
  ["yifa"] = "仪法",
  [":yifa"] = "锁定技，当其他角色使用【杀】或黑色普通锦囊牌指定你为目标后，其手牌上限-1直到其回合结束。",
  ["bolan&"] = "博览",
  [":bolan&"] = "出牌阶段限一次，你可以失去1点体力，令钟琰从随机三个“出牌阶段限一次”的技能中选择一个，你获得之直到此阶段结束。",
  ["#bolan-choice"] = "博览：选择令 %dest 此阶段获得技能",
  ["#bolan-other"] = "博览：你可失去1点体力，令钟琰从三个“出牌阶段限一次”的技能中选择一个令你获得",
  ["@yifa"] = "仪法",

  ["$bolan1"] = "博览群书，融会贯通。",
  ["$bolan2"] = "博览于文，约之以礼。",
  ["$yifa1"] = "仪法不明，则实不称名。",
  ["$yifa2"] = "仪法明晰，则长治久安。",
  ["~zhongyan"] = "嗟尔姜任，邈不我留。",
}

local xinchang = General(extension, "xinchang", "jin", 3)
local canmou = fk.CreateTriggerSkill{
  name = "canmou",
  anim_type = "control",
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.card:isCommonTrick() and table.every(player.room:getOtherPlayers(target),
    function (p) return target:getHandcardNum() > p:getHandcardNum() end) then
      local targets = U.getUseExtraTargets(player.room, data)
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, self.cost_data, 1, 1,
    "#canmou-choose:::"..data.card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    TargetGroup:pushTargets(data.tos, self.cost_data)
  end,
}
local congjianx = fk.CreateTriggerSkill{
  name = "congjianx",
  anim_type = "control",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and data.card:isCommonTrick() and
      U.isOnlyTarget(target, data, event) and U.canTransferTarget(player, data) and
      table.every(player.room:getOtherPlayers(target), function (p) return target.hp > p.hp end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#congjianx-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    local targets = {player.id}
    if type(data.subTargets) == "table" then
      table.insertTable(targets, data.subTargets)
    end
    AimGroup:addTargets(player.room, data, targets)
    data.extra_data = data.extra_data or {}
    data.extra_data.congjianx = data.extra_data.congjianx or {}
    table.insert(data.extra_data.congjianx, player.id)
  end,
}

local congjianx_delay = fk.CreateTriggerSkill{
  name = "#congjianx_delay",
  events = {fk.CardUseFinished},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.damageDealt and data.damageDealt[player.id] and
    data.extra_data and data.extra_data.congjianx and table.contains(data.extra_data.congjianx, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, congjianx.name)
  end,
}

congjianx:addRelatedSkill(congjianx_delay)
xinchang:addSkill(canmou)
xinchang:addSkill(congjianx)
Fk:loadTranslationTable{
  ["xinchang"] = "辛敞",
  ["#xinchang"] = "英鉴中铭",
  ["illustrator:xinchang"] = "君桓文化",
  ["canmou"] = "参谋",
  [":canmou"] = "当手牌数全场唯一最多的角色使用普通锦囊牌指定目标时，你可以为此锦囊牌多指定一个目标。",
  ["congjianx"] = "从鉴",
  [":congjianx"] = "当体力值全场唯一最大的其他角色成为普通锦囊牌的唯一目标时，你可以也成为此牌目标，此牌结算后，若此牌对你造成伤害，你摸两张牌。",
  ["#canmou-choose"] = "参谋：你可以为此%arg多指定一个目标",
  ["#congjianx-invoke"] = "从鉴：你可以成为此%arg的额外目标，若此牌对你造成伤害，你摸两张牌",
  ["#congjianx_delay"] = "从鉴",

  ["$canmou1"] = "兢兢业业，竭心筹划。",
  ["$canmou2"] = "欲设此法，计谋二人。",
  ["$congjianx1"] = "为人臣属，安可不随？",
  ["$congjianx2"] = "主公有难，吾当从之。",
  ["~xinchang"] = "宪英，救我！",
}

local jiachong = General(extension, "ol__jiachong", "jin", 3)
local xiongshu = fk.CreateTriggerSkill{
  name = "xiongshu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Play and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local n = player:usedSkillTimes(self.name, Player.HistoryRound)
    local all = table.filter(player:getCardIds("he"), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end)
    if n == 0 then
      self.cost_data = {}
      return player.room:askForSkillInvoke(player, self.name, nil, "#xiongshu-invoke::"..target.id)
    elseif #all <= n then
      self.cost_data = all
      return player.room:askForSkillInvoke(player, self.name, nil, "#xiongshu-throwall::"..target.id)
    else
      local cards = player.room:askForDiscard(player, n, n, true, self.name, true, ".", "#xiongshu-cost::"..target.id..":"..n, true)
      if #cards == n then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data
    room:throwCard(cards, self.name, player, player)
    if player.dead or target.dead or target:isKongcheng() then return end
    local id = room:askForCardChosen(player, target, "h", self.name)
    target:showCards({id})
    local name = Fk:getCardById(id).trueName
    local choice = room:askForChoice(player, {"yes", "no"}, self.name, "#xiongshu-choice::"..target.id..":"..name)
    room:setPlayerMark(player, "xiongshu-phase", {id, name, choice})
  end,
}
local xiongshu_delay = fk.CreateTriggerSkill{
  name = "#xiongshu_delay",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return not target.dead and type(player:getMark("xiongshu-phase")) == "table"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("xiongshu")
    local id, name, choice = table.unpack(player:getMark("xiongshu-phase"))
    local used = "no"
    if #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data[1]
      return use.from == target.id and use.card.trueName == name
    end, Player.HistoryPhase) > 0 then
      used = "yes"
    end
    if choice == used then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = "xiongshu",
      }
    elseif table.contains(target:getCardIds("hej"), id) or room:getCardArea(id) == Card.DiscardPile or room:getCardArea(id) == Card.DrawPile then
      room:obtainCard(player, id, true, fk.ReasonPrey)
    end
  end,
}
xiongshu:addRelatedSkill(xiongshu_delay)
jiachong:addSkill(xiongshu)
local jianhui = fk.CreateTriggerSkill{
  name = "jianhui",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.Damage then
        return player:getMark(self.name) == data.to.id
      else
        return data.from and player:getMark(self.name) == data.from.id
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.Damage then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(1, self.name)
    else
      room:notifySkillInvoked(player, self.name, "control")
      if not data.from:isNude() then
        room:askForDiscard(data.from, 1, 1, true, self.name, false, ".")
      end
    end
  end,

  refresh_events = {fk.DamageFinished},
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(self, true) and target == player and data.from
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, data.from.id)
    player.room:setPlayerMark(player, "@jianhui", data.from.general)
  end,
}
jiachong:addSkill(jianhui)
Fk:loadTranslationTable{
  ["ol__jiachong"] = "贾充",
  ["#ol__jiachong"] = "鲁郡公",
  ["illustrator:ol__jiachong"] = "游漫美绘",
  ["xiongshu"] = "凶竖",
  [":xiongshu"] = "其他角色出牌阶段开始时，你可以：弃置X张牌（X为本轮你此前发动过此技能的次数；不足则全弃，无牌则不弃），展示其一张手牌，"..
  "你秘密猜测其于此出牌阶段是否会使用与此牌同名的牌。出牌阶段结束时，若你猜对，你对其造成1点伤害；若你猜错，你获得此牌。",
  ["jianhui"] = "奸回",
  [":jianhui"] = "锁定技，你记录上次对你造成伤害的角色。当你对其造成伤害后，你摸一张牌；当你受到其造成的伤害后，其弃置一张牌。",
  ["#xiongshu_delay"] = "凶竖",
  ["#xiongshu-invoke"] = "凶竖：你可以展示 %dest 的一张手牌",
  ["#xiongshu-cost"] = "凶竖：你可以弃置 %arg 张牌，展示 %dest 一张手牌",
  ["#xiongshu-throwall"] = "凶竖：你可以弃置所有牌，展示 %dest 一张手牌",
  ["#xiongshu-choice"] = "凶竖：猜测 %dest 本阶段是否会使用 %arg",
  ["yes"] = "是",
  ["no"] = "否",
  ["@jianhui"] = "奸回",

  ["$xiongshu1"] = "怀志拥权，谁敢不服？",
  ["$xiongshu2"] = "天下凶凶，由我一人。",
  ["$jianhui1"] = "一箭之仇，十年不忘！",
  ["$jianhui2"] = "此仇不报，怨恨难消！",
  ["~ol__jiachong"] = "任元褒，吾与汝势不两立！",
}

local wangxiang = General(extension, "wangxiang", "jin", 3)
local bingxin = fk.CreateViewAsSkill{
  name = "bingxin",
  pattern = ".|.|.|.|.|basic|.",
  interaction = function()
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(Self, "bingxin", all_names, {}, Self:getTableMark("bingxin-turn"))
    if #names > 0 then
      return UI.ComboBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    local mark = player:getMark("bingxin-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, Fk:cloneCard(self.interaction.data).trueName)
    player.room:setPlayerMark(player, "bingxin-turn", mark)
    player:drawCards(1, self.name)
  end,
  enabled_at_play = function(self, player)
    local cards = player.player_cards[Player.Hand]
    return #cards == player.hp and
      table.every(cards, function(id) return Fk:getCardById(id).color ==Fk:getCardById(cards[1]).color end)
  end,
  enabled_at_response = function(self, player, response)
    local cards = player.player_cards[Player.Hand]
    return not response and #cards == player.hp and
      table.every(cards, function(id) return Fk:getCardById(id).color ==Fk:getCardById(cards[1]).color end)
  end,
}
wangxiang:addSkill(bingxin)
Fk:loadTranslationTable{
  ["wangxiang"] = "王祥",
  ["#wangxiang"] = "沂川跃鲤",
  ["illustrator:wangxiang"] = "KY",
  ["bingxin"] = "冰心",
  [":bingxin"] = "若你手牌的数量等于体力值且颜色相同，你可以摸一张牌视为使用一张与本回合以此法使用过的牌牌名不同的基本牌。",

  ["$bingxin1"] = "思鸟黄雀至，卧冰鱼自跃。",
  ["$bingxin2"] = "夜静向寒月，卧冰求鲤鱼。",
  ["~wangxiang"] = "夫生之有死，自然之理也。",
}

local yangyan = General(extension, "yangyan", "jin", 3, 3, General.Female)
local xuanbei = fk.CreateActiveSkill{
  name = "xuanbei",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#xuanbei",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isAllNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "hej", self.name)
    local card = Fk:cloneCard("slash")
    card:addSubcard(id)
    local num = 1
    if U.canUseCardTo(room, target, player, card, false, false) then
      local use = {
        from = target.id,
        tos = {{player.id}},
        card = card,
        skillName = self.name,
        extraUse = true,
      }
      room:useCard(use)
      if use.damageDealt and use.damageDealt[player.id] then
        num = 2
      end
    end
    if not player.dead then
      player:drawCards(num, self.name)
    end
  end,
}
local xianwan = fk.CreateViewAsSkill{
  name = "xianwan",
  pattern = "slash,jink",
  anim_type = "defensive",
  prompt = function()
    if Self.chained then
      return "#xianwan-slash"
    else
      return "#xianwan-jink"
    end
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card
    if Self:hasSkill(self) then
      if Self.chained then
        card = Fk:cloneCard("slash")
      else
        card = Fk:cloneCard("jink")
      end
    end
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    if player.chained then
      player:setChainState(false)
    else
      player:setChainState(true)
    end
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
}
yangyan:addSkill(xuanbei)
yangyan:addSkill(xianwan)
Fk:loadTranslationTable{
  ["yangyan"] = "杨艳",
  ["#yangyan"] = "武元皇后",
  ["illustrator:yangyan"] = "游漫美绘",
  ["xuanbei"] = "选备",
  [":xuanbei"] = "出牌阶段限一次，你可以选择一名其他角色区域内的一张牌，令其将此牌当无距离限制的【杀】对你使用，若此【杀】未对你造成伤害，"..
  "你摸一张牌，否则你摸两张牌。",
  ["xianwan"] = "娴婉",
  [":xianwan"] = "你可以横置，视为使用一张【闪】；你可以重置，视为使用一张【杀】。",
  ["#xuanbei"] = "选备：选择一名角色，将其区域内一张牌当【杀】对你使用",
  ["#xianwan-slash"] = "娴婉：你可以重置，视为使用一张【杀】",
  ["#xianwan-jink"] = "娴婉：你可以横置，视为使用一张【闪】",

  ["$xuanbei1"] = "博选良家，以充后宫。",
  ["$xuanbei2"] = "非良家，不可选也。",
  ["$xianwan1"] = "婉而从物，不竞不争。",
  ["$xianwan2"] = "娴婉恭谨，重贤加礼。",
  ["~yangyan"] = "一旦殂损，痛悼伤怀……",
}

local yangzhi = General(extension, "yangzhi", "jin", 3, 3, General.Female)
local wanyi_select = fk.CreateActiveSkill{
  name = "wanyi_select",
  card_num = 1,
  target_num = 1,
  expand_pile = "wanyi",
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Self:getPileNameOfId(to_select) == "wanyi"
  end,
}
Fk:addSkill(wanyi_select)
local wanyi = fk.CreateTriggerSkill{
  name = "wanyi",
  anim_type = "control",
  derived_piles = "wanyi",
  events = {fk.TargetSpecified, fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.TargetSpecified then
        if (data.card.trueName ~= "slash" and not data.card:isCommonTrick()) or data.to == player.id then return false end
        local to = player.room:getPlayerById(data.to)
        return U.isOnlyTarget(to, data, event) and not to:isNude()
      elseif #player:getPile("wanyi") > 0 then
        if event == fk.EventPhaseStart then
          return player.phase == Player.Finish
        else
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetSpecified then
      local room = player.room
      if room:askForSkillInvoke(player, self.name, nil, "#wanyi-invoke::"..data.to) then
        room:doIndicate(player.id, {data.to})
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      local id = room:askForCardChosen(player, room:getPlayerById(data.to), "he", self.name)
      player:addToPile(self.name, id, true, self.name)
    else
      local _, dat = room:askForUseActiveSkill(player, "wanyi_select", "#wanyi-card", false, Util.DummyTable, true)
      if dat then
        room:moveCardTo(dat.cards, Card.PlayerHand, room:getPlayerById(dat.targets[1]), fk.ReasonGive, self.name, nil, true, player.id)
      else
        room:moveCardTo(player:getPile("wanyi")[1], Card.PlayerHand, player, fk.ReasonGive, self.name, nil, true, player.id)
      end
    end
  end,
}

local wanyi_prohibit = fk.CreateProhibitSkill{
  name = "#wanyi_prohibit",
  prohibit_use = function(self, player, card)
    return table.find(player:getPile("wanyi"), function(id) return Fk:getCardById(id).suit == card.suit end)
  end,
  prohibit_response = function(self, player, card)
    return table.find(player:getPile("wanyi"), function(id) return Fk:getCardById(id).suit == card.suit end)
  end,
  prohibit_discard = function(self, player, card)
    return table.find(player:getPile("wanyi"), function(id) return Fk:getCardById(id).suit == card.suit end)
  end,
}
local maihuo = fk.CreateTriggerSkill{
  name = "maihuo",
  anim_type = "defensive",
  derived_piles = "yangzhi_huo",
  events = {fk.TargetConfirmed, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(self) then return false end
    if event == fk.TargetConfirmed then
      if data.card.trueName == "slash" and U.isOnlyTarget(player, data, event) and U.isPureCard(data.card) and data.from then
        if (data.extra_data and data.extra_data.maihuo) then return false end
        local from = player.room:getPlayerById(data.from)
        return from ~= nil and not from.dead and #from:getPile("yangzhi_huo") == 0
      end
    elseif event == fk.Damage then
      --FIXME：不清楚埋祸牌是不是绑定角色，先按简单的做
      return data.to and not data.to.dead and #data.to:getPile("yangzhi_huo") > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirmed then
      if room:askForSkillInvoke(player, self.name, nil, "#maihuo-invoke::"..data.from..":"..data.card:toLogString()) then
        room:doIndicate(player.id, {data.from})
        return true
      end
    elseif event == fk.Damage then
      room:doIndicate(player.id, {data.to.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirmed then
      table.insertIfNeed(data.nullifiedTargets, player.id)
      if room:getCardArea(data.card) == Card.Processing then
        room:doIndicate(player.id, {data.from})
        local to = room:getPlayerById(data.from)
        to:addToPile("yangzhi_huo", data.card, true, self.name)
        room:setPlayerMark(to, self.name, {player.id, data.card.id})
      end
    elseif event == fk.Damage then
      room:setPlayerMark(data.to, self.name, 0)
      room:moveCards({
        from = data.to.id,
        ids = data.to:getPile("yangzhi_huo"),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
      })
    end
  end,
}
local maihuo_delay = fk.CreateTriggerSkill{
  name = "#maihuo_delay",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player == target and player.phase == Player.Play and #player:getPile("yangzhi_huo") > 0 and not player.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("maihuo")[1])
    local card = Fk:getCardById(player:getPile("yangzhi_huo")[1])
    room:setPlayerMark(player, "maihuo", 0)
    if U.canUseCardTo(room, player, to, card, true, true) then
      room:useCard({
        from = player.id,
        tos = {{to.id}},
        card = card,
        extraUse = false,
        extra_data = {maihuo = true},
      })
    else
      room:moveCards({
        from = player.id,
        ids = player:getPile("yangzhi_huo"),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = "maihuo",
      })
    end
  end,
}
wanyi:addRelatedSkill(wanyi_prohibit)
maihuo:addRelatedSkill(maihuo_delay)
yangzhi:addSkill(wanyi)
yangzhi:addSkill(maihuo)
Fk:loadTranslationTable{
  ["yangzhi"] = "杨芷",
  ["#yangzhi"] = "武悼皇后",
  ["illustrator:yangzhi"] = "游漫美绘",
  ["wanyi"] = "婉嫕",
  [":wanyi"] = "当你使用【杀】或普通锦囊牌指定唯一其他角色为目标后，你可以将其一张牌置于你的武将牌上。"..
  "你不能使用、打出、弃置与“婉嫕”牌花色相同的牌。结束阶段或当你受到伤害后，你令一名角色获得一张“婉嫕”牌。",
  ["maihuo"] = "埋祸",
  [":maihuo"] = "其他角色非因本技能使用的非转化的【杀】指定你为唯一目标后，若其没有“祸”，你可以令此【杀】对你无效并将之置于其武将牌上，称为“祸”，"..
  "其下个出牌阶段开始时对你使用此【杀】（须合法且有次数限制，不合法则移去之）。当你对其他角色造成伤害后，你移去其武将牌上的“祸”。",
  ["#wanyi-invoke"] = "婉嫕：你可以将 %dest 的一张牌置于你的武将牌上",
  ["wanyi_select"] = "婉嫕",
  ["#wanyi-card"] = "婉嫕：令一名角色获得一张“婉嫕”牌",
  ["yangzhi_huo"] = "祸",
  ["#maihuo-invoke"] = "埋祸：你可以令 %dest 对你使用的%arg无效并将之置为其“祸”，延迟到其下个出牌阶段对你使用",
  ["#maihuo_delay"] = "埋祸",

  ["$wanyi1"] = "天性婉嫕，易以道御。",
  ["$wanyi2"] = "婉嫕利珍，为后攸行。",
  ["$maihuo1"] = "祸根未决，转而滋蔓。",
  ["$maihuo2"] = "无德之亲，终为祸根。",
  ["~yangzhi"] = "贾氏……构陷……",
}

local wangyan = General(extension, "wangyan", "jin", 3)
local yangkuang = fk.CreateTriggerSkill{
  name = "yangkuang",
  anim_type = "control",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and not player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#yangkuang-invoke"
    if room.current and not room.current.dead then
      prompt = "#yangkuang2-invoke::"..room.current.id
    end
    return room:askForSkillInvoke(player, self.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:canUse(Fk:cloneCard("analeptic")) then
      room:useVirtualCard("analeptic", nil, player, player, self.name)
    end
    if not player.dead then
      player:drawCards(1, self.name)
    end
    if room.current and not room.current.dead then
      room.current:drawCards(1, self.name)
    end
  end,
}
local cihuang_active = fk.CreateActiveSkill{
  name = "cihuang_active",
  card_num = 1,
  target_num = 0,
  interaction = function()
    return UI.ComboBox {choices = Self:getMark("cihuang_names")}
  end,
  card_filter = function(self, to_select, selected)
    if #selected ~= 0 or not self.interaction.data then return false end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(to_select)
    card.skillName = "cihuang"
    local to = Fk:currentRoom():getPlayerById(self.cihuang_to)
    return not Self:isProhibited(to, card) and not Self:prohibitUse(card)
  end,
}
local cihuang = fk.CreateTriggerSkill{
  name = "cihuang",
  anim_type = "control",
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.from and player.room:getPlayerById(data.from).phase ~= Player.NotActive and
      data.tos and #TargetGroup:getRealTargets(data.tos) == 1 and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    local mark = player:getTableMark("cihuang-round")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(mark, card.name) and card.skill:getMinTargetNum() < 2 then
        if not (card.skill:getMinTargetNum() == 0 and data.from ~= player.id and not card.multiple_targets) then
          if not card.is_derived and card.skill:modTargetFilter(data.from, {}, player.id, card, true) then
            if (card.trueName == "slash" and card.name ~= "slash") or (card:isCommonTrick() and not card.multiple_targets) then
              table.insertIfNeed(names, card.name)
            end
          end
        end
      end
    end
    if #names == 0 then return false end
    room:setPlayerMark(player, "cihuang_names", names)
    local _,dat = room:askForUseActiveSkill(player, "cihuang_active", "#cihuang-invoke::"..data.from, true, {cihuang_to = data.from})
    if dat then
      self.cost_data = {
        cards = dat.cards,
        interaction_data = dat.interaction,
      }
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard(self.cost_data.interaction_data)
    card:addSubcards(self.cost_data.cards)
    card.skillName = self.name
    room:useCard{
      from = player.id,
      tos = {{room.current.id}},
      card = card,
      disresponsiveList = table.map(room.alive_players, Util.IdMapper),
    }
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return target == player and (data.card.trueName == "slash" or data.card.type == Card.TypeTrick)
    else
      return target == player and data == self and player.room:getTag("RoundCount")
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      local mark = player:getTableMark("cihuang-round")
      table.insertIfNeed(mark, data.card.name)
      room:setPlayerMark(player, "cihuang-round", mark)
    else
      local mark = {}
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        if use.from == player.id then
          table.insertIfNeed(mark, use.card.name)
        end
        return false
      end, Player.HistoryRound)
      room:setPlayerMark(player, "cihuang-round", mark)
    end
  end,
}
local sanku = fk.CreateTriggerSkill{
  name = "sanku",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying, fk.BeforeMaxHpChanged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      return event == fk.EnterDying or (event == fk.BeforeMaxHpChanged and data.num > 0)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EnterDying then
      room:changeMaxHp(player, -1)
      if not player.dead then
        room:recover({
          who = player,
          num = player.maxHp - player.hp,
          recoverBy = player,
          skillName = self.name
        })
      end
    else
      return true
    end
  end,
}
Fk:addSkill(cihuang_active)
wangyan:addSkill(yangkuang)
wangyan:addSkill(cihuang)
wangyan:addSkill(sanku)
Fk:loadTranslationTable{
  ["wangyan"] = "王衍",
  ["#wangyan"] = "玄虚陆沉",
  ["designer:wangyan"] = "玄蝶既白",
  ["illustrator:wangyan"] = "匠人绘",

  ["yangkuang"] = "阳狂",
  [":yangkuang"] = "当你回复体力至上限后，你可以视为使用一张【酒】并与当前回合角色各摸一张牌。",
  ["cihuang"] = "雌黄",
  [":cihuang"] = "当前回合角色对唯一目标使用的牌被抵消后，你可以将一张牌当一张本轮你未使用过的属性【杀】或单一目标普通锦囊牌对使用者使用且此牌不能被响应。",
  ["sanku"] = "三窟",
  [":sanku"] = "锁定技，当你进入濒死状态时，你减1点体力上限并回复体力至上限；当你的体力上限增加时，你防止之。",
  ["#yangkuang-invoke"] = "阳狂：你可以视为使用【酒】并摸一张牌",
  ["#yangkuang2-invoke"] = "阳狂：你可以视为使用【酒】并与 %dest 各摸一张牌",
  ["#cihuang-invoke"] = "雌黄：选择一张牌，将之当属性【杀】或单目标锦囊对 %dest 使用",
  ["cihuang_active"] = "雌黄",

  ["$yangkuang1"] = "比干忠谏剖心死，箕子披发阳狂生。",
  ["$yangkuang2"] = "梅伯数谏遭炮烙，来革顺志而用国。",
  ["$cihuang1"] = "腹存经典，口吐雌黄。",
  ["$cihuang2"] = "手把玉麈，胸蕴成篇。",
  ["$sanku1"] = "纲常难为，应存后路。",
  ["$sanku2"] = "世将大乱，当思保全。",
  ["~wangyan"] = "影摇枭鸱动，三窟难得生。",
}

return extension
