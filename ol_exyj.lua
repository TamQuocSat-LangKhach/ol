local extension = Package("ol_exyj")
extension.extensionName = "ol"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_exyj"] = "OL-界一将成名",
}

local fazheng = General(extension, "ol_ex__fazheng", "shu", 3)
local ol_ex__xuanhuo = fk.CreateTriggerSkill{
  name = "ol_ex__xuanhuo",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw and player:getHandcardNum() > 1 and
      #player.room.alive_players > 1
  end,
  on_cost = function(self, event, target, player, data)
    local _, dat = player.room:askForUseActiveSkill(player, "ol_ex__xuanhuo_choose", "#ol_ex__xuanhuo-invoke", true)
    if dat then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.targets[1])
    room:moveCardTo(self.cost_data.cards, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
    if to.dead then return end
    local victim = room:getPlayerById(self.cost_data.targets[2])
    local use = room:askForUseCard(to, "slash", nil, "#ol_ex__xuanhuo-use:"..player.id..":"..victim.id, nil,
      {must_targets = {victim.id}, bypass_times = true, bypass_distances = true})
    if use then
      use.extraUse = true
      room:useCard(use)
    else
      if player.dead or to.dead or to:isNude() then return end
      local cards = U.askforChooseCardsAndChoice(player, to:getCardIds("he"), {"OK"}, self.name,
        "#ol_ex__xuanhuo-prey::"..to.id, {}, math.min(#to:getCardIds("he"), 2), 2)
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, self.name, nil, false)
    end
  end,
}
local ol_ex__xuanhuo_choose = fk.CreateActiveSkill{
  name = "ol_ex__xuanhuo_choose",
  card_num = 2,
  target_num = 2,
  card_filter = function(self, to_select, selected)
    return #selected < 2 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, cards)
    if #cards == 2 then
      return #selected == 0 and to_select ~= Self.id or #selected == 1
    end
  end,
}
local ol_ex__enyuan = fk.CreateTriggerSkill{
  name = "ol_ex__enyuan",
  mute = true,
  anim_type = "masochism",
  events = {fk.AfterCardsMove, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.from and move.from ~= player.id and move.to == player.id and move.toArea == Card.PlayerHand and #move.moveInfo > 1 then
          self.cost_data = move.from
          return true
        end
      end
    elseif target == player and data.from and not data.from.dead and not player.dead then
      self.cost_data = data.from.id
      return true
    end
  end,
  on_trigger = function(self, event, target, player, data)
    if event == fk.Damaged then
      self.cancel_cost = false
      for i = 1, data.damage do
        if self.cancel_cost or player.dead or player.room:getPlayerById(self.cost_data).dead then
          break
        end
        self:doCost(event, target, player, {self.cost_data})
      end
    else
      self:doCost(event, target, player, {self.cost_data})
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#ol_ex__enyuan"
    if event == fk.Damaged then
      prompt = prompt.."2-invoke::"..data[1]
    else
      prompt = prompt.."1-invoke::"..data[1]
    end
    if player.room:askForSkillInvoke(player, self.name, data, prompt) then
      self.cost_data = data[1]
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:doIndicate(player.id, {self.cost_data})
    if event ==  fk.AfterCardsMove then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "support")
      to:drawCards(1, self.name)
    else
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name)
      local card = room:askForCard(to, 1, 1, false, self.name, true, ".|.|heart,diamond|hand|.|.", "#ol_ex__enyuan-give:"..player.id)
      if #card > 0 then
        room:moveCardTo(card, Player.Hand, player, fk.ReasonGive, self.name, nil, false)
      else
        room:loseHp(to, 1, self.name)
      end
    end
  end,
}
Fk:addSkill(ol_ex__xuanhuo_choose)
fazheng:addSkill(ol_ex__xuanhuo)
fazheng:addSkill(ol_ex__enyuan)
Fk:loadTranslationTable{
  ["ol_ex__fazheng"] = "界法正",
  ["#ol_ex__fazheng"] = "蜀汉的辅翼",
  --["designer:ol_ex__fazheng"] = "玄蝶既白",
  --["illustrator:ol_ex__fazheng"] = "君桓文化",

  ["ol_ex__xuanhuo"] = "眩惑",
  [":ol_ex__xuanhuo"] = "摸牌阶段结束时，你可以交给一名其他角色两张牌，令其选择一项：1.对你指定的另一名角色使用一张【杀】；2.你观看其手牌并"..
  "获得其两张牌。",
  ["ol_ex__enyuan"] = "恩怨",
  [":ol_ex__enyuan"] = "当你获得一名其他角色至少两张牌后，你可以令其摸一张牌。当你受到1点伤害后，你可以令伤害来源选择一项：1.交给你一张红色手牌；"..
  "2.失去1点体力。",

  ["ol_ex__xuanhuo_choose"] = "眩惑",
  ["#ol_ex__xuanhuo-invoke"] = "眩惑：交给第一名角色两张手牌，令其选择对第二名角色使用【杀】或你获得其两张牌",
  ["#ol_ex__xuanhuo-use"] = "眩惑：你需对 %dest 使用一张【杀】，否则 %src 观看你手牌并获得你两张牌",
  ["#ol_ex__xuanhuo-prey"] = "眩惑：获得 %dest 两张牌",
  ["#ol_ex__enyuan1-invoke"] = "恩怨：是否令 %dest 摸一张牌？",
  ["#ol_ex__enyuan2-invoke"] = "恩怨：是否令 %dest 选择交给你牌或失去体力？",
  ["#ol_ex__enyuan-give"] = "交给 %src 一张红色手牌，否则你失去1点体力",
}

local lingtong = General(extension, "ol_ex__lingtong", "wu", 4)
local ol_ex__xuanfeng = fk.CreateTriggerSkill{
  name = "ol_ex__xuanfeng",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.from == player.id then
          local n = 0
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              n = n + 1
            elseif info.fromArea == Card.PlayerEquip then
              n = 2
            end
          end
          if n > 1 then
            return table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper)
    while player.room:askForSkillInvoke(player, self.name) do
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#xuanfeng-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCardChosen(player, to, "he", self.name)
    room:throwCard({card}, self.name, to, player)
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper)
    if #targets == 0 or player.dead then return end
    to = room:askForChoosePlayers(player, targets, 1, 1, "#xuanfeng-choose", self.name, true)
    if #to > 0 then
      to = room:getPlayerById(to[1])
      card = room:askForCardChosen(player, to, "he", self.name)
      room:throwCard({card}, self.name, to, player)
    end
  end,
}
lingtong:addSkill(ol_ex__xuanfeng)
Fk:loadTranslationTable{
  ["ol_ex__lingtong"] = "界凌统",
  ["#ol_ex__lingtong"] = "豪情烈胆",
  ["designer:ol_ex__lingtong"] = "玄蝶既白",
  ["illustrator:ol_ex__lingtong"] = "君桓文化",

  ["ol_ex__xuanfeng"] = "旋风",
  [":ol_ex__xuanfeng"] = "当你失去装备区里的牌后，或一次性失去至少两张牌后，你可以依次弃置至多两名其他角色共计至多两张牌。",

  ["$ol_ex__xuanfeng1"] = "短兵相接，让敌人丢盔弃甲！",
  ["$ol_ex__xuanfeng2"] = "攻敌不备，看他们闻风而逃！",
  ["~ol_ex__lingtong"] = "先……停一下吧……",
}

-- yj2012
local ol_ex__caozhang = General(extension, "ol_ex__caozhang", "wei", 4)
local ol_ex__jiangchi_select = fk.CreateActiveSkill{
  name = "ol_ex__jiangchi_select",
  target_num = 0,
  max_card_num = 1,
  min_card_num = 0,
  interaction = function()
    return UI.ComboBox {choices = {"ol_ex__jiangchi1", "ol_ex__jiangchi2"}}
  end,
  card_filter = function(self, to_select, selected)
    return (self.interaction or {}).data == "ol_ex__jiangchi2" and #selected == 0
  end,
}
local ol_ex__jiangchi = fk.CreateTriggerSkill{
  name = "ol_ex__jiangchi",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local _, ret = player.room:askForUseActiveSkill(player, "ol_ex__jiangchi_select", "#ol_ex__jiangchi-invoke", true)
    if ret then
      self.cost_data = ret.cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #self.cost_data > 0 then
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke(self.name, 2)
      room:recastCard(self.cost_data, player, self.name)
      room:addPlayerMark(player, "ol_ex__jiangchi_plus-turn")
    else
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name, 1)
      player:drawCards(1, self.name)
      room:addPlayerMark(player, "ol_ex__jiangchi_minus-turn")
    end
  end,
}
local ol_ex__jiangchi_targetmod = fk.CreateTargetModSkill{
  name = "#ol_ex__jiangchi_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      local n = 0
      if player:getMark("ol_ex__jiangchi_plus-turn") > 0 then
        n = n + 1
      end
      if player:getMark("ol_ex__jiangchi_minus-turn") > 0 then
        n = n - 1
      end
      return n
    end
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return skill.trueName == "slash_skill" and player:getMark("ol_ex__jiangchi_plus-turn") > 0
  end,
}
local ol_ex__jiangchi_maxcards = fk.CreateMaxCardsSkill{
  name = "#ol_ex__jiangchi_maxcards",
  exclude_from = function(self, player, card)
    return card and card.trueName == "slash" and player:getMark("ol_ex__jiangchi_minus-turn") > 0
  end,
}
Fk:addSkill(ol_ex__jiangchi_select)
ol_ex__jiangchi:addRelatedSkill(ol_ex__jiangchi_targetmod)
ol_ex__jiangchi:addRelatedSkill(ol_ex__jiangchi_maxcards)
ol_ex__caozhang:addSkill(ol_ex__jiangchi)

Fk:loadTranslationTable{
  ["ol_ex__caozhang"] = "界曹彰",
  ["#ol_ex__caozhang"] = "黄须儿",
  ["designer:ol_ex__caozhang"] = "玄蝶既白",
  ["illustrator:ol_ex__caozhang"] = "枭瞳",
  ["ol_ex__jiangchi"] = "将驰",
  [":ol_ex__jiangchi"] = "摸牌阶段结束时，你可以选择一项：1.摸一张牌，本回合使用【杀】的次数上限-1，且【杀】不计入手牌上限；2.重铸一张牌，本回合使用【杀】无距离限制且次数上限+1。",
  ["#ol_ex__jiangchi-invoke"] = "1.摸一张牌，【杀】次数-1，不计入手牌上限；2.重铸一张牌，【杀】次数+1，无距离限制",
  ["ol_ex__jiangchi_select"] = "将驰",
  ["ol_ex__jiangchi1"] = "摸牌，少用【杀】",
  ["ol_ex__jiangchi2"] = "重铸，多用【杀】",
  ["$ol_ex__jiangchi1"] = "丈夫当将十万骑驰沙漠，立功建号耳。",
  ["$ol_ex__jiangchi2"] = "披坚执锐，临危不难，身先士卒。",
  ["~ol_ex__caozhang"] = "黄须儿，愧对父亲……",
}

local wangyi = General(extension, "ol_ex__wangyi", "wei", 3, 3, General.Female)
local miji = fk.CreateTriggerSkill{
  name = "ol_ex__miji",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getLostHp()
    room:drawCards(player, n, self.name)
    if player.dead or player:isNude() then return false end
    n = player:getLostHp()
    if n > 0 then
      U.askForDistribution(player, player:getCardIds("he"), room:getOtherPlayers(player, false), self.name, 0, n)
    end
  end,
}
local zhenlie = fk.CreateTriggerSkill{
  name = "ol_ex__zhenlie",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and
      (data.card:isCommonTrick() or data.card.trueName == "slash")
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, "#ol_ex__zhenlie-invoke:" .. data.from .. "::" .. data.card:toLogString()) then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    if player.dead then return false end
    table.insertIfNeed(data.nullifiedTargets, player.id)
    local choices = {}
    local to = room:getPlayerById(data.from)
    if not (to.dead or to:isNude()) then
      table.insert(choices, "ol_ex__zhenlie_prey")
    end
    if player:isWounded() and player:hasSkill(miji) then
      table.insert(choices, "ol_ex__zhenlie_miji")
    end
    if #choices == 0 then return false end
    local choice = room:askForChoice(player, choices, self.name, "", false, {"ol_ex__zhenlie_prey", "ol_ex__zhenlie_miji"})
    if choice == "ol_ex__zhenlie_prey" then
      local id = room:askForCardChosen(player, to, "he", self.name)
      room:obtainCard(player.id, id, false, fk.ReasonPrey, player.id)
    elseif choice == "ol_ex__zhenlie_miji" then
      room:notifySkillInvoked(player, "ol_ex__miji")
      player:broadcastSkillInvoke("ol_ex__miji")
      miji:use(event, target, player, data)
    end
  end,
}
wangyi:addSkill(zhenlie)
wangyi:addSkill(miji)
Fk:loadTranslationTable{
  ["ol_ex__wangyi"] = "界王异",
  ["#ol_ex__wangyi"] = "决意的巾帼",
  --["designer:ol_ex__wangyi"] = "",
  --["illustrator:ol_ex__wangyi"] = "",
  ["ol_ex__zhenlie"] = "贞烈",
  [":ol_ex__zhenlie"] = "当你成为【杀】或普通锦囊牌的目标后，若使用者不为你，你可以失去1点体力，令此牌对你无效，你选择：1.获得使用者的一张牌；2.发动〖秘计〗。",
  ["ol_ex__miji"] = "秘计",
  [":ol_ex__miji"] = "结束阶段，若你已受伤，你可以摸X张牌，然后可以将至多X张牌交给其他角色。（X为你已损失的体力值）",
  ["#ol_ex__zhenlie-invoke"] = "是否对%src发动 贞烈，令其使用的%arg对你无效",
  ["ol_ex__zhenlie_prey"] = "获得使用者一张牌",
  ["ol_ex__zhenlie_miji"] = "发动一次“秘计”",

  ["$ol_ex__zhenlie1"] = "",
  ["$ol_ex__zhenlie2"] = "",
  ["$ol_ex__miji1"] = "",
  ["$ol_ex__miji2"] = "",
  ["~ol_ex__wangyi"] = "",
}

-- yj2013
local yufan = General(extension, "ol_ex__yufan", "wu", 3)
local zongxuan = fk.CreateTriggerSkill{
  name = "ol_ex__zongxuan",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local cards1, cards2 = {}, {}
      local room = player.room
      local last_player_id = 0
      local last_player
      local mark = 0
      local move_event = room.logic:getCurrentEvent():findParent(GameEvent.MoveCards, true)
      if not player:isRemoved() then
        last_player = player:getLastAlive(false)
        if last_player ~= player and move_event ~= nil then
          mark = last_player:getMark("ol_ex__zongxuan_record-turn")
          if mark == 0 or mark == move_event.id then
            last_player_id = last_player.id
          end
        end
      end
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              room:getCardArea(info.cardId) == Card.DiscardPile then
                table.insertIfNeed(cards1, info.cardId)
              end
            end
          elseif move.from == last_player_id then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              room:getCardArea(info.cardId) == Card.DiscardPile then
                table.insertIfNeed(cards2, info.cardId)
              end
            end
          end
        end
      end
      cards1 = U.moveCardsHoldingAreaCheck(room, cards1)
      if #cards2 > 0 then
        if mark == 0 then
          room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
            for _, move in ipairs(e.data) do
              if move.from == last_player_id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard and
              table.find(move.moveInfo, function (info)
                return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
              end) then
                mark = e.id
                room:setPlayerMark(last_player, "ol_ex__zongxuan_record-turn", mark)
                return true
              end
            end
            return false
          end, Player.HistoryTurn)
          if mark ~= move_event.id then
            cards2 = {}
          end
        end
      end
      if #cards2 > 0 then
        table.insertTable(cards1, U.moveCardsHoldingAreaCheck(room, cards2))
      end
      if #cards1 > 0 then
        self.cost_data = cards1
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local top = U.askForArrangeCards(player, self.name, {self.cost_data, "pile_discard","Top"},
    "#ol_ex__zongxuan-invoke", true, 7, nil, {0, 1})[2]
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
  end,
}
local zhiyan = fk.CreateTriggerSkill{
  name = "ol_ex__zhiyan",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and (target == player or target:getNextAlive() == player) and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, "#ol_ex__zhiyan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local ids = to:drawCards(1, self.name)
    if #ids == 0 then return false end
    local id = ids[1]
    if room:getCardOwner(id) ~= to or room:getCardArea(id) ~= Card.PlayerHand then return false end
    local card = Fk:getCardById(id)
    to:showCards(card)
    if to.dead then return false end
    room:delay(1000)
    if card.type == Card.TypeEquip then
      if to:canUseTo(card, to) then
        room:useCard({
          from = to.id,
          tos = {{to.id}},
          card = card,
        })
        if to:isWounded() and not to.dead then
          room:recover({
            who = to,
            num = 1,
            recoverBy = player,
            skillName = self.name
          })
        end
      end
    elseif to.hp >= player.hp then
      room:loseHp(to, 1, self.name)
    end
  end,
}
yufan:addSkill(zongxuan)
yufan:addSkill(zhiyan)
Fk:loadTranslationTable{
  ["ol_ex__yufan"] = "界虞翻",
  ["#ol_ex__yufan"] = "狂直之士",
  --["designer:ol_ex__yufan"] = "",
  ["illustrator:ol_ex__yufan"] = "YanBai",
  ["ol_ex__zongxuan"] = "纵玄",
  [":ol_ex__zongxuan"] = "当你的牌因弃置而置入弃牌堆后，或你上家的牌于当前回合内第一次因弃置而置入弃牌堆后，"..
  "你可以将其中任意张牌置于牌堆顶。",
  ["ol_ex__zhiyan"] = "直言",
  [":ol_ex__zhiyan"] = "你或你上家的结束阶段，你可以令一名角色摸一张牌并展示之，若此牌：为装备牌，其使用此牌并回复1点体力；"..
  "不为装备牌且其体力值不小于你，其失去1点体力。",

  ["#ol_ex__zongxuan-invoke"] = "纵玄：将任意数量的弃牌置于牌堆顶",
  ["#ol_ex__zhiyan-choose"] = "是否发动 直言，令一名角色摸一张牌",
  ["#PutKnownCardtoDrawPile"] = "%from 将 %card 置于牌堆顶",

  ["$ol_ex__zongxuan1"] = "",
  ["$ol_ex__zongxuan2"] = "",
  ["$ol_ex__zhiyan1"] = "",
  ["$ol_ex__zhiyan2"] = "",
  ["~ol_ex__yufan"] = "",
}

local ol_ex__jianyong = General(extension, "ol_ex__jianyong", "shu", 3)
local ol_ex__qiaoshui = fk.CreateActiveSkill{
  name = "ol_ex__qiaoshui",
  anim_type = "control",
  prompt = "#ol_ex__qiaoshui-prompt",
  can_use = function(self, player)
    return not player:isKongcheng() and player:getMark("ol_ex__qiaoshui_fail-turn") == 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:broadcastSkillInvoke("m_ex__qiaoshui")
    local to = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({to}, self.name)
    if player.dead then return end
    if pindian.results[to.id].winner == player then
      room:setPlayerMark(player, "@@ol_ex__qiaoshui-turn", 1)
    else
      room:setPlayerMark(player, "ol_ex__qiaoshui_fail-turn", 1)
    end
  end,
}
local ol_ex__qiaoshui_delay = fk.CreateTriggerSkill{
  name = "#ol_ex__qiaoshui_delay",
  events = {fk.AfterCardTargetDeclared},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@ol_ex__qiaoshui-turn") > 0
    and data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@ol_ex__qiaoshui-turn", 0)
    local targets = U.getUseExtraTargets(room, data, true)
    if #TargetGroup:getRealTargets(data.tos) > 1 then
      table.insertTable(targets, TargetGroup:getRealTargets(data.tos))
    end
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#ol_ex__qiaoshui-choose:::"
    ..data.card:toLogString(), ol_ex__qiaoshui.name, true)
    if #tos == 0 then return false end
    if table.contains(TargetGroup:getRealTargets(data.tos), tos[1]) then
      TargetGroup:removeTarget(data.tos, tos[1])
      room:sendLog{ type = "#RemoveTargetsBySkill", from = target.id, to = tos, arg = ol_ex__qiaoshui.name, arg2 = data.card:toLogString() }
    else
      table.insert(data.tos, tos)
      room:sendLog{ type = "#AddTargetsBySkill", from = target.id, to = tos, arg = ol_ex__qiaoshui.name, arg2 = data.card:toLogString() }
    end
  end,
}
ol_ex__qiaoshui:addRelatedSkill(ol_ex__qiaoshui_delay)
local ol_ex__qiaoshui_prohibit = fk.CreateProhibitSkill{
  name = "#ol_ex__qiaoshui_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("ol_ex__qiaoshui_fail-turn") > 0 and card and card.type == Card.TypeTrick
  end,
}
ol_ex__qiaoshui:addRelatedSkill(ol_ex__qiaoshui_prohibit)
ol_ex__jianyong:addSkill(ol_ex__qiaoshui)
ol_ex__jianyong:addSkill("zongshij")
Fk:loadTranslationTable{
  ["ol_ex__jianyong"] = "界简雍",
  ["#ol_ex__jianyong"] = "悠游风议",

  ["ol_ex__qiaoshui"] = "巧说",
  [":ol_ex__qiaoshui"] = "出牌阶段，你可以与一名角色拼点。若你赢，本回合你使用下一张基本牌或普通锦囊牌可以多或少选择一个目标（无距离限制）；若你没赢，此技能失效且你不能使用锦囊牌直到回合结束。",
  ["#ol_ex__qiaoshui-choose"] = "巧说：你可以为%arg增加/减少一个目标",
  ["@@ol_ex__qiaoshui-turn"] = "巧说",
  ["#ol_ex__qiaoshui-prompt"] = "巧说:与一名角色拼点，若赢，下一张基本牌或普通锦囊牌可增加或取消一个目标",
}

-- yj2014
local ol_ex__caifuren = General(extension, "ol_ex__caifuren", "qun", 3, 3, General.Female)
local ol_ex__qieting = fk.CreateTriggerSkill{
  name = "ol_ex__qieting",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Finish
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local n = 0
    if #room.logic:getEventsOfScope(GameEvent.Damage, 1, function(e)
      local damage = e.data[1]
      return damage.from and damage.from == target
    end, Player.HistoryTurn) == 0 then
      n = 1
    end
    if #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data[1]
      if use.from == target.id and use.tos then
        if table.find(TargetGroup:getRealTargets(use.tos), function(pid) return pid ~= target.id end) then
          return true
        end
      end
      return false
    end, Player.HistoryTurn) == 0 then
      n = 2
    end
    if n > 0 then
      local all_choices = {"ol_ex__qieting_move::"..target.id, "draw1", "Cancel"}
      local choices = table.simpleClone(all_choices)
      self.cost_data = ""
      self.cancel_cost = false
      for i = 1, n, 1 do
        table.removeOne(choices, self.cost_data)
        if #choices == 3 and not target:canMoveCardsInBoardTo(player, "e") then
          table.remove(choices, 1)
        end
        if player.dead or #choices < 2 or self.cancel_cost then return end
        self:doCost(event, target, player, {choices, all_choices, n})
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local choice = player.room:askForChoice(player, data[1], self.name, "#ol_ex__qieting-invoke:::"..data[3], false, data[2])
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    if self.cost_data == "draw1" then
      player:drawCards(1, self.name)
    else
      player.room:askForMoveCardInBoard(player, target, player, self.name, "e", target)
    end
  end,
}
ol_ex__caifuren:addSkill(ol_ex__qieting)
ol_ex__caifuren:addSkill("xianzhou")  --辣鸡策划真摆
Fk:loadTranslationTable{
  ["ol_ex__caifuren"] = "界蔡夫人",
  ["#ol_ex__caifuren"] = "襄江的蒲苇",

  ["ol_ex__qieting"] = "窃听",
  [":ol_ex__qieting"] = "其他角色的回合结束后，若其本回合未对其他角色造成伤害，你可以选择一项；若其本回合未对其他角色使用过牌，你可以选择两项："..
  "1.将其装备区的一张牌置入你的装备区；2.摸一张牌。",
  ["ol_ex__qieting_move"] = "将%dest一张装备移动给你",
  ["#ol_ex__qieting-invoke"] = "窃听：你可以选择%arg项",
}




return extension
