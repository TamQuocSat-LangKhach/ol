local extension = Package("ol_sp3")
extension.extensionName = "ol"

Fk:loadTranslationTable{
  ["ol_sp3"] = "OL专属3",
}

--胡班2023.1.13
--傅肜2023.2.4
--刘巴2023.2.25
--马承2023.3.26

local quhuang = General(extension, "quhuang", "wu", 3)
local qiejian = fk.CreateTriggerSkill{
  name = "qiejian",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:getMark("qiejian-turn") == 0 then
      for _, move in ipairs(data) do
        if move.from and player.room:getPlayerById(move.from):isKongcheng() and not player.room:getPlayerById(move.from).dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              self.cost_data = move.from
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    player:drawCards(1, self.name)
    to:drawCards(1, self.name)
    local choices = {"qiejian_nulli"}
    if #player:getCardIds{Player.Equip, Player.Judge} > 0 or #to:getCardIds{Player.Equip, Player.Judge} > 0 then
      table.insert(choices, 1, "qiejian_discard")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "qiejian_discard" then
      local targets = {}
      if #player:getCardIds{Player.Equip, Player.Judge} > 0 then table.insertIfNeed(targets, player.id) end
      if #to:getCardIds{Player.Equip, Player.Judge} > 0 then table.insertIfNeed(targets, to.id) end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#qiejian-choose", self.name)
      local p
      if #tos > 0 then
        p = room:getPlayerById(tos[1])
      else
        p = room:getPlayerById(table.random(targets))
      end
      local id = room:askForCardChosen(player, p, 'ej', self.name)
      room:throwCard({id}, self.name, p, player)
    else
      room:addPlayerMark(player, "qiejian-turn", 1)
    end
  end,
}
local nishou = fk.CreateTriggerSkill{
  name = "nishou",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              self.cost_data = info.cardId
              return not player:hasDelayedTrick("lightning") or player:getMark(self.name) == 0
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    if not player:hasDelayedTrick("lightning") then
      table.insert(choices, "nishou_lightning")
    end
    if player:getMark(self.name) == 0 then
      table.insert(choices, "nishou_nulli")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "nishou_lightning" then
      local card = Fk:cloneCard("lightning")
      card:addSubcards({self.cost_data})
      room:useCard{
        from = player.id,
        tos = {{player.id}},
        card = card,
      }
    else
      room:addPlayerMark(player, self.name, 1)  --ATTENTION: this mark shouldn't end with "-phase"!
    end
  end,

  refresh_events = {fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    return player:getMark(self.name) > 0 and not player:isKongcheng()
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name, 0)
    local n = #player.player_cards[Player.Hand]
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if #p.player_cards[Player.Hand] < n then
        n = #p.player_cards[Player.Hand]
      end
    end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if #p.player_cards[Player.Hand] == n then
        table.insert(targets, p.id)
      end
    end
    local to
    if #targets == 0 then
      return
    elseif #targets == 1 then
      to = targets[1]
    else
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#nishou-choose", self.name)
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
    end
    local cards1 = table.clone(player.player_cards[Player.Hand])
    local cards2 = table.clone(room:getPlayerById(to).player_cards[Player.Hand])
    local move1 = {
      from = player.id,
      ids = cards1,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,  --FIXME: this is still visible! same problem with dimeng!
    }
    local move2 = {
      from = to,
      ids = cards2,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    room:moveCards(move1, move2)
    local move3 = {
      ids = cards1,
      fromArea = Card.Processing,
      to = to,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    local move4 = {
      ids = cards2,
      fromArea = Card.Processing,
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    room:moveCards(move3, move4)
  end,
}
quhuang:addSkill(qiejian)
quhuang:addSkill(nishou)
Fk:loadTranslationTable{
  ["quhuang"] = "屈晃",
  ["qiejian"] = "切谏",
  [":qiejian"] = "当一名角色失去最后的手牌后，你可以与其各摸一张牌，然后选择一项：1.弃置你或其场上一张牌；2.本回合本技能失效。",
  ["nishou"] = "泥首",
  [":nishou"] = "锁定技，当你装备区里的牌进入弃牌堆后，你选择一项：1.将第一张装备牌当【闪电】使用；2.本阶段结束时与手牌数最少的角色交换手牌，然后本阶段内你无法选择本项。",
  ["qiejian_discard"] = "弃置你或其场上一张牌",
  ["qiejian_nulli"] = "本回合本技能失效",
  ["#qiejian-choose"] = "切谏：弃置你或其场上一张牌",
  ["nishou_lightning"] = "将第一张装备牌当【闪电】使用",
  ["nishou_nulli"] = "本阶段无法选择本项，本阶段结束时你与手牌数最少的角色交换手牌",
  ["#nishou-choose"] = "泥首：你需与手牌数最少的角色交换手牌",
}

local zhanghua = General(extension, "zhanghua", "jin", 3)
local bihun = fk.CreateTriggerSkill{
  name = "bihun",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and #player.player_cards[Player.Hand] > player:getMaxCards() and data.firstTarget and
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
    return target == player and player:hasSkill(self.name)
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
}

local dongtuna = General(extension, "dongtuna", "qun", 4)
local jianman = fk.CreateTriggerSkill{
  name = "jianman",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
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
          return not player:isProhibited(p, Fk:cloneCard(name)) end), function(p) return p.id end)
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
    return player:hasSkill(self.name) and data.card.type == Card.TypeBasic and not table.contains(data.card.skillNames, self.name)
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
}

local zhangyi = General(extension, "ol__zhangyiy", "shu", 4)
local dianjun = fk.CreateTriggerSkill{
  name = "dianjun",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to == Player.NotActive
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
    if player:hasSkill(self.name) and target.phase ~= Player.NotActive and not target.dead then
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
    local choice = room:askForChoice(target, {"recover", "kangrui_damage"}, self.name)
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

  refresh_events = {fk.DamageCaused, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("kangrui_damage-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      data.damage = data.damage + 1
    else
      player.room:addPlayerMark(player, "MinusMaxCards-turn", 999)
      player.room:setPlayerMark(player, "kangrui_damage-turn", 0)
    end
  end,
}
zhangyi:addSkill(dianjun)
zhangyi:addSkill(kangrui)
Fk:loadTranslationTable{
  ["ol__zhangyiy"] = "张翼",
  ["dianjun"] = "殿军",
  [":dianjun"] = "锁定技，回合结束时，你受到1点伤害并执行一个额外的出牌阶段。",
  ["kangrui"] = "亢锐",
  [":kangrui"] = "当一名角色于其回合内首次受到伤害后，你可以摸一张牌并令其：1.回复1点体力；2.本回合下次造成的伤害+1，然后当其造成伤害后，其此回合手牌上限改为0。",
  ["#kangrui-invoke"] = "亢锐：你可以摸一张牌，令 %dest 选择回复1点体力或本回合下次造成伤害+1",
  ["kangrui_damage"] = "本回合下次造成伤害+1，造成伤害后本回合手牌上限改为0",
}

local maxiumatie = General(extension, "maxiumatie", "qun", 4)
local kenshang = fk.CreateViewAsSkill{
  name = "kenshang",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return true
  end,
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
      return not player:isProhibited(p, use.card) end), function(p) return p.id end)
    local n = math.min(#targets, #use.card.subcards)
    local tos = room:askForChoosePlayers(player, targets, n, n, "#kenshang-choose:::"..n, self.name, false)
    if #tos > 0 then
      table.forEach(TargetGroup:getRealTargets(use.tos), function (id)
        TargetGroup:removeTarget(use.tos, id)
      end)
      for _, id in ipairs(tos) do
        TargetGroup:pushTargets(use.tos, id)
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    return player:hasSkill(self.name) and not response
  end,
}
local kenshang_record = fk.CreateTriggerSkill{
  name = "#kenshang_record",

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "kenshang") and data.damageDealt
  end,
  on_refresh = function(self, event, target, player, data)
    local n = 0
    for _, p in ipairs(player.room:getAllPlayers()) do
      if data.damageDealt[p.id] then
        n = n + data.damageDealt[p.id]
      end
    end
    if #data.card.subcards > n then
      player:drawCards(1, "kenshang")
    end
  end,
}
kenshang:addRelatedSkill(kenshang_record)
maxiumatie:addSkill("mashu")
maxiumatie:addSkill(kenshang)
Fk:loadTranslationTable{
  ["maxiumatie"] = "马休马铁",
  ["kenshang"] = "垦伤",
  [":kenshang"] = "你可以将至少两张牌当【杀】使用，然后目标可以改为等量的角色。你以此法使用的【杀】结算后，若这些牌数大于此牌造成的伤害，你摸一张牌。",
  ["#kenshang-choose"] = "垦伤：你可以将目标改为指定%arg名角色",
}

local zhujun = General(extension, "ol__zhujun", "qun", 4)
local cuipo = fk.CreateTriggerSkill{
  name = "cuipo",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("@cuipo-turn") == #Fk:translate(data.card.trueName)/3
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
    return target == player and player:hasSkill(self.name)
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
}
--王瓘 2023.5.10
local luoxian = General(extension, "luoxian", "shu", 4)
local daili = fk.CreateTriggerSkill{
  name = "daili",
  anim_type = "drawcard",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and (player:getMark("@$daili") == 0 or #player:getMark("@$daili") % 2 == 0)
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
    local cards = player:drawCards(3, self.name)
    player:showCards(cards)
  end,

  refresh_events = {fk.CardShown, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardShown then
      return target == player and player:hasSkill(self.name, true)
    else
      return player:getMark(self.name) ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("@$daili")
    local mark2 = player:getMark(self.name)
    if event == fk.CardShown then
      if mark == 0 then mark = {} end
      if mark2 == 0 then mark2 = {} end
      for _, id in ipairs(data.cardIds) do
        table.insert(mark, Fk:getCardById(id, true).name)
        table.insert(mark2, id)
      end
      player.room:setPlayerMark(player, "@$daili", mark)
      player.room:setPlayerMark(player, self.name, mark2)
    else
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              if table.contains(mark2, info.cardId) then
                table.removeOne(mark, Fk:getCardById(info.cardId, true).name)
                table.removeOne(mark2, info.cardId)
              end
            end
          end
        end
      end
      player.room:setPlayerMark(player, "@$daili", mark)
      player.room:setPlayerMark(player, self.name, mark2)
    end
  end,
}
luoxian:addSkill(daili)
Fk:loadTranslationTable{
  ["luoxian"] = "罗宪",
  ["daili"] = "带砺",
  [":daili"] = "每回合结束时，若你有偶数张展示过的手牌，你可以翻面，摸三张牌并展示之。",
  ["@$daili"] = "带砺",
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
  card_filter = function(self, to_select, selected)
    return false
  end,
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
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = data.num
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p:getMark(self.name) == 0 and #p:getCardIds{Player.Hand, Player.Equip} >= n end), function(p) return p.id end)
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
    room:obtainCard(player, dummy, false, fk.ReasonPrey)
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
}

return extension
