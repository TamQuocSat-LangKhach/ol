local extension = Package("ol_re")
extension.extensionName = "ol"
local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_re"] = "OL专属",
}

--这个包放OL修改的武将，按神话再临-sp-一将成名的顺序排

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
  frequency = Skill.Compulsory,
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
        local targets = table.filter(player.room:getOtherPlayers(player), function(p) return not p:inMyAttackRange(player) end)
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
      local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:inMyAttackRange(player) and not p:isNude() end)
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
    if player:hasSkill(self) and target ~= player and target.kingdom == "wu" and data.card.trueName == "slash" and target.phase == Player.Play and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      local cardList = data.card:isVirtual() and data.card.subcards or {data.card.id}
      return table.find(cardList, function(id) return not player.room:getCardOwner(id) end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(target, self.name, data, "#ol__lijun-invoke:"..player.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cardList = data.card:isVirtual() and data.card.subcards or {data.card.id}
    local cards = table.filter(cardList, function(id) return not room:getCardOwner(id) end)
    if #cards == 0 then return end
    local dummy = Fk:cloneCard("slash")
    dummy:addSubcards(cards)
    room:obtainCard(player, dummy, true, fk.ReasonJustMove)
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
  ["~ol__sunliang"] = "君不君，臣不臣，此国之悲。",
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
    local to = player.room:askForChoosePlayers(player, table.map(targets, function (p)
      return p.id end), 1, 1, "#ol__liangyin-" .. choice, self.name, true)
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
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player.phase == Player.Start or
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
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(self.cost_data)
      player:addToPile("ol__kongsheng_harp", self.cost_data, true, self.name)
    elseif player.phase == Player.Finish then
      local room = player.room
      local cards = table.filter(player:getPile("ol__kongsheng_harp"), function (id)
        return Fk:getCardById(id).type ~= Card.TypeEquip
      end)
      if #cards == 0 then return false end
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(cards)
      room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
      if player.dead or #player:getPile("ol__kongsheng_harp") == 0 then return false end
      local targets = table.filter(room.alive_players, function (p)
        return table.find(player:getPile("ol__kongsheng_harp"), function (id)
          local card = Fk:getCardById(id)
          return card.type == Card.TypeEquip and not p:prohibitUse(card) and not p:isProhibited(p, card) and p:canUse(card)
        end)
      end)
      if #targets == 0 then return false end
      local tos = room:askForChoosePlayers(player, table.map(targets, function (p)
        return p.id end), 1, 1, "#ol__kongsheng-choose", self.name, false)
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

local machao = General(extension, "ol__machao", "qun", 4)
local ol__zhuiji = fk.CreateTriggerSkill{
  name = "ol__zhuiji",
  anim_type = "control",
  events = {fk.TargetSpecified},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self) and data.card.trueName == "slash") then return false end
    local to = player.room:getPlayerById(data.to)
    return not to.dead and not to:isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to})
    local to = room:getPlayerById(data.to)
    local x = #to:getCardIds("e")
    local cards = room:askForDiscard(to, 1, 1, true, self.name, x > 0, ".", "#ol__zhuiji-discard")
    if #cards == 0 and x > 0 then
      to:throwAllCards("e")
      if not to.dead then
        room:drawCards(to, x, self.name)
      end
    end
  end,
}
local ol__zhuiji_distance = fk.CreateDistanceSkill{
  name = "#ol__zhuiji_distance",
  frequency = Skill.Compulsory,
  fixed_func = function(self, from, to)
    if from:hasSkill(self) and from.hp >= to.hp then
      return 1
    end
  end,
}
local ol__shichou = fk.CreateTriggerSkill{
  name = "ol__shichou",
  anim_type = "offensive",
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card.trueName == "slash" then
      local current_targets = TargetGroup:getRealTargets(data.tos)
      for _, p in ipairs(player.room.alive_players) do
        if not table.contains(current_targets, p.id) and not player:isProhibited(p, data.card) and
            data.card.skill:modTargetFilter(p.id, current_targets, data.from, data.card, true) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local current_targets = TargetGroup:getRealTargets(data.tos)
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if not table.contains(current_targets, p.id) and not player:isProhibited(p, data.card) and
          data.card.skill:modTargetFilter(p.id, current_targets, data.from, data.card, true) then
        table.insert(targets, p.id)
      end
    end
    local n = player:getLostHp() + 1
    local tos = room:askForChoosePlayers(player, targets, 1, n,
    "#ol__shichou-choose:::"..data.card:toLogString()..":"..tostring(n), self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    table.insertTable(data.tos, table.map(self.cost_data, function (p)
      return {p}
    end))
  end,
}
ol__zhuiji:addRelatedSkill(ol__zhuiji_distance)
machao:addSkill(ol__zhuiji)
machao:addSkill(ol__shichou)

Fk:loadTranslationTable{
  ["ol__machao"] = "马超",
  ["ol__zhuiji"] = "追击",
  [":ol__zhuiji"] = "锁定技，你计算与体力值不大于你的角色的距离始终为1。当你使用【杀】指定距离为1的角色为目标后，其弃置一张牌或弃置装备区里的所有牌并摸等量的牌。",
  ["ol__shichou"] = "誓仇",
  [":ol__shichou"] = "你使用【杀】可以多选择至多X+1名角色为目标（X为你已损失的体力值）。",

  ["#ol__zhuiji-discard"] = "追击：选择一张牌弃置，或点取消则弃置装备区里的所有牌并摸等量的牌",
  ["#ol__shichou-choose"] = "是否使用誓仇，为此【%arg】额外指定至多%arg2个目标",

  ["$ol__shichou1"] = "你们一个都别想跑！",
  ["$ol__shichou2"] = "新仇旧恨，一并结算！",
  ["~ol__machao"] = "父亲！父亲！！",
}

local ol__guanyinping = General(extension, "ol__guanyinping", "shu", 3, 3, General.Female)
local ol__xuehen = fk.CreateActiveSkill{
  name = "ol__xuehen",
  anim_type = "offensive",
  card_num = 1,
  min_target_num = 1,
  max_target_num = function ()
    return math.max(1,Self:getLostHp())
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected < math.max(1,Self:getLostHp())
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    local tos = table.map(effect.tos, Util.Id2PlayerMapper)
    for _, p in ipairs(tos) do
      if not p.dead and not p.chained then
        p:setChainState(true)
      end
    end
    tos = table.filter(tos, function(p) return not p.dead end)
    if #tos == 0 then return end
    local to = #tos == 1 and tos[1] or 
    room:getPlayerById(room:askForChoosePlayers(player, effect.tos, 1, 1, "#ol__xuehen-choose", self.name, false)[1])
    room:damage{ from = player, to = to, damage = 1, skillName = self.name, damageType = fk.FireDamage}
  end,
}
local ol__huxiao = fk.CreateTriggerSkill{
  name = "ol__huxiao",
  anim_type = "offensive",
  events = {fk.Damage},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player == target and data.damageType == fk.FireDamage and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    data.to:drawCards(1, self.name)
    player.room:setPlayerMark(data.to, "@@ol__huxiao-turn", 1)
  end,
}
local ol__huxiao_targetmod = fk.CreateTargetModSkill{
  name = "#ol__huxiao_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill("ol__huxiao") and to:getMark("@@ol__huxiao-turn") > 0
  end,
}
ol__huxiao:addRelatedSkill(ol__huxiao_targetmod)
local ol__wuji = fk.CreateTriggerSkill{
  name = "ol__wuji",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local n = 0 --TODO:伤害被防止也计数
    player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function(e)
      local damage = e.data[1]
      if damage and player == damage.from then
        n = n + damage.damage
      end
    end, Player.HistoryTurn)
    return n > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player:isWounded() and not player.dead then
      room:recover({ who = player, num = 1, recoverBy = player, skillName = self.name })
    end
    room:handleAddLoseSkills(player, "-ol__huxiao", nil)
    for _, id in ipairs(Fk:getAllCardIds()) do
      if Fk:getCardById(id).name == "blade" then
        if room:getCardArea(id) == Card.DiscardPile or room:getCardArea(id) == Card.DiscardPile or room:getCardArea(id) == Card.PlayerEquip then
          room:obtainCard(player, id, true, fk.ReasonPrey)
          break
        end
      end
    end
  end,
}
ol__guanyinping:addSkill(ol__xuehen)
ol__guanyinping:addSkill(ol__huxiao)
ol__guanyinping:addSkill(ol__wuji)
Fk:loadTranslationTable{
  ["ol__guanyinping"] = "关银屏",
  ["ol__xuehen"] = "雪恨",
  [":ol__xuehen"] = "出牌阶段限一次，你可以弃置一张红色牌并选择至多X名角色（X为你已损失的体力值且至少为1），然后你横置这些角色，并对其中一名角色造成1点火焰伤害。",
  ["#ol__xuehen-choose"] = "雪恨：对其中一名角色造成1点火焰伤害",
  ["ol__huxiao"] = "虎啸",
  [":ol__huxiao"] = "锁定技，当你对一名角色造成火焰伤害后，该角色摸一张牌，然后本回合你对其使用牌无次数限制。",
  ["@@ol__huxiao-turn"] = "虎啸",
  ["ol__wuji"] = "武继",
  [":ol__wuji"] = "觉醒技，结束阶段，若你本回合造成过至少3点伤害，你加1点体力上限并回复1点体力，失去技能〖虎啸〗，然后从牌堆、弃牌堆或场上获得【青龙偃月刀】。",

  ["$ol__xuehen1"] = "就用你的性命，一雪前耻。",
  ["$ol__xuehen2"] = "雪耻旧恨，今日清算。",
  ["$ol__huxiao1"] = "看我连招发动。",
  ["$ol__huxiao2"] = "想躲过我的攻击，不可能。",
  ["$ol__wuji1"] = "父亲的武艺，我已掌握大半。",
  ["$ol__wuji2"] = "有青龙偃月刀在，小女必胜。",
  ["~ol__guanyinping"] = "红已花残，此仇未能报……",
}

local ol__zhugejin = General(extension, "ol__zhugejin", "wu", 3)
local ol__hongyuan = fk.CreateTriggerSkill{
  name = "ol__hongyuan",
  anim_type = "defensive",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and not player:isNude() then
      local currentplayer = player.room.current
      if currentplayer and currentplayer.phase <= Player.Finish and currentplayer.phase >= Player.Start then
        local x = 0
        for _, move in ipairs(data) do
          if move.to == player.id and move.toArea == Card.PlayerHand then
            x = x + #move.moveInfo
          end
        end
        return x > 1
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), function(p)
      return p.id
    end)
    for _ = 1, 2, 1 do
      if player.dead or player:isNude() then break end
      local tos, cardId = room:askForChooseCardAndPlayers(
        player,
        targets,
        1,
        1,
        ".",
        "#ol__hongyuan-give",
        self.name,
        true,
        true
      )
      if #tos > 0 then
        room:obtainCard(tos[1], cardId, false, fk.ReasonGive)
        targets = table.filter(targets, function (pid)
          return tos[1] ~= pid and not room:getPlayerById(pid).dead
        end)
        if #targets < 1 then break end
      else
        break
      end
    end
  end,
}
local ol__mingzhe = fk.CreateTriggerSkill{
  name = "ol__mingzhe",
  frequency = Skill.Compulsory,
  anim_type = "defensive",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase ~= Player.Play then
      for _, move in ipairs(data) do
        if move.from == player.id and (move.to ~= player.id or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            Fk:getCardById(info.cardId).color == Card.Red then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
ol__zhugejin:addSkill("huanshi")
ol__zhugejin:addSkill(ol__hongyuan)
ol__zhugejin:addSkill(ol__mingzhe)
Fk:loadTranslationTable{
  ["ol__zhugejin"] = "诸葛瑾",
  ["ol__huanshi"] = "缓释",
  [":ol__huanshi"] = "当一名角色的判定牌生效前，你可以令其观看你的牌并用其中一张牌代替判定牌。",
  ["ol__hongyuan"] = "弘援",
  [":ol__hongyuan"] = "每阶段限一次，当你一次获得至少两张牌后，你可以交给至多两名其他角色各一张牌。",
  ["ol__mingzhe"] = "明哲",
  [":ol__mingzhe"] = "锁定技，当你于出牌阶段外失去红色牌后，你摸一张牌。",

  ["#ol__hongyuan-give"] = "弘援：你可以选择一张牌交给一名角色",

  ["$huanshi_ol__zhugejin1"] = "不因困顿夷初志，肯为联蜀改阵营。",
  ["$huanshi_ol__zhugejin2"] = "合纵连横，只为天下苍生。",
  ["$ol__hongyuan1"] = "吾已料有所困，援兵不久必至。",
  ["$ol__hongyuan2"] = "恪守信义，方为上策。",
  ["$ol__mingzhe1"] = "乱世，当稳中求胜。",
  ["$ol__mingzhe2"] = "明哲维天，临君下土。",
  ["~ol__zhugejin"] = "联盟若能得以维系，吾……无他愿矣……",
}

local ol__zhugedan = General(extension, "ol__zhugedan", "wei", 4)
local ol__juyi = fk.CreateTriggerSkill{
  name = "ol__juyi",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player.maxHp > #player.room.alive_players
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player.maxHp, self.name)
    player.room:handleAddLoseSkills(player, "benghuai|ol__weizhong", nil)
  end,
}
local ol__weizhong = fk.CreateTriggerSkill{
  name = "ol__weizhong",
  frequency = Skill.Compulsory,
  events = {fk.MaxHpChanged},
  on_use = function(self, event, target, player, data)
    local room = player.room
    local min_num = 999
    for _, p in ipairs(room.alive_players) do
      min_num = math.min(min_num, p:getHandcardNum())
    end
    if player:getHandcardNum() ~= min_num then
      player:drawCards(1, self.name)
    else
      player:drawCards(2, self.name)
    end
  end,
}
ol__zhugedan:addSkill("gongao")
ol__zhugedan:addSkill(ol__juyi)
ol__zhugedan:addRelatedSkill("benghuai")
ol__zhugedan:addRelatedSkill(ol__weizhong)
Fk:loadTranslationTable{
  ["ol__zhugedan"] = "诸葛诞",
  ["ol__juyi"] = "举义",
  [":ol__juyi"] = "觉醒技，准备阶段，若你体力上限大于存活角色数，你摸X张牌（X为你的体力上限），然后获得技能〖崩坏〗和〖威重〗。",
  ["ol__weizhong"] = "威重",
  [":ol__weizhong"] = "锁定技，每当你的体力上限变化时，若你手牌数：不为全场最少，你摸一张牌；为全场最少，你摸两张牌。",

  ["$gongao_ol__zhugedan1"] = "大魏獒犬，恪忠于国。",
  ["$gongao_ol__zhugedan2"] = "斯人已逝，余者奋威。",
  ["$ol__juyi1"] = "司马氏，定不攻自败也。",
  ["$ol__juyi2"] = "义照淮流，身报国恩！",
  ["$ol__weizhong"] = "本将军，誓与寿春，共存亡。",
  ["$benghuai_ol__zhugedan"] = "诞，能得诸位死力，无憾矣。",
  ["~ol__zhugedan"] = "成功！成仁！",
}

local hetaihou = General(extension, "ol__hetaihou", "qun", 3, 3, General.Female)
local ol__zhendu = fk.CreateTriggerSkill{
  name = "ol__zhendu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Play and not player:isKongcheng() and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#ol__zhendu-invoke::"..target.id, true)
    if #card > 0 then
      player.room:doIndicate(player.id, {target.id})
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if not target.dead and room:useVirtualCard("analeptic", nil, target, target, self.name, false) and player ~= target and not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
local ol__qiluan = fk.CreateTriggerSkill{
  name = "ol__qiluan",
  anim_type = "offensive",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local logic = player.room.logic
      local deathevents = logic.event_recorder[GameEvent.Death] or Util.DummyTable
      local turnevents = logic.event_recorder[GameEvent.Turn] or Util.DummyTable
      return #deathevents > 0 and #turnevents > 0 and deathevents[#deathevents].id > turnevents[#turnevents].id
    end
  end,
  on_use = function(self, event, target, player, data)
    local x = 0
    player.room.logic:getEventsOfScope(GameEvent.Death, 1, function (e)
      local deathData = e.data[1]
      if deathData.damage and deathData.damage.from == player then
        x = x + 3
      else
        x = x + 1
      end
      return false
    end, Player.HistoryTurn)
    if x > 0 then
      player:drawCards(x, self.name)
    end
  end,
}
hetaihou:addSkill(ol__zhendu)
hetaihou:addSkill(ol__qiluan)
Fk:loadTranslationTable{
  ["ol__hetaihou"] = "何太后",
  ["ol__zhendu"] = "鸩毒",
  [":ol__zhendu"] = "一名角色的出牌阶段开始时，你可以弃置一张手牌。若如此做，该角色视为使用一张【酒】，然后若该角色不为你，你对其造成1点伤害。",
  ["ol__qiluan"] = "戚乱",
  [":ol__qiluan"] = "一名角色回合结束时，你可摸X张牌（X为本回合死亡的角色数，其中每有一名角色是你杀死的，你多摸两张牌）。",
  ["#ol__zhendu-invoke"] = "鸩毒：你可以弃置一张手牌视为 %dest 使用一张【酒】，然后你对其造成1点伤害",

  ["$ol__zhendu1"] = "想要母凭子贵？你这是妄想。",
  ["$ol__zhendu2"] = "这皇宫，只能有一位储君。",
  ["$ol__qiluan1"] = "权力，只有掌握在自己手里才安心。",
  ["$ol__qiluan2"] = "有兄长在，我何愁不能继续享受。",
  ["~ol__hetaihou"] = "扰乱朝堂之事，我怎么会做……",
}

local ol__sunluyu = General(extension, 'ol__sunluyu', 'wu', 3, 3, General.Female)
local ol__meibu_dis = fk.CreateDistanceSkill{
  name = '#ol__meibu_dis',
  fixed_func = function(self, from, to)
    if from:getMark('ol__meibu') > 0 and to:getMark('ol__meibu_src-turn') > 0 then
      return 1
    end
  end,
}
local ol__meibu = fk.CreateTriggerSkill{
  name = "ol__meibu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Play and target ~= player
      and target:inMyAttackRange(player) and not target:hasSkill('ol__zhixi')
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local c = room:askForDiscard(player, 1, 1, true, self.name, true,
      ".", "#ol__meibu-invoke:" .. target.id, true)[1]

    if c then
      self.cost_data = c
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local c = self.cost_data
    room:throwCard(c, self.name, player, player)
    local card = Fk:getCardById(c)
    room:setPlayerMark(target, "ol__meibu", 1)
    room:handleAddLoseSkills(target, 'ol__zhixi', nil, true, true)

    if card.trueName ~= 'slash' and not (card.color == Card.Black and card.type == Card.TypeTrick) then
      room:setPlayerMark(player, "ol__meibu_src-turn", 1)
    end
  end,

  refresh_events = { fk.TurnEnd },
  can_refresh = function(self, event, target, player, data)
    return target == player and target:getMark("ol__meibu") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, "ol__meibu", 0)
    room:handleAddLoseSkills(target, '-ol__zhixi', nil, true, true)
  end,
}
ol__meibu:addRelatedSkill(ol__meibu_dis)
ol__sunluyu:addSkill(ol__meibu)
local ol__mumu_pro = fk.CreateProhibitSkill{
  name = '#ol__mumu_prohibit',
  prohibit_response = function(self, player, card)
    return card.trueName == 'slash' and player:getMark('@ol__mumu-turn') > 0
  end,
  prohibit_use = function(self, player, card)
    return card.trueName == 'slash' and player:getMark('@ol__mumu-turn') > 0
  end,
}
local ol__mumu = fk.CreateTriggerSkill{
  name = 'ol__mumu',
  anim_type = 'control',
  events = { fk.EventPhaseStart },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = { "Cancel" }
    if table.find(room.alive_players, function(p)
      return p:getEquipment(Card.SubtypeArmor)
    end) then table.insert(choices, 1, "ol__mumu_get") end
    if table.find(room:getOtherPlayers(player), function(p)
      return #p:getCardIds("e") > 0
    end) then table.insert(choices, 1, "ol__mumu_discard") end
    local choice = room:askForChoice(player, choices, self.name)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == 'ol__mumu_discard' then
      local targets = table.filter(room:getOtherPlayers(player), function(p)
        return #p:getCardIds("e") > 0
      end)

      targets = table.map(targets, Util.IdMapper)
      local pid = room:askForChoosePlayers(player, targets, 1, 1, '#ol__mumu-discard',
        self.name, false)[1]

      local to = room:getPlayerById(pid)
      local id = room:askForCardChosen(player, to, "e", self.name)
      room:throwCard(id, self.name, to, player)
    else
      local targets = table.filter(room.alive_players, function(p)
        return p:getEquipment(Card.SubtypeArmor)
      end)

      targets = table.map(targets, Util.IdMapper)
      local pid = room:askForChoosePlayers(player, targets, 1, 1, '#ol__mumu-get',
        self.name, false)[1]

      local to = room:getPlayerById(pid)
      local id = to:getEquipment(Card.SubtypeArmor)
      room:setPlayerMark(player, '@ol__mumu-turn', 1)
      room:obtainCard(player, id)
    end
  end,
}
ol__mumu:addRelatedSkill(ol__mumu_pro)
ol__sunluyu:addSkill(ol__mumu)
local zhixip = fk.CreateProhibitSkill{
  name = '#ol__zhixi_prohibit',
  prohibit_use = function(self, player)
    if not player:hasSkill('ol__zhixi') then
      return false
    end
    local mark = player:getMark('@ol__zhixi-phase')
    if type(mark) == "string" then mark = math.huge end
    return mark >= player.hp
  end,
}
local zhixi = fk.CreateTriggerSkill{
  name = 'ol__zhixi',
  frequency = Skill.Compulsory,
  refresh_events = { fk.CardUsing },
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.card.type == Card.TypeTrick then
      room:setPlayerMark(player, '@ol__zhixi-phase', '∞')
    elseif type(player:getMark('@ol__zhixi-phase')) == "number" then
      room:addPlayerMark(player, '@ol__zhixi-phase', 1)
    end
  end,
}
zhixi:addRelatedSkill(zhixip)
ol__sunluyu:addRelatedSkill(zhixi)
Fk:loadTranslationTable{
  ['ol__sunluyu'] = '孙鲁育',
  ['ol__meibu'] = '魅步',
  [':ol__meibu'] = '其他角色的出牌阶段开始时，若你在其攻击范围内，' ..
    '你可以弃置一张牌，令该角色于本回合内拥有〖止息〗。' ..
    '若你以此法弃置的牌不是【杀】或黑色锦囊牌，则本回合其与你距离视为1。',
  ['#ol__meibu-invoke'] = '魅步：是否弃置一张牌让 %src 本回合获得技能“止息”？',
  ['ol__mumu'] = '穆穆',
  [':ol__mumu'] = '出牌阶段开始时，你可以选择一项：1.弃置一名其他角色装备区里的一张牌；2.获得一名角色装备区里的一张防具牌且你本回合不能使用或打出【杀】。',
  ['ol__mumu_get'] = '获得一名角色装备区的防具，本回合不可出杀',
  ['ol__mumu_discard'] = '弃置一名其他角色装备区里的一张牌',
  ['#ol__mumu-discard'] = '穆穆：请选择一名其他角色，弃置其装备区里的一张牌',
  ['#ol__mumu-get'] = '穆穆：请选择一名角色，获得其防具',
  ['@ol__mumu-turn'] = '穆穆不能出杀',
  ['ol__zhixi'] = '止息',
  [':ol__zhixi'] = '锁定技，出牌阶段你可至多使用X张牌，你使用锦囊牌后，不能再使用牌（X为你的体力值）。',
  ['@ol__zhixi-phase'] = '止息已使用',

  ['$ol__meibu1'] = '姐姐，妹妹不求达官显贵，但求家人和睦。',
  ['$ol__meibu2'] = '储君之争，实为仇者快，亲者痛矣。',
  ['$ol__mumu1'] = '穆穆语言，不惊左右。',
  ['$ol__mumu2'] = '亲人和睦，国家安定就好。',
  ['~ol__sunluyu'] = '姐妹之间，何必至此？',
}

-- local hejin = General(extension, "ol__hejin", "qun", 4)

Fk:loadTranslationTable{
  ["ol__hejin"] = "何进",
  ["ol__mouzhu"] = "谋诛",
  [":ol__mouzhu"] = "出牌阶段限一次，你可以令一名其他角色交给你一张手牌，若其手牌数小于你，其视为使用一张【杀】或【决斗】。",
  ["ol__yanhuo"] = "延祸",
  [":ol__yanhuo"] = "当你死亡时，你可以弃置杀死你的角色至多X张牌（X为你的牌数）。",
}

-- local niujin = General(extension, "ol__niujin", "wei", 4)

Fk:loadTranslationTable{
  ["ol__niujin"] = "牛金",
  ["ol__cuorui"] = "挫锐",
  [":ol__cuorui"] = "锁定技，游戏开始时，你将手牌数摸至X张（X为场上角色数）。当你成为延时锦囊牌的目标后，你跳过下个判定阶段。",
  ["ol__liewei"] = "裂围",
  [":ol__liewei"] = "当你杀死一名角色时，你可以摸三张牌。",
}

local hansui = General(extension, "ol__hansui", "qun", 4)
local niluan = fk.CreateTriggerSkill{
  name = "ol__niluan",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Finish and target.hp > player.hp and target:usedCardTimes("slash") > 0 and not player:prohibitUse(Fk:cloneCard("slash")) and not player:isProhibited(target, Fk:cloneCard("slash"))
  end,
  on_cost = function(self, event, target, player, data)
    local cids = player.room:askForCard(player, 1, 1, true, self.name, true, ".|.|club,spade", "#ol__niluan-slash:" .. target.id)
    if #cids > 0 then
      self.cost_data = cids
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("slash", self.cost_data, player, target, self.name)
  end,
}
local xiaoxi = fk.CreateTriggerSkill{
  name = "ol__xiaoxi",
  anim_type = "offensive",
  events = {fk.RoundStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not player:prohibitUse(Fk:cloneCard("slash"))
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
    local tos = room:askForChoosePlayers(player, targets, 1, max_num, "#ol__xiaoxi-ask", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local slash = Fk:cloneCard("slash")
    slash.skillName = self.name
    player.room:useCard{
      from = target.id,
      tos = table.map(self.cost_data, function(pid) return { pid } end),
      card = slash,
      extraUse = true,
    }
  end,
}
hansui:addSkill(niluan)
hansui:addSkill(xiaoxi)
Fk:loadTranslationTable{
  ["ol__hansui"] = "韩遂",
  ["ol__niluan"] = "逆乱",
  [":ol__niluan"] = "体力值大于你的角色的结束阶段，若其此回合使用过【杀】，你可以将一张黑色牌当【杀】对其使用。",
  ["ol__xiaoxi"] = "骁袭",
  [":ol__xiaoxi"] = "每轮开始时，你可以视为使用一张无距离限制的【杀】。",

  ["#ol__niluan-slash"] = "逆乱：你可以将一张黑色牌当【杀】对 %src 使用",
  ["#ol__xiaoxi-ask"] = "骁袭：你可以视为使用一张无距离限制的【杀】",

  ["$ol__niluan1"] = "如果不能功成名就，那就干脆为祸一方！",
  ["$ol__niluan2"] = "哈哈哈哈哈，天下之事皆无常！",
  ["$ol__xiaoxi1"] = "打你个措手不及！",
  ["$ol__xiaoxi2"] = "两军交战，勇者为胜！",
  ["~ol__hansui"] = "马侄儿为何……啊！",
}

local ol__zhugeguo =  General(extension, "ol__zhugeguo", "shu", 3, 3, General.Female)
local ol__qirang = fk.CreateTriggerSkill{
  name = "ol__qirang",
  anim_type = "control",
  events = {fk.CardUseFinished ,fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      return player:hasSkill(self) and target == player and data.card.type == Card.TypeEquip
    else
      return player:hasSkill(self) and target == player and data.card:getMark("@@ol__qirang") > 0 and data.firstTarget and data.tos and #AimGroup:getAllTargets(data.tos) == 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      return room:askForSkillInvoke(player, self.name)
    else
      local targets = {}
      local current_targets = AimGroup:getAllTargets(data.tos) -- TargetGroup:getRealTargets(data.tos)
      for _, p in ipairs(room.alive_players) do
        if not table.contains(current_targets, p.id) and not player:isProhibited(p, data.card) 
        and data.card.skill:modTargetFilter(p.id, {}, data.from, data.card, true) then
          if not (data.card.name == "collateral" and not table.find(room:getOtherPlayers(p), function(v) return p:inMyAttackRange(v) end)) then
            table.insert(targets, p.id)
          end
        end
      end
      if #targets == 0 then return false end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#ol__qirang-choose:::"..data.card:toLogString(), self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|trick")
      if #cards > 0 then
        local get = cards[1]
        local card = Fk:getCardById(get)
        room:obtainCard(player, get, false, fk.ReasonDraw)
        if card.sub_type == Card.SubtypeDelayedTrick then
          room:addPlayerMark(player, "ol__yuhua_next")
        elseif room:getCardArea(get) == Card.PlayerHand and room:getCardOwner(get) == player then
          room:setCardMark(card, "@@ol__qirang", 1)
        end
      else
        room:sendLog{type = "#DrawByRuleFailed", from = player.id, arg = self.name}
      end
    else
      local id = self.cost_data
      local to = room:getPlayerById(id)
      if data.card.name == "collateral" then
        local victim = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(to), function(v)
        return to:inMyAttackRange(v) end), Util.IdMapper), 1, 1,
        "#collateral-choose::"..to.id..":"..data.card:toLogString(), "collateral_skill", false)
        TargetGroup:pushTargets(data.targetGroup, {id, victim[1]})
      else
        TargetGroup:pushTargets(data.targetGroup, id)
      end
    end
  end,

  refresh_events = {fk.TurnEnd, fk.AfterCardsMove},
  can_refresh = function (self, event, target, player, data)
    if event == fk.TurnEnd then
      return target == player and (player:getMark("ol__yuhua_next") > 0 or player:getMark("ol__yuhua_current") > 0)
    else
      for _, move in ipairs(data) do
        if move.toArea ~= Card.Processing then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getMark("@@ol__qirang") > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if event == fk.TurnEnd then
      room:setPlayerMark(player, "ol__yuhua_current", player:getMark("ol__yuhua_next"))
      room:setPlayerMark(player, "ol__yuhua_next", 0)
    else
      for _, move in ipairs(data) do
        if move.toArea ~= Card.Processing then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getMark("@@ol__qirang") > 0 then
              room:setCardMark(Fk:getCardById(info.cardId), "@@ol__qirang", 0)
            end
          end
        end
      end
    end
  end
}
ol__zhugeguo:addSkill(ol__qirang)
local ol__yuhua = fk.CreateTriggerSkill{
  name = "ol__yuhua",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askForGuanxing(player, room:getNCards(math.min(5, 1+player:getMark("ol__yuhua_current"))))
  end,
}
local ol__yuhua_maxcards = fk.CreateMaxCardsSkill{
  name = "#ol__yuhua_maxcards",
  exclude_from = function(self, player, card)
    return player:hasSkill(self) and card and card.type ~= Card.TypeBasic
  end,
}
ol__yuhua:addRelatedSkill(ol__yuhua_maxcards)
ol__zhugeguo:addSkill(ol__yuhua)
Fk:loadTranslationTable{
  ["ol__zhugeguo"] = "诸葛果",
  ["ol__qirang"] = "祈禳",
  [":ol__qirang"] = "当你使用装备牌结算结束后，你可以获得牌堆中的一张锦囊牌，若此牌：为普通锦囊牌，你使用此牌仅指定一个目标时，可以额外指定一个目标；不为普通锦囊牌，你的下个回合发动〖羽化〗时观看的牌数的值+1（至多加至5）。",
  ["@@ol__qirang"] = "祈禳",
  ["#DrawByRuleFailed"] = "由于没有符合条件的牌，%from 发动的 %arg 定向检索失败",
  ["#ol__qirang-choose"] = "祈禳：你可以为%arg额外指定一个目标",
  ["ol__yuhua"] = "羽化",
  [":ol__yuhua"] = "锁定技，①你的非基本牌不计入手牌上限；②准备阶段或结束阶段，你观看牌堆顶的一张牌，并将其中任意张牌以任意顺序置于牌堆顶，将剩余的牌以任意顺序置于牌堆底。",

  ["$ol__qirang1"] = "求福禳灾，家和万兴。",
  ["$ol__qirang2"] = "禳解百祸，祈运千秋。",
  ["$ol__yuhua1"] = "虹衣羽裳，出尘入仙。",
  ["$ol__yuhua2"] = "羽化成蝶，翩仙舞愿。",
  ["~ol__zhugeguo"] = "化羽难成，仙境已逝。",
}

local ol__caozhang = General(extension, "ol__caozhang", "wei", 4)
local ol__jiangchi_select = fk.CreateActiveSkill{
  name = "ol__jiangchi_select",
  can_use = function() return false end,
  target_num = 0,
  max_card_num = 1,
  min_card_num = 0,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
}
local ol__jiangchi = fk.CreateTriggerSkill{
  name = "ol__jiangchi",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local _, ret = player.room:askForUseActiveSkill(player, "#ol__jiangchi_select", "#ol__jiangchi-invoke", true)
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
      room:throwCard(self.cost_data, self.name, player)
      room:addPlayerMark(player, "@@ol__jiangchi_targetmod-turn")
    else
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name, 1)
      player:drawCards(1, self.name)
      room:addPlayerMark(player, "@@ol__jiangchi_prohibit-turn")
    end
  end,
}
local ol__jiangchi_targetmod = fk.CreateTargetModSkill{
  name = "#ol__jiangchi_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@@ol__jiangchi_targetmod-turn") > 0 and scope == Player.HistoryPhase then
      return 1
    end
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return skill.trueName == "slash_skill" and player:getMark("@@ol__jiangchi_targetmod-turn") > 0
  end,
}
local ol__jiangchi_prohibit = fk.CreateProhibitSkill{
  name = "#ol__jiangchi_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@ol__jiangchi_prohibit-turn") > 0 and card and card.trueName == "slash"
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("@@ol__jiangchi_prohibit-turn") > 0 and card and card.trueName == "slash"
  end,
}
local ol__jiangchi_maxcards = fk.CreateMaxCardsSkill{
  name = "#ol__jiangchi_maxcards",
  exclude_from = function(self, player, card)
    return card and card.trueName == "slash" and player:getMark("@@ol__jiangchi_prohibit-turn") > 0
  end,
}
Fk:addSkill(ol__jiangchi_select)
ol__jiangchi:addRelatedSkill(ol__jiangchi_targetmod)
ol__jiangchi:addRelatedSkill(ol__jiangchi_prohibit)
ol__jiangchi:addRelatedSkill(ol__jiangchi_maxcards)
ol__caozhang:addSkill(ol__jiangchi)

Fk:loadTranslationTable{
  ["ol__caozhang"] = "曹彰",
  ["ol__jiangchi"] = "将驰",
  [":ol__jiangchi"] = "摸牌阶段结束时，你可以选择一项：1.摸一张牌，本回合不能使用或打出【杀】，且【杀】不计入手牌上限；2.弃置一张牌，本回合使用【杀】无距离限制且可以多使用一张【杀】。",
  ["#ol__jiangchi-invoke"] = "将驰：1.摸一张牌，本回合不能使用或打出【杀】，【杀】不计入手牌上限；<br>2.弃置一张牌，本回合使用【杀】无距离限制且可多使用一张【杀】。点“取消”：不发动",
  ["@@ol__jiangchi_targetmod-turn"] = "将驰 多出杀",
  ["@@ol__jiangchi_prohibit-turn"] = "将驰 不出杀",
  ["#ol__jiangchi_prohibit"] = "将驰",
  ["ol__jiangchi_select"] = "将驰",
  ["$ol__jiangchi1"] = "丈夫当将十万骑驰沙漠，立功建号耳。",
  ["$ol__jiangchi2"] = "披坚执锐，临危不难，身先士卒。",
  ["~ol__caozhang"] = "黄须儿，愧对父亲……",
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
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), function(p)
      return p.id end), 1, #cards, "#ol__bingyi-choose:::"..#cards, self.name, true)
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
  ["ol__bingyi"] = "秉壹",
  [":ol__bingyi"] = "每阶段限一次，当你的牌被弃置后，你可以展示所有手牌，若颜色均相同，你令你与至多X名角色各摸一张牌（X为你的手牌数）。",
  ["#ol__bingyi-choose"] = "秉壹：你可以与至多%arg名其他角色各摸一张牌，点取消则仅你摸牌",

  ["$shenxing_ol__guyong1"] = "上兵伐谋，三思而行。",
  ["$shenxing_ol__guyong2"] = "精益求精，慎之再慎。",
  ["$ol__bingyi1"] = "秉直进谏，勿藏私心！",
  ["$ol__bingyi2"] = "秉公守一，不负圣恩！",
  ["~ol__guyong"] = "此番患疾，吾必不起……",
}

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
      local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#skillchooseother:::"..self.name, self.name, true)
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
    return player:hasSkill(self.name,false,true) and target == player
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#skillchooseother:::"..self.name, self.name, true)
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
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#skillchooseother:::"..self.name, self.name, true)
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
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#skillchooseother:::"..self.name, self.name, true)
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
  ["~ol__jikang"] = "曲终人散，空留余音。",
}

return extension