
Fk:loadTranslationTable{
  ["ol_re"] = "OL专属",
}

local ol__sunliang = General(extension, "ol__sunliang", "wu", 3)
local ol__kuizhu_active = fk.CreateActiveSkill{
  name = "ol__kuizhu_active",
  anim_type = "control",
  interaction = function()
    return UI.ComboBox {choices = {"ol__kuizhu_choice1", "ol__kuizhu_choice2"}}
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  min_target_num = 1,
  target_filter = function(self, to_select, selected)
    if self.interaction.data == "ol__kuizhu_choice1" then
      return #selected < Self:getMark("ol__kuizhu")
    elseif self.interaction.data == "ol__kuizhu_choice2" then
      local n = Fk:currentRoom():getPlayerById(to_select).hp
      for _, p in ipairs(selected) do
        n = n + Fk:currentRoom():getPlayerById(p).hp
      end
      return n <= Self:getMark("ol__kuizhu")
    end
    return false
  end,
  feasible = function(self, selected, selected_cards)
    if #selected_cards ~= 0 or #selected == 0 then return false end
    if self.interaction.data == "ol__kuizhu_choice1" then
      return #selected <= Self:getMark("ol__kuizhu")
    elseif self.interaction.data == "ol__kuizhu_choice2" then
      local n = 0
      for _, p in ipairs(selected) do
        n = n + Fk:currentRoom():getPlayerById(p).hp
      end
      return n == Self:getMark("ol__kuizhu")
    end
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if self.interaction.data == "ol__kuizhu_choice1" then
      room:setPlayerMark(player, "ol__kuizhu_choice", 1)
    else
      room:setPlayerMark(player, "ol__kuizhu_choice", 2)
    end
  end,
}
Fk:addSkill(ol__kuizhu_active)
local ol__kuizhu = fk.CreateTriggerSkill{
  name = "ol__kuizhu",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Discard and #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile and move.from == player.id and move.moveReason == fk.ReasonDiscard then
          return true
        end
      end
      return false
    end, Player.HistoryPhase) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile and move.from == player.id and move.moveReason == fk.ReasonDiscard then
          n = n + #move.moveInfo
        end
      end
      return false
    end, Player.HistoryPhase)
    if n == 0 then return false end
    room:setPlayerMark(player, self.name, n)
    local success, dat = room:askForUseActiveSkill(player, "ol__kuizhu_active", "#ol__kuizhu-use:::"..n, true)
    local choice = player:getMark("ol__kuizhu_choice")
    if success then
      self.cost_data = {dat.targets, choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    local tos = table.map(self.cost_data[1], Util.Id2PlayerMapper)
    local choice = self.cost_data[2]
    if choice == 1 then
      room:notifySkillInvoked(player, self.name, "support")
      for _, p in ipairs(tos) do
        if not p.dead then
          p:drawCards(1, self.name)
        end
      end
    else
      room:notifySkillInvoked(player, self.name, "offensive")
      for _, p in ipairs(tos) do
        if not p.dead then
          room:damage { from = player, to = p, damage = 1, skillName = self.name }
        end
      end
    end
  end,
}
ol__sunliang:addSkill(ol__kuizhu)
local ol__chezheng = fk.CreateTriggerSkill{
  name = "ol__chezheng",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseEnd, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      if event == fk.EventPhaseEnd then
        local targets = table.filter(player.room:getOtherPlayers(player, false), function(p) return not p:inMyAttackRange(player) end)
        local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function (e)
          local use = e.data[1]
          return use and use.from == target.id
        end, Player.HistoryPhase)
        return #events < #targets
      else
        return not data.to:inMyAttackRange(player)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      local targets = table.filter(room:getOtherPlayers(player, false), function(p) return not p:inMyAttackRange(player) and not p:isNude() end)
      if #targets > 0 then
        local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#ol__chezheng-throw", self.name, false)
        if #tos > 0 then
          local to = room:getPlayerById(tos[1])
          local cid = room:askForCardChosen(player, to, "he", self.name)
          room:throwCard({cid}, self.name, to, player)
        end
      end
    else
      return true
    end
  end,
}
ol__sunliang:addSkill(ol__chezheng)
local ol__lijun = fk.CreateTriggerSkill{
  name = "ol__lijun$",
  events = { fk.CardUseFinished },
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target and target ~= player and target.kingdom == "wu" and data.card and data.card.trueName == "slash" and target.phase == Player.Play and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      return #Card:getIdList(data.card) ~= 0 and table.every(Card:getIdList(data.card), function(id) return player.room:getCardArea(id) == Card.Processing end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(target, self.name, data, "#ol__lijun-invoke:"..player.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:obtainCard(player, Card:getIdList(data.card), true, fk.ReasonJustMove)
    if not player.dead and not target.dead and room:askForSkillInvoke(player, self.name, data, "#ol__lijun-draw:"..target.id) then
      target:drawCards(1, self.name)
      room:addPlayerMark(target, "ol__lijun_slash-phase")
    end
  end,
}
local ol__lijun_targetmod = fk.CreateTargetModSkill{
  name = "#ol__lijun_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:getMark("ol__lijun_slash-phase") > 0 and skill and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("ol__lijun_slash-phase")
    end
  end,
}
ol__lijun:addRelatedSkill(ol__lijun_targetmod)
ol__sunliang:addSkill(ol__lijun)
Fk:loadTranslationTable{
  ["ol__sunliang"] = "孙亮",
  ["#ol__sunliang"] = "寒江枯水",
  ["cv:ol__sunliang"] = "徐刚",
  ["ol__kuizhu"] = "溃诛",
  [":ol__kuizhu"] = "弃牌阶段结束时，你可以选择一项：1. 令至多X名角色各摸一张牌；2. 对任意名体力值之和为X的角色造成1点伤害（X为你此阶段弃置的牌数）。",
  ["ol__kuizhu_active"] = "溃诛",
  ["#ol__kuizhu-use"] = "你可发动“溃诛”，X为%arg",
  ["ol__kuizhu_choice1"] = "令至多X名角色各摸一张牌",
  ["ol__kuizhu_choice2"] = "对任意名体力值之和为X的角色造成1点伤害",
  ["ol__chezheng"] = "掣政",
  [":ol__chezheng"] = "锁定技，你于你出牌阶段内对攻击范围内不包含你的其他角色造成伤害时，防止之。出牌阶段结束时，若你本阶段使用的牌数小于这些角色数，你弃置其中一名角色一张牌。",
  ["#ol__chezheng-throw"] = "掣政：选择攻击范围内不包含你的一名角色，弃置其一张牌",
  ["#ol__chezheng_prohibit"] = "掣政",
  ["ol__lijun"] = "立军",
  [":ol__lijun"] = "主公技，其他吴势力角色于其出牌阶段使用【杀】结算结束后（每阶段限一次），其可以将此【杀】交给你，然后你可以令其摸一张牌且其本回合使用【杀】次数上限+1。",
  ["#ol__lijun-invoke"] = "立军：你可以将此【杀】交给 %src，然后 %src 可令你摸一张牌且本回合使用【杀】次数上限+1",
  ["#ol__lijun-draw"] = "立军：你可以令 %src 摸一张牌且其本回合使用【杀】次数上限+1",

  ["$ol__kuizhu1"] = "东吴之主，岂是贪生怕死之辈？",
  ["$ol__kuizhu2"] = "欺朕年幼？有胆，便一决雌雄！",
  ["$ol__chezheng1"] = "朕倒要看看，这大吴是谁的江山！",
  ["$ol__chezheng2"] = "只要朕还在，老贼休想稳坐一天！",
  ["$ol__lijun1"] = "能征善战，乃我东吴长久之风。",
  ["$ol__lijun2"] = "重赏之下，必有勇夫。",
  ["~ol__sunliang"] = "君不君，臣不臣，此国之悲……",
}

local ol__zhoufei = General(extension, "ol__zhoufei", "wu", 3, 3, General.Female)
local ol__liangyin = fk.CreateTriggerSkill{
  name = "ol__liangyin",
  events = {fk.AfterCardsMove},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local x, y = player:getMark("ol__liangyin1_record-turn"), player:getMark("ol__liangyin2_record-turn")
      local room = player.room
      local move__event = room.logic:getCurrentEvent()
      local turn_event = move__event:findParent(GameEvent.Turn)
      if turn_event == nil then return false end
      if not move__event or (x > 0 and x ~= move__event.id and y > 0 and y ~= move__event.id) then return false end
      local liangyin1_search, liangyin2_search = false, false
      for _, move in ipairs(data) do
        if move.toArea == Card.PlayerSpecial then
          if x == 0 then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea ~= Card.PlayerSpecial then
                liangyin1_search = true
              end
            end
          end
        elseif y == 0 then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerSpecial then
              liangyin2_search = true
            end
          end
        end
      end
      if liangyin1_search or liangyin2_search then
        room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
          local moves = e.data
          for _, move in ipairs(moves) do
            if move.toArea == Card.PlayerSpecial then
              if liangyin1_search then
                for _, info in ipairs(move.moveInfo) do
                  if info.fromArea ~= Card.PlayerSpecial then
                    x = e.id
                    room:setPlayerMark(player, "ol__liangyin1_record-turn", x)
                    liangyin1_search = false
                  end
                end
              end
            elseif liangyin2_search then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerSpecial then
                  y = e.id
                  room:setPlayerMark(player, "ol__liangyin2_record-turn", y)
                  liangyin2_search = false
                end
              end
            end
            if not (liangyin1_search or liangyin2_search) then return true end
          end
          return false
        end, Player.HistoryTurn)
      end
      return x == move__event.id or y == move__event.id
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local x, y = player:getMark("ol__liangyin1_record-turn"), player:getMark("ol__liangyin2_record-turn")
    local move__event = room.logic:getCurrentEvent()
    if x == move__event.id then
      self.cost_data = "drawcard"
      self:doCost(event, target, player, data)
    end
    if y == move__event.id and player:hasSkill(self) and not player:isNude() then
      self.cost_data = "discard"
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local choice = self.cost_data
    local targets = table.filter(player.room.alive_players, function (p)
      return p ~= player and (choice == "drawcard" or not p:isNude())
    end)
    local to = player.room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#ol__liangyin-" .. choice, self.name, true)
    if #to > 0 then
      self.cost_data = {to[1], choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tar = room:getPlayerById(self.cost_data[1])
    local choice = self.cost_data[2]
    if choice == "drawcard" then
      room:notifySkillInvoked(player, self.name, "support")
      player:broadcastSkillInvoke(self.name)
      room:drawCards(player, 1, self.name)
      if not tar.dead then
        room:drawCards(tar, 1, self.name)
      end
    elseif choice == "discard" then
      room:notifySkillInvoked(player, self.name, "control")
      player:broadcastSkillInvoke(self.name)
      room:askForDiscard(player, 1, 1, true, self.name, false)
      if not tar.dead then 
        room:askForDiscard(tar, 1, 1, true, self.name, false)
      end
    end
    if player.dead then return false end
    local x = #player:getPile("ol__kongsheng_harp")
    local targets = {}
    if player:getHandcardNum() == x and player:isWounded() then
      table.insert(targets, player.id)
    end
    if not tar.dead and tar:getHandcardNum() == x and tar:isWounded() then
      table.insert(targets, tar.id)
    end
    if #targets == 0 then return false end
    local tos = player.room:askForChoosePlayers(player, targets, 1, 1, "#ol__liangyin-recover", self.name, true)
    if #tos > 0 then
      local to = room:getPlayerById(tos[1])
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local ol__kongsheng = fk.CreateTriggerSkill{
  name = "ol__kongsheng",
  anim_type = "defensive",
  derived_piles = "ol__kongsheng_harp",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and ((player.phase == Player.Start and not player:isNude()) or
    (player.phase == Player.Finish and #player:getPile("ol__kongsheng_harp") > 0))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      local cards = room:askForCard(player, 1, 998, true, self.name, true, ".", "#ol__kongsheng-invoke")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    elseif player.phase == Player.Finish then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if player.phase == Player.Start then
      player:addToPile("ol__kongsheng_harp", self.cost_data, true, self.name)
    elseif player.phase == Player.Finish then
      local room = player.room
      local cards = table.filter(player:getPile("ol__kongsheng_harp"), function (id)
        return Fk:getCardById(id).type ~= Card.TypeEquip
      end)
      if #cards == 0 then return false end
      room:obtainCard(player.id, cards, true, fk.ReasonJustMove)
      if player.dead or #player:getPile("ol__kongsheng_harp") == 0 then return false end
      local targets = table.filter(room.alive_players, function (p)
        return table.find(player:getPile("ol__kongsheng_harp"), function (id)
          local card = Fk:getCardById(id)
          return card.type == Card.TypeEquip and not p:prohibitUse(card) and not p:isProhibited(p, card) and p:canUse(card)
        end)
      end)
      if #targets == 0 then return false end
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#ol__kongsheng-choose", self.name, false)
      if #tos == 0 then return false end
      local to = room:getPlayerById(tos[1])
      while true do
        if player.dead or to.dead then break end
        local to_use = table.find(player:getPile("ol__kongsheng_harp"), function (id)
          local card = Fk:getCardById(id)
          return card.type == Card.TypeEquip and not to:prohibitUse(card) and not to:isProhibited(to, card) and to:canUse(card)
        end)
        if to_use == nil then break end
        room:useCard({
          from = to.id,
          tos = {{to.id}},
          card = Fk:getCardById(to_use),
        })
      end
      if not to.dead then
        room:loseHp(to, 1, self.name)
      end
    end
  end,
}
ol__zhoufei:addSkill(ol__liangyin)
ol__zhoufei:addSkill(ol__kongsheng)
Fk:loadTranslationTable{
  ["ol__zhoufei"] = "周妃",
  ["#ol__zhoufei"] = "软玉温香",
  ["designer:ol__zhoufei"] = "玄蝶既白",
  ["illustrator:ol__zhoufei"] = "圆子",

  ["ol__liangyin"] = "良姻",
  [":ol__liangyin"] = "当每回合首次有牌移出/移入游戏后，你可以与一名其他角色各摸/弃置一张牌，然后你可以令其中一名手牌数为X的角色回复1点体力（X为“箜”数）。",
  ["ol__kongsheng"] = "箜声",
  [":ol__kongsheng"] = "准备阶段，你可以将任意张牌置于你的武将牌上，称为“箜”。结束阶段，你获得“箜”中的非装备牌，然后令一名角色使用剩余“箜”并失去1点体力。",

  ["#ol__liangyin-drawcard"] = "你可以发动良姻，选择一名角色，与其各摸一张牌",
  ["#ol__liangyin-discard"] = "你可以发动良姻，选择一名角色，与其各弃置一张牌",
  ["#ol__liangyin-recover"] = "良姻：可以选择一名角色，令其回复1点体力",
  ["#ol__kongsheng-invoke"] = "你可以发动箜声，选择任意张牌作为“箜”置于武将牌上",
  ["#ol__kongsheng-choose"] = "箜声：选择一名角色，令其使用“箜”中的装备牌并失去1点体力",
  ["ol__kongsheng_harp"] = "箜",

  ["$ol__liangyin1"] = "碧水云月间，良缘情长在。",
  ["$ol__liangyin2"] = "皓月皎，花景明，两心同。",
  ["$ol__kongsheng1"] = "歌尽桃花颜，箜鸣玉娇黛。",
  ["$ol__kongsheng2"] = "箜篌双丝弦，心有千绪结。",
  ["~ol__zhoufei"] = "梧桐半枯衰，鸳鸯白头散……",
}
local ol__godguanyu = General(extension, "ol__godguanyu", "god", 5)
local ol__wushen = fk.CreateTriggerSkill{
  name = "ol__wushen",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and data.card.suit == Card.Heart
  end,
  on_use = function(self, event, target, player, data)
    if not data.extraUse then
      data.extraUse = true
      player:addCardUseHistory(data.card.trueName, -1)
    end
    data.disresponsiveList = table.map(player.room.alive_players, Util.IdMapper)
  end,
}
local ol__wushen_filter = fk.CreateFilterSkill{
  name = "#ol__wushen_filter",
  card_filter = function(self, to_select, player)
    return player:hasSkill(ol__wushen) and to_select.suit == Card.Heart and
    table.contains(player.player_cards[Player.Hand], to_select.id)
  end,
  view_as = function(self, to_select)
    local card = Fk:cloneCard("slash", Card.Heart, to_select.number)
    card.skillName = "ol__wushen"
    return card
  end,
}
local ol__wushen_targetmod = fk.CreateTargetModSkill{
  name = "#ol__wushen_targetmod",
  frequency = Skill.Compulsory,
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:hasSkill(self) and skill.trueName == "slash_skill" and card.suit == Card.Heart
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:hasSkill(self) and skill.trueName == "slash_skill" and card.suit == Card.Heart
  end,
}
ol__wushen:addRelatedSkill(ol__wushen_filter)
ol__wushen:addRelatedSkill(ol__wushen_targetmod)
ol__godguanyu:addSkill(ol__wushen)
ol__godguanyu:addSkill("wuhun")
Fk:loadTranslationTable {
  ["ol__godguanyu"] = "神关羽",
  ["#ol__godguanyu"] = "鬼神再临",
  ["ol__wushen"] = "武神",
  [":ol__wushen"] = "锁定技，你的<font color='red'>♥</font>手牌视为【杀】；你使用<font color='red'>♥</font>【杀】无距离与次数限制、不计次数且不能被响应。",
  ["#ol__wushen_filter"] = "武神",

  ["$ol__wushen1"] = "千里追魂，一刀索命。",
  ["$ol__wushen2"] = "鬼龙斩月刀！",
  ["$wuhun_ol__godguanyu1"] = "还我头来！",
  ["$wuhun_ol__godguanyu2"] = "不杀此人，何以雪恨？",
  ["~ol__godguanyu"] = "夙愿已了，魂归地府。",
}

local godzhangliao = General(extension, "ol__godzhangliao", "god", 4)

local duorui = fk.CreateTriggerSkill{
  name = "ol__duorui",
  anim_type = "control",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to ~= player and not data.to.dead and player.phase == Player.Play
    and data.to:getMark("@ol__duorui") == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = {}
    for _, skill in ipairs(Fk.generals[data.to.general]:getSkillNameList()) do
      if data.to:hasSkill(skill, true) then
        table.insert(choices, skill)
      end
    end
    if data.to.deputyGeneral ~= "" then
      for _, skill in ipairs(Fk.generals[data.to.deputyGeneral]:getSkillNameList()) do
        if data.to:hasSkill(skill, true) then
          table.insertIfNeed(choices, skill)
        end
      end
    end
    if #choices == 0 then return false end
    choices = room:askForChoices(player, choices, 1, 1, self.name, "#ol__duorui-choice:"..data.to.id, true, true)
    if #choices == 1 then
      self.cost_data = {tos = {data.to.id}, choice = choices[1]}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(data.to, "@ol__duorui", self.cost_data.choice)
    player:endPlayPhase()
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@ol__duorui") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@ol__duorui", 0)
  end,
}
local duorui_invalidity = fk.CreateInvaliditySkill {
  name = "#ol__duorui_invalidity",
  invalidity_func = function(self, player, skill)
    return player:getMark("@ol__duorui") == skill.name
  end
}
duorui:addRelatedSkill(duorui_invalidity)

godzhangliao:addSkill(duorui)

local zhiti = fk.CreateTriggerSkill{
  name = "ol__zhiti",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      local num = #table.filter(player.room.alive_players, function (p) return p:isWounded() end)
      if event == fk.DrawNCards then
        return num >= 3
      else
        return num >= 5
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DrawNCards then
      data.n = data.n + 1
    else
      local targets = table.filter(room:getOtherPlayers(player, false), function (p) return #p:getAvailableEquipSlots() > 0 end)
      if #targets == 0 then return false end
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#ol__zhiti-choose", self.name, true)
      if #tos > 0 then
        local to = room:getPlayerById(tos[1])
        local slots = to:getAvailableEquipSlots()
        if #slots > 0 then
          if table.removeOne(slots, Card.SubtypeDefensiveRide) then
            table.insertIfNeed(slots, Card.SubtypeOffensiveRide)
          end
          local slot = table.random(slots)
          if slot == Card.SubtypeOffensiveRide then
            slot = {Card.SubtypeOffensiveRide, Card.SubtypeDefensiveRide}
          end
          room:abortPlayerArea(to, slot)
        end
      end
    end
  end,
}
local zhiti_maxcards = fk.CreateMaxCardsSkill{
  name = "#ol__zhiti_maxcards",
  correct_func = function(self, player)
    local n = 0
    local players = Fk:currentRoom().alive_players
    if player:hasSkill(zhiti) and table.find(players, function (p) return p:isWounded() end) then
      n = 1
    end
    if player:isWounded() then
      for _, p in ipairs(players) do
        if p:hasSkill(zhiti) and p:inMyAttackRange(player) then
          n = n - 1
        end
      end
    end
    return n
  end,
}
zhiti:addRelatedSkill(zhiti_maxcards)

godzhangliao:addSkill(zhiti)

Fk:loadTranslationTable {
  ["ol__godzhangliao"] = "神张辽",
  ["#ol__godzhangliao"] = "雁门之刑天",

  ["ol__duorui"] = "夺锐",
  [":ol__duorui"] = "当你于出牌阶段内对一名其他角色造成伤害后，若其没有因此技能而失效的技能，你可以令其武将牌上的一个技能失效直到其下回合结束，然后结束此阶段。",
  ["#ol__duorui-choice"] = "夺锐：你可以令 %src 武将牌上的一个技能失效直到其下回合结束，然后结束出牌阶段",
  ["@ol__duorui"] = "被夺锐",

  ["ol__zhiti"] = "止啼",
  [":ol__zhiti"] = "锁定技，①你的攻击范围内已受伤的角色手牌上限-1；②若场上已受伤的角色数不小于：1，你的手牌上限+1；3，摸牌阶段，你多摸一张牌；5，回合结束时，你可以废除一名角色一个随机的装备栏。",
  ["#ol__zhiti-choose"] = "止啼：废除一名角色一个随机的装备栏",

  ["$ol__duorui1"] = "天下雄兵之锐，吾一人可尽夺之！",
  ["$ol__duorui2"] = "夺旗者勇，夺命者利，夺锐者神！",
  ["$ol__zhiti1"] = "凌烟常忆张文远，逍遥常哭孙仲谋！",
  ["$ol__zhiti2"] = "吾名如良药，可医吴儿夜啼！",
  ["~ol__godzhangliao"] = "辽来，辽来！辽去！辽去……",
}

-- yj2011
local masu = General(extension, "ol__masu", "shu", 3)
local ol__sanyao = fk.CreateActiveSkill{
  name = "ol__sanyao",
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return (player:getMark("ol__sanyao_hp-phase") == 0 or player:getMark("ol__sanyao_hand-phase") == 0)
  end,
  interaction = function()
    local choices = {}
    for _, m in ipairs({"ol__sanyao_hand-phase", "ol__sanyao_hp-phase"}) do
      if Self:getMark(m) == 0 then table.insert(choices, m) end
    end
    return UI.ComboBox {choices = choices}
  end,
  target_filter = function(self, to_select, selected, cards)
    if #selected > 0 or not self.interaction.data or #cards ~= 1 then return false end
    local target = Fk:currentRoom():getPlayerById(to_select)
    if self.interaction.data == "ol__sanyao_hp-phase" then
      return table.every(Fk:currentRoom().alive_players, function(p) return p.hp <= target.hp end)
    else
      return table.every(Fk:currentRoom().alive_players, function(p) return p:getHandcardNum() <= target:getHandcardNum() end)
    end
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addPlayerMark(player, self.interaction.data)
    room:throwCard(effect.cards, self.name, player, player)
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = self.name,
    }
  end
}
masu:addSkill(ol__sanyao)
masu:addSkill("ty_ex__zhiman")
Fk:loadTranslationTable{
  ["ol__masu"] = "马谡",
  ["#ol__masu"] = "军略之才器",
  ["designer:ol__masu"] = "豌豆帮帮主",
  ["illustrator:ol__masu"] = "鬼画府", -- 皮肤 勘策惊涛

  ["ol__sanyao"] = "散谣",
  [":ol__sanyao"] = "出牌阶段每项各限一次，你可以选择一项并弃置一张牌：1.对全场体力值最大的一名角色造成1点伤害；2.对(弃置此牌前)手牌数最多的一名角色造成1点伤害。",
  ["ol__sanyao_hp-phase"] = "体力值最大",
  ["ol__sanyao_hand-phase"] = "手牌数最多",

  ["$ol__sanyao1"] = "吾有一计，可致司马懿于死地。",
  ["$ol__sanyao2"] = "丞相勿忧，司马懿不足为患。",
  ["$ty_ex__zhiman_ol__masu1"] = "覆军杀将非良策也，当服其心以求长远。",
  ["$ty_ex__zhiman_ol__masu2"] = "欲平南中之叛，当以攻心为上。",
  ["~ol__masu"] = "悔不听王平之言，铸此大错……",
}

-- yj2013
local ol__guohuai = General(extension, "ol__guohuai", "wei", 3)
local ol__jingce = fk.CreateTriggerSkill{
  name = "ol__jingce",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      local types = {}
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        if use.from == player.id then
          table.insertIfNeed(types, use.card.type)
        end
      end, Player.HistoryTurn)
      if #types > 0 then
        self.cost_data = #types
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(self.cost_data, self.name)
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function (self, event, target, player, data)
    if player ~= player.room.current then return false end
    return player:hasSkill(self, true) and data.card.suit ~= Card.NoSuit
    and not table.contains(player:getTableMark("@ol__jingce-turn"), data.card:getSuitString(true))
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addTableMark(player, "@ol__jingce-turn", data.card:getSuitString(true))
  end,

  on_acquire = function (self, player, is_start)
    local room = player.room
    if player ~= player.room.current then return end
    local mark = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      local use = e.data[1]
      if use.from == player.id and use.card.suit ~= Card.NoSuit then
        table.insertIfNeed(mark, use.card:getSuitString(true))
      end
    end, Player.HistoryTurn)
    room:setPlayerMark(player, "@ol__jingce-turn", #mark > 0 and mark or 0)
  end,
}
local ol__jingce_maxcards = fk.CreateMaxCardsSkill{
  name = "#ol__jingce_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(ol__jingce) then
      return #player:getTableMark("@ol__jingce-turn")
    end
  end,
}
ol__jingce:addRelatedSkill(ol__jingce_maxcards)
ol__guohuai:addSkill(ol__jingce)
Fk:loadTranslationTable{
  ["ol__guohuai"] = "郭淮",
  ["#ol__guohuai"] = "垂问秦雍",
  ["illustrator:ol__guohuai"] = "张帅", -- 御蜀屏障
  ["ol__jingce"] = "精策",
  [":ol__jingce"] = "①出牌阶段结束时，你可以摸等同于你本回合使用过牌的类别数张牌；②你的手牌上限+X（X为你本回合使用过牌的花色数）。",
  ["@ol__jingce-turn"] = "精策",
  ["$ol__jingce1"] = "良策佐君王，率征万精兵。",
  ["$ol__jingce2"] = "得一寸，进一尺。",
  ["~ol__guohuai"] = "穷寇莫追……",
}

-- yj2014
local caozhen = General(extension, "ol__caozhen", "wei", 4)
local sidi = fk.CreateTriggerSkill{
  name = "ol__sidi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Play and not target.dead and
      #player:getCardIds("e") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local cards = table.filter(player:getCardIds("he"), function (id)
      return Fk:getCardById(id).type ~= Card.TypeBasic and not player:prohibitDiscard(id) and
        table.find(player:getCardIds("e"), function (id2)
          return Fk:getCardById(id):compareColorWith(Fk:getCardById(id2))
        end) ~= nil
    end)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, tostring(Exppattern{ id = cards }),
      "#ol__sidi-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = {tos = {target.id}, cards = card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local color = Fk:getCardById(self.cost_data.cards[1]):getColorString()
    room:throwCard(self.cost_data.cards, self.name, player, player)
    if not target.dead then
      room:addTableMarkIfNeed(target, "@ol__sidi-turn", color)
    end
  end,
}
local sidi_delay = fk.CreateTriggerSkill{
  name = "#ol__sidi_delay",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:usedSkillTimes("ol__sidi", Player.HistoryPhase) > 0 and not player.dead and not target.dead and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        return use.from == target.id and use.card.trueName == "slash"
      end, Player.HistoryPhase) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("slash", nil, player, target, "ol__sidi", true)
  end,
}
local sidi_prohibit = fk.CreateProhibitSkill{
  name = "#ol__sidi_prohibit",
  prohibit_use = function(self, player, card)
    local mark = player:getMark("@ol__sidi-turn")
    if type(mark) == "table" and table.contains(mark, card:getColorString()) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0
    end
  end,
  prohibit_response = function(self, player, card)
    local mark = player:getMark("@ol__sidi-turn")
    if type(mark) == "table" and table.contains(mark, card:getColorString()) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0
    end
  end,
}
sidi:addRelatedSkill(sidi_delay)
sidi:addRelatedSkill(sidi_prohibit)
caozhen:addSkill(sidi)
Fk:loadTranslationTable{
  ["ol__caozhen"] = "曹真",
  ["#ol__caozhen"] = "荷国天督",
  ["illustrator:ol__caozhen"] = "biou09",

  ["ol__sidi"] = "司敌",
  [":ol__sidi"] = "其他角色出牌阶段开始时，你可以弃置一张与你装备区里任意牌颜色相同的非基本牌，令其本阶段不能使用和打出与此牌颜色相同的牌，"..
  "然后此阶段结束时，若其本阶段未使用过【杀】，你视为对其使用一张【杀】。",
  ["#ol__sidi-invoke"] = "司敌：弃置与装备区内牌颜色相同的非基本牌，令 %dest 本阶段不能使用打出此颜色牌",
  ["@ol__sidi-turn"] = "司敌",
  ["#ol__sidi_delay"] = "司敌",

  ["$ol__sidi1"] = "扼守关中，以静制动。",
  ["$ol__sidi2"] = "料敌为先，破敌为备。",
  ["~ol__caozhen"] = "三马共槽，养虎为患哪！",
}

local ol__guyong = General(extension, "ol__guyong", "wu", 3)
local ol__bingyi = fk.CreateTriggerSkill{
  name = "ol__bingyi",
  anim_type = "defensive",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and not player:isKongcheng() then
      local currentplayer = player.room.current
      if currentplayer and currentplayer.phase <= Player.Finish and currentplayer.phase >= Player.Start then
        for _, move in ipairs(data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)
    if #cards > 1 then
      for _, id in ipairs(cards) do
        if Fk:getCardById(id).color == Card.NoColor or Fk:getCardById(id).color ~= Fk:getCardById(cards[1]).color then
          return false
        end
      end
    end
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, #cards, "#ol__bingyi-choose:::"..#cards, self.name, true)
    table.insert(tos, player.id)
    room:sortPlayersByAction(tos)
    for _, pid in ipairs(tos) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        room:drawCards(p, 1, self.name)
      end
    end
  end,
}
ol__guyong:addSkill("shenxing")
ol__guyong:addSkill(ol__bingyi)
Fk:loadTranslationTable{
  ["ol__guyong"] = "顾雍",
  ["#ol__guyong"] = "庙堂的玉磐",
  ["designer:ol__guyong"] = "玄蝶既白",
  ["illustrator:ol__guyong"] = "Sky",

  ["ol__bingyi"] = "秉壹",
  [":ol__bingyi"] = "每阶段限一次，当你的牌被弃置后，你可以展示所有手牌，若颜色均相同，你令你与至多X名角色各摸一张牌（X为你的手牌数）。",
  ["#ol__bingyi-choose"] = "秉壹：你可以与至多%arg名其他角色各摸一张牌，点取消则仅你摸牌",

  ["$shenxing_ol__guyong1"] = "上兵伐谋，三思而行。",
  ["$shenxing_ol__guyong2"] = "精益求精，慎之再慎。",
  ["$ol__bingyi1"] = "秉直进谏，勿藏私心！",
  ["$ol__bingyi2"] = "秉公守一，不负圣恩！",
  ["~ol__guyong"] = "此番患疾，吾必不起……",
}
-- yj2017
local ol__jikang = General(extension, "ol__jikang", "wei", 3)
local doOl__qingxian = function (room, to, from, choice, skillName)
  if to.dead then return nil end
  local returnCard
  if choice == "ol__qingxian_losehp" then
    room:loseHp(to, 1, skillName)
    if to.dead then return end
    local cards = {}
    for _, cid in ipairs(room.draw_pile) do
      local card = Fk:getCardById(cid)
      if card.type == Card.TypeEquip and to:canUse(card) then
        table.insert(cards, card)
      end
    end
    if #cards > 0 then
      returnCard = table.random(cards)
      room:useCard({ from = to.id, tos = {{to.id}}, card = returnCard })
    end
  else
    if to:isWounded() then
      room:recover({ who = to, num = 1, recoverBy = from, skillName = skillName })
    end
    if not to.dead and not to:isNude() then
      local throw = room:askForDiscard(to, 1, 1, true, skillName, false, ".|.|.|.|.|equip")
      if #throw > 0 then
        returnCard = Fk:getCardById(throw[1])
      end
    end
  end
  return returnCard
end
local ol__qingxian = fk.CreateTriggerSkill{
  name = "ol__qingxian",
  events = { fk.Damaged , fk.HpRecover },
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target == player and not table.find(player.room.alive_players, function(p) return p.dying end) then
      if event == fk.Damaged then
        return data.from and not data.from.dead
      else
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      return room:askForSkillInvoke(player, self.name, data, "#skilltosb::"..data.from.id..":"..self.name)
    else
      local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1, "#skillchooseother:::"..self.name, self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = (event == fk.Damaged) and data.from or room:getPlayerById(self.cost_data)
    local choice = room:askForChoice(player, {"ol__qingxian_losehp","ol__qingxian_recover"}, self.name)
    local card = doOl__qingxian(room, to, player, choice, self.name)
    if card and card.suit == Card.Club and not player.dead then
      player:drawCards(1, self.name)
    end
  end,
}
ol__jikang:addSkill(ol__qingxian)
local ol__juexiang = fk.CreateTriggerSkill{
  name = "ol__juexiang",
  anim_type = "support",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self,false,true) and target == player
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1, "#skillchooseother:::"..self.name, self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local skills = table.filter({"ol__jixian","ol__liexian","ol__rouxian","ol__hexian"}, function (s) return not to:hasSkill(s,true) end)
    if #skills > 0 then
      room:handleAddLoseSkills(to, table.random(skills), nil)
    end
    room:setPlayerMark(to, "@@ol__juexiang", 1)
  end,
  refresh_events = {fk.TurnStart},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@ol__juexiang") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ol__juexiang", 0)
  end,
}
local ol__juexiang_prohibit = fk.CreateProhibitSkill{
  name = "#ol__juexiang_prohibit",
  is_prohibited = function(self, from, to, card)
    if card and card.suit == Card.Club then
      return to:getMark("@@ol__juexiang") > 0 and from ~= to
    end
  end,
}
ol__juexiang:addRelatedSkill(ol__juexiang_prohibit)
ol__jikang:addSkill(ol__juexiang)
local ol__jixian = fk.CreateTriggerSkill{
  name = "ol__jixian",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and data.from and not data.from.dead and not table.find(player.room.alive_players, function(p) return p.dying end)
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#skilltosb::"..data.from.id..":"..self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    doOl__qingxian(room, data.from, player, "ol__qingxian_losehp", self.name)
  end,
}
ol__jikang:addRelatedSkill(ol__jixian)
local ol__liexian = fk.CreateTriggerSkill{
  name = "ol__liexian",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and not table.find(player.room.alive_players, function(p) return p.dying end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1, "#skillchooseother:::"..self.name, self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    doOl__qingxian(room, room:getPlayerById(self.cost_data), player, "ol__qingxian_losehp", self.name)
  end,
}
ol__jikang:addRelatedSkill(ol__liexian)
local ol__rouxian = fk.CreateTriggerSkill{
  name = "ol__rouxian",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and data.from and not data.from.dead and not table.find(player.room.alive_players, function(p) return p.dying end)
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#skilltosb::"..data.from.id..":"..self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    doOl__qingxian(room, data.from, player, "ol__qingxian_recover", self.name)
  end,
}
ol__jikang:addRelatedSkill(ol__rouxian)
local ol__hexian = fk.CreateTriggerSkill{
  name = "ol__hexian",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and not table.find(player.room.alive_players, function(p) return p.dying end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1, "#skillchooseother:::"..self.name, self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    doOl__qingxian(room, room:getPlayerById(self.cost_data), player, "ol__qingxian_recover", self.name)
  end,
}
ol__jikang:addRelatedSkill(ol__hexian)
Fk:loadTranslationTable{
  ["ol__jikang"] = "嵇康",
  ["#ol__jikang"] = "峻峰孤松",
  ["ol__qingxian"] = "清弦",
  [":ol__qingxian"] = "当你受到伤害/回复体力后，若没有角色处于濒死状态，你可以选一项令伤害来源/一名其他角色执行：1.失去1点体力并随机使用牌堆一张装备牌；2.回复1点体力并弃置一张装备牌。若其使用或弃置的牌的花色为♣，你摸一张牌。",
  ["ol__qingxian_losehp"] = "失去1点体力并随机使用牌堆一张装备牌",
  ["ol__qingxian_recover"] = "回复1点体力并弃置一张装备牌",
  ["ol__juexiang"] = "绝响",
  [":ol__juexiang"] = "当你死亡时，你可以令一名其他角色随机获得〖激弦〗、〖烈弦〗、〖柔弦〗、〖和弦〗中的一个技能，然后直到其下回合开始前，该角色不能成为除其以外的角色使用♣牌的目标。",
  ["@@ol__juexiang"] = "绝响",
  ["#ol__juexiang_prohibit"] = "绝响",
  ["ol__jixian"] = "激弦",
  [":ol__jixian"] = "当你受到伤害后，若没有角色处于濒死状态，你可以令伤害来源失去1点体力并随机使用牌堆一张装备牌。",
  ["ol__liexian"] = "烈弦",
  [":ol__liexian"] = "当你回复体力后，若没有角色处于濒死状态，你可以令一名其他角色失去1点体力并随机使用牌堆一张装备牌。",
  ["ol__rouxian"] = "柔弦",
  [":ol__rouxian"] = "当你受到伤害后，若没有角色处于濒死状态，你可以令伤害来源回复1点体力并弃置一张装备牌。",
  ["ol__hexian"] = "和弦",
  [":ol__hexian"] = "当你回复体力后，若没有角色处于濒死状态，你可以令一名其他角色回复1点体力并弃置一张装备牌。",
  ["#skilltosb"] = "你可以对 %dest 发动“%arg”",
  ["#skillchooseother"] = "你可以对一名其他角色发动“%arg”",

  ["$ol__qingxian1"] = "弦音之妙，尽在无心。",
  ["$ol__qingxian2"] = "流水清音听，高山弦拨心。",
  ["$ol__juexiang1"] = "曲终人散皆是梦，繁华落尽一场空。",
  ["$ol__juexiang2"] = "广陵一失，千古绝响。",
  ["$ol__jixian"] = "曲至高亢，荡气回肠。",
  ["$ol__liexian"] = "烈火灼心，弦音刺耳。",
  ["$ol__rouxian"] = "稍安勿躁，请先听我一曲。",
  ["$ol__hexian"] = "和声悦悦，琴音悠悠。",
  ["~ol__jikang"] = "曲终人散，空留余音……",
}

local ol__xinxianying = General(extension, "ol__xinxianying", "wei", 3, 3, General.Female)
local ol__zhongjian = fk.CreateActiveSkill{
  name = "ol__zhongjian",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#ol__zhongjian-prompt",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < (1 + player:getMark("ol__zhongjian_times-turn"))
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, cards)
    if #selected == 0 and Self.id ~= to_select and #cards == 1 then
      local to = Fk:currentRoom():getPlayerById(to_select)
      return to.hp > 0 and not to:isKongcheng()
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    player:showCards(effect.cards)
    local x = math.min(to:getHandcardNum(), to.hp)
    local show = room:askForCardsChosen(player, to, x, x, "h", self.name)
    to:showCards(show)
    local card = Fk:getCardById(effect.cards[1])
    local hasSame
    if table.find(show, function(id) return Fk:getCardById(id).number == card.number end) then
      room:setPlayerMark(player, "ol__zhongjian_times-turn", 1)
      hasSame = true
    end
    if table.find(show, function(id) return Fk:getCardById(id).color == card.color end) then
      local targets = table.filter(room:getOtherPlayers(player, false), function (p) return not p:isNude() end)
      if #targets > 0 then
        local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#ol__zhongjian-choose", self.name, true)
        if #tos > 0 then
          local to2 = room:getPlayerById(tos[1])
          local cid = room:askForCardChosen(player, to2, "he", self.name)
          room:throwCard({cid}, self.name, to2, player)
          return
        end
      end
      player:drawCards(1, self.name)
      hasSame = true
    end
    if not hasSame and player:getMaxCards() > 0 then
      room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
      room:broadcastProperty(player, "MaxCards")
    end
  end,
}
ol__xinxianying:addSkill(ol__zhongjian)
local ol__caishi = fk.CreateTriggerSkill{
  name = "ol__caishi",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player == target and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"#ol__caishi1","cancel"}
    if player:isWounded() then table.insert(choices,2, "#ol__caishi2") end
    local choice = player.room:askForChoice(target, choices, self.name)
    if choice ~= "cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data
    if choice == "#ol__caishi1" then
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
      room:broadcastProperty(player, "MaxCards")
    else
      room:recover({ who = player,  num = 1, skillName = self.name })
      room:setPlayerMark(player, "@@ol__caishi-turn", 1)
    end
  end,
}
local ol__caishi_prohibit = fk.CreateProhibitSkill{
  name = "#ol__caishi_prohibit",
  is_prohibited = function(self, from, to)
    return from:getMark("@@ol__caishi-turn") > 0 and from == to
  end,
}
ol__caishi:addRelatedSkill(ol__caishi_prohibit)
ol__xinxianying:addSkill(ol__caishi)
Fk:loadTranslationTable{
  ["ol__xinxianying"] = "辛宪英",
  ["#ol__xinxianying"] = "名门智女",
  ["designer:ol__xinxianying"] = "如释帆飞",
  ["illustrator:ol__xinxianying"] = "凝聚永恒", -- 才涌花娇

  ["ol__zhongjian"] = "忠鉴",
  [":ol__zhongjian"] = "出牌阶段限一次，你可以展示一张手牌，并展示一名其他角色的X张手牌（X为其体力值）。若其以此法展示的牌与你展示的牌中：有颜色相同的，你摸一张牌或弃置一名其他角色的一张牌；有点数相同的，本回合此技能改为“出牌阶段限两次”；均不同且你手牌上限大于0，你的手牌上限-1。",
  ["#ol__zhongjian-choose"] = "忠鉴：你可弃置一名其他角色一张牌，或点“取消”摸一张牌",
  ["#ol__zhongjian-prompt"] = "忠鉴：展示一张手牌，并展示一名其他角色X张手牌（X为其体力值）",
  ["ol__caishi"] = "才识",
  [":ol__caishi"] = "摸牌阶段开始时，你可以选择一项：1.手牌上限+1；2.回复1点体力，然后本回合你不能对自己使用牌。",
  ["#ol__caishi1"] = "手牌上限+1",
  ["#ol__caishi2"] = "回复1点体力，本回合不能对自己用牌",
  ["@@ol__caishi-turn"] = "才识",

  ["$ol__zhongjian1"] = "野心昭著者，虽女子亦能知晓。",
  ["$ol__zhongjian2"] = "慧眼识英才，明智辨忠奸。",
  ["$ol__caishi1"] = "才学雅量，识古通今。",
  ["$ol__caishi2"] = "女子才智，自当有男子不及之处。",
  ["~ol__xinxianying"] = "料人如神，而难自知啊……",
}


return extension
