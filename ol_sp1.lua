local extension = Package("ol_sp1")
extension.extensionName = "ol"

Fk:loadTranslationTable{
  ["ol_sp1"] = "OL专属1",
  ["ol"] = "OL",
}

---@param player ServerPlayer @ 执行的玩家
---@param targets ServerPlayer[] @ 可选的目标范围
---@param num integer @ 可选的目标数
---@param can_minus boolean @ 是否可减少
---@param prompt string @ 提示信息
---@param skillName string @ 技能名
---@param data CardUseStruct @ 使用数据
--枚举法为使用牌增减目标（无距离限制）
local function AskForAddTarget(player, targets, num, can_minus, prompt, skillName, data)
  num = num or 1
  can_minus = can_minus or false
  prompt = prompt or ""
  skillName = skillName or ""
  local room = player.room
  local tos = {}
  if can_minus and #AimGroup:getAllTargets(data.tos) > 1 then  --默认不允许减目标至0
    tos = table.map(table.filter(targets, function(p)
      return table.contains(AimGroup:getAllTargets(data.tos), p.id) end), function(p) return p.id end)
  end
  for _, p in ipairs(targets) do
    if not table.contains(AimGroup:getAllTargets(data.tos), p.id) and not room:getPlayerById(data.from):isProhibited(p, data.card) then
      if data.card.name == "jink" or data.card.trueName == "nullification" or data.card.name == "adaptation" or
        (data.card.name == "peach" and not p:isWounded()) then
        --continue
      else
        if data.from ~= p.id then
          if (data.card.trueName == "slash") or
            ((table.contains({"dismantlement", "snatch", "chasing_near"}, data.card.name)) and not p:isAllNude()) or
            (table.contains({"fire_attack", "unexpectation"}, data.card.name) and not p:isKongcheng()) or
            (table.contains({"peach", "analeptic", "ex_nihilo", "duel", "savage_assault", "archery_attack", "amazing_grace", "god_salvation", 
              "iron_chain", "foresight", "redistribute", "enemy_at_the_gates", "raid_and_frontal_attack"}, data.card.name)) or
            (data.card.name == "collateral" and p:getEquipment(Card.SubtypeWeapon) and
              #table.filter(room:getOtherPlayers(p), function(v) return p:inMyAttackRange(v) end) > 0)then
            table.insertIfNeed(tos, p.id)
          end
        else
          if (data.card.name == "analeptic") or
            (table.contains({"ex_nihilo", "foresight", "iron_chain", "amazing_grace", "god_salvation", "redistribute"}, data.card.name)) or
            (data.card.name == "fire_attack" and not p:isKongcheng()) then
            table.insertIfNeed(tos, p.id)
          end
        end
      end
    end
  end
  if #tos > 0 then
    tos = room:askForChoosePlayers(player, tos, 1, num, prompt, skillName, true)
    if data.card.name ~= "collateral" then
      return tos
    else
      local result = {}
      for _, id in ipairs(tos) do
        local to = room:getPlayerById(id)
        local target = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(v)
          return to:inMyAttackRange(v) end), function(p) return p.id end), 1, 1,
          "#collateral-choose::"..to.id..":"..data.card:toLogString(), "collateral_skill", true)
        if #target > 0 then
          table.insert(result, {id, target[1]})
        end
      end
      if #result > 0 then
        return result
      else
        return {}
      end
    end
  end
  return {}
end

local zhugeke = General(extension, "zhugeke", "wu", 3)
local aocai = fk.CreateTriggerSkill{
  name = "aocai",
  anim_type = "defensive",
  events = {fk.AskForCardUse, fk.AskForCardResponse},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.NotActive and
      ((data.cardName and Fk:cloneCard(data.cardName).type == Card.TypeBasic) or
      (data.pattern and Exppattern:Parse(data.pattern):matchExp(".|.|.|.|.|basic")))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids
    if player:isKongcheng() then
      ids = room:getNCards(4)
    else
      ids = room:getNCards(2)
    end
    local fakemove = {
      toArea = Card.PlayerHand,
      to = player.id,
      moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.Void} end),
      moveReason = fk.ReasonJustMove,
    }
    room:notifyMoveCards({player}, {fakemove})
    local availableCards = {}
    for _, id in ipairs(ids) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic then
        if data.pattern then
          if Exppattern:Parse(data.pattern):match(card) then
            table.insertIfNeed(availableCards, id)
          end
        else
          if player:canUse(card) then
            table.insertIfNeed(availableCards, id)
          end
        end
      end
    end
    room:setPlayerMark(player, "aocai_cards", availableCards)
    local success, dat
    if event == fk.AskForCardUse then
      success, dat = room:askForUseActiveSkill(player, "aocai_use", "#aocai-use", true)
    else
      success, dat = room:askForUseActiveSkill(player, "aocai_response", "#aocai-response", true)
    end
    room:setPlayerMark(player, "aocai_cards", 0)
    fakemove = {
      from = player.id,
      toArea = Card.Void,
      moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.PlayerHand} end),
      moveReason = fk.ReasonJustMove,
    }
    room:notifyMoveCards({player}, {fakemove})
    for i = #ids, 1, -1 do
      table.insert(room.draw_pile, 1, ids[i])
    end
    if success then
      if event == fk.AskForCardUse then
        local card = Fk.skills["aocai_use"]:viewAs(dat.cards)
        data.result = {
          from = player.id,
          card = card,
        }
        data.result.card.skillName = self.name
        if data.eventData then
          data.result.toCard = data.eventData.toCard
          data.result.responseToEvent = data.eventData.responseToEvent
        end
      else
        local card =  Fk:getCardById(dat.cards[1])
        data.result = card
        data.result.skillName = self.name
      end
    end
    return true
  end
}
local aocai_use = fk.CreateViewAsSkill{
  name = "aocai_use",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      local ids = Self:getMark("aocai_cards")
      return type(ids) == "table" and table.contains(ids, to_select)
    end
  end,
  view_as = function(self, cards)
    if #cards == 1 then
      return Fk:getCardById(cards[1])
    end
  end,
}
local aocai_response = fk.CreateActiveSkill{
  name = "aocai_response",
  card_num = 1,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      local ids = Self:getMark("aocai_cards")
      return type(ids) == "table" and table.contains(ids, to_select)
    end
  end,
}
local duwu = fk.CreateActiveSkill{
  name = "duwu",
  anim_type = "offensive",
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("@@duwu-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return true
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if target.hp == #selected_cards then
        if table.contains(selected_cards, Self:getEquipment(Card.SubtypeWeapon)) then
          return Self:distanceTo(target) == 1  --FIXME: some skills(eg.gongqi, meibu) add attackrange directly!
        else
          return Self:inMyAttackRange(target)
        end
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player)
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = self.name,
    }
  end,
}
local duwu_trigger = fk.CreateTriggerSkill{
  name = "#duwu_trigger",
  mute = true,
  events = {fk.EnterDying, fk.AfterDying},
  can_trigger = function(self, event, target, player, data)
    return data.damage and data.damage.skillName == "duwu" and data.damage.from and data.damage.from == player and not player.dead
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EnterDying then
      data.extra_data = data.extra_data or {}
      data.extra_data.duwu = player.id
    elseif data.extra_data.duwu == player.id and not target.dead then
      local room = player.room
      room:setPlayerMark(player, "@@duwu-turn", 1)
      room:loseHp(player, 1, "duwu")
    end
  end,
}
Fk:addSkill(aocai_use)
Fk:addSkill(aocai_response)
duwu:addRelatedSkill(duwu_trigger)
zhugeke:addSkill(aocai)
zhugeke:addSkill(duwu)
Fk:loadTranslationTable{
  ["zhugeke"] = "诸葛恪",
  ["aocai"] = "傲才",
  [":aocai"] = "当你于回合外需要使用或打出一张基本牌时，你可以观看牌堆顶的两张牌（若你没有手牌则改为四张），若你观看的牌中有此牌，你可以使用或打出之。",
  ["duwu"] = "黩武",
  [":duwu"] = "出牌阶段，你可以弃置X张牌对你攻击范围内的一名其他角色造成1点伤害（X为该角色的体力值）。"..
  "若其因此进入濒死状态且被救回，则濒死状态结算后你失去1点体力，且本回合不能再发动〖黩武〗。",
  ["aocai_use"] = "傲才",
  ["aocai_response"] = "傲才",
  ["#aocai-use"] = "傲才：你可以使用其中你需要的牌",
  ["#aocai-response"] = "傲才：你可以打出其中你需要的牌",
  ["@@duwu-turn"] = "黩武失效",

  ["$aocai1"] = "哼，易如反掌。",
  ["$aocai2"] = "吾主圣明，泽披臣属。",
  ["$duwu1"] = "破曹大功，正在今朝！",
  ["$duwu2"] = "全力攻城！言退者，斩！",
  ["~zhugeke"] = "重权震主，是我疏忽了……",
}

local chengyu = General(extension, "chengyu", "wei", 3)
local shefu = fk.CreateTriggerSkill{
  name = "shefu",
  anim_type = "control",
  events ={fk.EventPhaseStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish and not player:isKongcheng()
      else
        return target ~= player and player.phase == Player.NotActive and (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local card = room:askForCard(player, 1, 1, false, self.name, true, ".", "#shefu-cost")
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      self.cost_data = 0
      local tag = player.tag[self.name]
      if type(tag) ~= "table" then return end
      for i = 1, #tag, 1 do
        if data.card.trueName == tag[i][2] then
          self.cost_data = tag[i][1]
          break
        end
      end
      if self.cost_data > 0 then
        return room:askForSkillInvoke(player, self.name)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      player:addToPile(self.name, self.cost_data, false, self.name)
      local names ={}
      local tag = player.tag[self.name]
      if type(tag) ~= "table" then tag ={} end
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id)
        if card.type == Card.TypeBasic or card.type == Card.TypeTrick then
          table.insertIfNeed(names, card.trueName)
        end
      end
      for i = #names, 1, -1 do
        for j = 1, #tag, 1 do
          if names[i] == tag[j][2] then
            table.remove(names, i)
          end
        end
      end
      if #names > 0 then
        local name = room:askForChoice(player, names, self.name)
        table.insert(tag,{self.cost_data[1], name})
        player.tag[self.name] = tag
      end
    else
      local tag = player.tag[self.name]
      for i = 1, #tag, 1 do
        if data.card.trueName == tag[i][2] then
          table.remove(tag, i)
          break
        end
      end
      player.tag[self.name] = tag
      room:moveCards({
        from = player.id,
        ids ={self.cost_data},
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        specialName = self.name,
      })
      data.tos ={}
    end
  end,
}
local benyu = fk.CreateTriggerSkill{
  name = "benyu",
  anim_type = "masochism",
  events ={fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from and not data.from.dead and player:getHandcardNum() ~= data.from:getHandcardNum()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getHandcardNum() > data.from:getHandcardNum() then
      local _, discard = room:askForUseActiveSkill(player, "discard_skill", "#benyu-discard::"..data.from.id..":"..data.from:getHandcardNum() + 1, true,{
        num = player:getHandcardNum(),
        min_num = data.from:getHandcardNum() + 1,
        include_equip = false,
        reason = self.name,
        pattern = ".|.|.|hand|.|.",
      })
      if discard then
        self.cost_data = discard.cards
        return true
      end
    else
      if player:getHandcardNum() < math.min(data.from:getHandcardNum(), 5) then
        return room:askForSkillInvoke(player, self.name)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if self.cost_data and type(self.cost_data) == "table" and #self.cost_data > 0 then
      player.room:throwCard(self.cost_data, self.name, player, player)
      player.room:damage{
        from = player,
        to = data.from,
        damage = 1,
        skillName = self.name,
      }
    else
      player:drawCards(math.min(5, data.from:getHandcardNum()) - player:getHandcardNum())
    end
  end,
}
chengyu:addSkill(shefu)
chengyu:addSkill(benyu)
Fk:loadTranslationTable{
  ["chengyu"] = "程昱",
  ["shefu"] = "设伏",
  [":shefu"] = "结束阶段开始时，你可将一张手牌扣置于武将牌上，称为“伏兵”。若如此做，你为“伏兵”记录一个基本牌或锦囊牌的名称"..
  "（须与其他“伏兵”记录的名称均不同）。当其他角色于你的回合外使用手牌时，你可将记录的牌名与此牌相同的一张“伏兵”置入弃牌堆，然后此牌无效。",
  ["benyu"] = "贲育",
  [":benyu"] = "当你受到伤害后，若你的手牌数不大于伤害来源手牌数，你可以将手牌摸至与伤害来源手牌数相同（最多摸至5张）；"..
  "否则你可以弃置大于伤害来源手牌数的手牌，然后对其造成1点伤害。",
  ["#shefu-cost"] = "设伏：你可以将一张手牌扣置为“伏兵”",
  ["#benyu-discard"] = "贲育：你可以弃置至少%arg张手牌，对 %dest 造成1点伤害",

  ["$shefu1"] = "圈套已设，埋伏已完，只等敌军进来。",
  ["$shefu2"] = "如此天网，量你插翅也难逃。",
  ["$benyu1"] = "曹公智略乃上天所授！",
  ["$benyu2"] = "天下大乱，群雄并起，必有命事。",
  ["~chengyu"] = "此诚报效国家之时，吾却休矣。",
}

local sunhao = General(extension, "sunhao", "wu", 5)
local canshi = fk.CreateTriggerSkill{
  name = "canshi",
  anim_type = "drawcard",
  events ={fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:isWounded() or (player:hasSkill("guiming") and p.kingdom == "wu" and p ~= player) then
        room:broadcastSkillInvoke("guiming")
        n = n + 1
      end
    end
    data.n = data.n + n
  end,

  refresh_events ={fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick) and
      player:usedSkillTimes(self.name) > 0 and not player:isNude()
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:askForDiscard(player, 1, 1, true, self.name)
  end,
}
local chouhai = fk.CreateTriggerSkill{
  name = "chouhai",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events ={fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local guiming = fk.CreateTriggerSkill{
  name = "guiming$",
  frequency = Skill.Compulsory,
}
sunhao:addSkill(canshi)
sunhao:addSkill(chouhai)
sunhao:addSkill(guiming)
Fk:loadTranslationTable{
  ["sunhao"] = "孙皓",
  ["canshi"] = "残蚀",
  [":canshi"] = "摸牌阶段，你可以多摸X张牌（X为已受伤的角色数），若如此做，当你于此回合内使用基本牌或锦囊牌时，你弃置一张牌。",
  ["chouhai"] = "仇海",
  [":chouhai"] = "锁定技，当你受到伤害时，若你没有手牌，你令此伤害+1。",
  ["guiming"] = "归命",
  [":guiming"] = "主公技，锁定技，其他吴势力角色于你的回合内视为已受伤的角色。",

  ["$canshi1"] = "众人与蝼蚁何异？哈哈哈……",
  ["$canshi2"] = "难道一切不在朕手中？",
  ["$chouhai1"] = "哼，树敌三千又如何？",
  ["$chouhai2"] = "不发狂，就灭亡！",
  ["$guiming1"] = "这是要我命归黄泉吗？",
  ["$guiming2"] = "这就是末世皇帝的不归路！",
  ["~sunhao"] = "命啊！命！",
}

local shixie = General(extension, "shixie", "qun", 3)
local biluan = fk.CreateTriggerSkill{
  name = "biluan",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Draw then
      for _, p in ipairs(player.room:getOtherPlayers(player)) do
        if p:distanceTo(player) == 1 then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    player.room:addPlayerMark(player, "@biluan", #kingdoms)
    return true
  end,
}
local biluan_distance = fk.CreateDistanceSkill{
  name = "#biluan_distance",
  correct_func = function(self, from, to)
    if to:getMark("@biluan") ~= 0 then
      return to:getMark("@biluan")
    end
  end,
}
local lixia = fk.CreateTriggerSkill{
  name = "lixia",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self.name) and target.phase == Player.Finish and not target:inMyAttackRange(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"draw1", "lixia_draw"}, self.name)
    if choice == "draw1" then
      player:drawCards(1, self.name)
    else
      target:drawCards(1, self.name)
    end
    room:setPlayerMark(player, "@biluan", player:getMark("@biluan") - 1)
  end,
}
biluan:addRelatedSkill(biluan_distance)  --FIXME:maybe this should relate to lixia lest skill be sealed...
shixie:addSkill(biluan)
shixie:addSkill(lixia)
Fk:loadTranslationTable{
  ["shixie"] = "士燮",
  ["biluan"] = "避乱",
  [":biluan"] = "摸牌阶段开始时，若有其他角色与你距离为1，则你可以放弃摸牌，然后其他角色计算与你距离+X（X为势力数）。",
  ["lixia"] = "礼下",
  [":lixia"] = "锁定技，其他角色的结束阶段，若你不在其攻击范围内，你选择一项：1.摸一张牌；2.其摸一张牌。然后其他角色与你的距离-1。",
  ["@biluan"] = "避乱",
  ["lixia_draw"] = "其摸一张牌",

  ["$biluan1"] = "身处乱世，自保足矣。",
  ["$biluan2"] = "避一时之乱，求长世安稳。",
  ["$lixia1"] = "将军真乃国之栋梁。",
  ["$lixia2"] = "英雄可安身立命于交州之地。",
  ["~shixie"] = "我这一生，足矣……",
}

local zhanglu = General(extension, "zhanglu", "qun", 3)
local yishe = fk.CreateTriggerSkill{
  name = "yishe",
  anim_type = "support",
  events = {fk.EventPhaseStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish and #player:getPile("zhanglu_mi") == 0
      else
        if #player:getPile("zhanglu_mi") == 0 and player:isWounded() then
          for _, move in ipairs(data) do
            if move.from == player.id then
              for _, info in ipairs(move.moveInfo) do
                if info.fromSpecialName == "zhanglu_mi" then
                  return true
                end
              end
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name, nil, "#yishe-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      player:drawCards(2, self.name)
      if player:isNude() then return end
      local dummy = Fk:cloneCard("dilu")
      local cards
      if #player:getCardIds("he") < 3 then
        cards = player:getCardIds("he")
      else
        cards = room:askForCard(player, 2, 2, true, self.name, false, ".", "#yishe-cost")
      end
      dummy:addSubcards(cards)
      player:addToPile("zhanglu_mi", dummy, true, self.name)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local bushi = fk.CreateTriggerSkill{
  name = "bushi",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and (target == player or data.from == player) and #player:getPile("zhanglu_mi") > 0 and not (data.from.dead or data.to.dead)
  end,
  on_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      self.cancel_cost = false
      for i = 1, data.damage do
        if #player:getPile("zhanglu_mi") == 0 or self.cancel_cost then return end
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(target, self.name, data) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player:getPile("zhanglu_mi") == 1 then
      room:obtainCard(target, player:getPile("zhanglu_mi")[1], true, fk.ReasonPrey)
    else
      room:fillAG(target, player:getPile("zhanglu_mi"))
      local id = room:askForAG(target, player:getPile("zhanglu_mi"), false, self.name)
      room:closeAG(target)
      room:obtainCard(target, id, true, fk.ReasonPrey)
    end
  end,
}
local midao = fk.CreateTriggerSkill{
  name = "midao",
  anim_type = "control",
  expand_pile = "zhanglu_mi",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and #player:getPile("zhanglu_mi") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForCard(player, 1, 1, false, self.name, true, ".|.|.|zhanglu_mi|.|.", "#midao-choose::" .. target.id, "zhanglu_mi")
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(Fk:getCardById(self.cost_data), player, data, self.name)
  end,
}
zhanglu:addSkill(yishe)
zhanglu:addSkill(bushi)
zhanglu:addSkill(midao)
Fk:loadTranslationTable{
  ["zhanglu"] = "张鲁",
  ["yishe"] = "义舍",
  [":yishe"] = "结束阶段开始时，若你的武将牌上没有牌，你可以摸两张牌，若如此做，你将两张牌置于武将牌上，称为“米”。当“米”移至其他区域后，"..
  "若你的武将牌上没有“米”，你回复1点体力。",
  ["bushi"] = "布施",
  [":bushi"] = "当你受到1点伤害后，或其他角色受到你造成的1点伤害后，受到伤害的角色可以获得一张“米”。",
  ["midao"] = "米道",
  [":midao"] = "当一张判定牌生效前，你可以打出一张“米”代替之。",
  ["zhanglu_mi"] = "米",
  ["#yishe-invoke"] = "义舍：你可以摸两张牌，然后将两张牌置为“米”",
  ["#yishe-cost"] = "义舍：将两张牌置为“米”",
  ["#midao-choose"] = "米道：你可以打出一张“米”修改 %dest 的判定",

  ["$yishe1"] = "行大义之举，须有向道之心。",
  ["$yishe2"] = "你有你的权谋，我，哼，自有我的道义。",
  ["$bushi1"] = "布施行善，乃道义之本。",
  ["$bushi2"] = "行布施，得天道。",
  ["$midao1"] = "从善从良，从五斗米道。",
  ["$midao2"] = "兼济天下，解百姓之忧。",
  ["~zhanglu"] = "但，归置于道，无意凡事争斗。",
}

local mayunlu = General(extension, "mayunlu", "shu", 4, 4, General.Female)
local fengpo = fk.CreateTriggerSkill{
  name = "fengpo",
  anim_type = "offensive",
  events ={fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (data.card.trueName == "slash" or data.card.trueName == "duel") and
      player:usedCardTimes("slash") + player:usedCardTimes("duel") <= 1 and data.firstTarget
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#fengpo-invoke::"..data.to..":"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local n = 0
    for _, id in ipairs(to:getCardIds("he")) do
      if Fk:getCardById(id).suit == Card.Diamond then
        n = n + 1
      end
    end
    local choice = room:askForChoice(player, {"fengpo_draw", "fengpo_damage"}, self.name,
      "#fengpo-choice::"..data.to..":"..data.card:toLogString())
    if choice == "fengpo_draw" then
      if n > 0 then
        player:drawCards(n, self.name)
      end
      data.additionalDamage = (data.additionalDamage or 0) + 1
    else
      player:drawCards(1, self.name)
      if n > 0 then
        data.additionalDamage = (data.additionalDamage or 0) + n
      end
    end
  end,
}
mayunlu:addSkill("mashu")
mayunlu:addSkill(fengpo)
Fk:loadTranslationTable{
  ["mayunlu"] = "马云騄",
  ["fengpo"] = "凤魄",
  [":fengpo"] = "当你每回合首次使用【杀】或【决斗】指定目标后，你可以选择一项：1.摸X张牌，此牌伤害+1；2.摸一张牌，此牌伤害+X"..
  "（X为其<font color='red'>♦</font>牌数）。",
  ["fengpo_draw"] = "摸X张牌，伤害+1",
  ["fengpo_damage"] = "摸一张牌，伤害+X",
  ["#fengpo-invoke"] = "凤魄：你可以令你对 %dest 使用的%arg发动“凤魄”",
  ["#fengpo-choice"] = "凤魄：选择你对 %dest 使用的%arg执行一项",

  ["$fengpo1"] = "等我提枪上马，打你个落花流水！",
  ["$fengpo2"] = "对付你，用不着我家哥哥亲自上阵！",
  ["~mayunlu"] = "呜呜……是你们欺负人……",
}

local wutugu = General(extension, "wutugu", "qun", 15)
local ranshang = fk.CreateTriggerSkill{
  name = "ranshang",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.Damaged then
        return data.damageType == fk.FireDamage
      else
        return player.phase == Player.Finish and player:getMark("@wutugu_ran") > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      room:addPlayerMark(player, "@wutugu_ran", data.damage)
    else
      room:loseHp(player, player:getMark("@wutugu_ran"), self.name)
    end
  end,
}
local hanyong = fk.CreateTriggerSkill{
  name = "hanyong",
  anim_type = "offensive",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      (data.card.name == "savage_assault" or data.card.name == "archery_attack") and player.hp < player.room:getTag("RoundCount")
  end,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
}
wutugu:addSkill(ranshang)
wutugu:addSkill(hanyong)
Fk:loadTranslationTable{
  ["wutugu"] = "兀突骨",
  ["ranshang"] = "燃殇",
  [":ranshang"] = "锁定技，当你受到1点火焰伤害后，你获得1枚“燃”标记；结束阶段，你失去X点体力（X为“燃”标记的数量）。",
  ["hanyong"] = "悍勇",
  [":hanyong"] = "当你使用【南蛮入侵】或【万箭齐发】时，若你的体力值小于游戏轮数，你可以令此牌造成的伤害+1。",
  ["@wutugu_ran"] = "燃",

  ["$ranshang1"] = "尔等，竟如此歹毒！",
  ["$ranshang2"] = "战火燃尽英雄胆！",
  ["$hanyong1"] = "犯我者，杀！",
  ["$hanyong2"] = "藤甲军从无对手，不服来战！",
  ["~wutugu"] = "撤，快撤！",
}

local cuiyan = General(extension, "cuiyan", "wei", 3)
local yawang = fk.CreateTriggerSkill{
  name = "yawang",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events ={fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local n = 0
    for _, p in ipairs(player.room.alive_players) do
      if p.hp == player.hp then
        n = n + 1
      end
    end
    player:drawCards(n, self.name)
    player.room:addPlayerMark(player, "yawang-turn", n)
    return true
  end,

  refresh_events ={fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(self.name, Player.HistoryTurn) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@yawang-turn", 1)
  end,
}
local yawang_prohibit = fk.CreateProhibitSkill{
  name = "#yawang_prohibit",
  prohibit_use = function(self, player, card)
    return player:usedSkillTimes("yawang", Player.HistoryTurn) > 0 and player.phase == Player.Play and
      player:getMark("@yawang-turn") >= player:getMark("yawang-turn")
  end,
}
local xunzhi = fk.CreateTriggerSkill{
  name = "xunzhi",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Start then
      for _, p in ipairs(player.room:getOtherPlayers(player)) do
        if (player:getNextAlive() == p or p:getNextAlive() == player) and player.hp == p.hp then return end
      end
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    room:addPlayerMark(player, MarkEnum.AddMaxCards, 2)
  end,
}
yawang:addRelatedSkill(yawang_prohibit)
cuiyan:addSkill(yawang)
cuiyan:addSkill(xunzhi)
Fk:loadTranslationTable{
  ["cuiyan"] = "崔琰",
  ["yawang"] = "雅望",
  [":yawang"] = "锁定技，摸牌阶段开始时，你放弃摸牌，改为摸X张牌，然后你于出牌阶段内至多使用X张牌（X为与你体力值相等的角色数）。",
  ["xunzhi"] = "殉志",
  [":xunzhi"] = "准备阶段开始时，若你的上家和下家与你的体力值均不相等，你可以失去1点体力。若如此做，你的手牌上限+2。",
  ["@yawang-turn"] = "雅望",

  ["$yawang1"] = "君子，当以正气立于乱世。",
  ["$yawang2"] = "琰，定不负诸位雅望！",
  ["$xunzhi1"] = "春秋大义，自在我心！",
  ["$xunzhi2"] = "成大义者，这点牺牲算不得什么！",
  ["~cuiyan"] = "尔等，皆是欺世盗名之辈！",
}

local guansuo = General(extension, "guansuo", "shu", 4)
local zhengnan = fk.CreateTriggerSkill{
  name = "zhengnan",
  anim_type = "drawcard",
  events = {fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3)
    local choices = {"wusheng", "dangxian", "zhiman"}
    for i = 3, 1, -1 do
      if player:hasSkill(choices[i]) then
        table.removeOne(choices, choices[i])
      end
    end
    if #choices > 0 then
      local choice = player.room:askForChoice(player, choices, self.name, "#zhengnan-choice", true)
      player.room:handleAddLoseSkills(player, choice, nil)
    end
  end,
}
local xiefang = fk.CreateDistanceSkill{
  name = "xiefang",
  correct_func = function(self, from, to)
    if from:hasSkill(self.name) then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.gender == General.Female then
          n = n + 1
        end
      end
      return -n
    end
    return 0
  end,
}
guansuo:addSkill(zhengnan)
guansuo:addSkill(xiefang)
guansuo:addRelatedSkill("wusheng")
guansuo:addRelatedSkill("dangxian")
guansuo:addRelatedSkill("zhiman")
Fk:loadTranslationTable{
  ["guansuo"] = "关索",
  ["zhengnan"] = "征南",
  [":zhengnan"] = "当其他角色死亡后，你可以摸三张牌，若如此做，你获得下列技能中的任意一个：〖武圣〗，〖当先〗和〖制蛮〗。",
  ["xiefang"] = "撷芳",
  [":xiefang"] = "锁定技，你计算与其他角色的距离-X（X为女性角色数）。",
  ["#zhengnan-choice"] = "征南：选择获得的技能",

  ["$zhengnan1"] = "全凭丞相差遣，万死不辞！",
  ["$zhengnan2"] = "末将愿承父志，随丞相出征！",
  ["~guansuo"] = "只恨天下未平，空留遗志。",
}

local tadun = General(extension, "tadun", "qun", 4)
local luanzhan = fk.CreateTriggerSkill{
  name = "luanzhan",
  anim_type = "offensive",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (data.card.trueName == "slash" or
      (data.card.color == Card.Black and data.card:isCommonTrick())) and
      player:getMark("@luanzhan") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local n = player:getMark("@luanzhan")
    local tos = AskForAddTarget(player, player.room:getAlivePlayers(), n, false,
      "#luanzhan-choose:::"..data.card:toLogString()..":"..tostring(n), self.name, data)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, id in ipairs(self.cost_data) do
      TargetGroup:pushTargets(data.targetGroup, id)
    end
  end,

  refresh_events = {fk.Damage, fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name, true) then
      if event == fk.Damage then
        return true
      else
        return (data.card.trueName == "slash" or
          (data.card.color == Card.Black and data.card:isCommonTrick())) and
          data.targetGroup and #data.targetGroup < player:getMark("@luanzhan")
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      room:addPlayerMark(player, "@luanzhan", 1)
    else
      room:setPlayerMark(player, "@luanzhan", 0)
    end
  end,
}
tadun:addSkill(luanzhan)
Fk:loadTranslationTable{
  ["tadun"] = "蹋顿",
  ["luanzhan"] = "乱战",
  [":luanzhan"] = "你使用【杀】或黑色非延时类锦囊牌可以额外选择X名角色为目标；当你使用【杀】或黑色非延时类锦囊牌指定目标后，"..
  "若此牌的目标角色数小于X，则X减至0。（X为你于本局游戏内造成过伤害的次数）。",
  ["@luanzhan"] = "乱战",
  ["#luanzhan-choose"] = "乱战：你可以为%arg额外指定至多%arg2个目标",

  ["$luanzhan1"] = "受袁氏大恩，当效死力。",
  ["$luanzhan2"] = "现，正是我乌桓崛起之机。",
  ["~tadun"] = "呃……不该趟曹袁之争的浑水……",
}

local yanbaihu = General(extension, "yanbaihu", "qun", 4)
local zhidao = fk.CreateTriggerSkill{
  name = "zhidao",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and data.to ~= player and
      not data.to.dead and not data.to:isAllNude() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "zhidao-turn", 1)
    local dummy = Fk:cloneCard("dilu")
    local flag = {"h", "e", "j"}
    local areas = {Player.Hand, Player.Equip, Player.Judge}
    for i = 1, 3, 1 do
      if #data.to.player_cards[areas[i]] > 0 then
        local id = room:askForCardChosen(player, data.to, flag[i], self.name)
        dummy:addSubcard(id)
      end
    end
    room:obtainCard(player, dummy, false, fk.ReasonPrey)
  end,
}
local zhidao_prohibit = fk.CreateProhibitSkill{
  name = "#zhidao_prohibit",
  is_prohibited = function(self, from, to, card)
    if from:hasSkill(self.name) then
      return from:usedSkillTimes("zhidao") > 0 and from ~= to
    end
  end,
}
local jili = fk.CreateTriggerSkill{
  name = "jili",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and data.card.color == Card.Red and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      (data.from == nil or data.from ~= player.id) and data.targetGroup and #data.targetGroup == 1 and
      player.room:getPlayerById(AimGroup:getAllTargets(data.tos)[1]):distanceTo(player) == 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.is_damage_card or table.contains({"dismantlement", "snatch", "chasing_near"}, data.card.name) or data.card.is_derived  then
      room:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "negative")
    else
      room:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "control")
    end
    if data.from ~= nil then
      room:doIndicate(data.from, {player.id})
    end
    TargetGroup:pushTargets(data.targetGroup, player.id)
  end,
}
zhidao:addRelatedSkill(zhidao_prohibit)
yanbaihu:addSkill(zhidao)
yanbaihu:addSkill(jili)
Fk:loadTranslationTable{
  ["yanbaihu"] = "严白虎",
  ["zhidao"] = "雉盗",
  [":zhidao"] = "锁定技，当你于出牌阶段内第一次对区域里有牌的其他角色造成伤害后，你获得其手牌、装备区和判定区里的各一张牌，"..
  "然后直到回合结束，其他角色不能被选择为你使用牌的目标。",
  ["jili"] = "寄篱",
  [":jili"] = "锁定技，当一名其他角色成为红色基本牌或红色非延时类锦囊牌的目标时，若其与你的距离为1且你既不是此牌的使用者也不是目标，你也成为此牌的目标。",

  ["$zhidao1"] = "谁有地盘，谁是老大！",
  ["$zhidao2"] = "乱世之中，能者为王！",
  ["$jili1"] = "寄人篱下的日子，不好过呀！",
  ["$jili2"] = "这份恩德，白虎记下了！",
  ["~yanbaihu"] = "严舆吾弟，为兄来陪你了。",
}

local wanglang = General(extension, "wanglang", "wei", 3)
local gushe = fk.CreateActiveSkill{
  name = "gushe",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 3,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected < 3 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.map(effect.tos, function(p) return room:getPlayerById(p) end)
    local pindian = player:pindian(targets, self.name)
    for _, target in ipairs(targets) do
      local losers = {}
      if pindian.results[target.id].winner then
        if pindian.results[target.id].winner == player then
          table.insert(losers, target)
        else
          table.insert(losers, player)
        end
      else
        table.insert(losers, player)
        table.insert(losers, target)
      end
      for _, p in ipairs(losers) do
        if p == player then
          room:addPlayerMark(player, "@raoshe", 1)
          if player:getMark("@raoshe") >= 7 then
            room:killPlayer({who = player.id,})
          end
        end
        if #room:askForDiscard(p, 1, 1, true, self.name, true, ".", "#gushe-discard::"..player.id) == 0 then
          player:drawCards(1, self.name)
        end
      end
    end
  end,
}
local jici = fk.CreateTriggerSkill{
  name = "jici",
  anim_type = "special",
  events = {fk.PindianCardsDisplayed},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if player == data.from then
        return data.fromCard.number <= player:getMark("@raoshe")
      elseif data.results[player.id] then
        return data.results[player.id].toCard.number <= player:getMark("@raoshe")
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if player == data.from then
      data.fromCard.number = data.fromCard.number + player:getMark("@raoshe")
    elseif data.results[player.id] then
      data.results[player.id].toCard.number = data.results[player.id].toCard.number + player:getMark("@raoshe")
    end
    if player.phase == Player.Play then
      player:setSkillUseHistory("gushe", 0, Player.HistoryPhase)
    end
  end,
}
wanglang:addSkill(gushe)
wanglang:addSkill(jici)
Fk:loadTranslationTable{
  ["wanglang"] = "王朗",
  ["gushe"] = "鼓舌",
  [":gushe"] = "出牌阶段限一次，你可以用一张手牌与至多三名角色同时拼点，然后依次结算拼点结果，没赢的角色选择一项：1.弃置一张牌；2.令你摸一张牌。"..
  "若拼点没赢的角色是你，你需先获得一个“饶舌”标记（你有7个饶舌标记时，你死亡）。",
  ["jici"] = "激词",
  [":jici"] = "当你的拼点牌亮出后，若点数不大于X，你可令点数+X并视为此回合未发动过〖鼓舌〗。（X为你“饶舌”标记的数量）。",
  ["@raoshe"] = "饶舌",
  ["#gushe-discard"] = "鼓舌：你需弃置一张牌，否则 %dest 摸一张牌",

  ["$gushe1"] = "公既知天命，识时务，为何要兴无名之师，犯我疆界？",
  ["$gushe2"] = "你若倒戈卸甲，以礼来降，仍不失封侯之位，国安民乐，岂不美哉？",
  ["$jici1"] = "谅尔等腐草之荧光，如何比得上天空之皓月？",
  ["$jici2"] = "你……诸葛村夫，你敢！",
  ["~wanglang"] = "你，你…哇啊…啊……",
}

local litong = General(extension, "litong", "wei", 4)
local tuifeng = fk.CreateTriggerSkill{
  name = "tuifeng",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if target:isNude() or self.cancel_cost then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForCard(player, 1, 1, true, self.name, true, ".", "#tuifeng-cost")
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile(self.name, self.cost_data, false, self.name)
  end,
}
local tuifeng_trigger = fk.CreateTriggerSkill{
  name = "#tuifeng_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and #player:getPile("tuifeng") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("tuifeng")
    room:notifySkillInvoked(player, "tuifeng")
    local n = #player:getPile("tuifeng")
    room:moveCards({
      from = player.id,
      ids = player:getPile("tuifeng"),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = "tuifeng",
    })
    player:drawCards(2 * n, "tuifeng")
    room:addPlayerMark(player, "@tuifeng-turn", n)
  end,
}
local tuifeng_targetmod = fk.CreateTargetModSkill{
  name = "#tuifeng_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:getMark("@tuifeng-turn") > 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@tuifeng-turn")
    end
  end,
}
tuifeng:addRelatedSkill(tuifeng_targetmod)
tuifeng:addRelatedSkill(tuifeng_trigger)
litong:addSkill(tuifeng)
Fk:loadTranslationTable{
  ["litong"] = "李通",
  ["tuifeng"] = "推锋",
  [":tuifeng"] = "当你受到1点伤害后，你可以将一张牌置于武将牌上，称为“锋”。准备阶段开始时，若你的武将牌上有“锋”，你将所有“锋”置入弃牌堆，"..
  "摸2X张牌，然后你于此回合的出牌阶段内使用【杀】的次数上限+X（X为你此次置入弃牌堆的“锋”数）。",
  ["#tuifeng_trigger"] = "推锋",
  ["#tuifeng-cost"] = "推锋：你可以将一张牌置于武将牌上，称为“锋”",
  ["@tuifeng-turn"] = "推锋",

  ["$tuifeng1"] = "摧锋陷阵，以杀贼首！",
  ["$tuifeng2"] = "敌锋之锐，我已尽知。",
  ["~litong"] = "战死沙场，快哉。",
}

local mizhu = General(extension, "mizhu", "shu", 3)
local ziyuan = fk.CreateActiveSkill{
  name = "ziyuan",
  anim_type = "support",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) == Player.Equip then return end
    local num = 0
    for _, id in ipairs(selected) do
      num = num + Fk:getCardById(id).number
    end
    return num + Fk:getCardById(to_select).number <= 13
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    local num = 0
    for _, id in ipairs(selected_cards) do
      num = num + Fk:getCardById(id).number
    end
    return num == 13 and #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(effect.cards)
    room:obtainCard(target, dummy, false, fk.ReasonGive)
    if target:isWounded() then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local jugu = fk.CreateTriggerSkill{
  name = "jugu",
  events = {fk.GameStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    player.room:drawCards(player, player.maxHp, self.name)
  end,
}
local jugu_maxcards = fk.CreateMaxCardsSkill{
  name = "#jugu_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(self.name) then
      return player.maxHp
    else
      return 0
    end
  end,
}
jugu:addRelatedSkill(jugu_maxcards)
mizhu:addSkill(ziyuan)
mizhu:addSkill(jugu)
Fk:loadTranslationTable{
  ["mizhu"] = "糜竺",
  ["ziyuan"] = "资援",
  [":ziyuan"] = "出牌阶段限一次，你可以将任意张点数之和为13的手牌交给一名其他角色，然后该角色回复1点体力。",
  ["jugu"] = "巨贾",
  [":jugu"] = "锁定技，1.你的手牌上限+X。2.游戏开始时，你摸X张牌。（X为你的体力上限）",

  ["$ziyuan1"] = "钱？要多少有多少。",
  ["$ziyuan2"] = "君子爱财，取之有道。",
  ["$jugu1"] = "区区薄礼，万望使君笑纳。",
  ["$jugu2"] = "雪中送炭，以解君愁。",
  ["~mizhu"] = "劣弟背主，我之罪也。",
}

local buzhi = General(extension, "buzhi", "wu", 3)
local hongde = fk.CreateTriggerSkill{
  name = "hongde",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if #move.moveInfo > 1 and ((move.from == player.id and move.to ~= player.id) or
          (move.to == player.id and move.toArea == Card.PlayerHand)) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local p = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#hongde-choose", self.name, true)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:getPlayerById(self.cost_data):drawCards(1, self.name)
  end,
}
local dingpan = fk.CreateActiveSkill{
  name = "dingpan",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < player:getMark(self.name)
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and #Fk:currentRoom():getPlayerById(to_select).player_cards[Player.Equip] > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    target:drawCards(1, self.name)
    local choice = room:askForChoice(target, {"dingpan_discard", "dingpan_damage"}, self.name)
    if choice == "dingpan_discard" then
      local id = room:askForCardChosen(player, target, "e", self.name)
      room:throwCard({id}, self.name, target, player)
    else
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(target.player_cards[Player.Equip])
      room:obtainCard(target, dummy, true, fk.ReasonJustMove)
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
local dingpan_record = fk.CreateTriggerSkill{
  name = "#dingpan_record",

  refresh_events = {fk.GameStart, fk.BeforeGameOverJudge},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local n
      if room.settings.gameMode == "aaa_role_mode" then
        local total = #room.alive_players
        if total == 8 then n = 4
        elseif total == 7 or total == 6 then n = 3
        elseif total == 5 then n = 2
        else n = 1
        end
      elseif room.settings.gameMode == "m_1v2_mode" or room.settings.gameMode == "m_2v2_mode" then
        n = 2
      end
      room:setPlayerMark(player, "dingpan", n)
    else
      if target.role == "rebel" then
        room:removePlayerMark(player, "dingpan", 1)
      end
    end
  end,
}
dingpan:addRelatedSkill(dingpan_record)
buzhi:addSkill(hongde)
buzhi:addSkill(dingpan)
Fk:loadTranslationTable{
  ["buzhi"] = "步骘",
  ["hongde"] = "弘德",
  [":hongde"] = "当你一次获得或失去至少两张牌后，你可以令一名其他角色摸一张牌。",
  ["dingpan"] = "定叛",
  [":dingpan"] = "出牌阶段限X次，你可以令一名装备区里有牌的角色摸一张牌，然后其选择一项：1.令你弃置其装备区里的一张牌；"..
  "2.获得其装备区里的所有牌，若如此做，你对其造成1点伤害（X为场上存活的反贼数）。",
  ["#hongde-choose"] = "弘德：你可以令一名其他角色摸一张牌",
  ["dingpan_discard"] = "其弃置你装备区里的一张牌",
  ["dingpan_damage"] = "收回所有装备，其对你造成1点伤害",

  ["$hongde1"] = "江南重义，东吴尚德。",
  ["$hongde2"] = "德无单行，福必双至。",
  ["$dingpan1"] = "从孙者生，从刘者死！",
  ["$dingpan2"] = "多行不义必自毙！",
  ["~buzhi"] = "交州已定，主公尽可放心。",
}

local dongbai = General(extension, "dongbai", "qun", 3, 3, General.Female)
local lianzhu = fk.CreateActiveSkill{
  name = "lianzhu",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    player:showCards(effect.cards)
    local card = Fk:getCardById(effect.cards[1])
    room:obtainCard(target, card, true, fk.ReasonGive)
    if card.color == Card.Black then
      if #target:getCardIds{Player.Hand, Player.Equip} < 2 or
        #room:askForDiscard(target, 2, 2, true, self.name, true, ".", "#lianzhu-discard:"..player.id) ~= 2 then
        player:drawCards(2, self.name)
      end
    end
  end,
}
local xiahui = fk.CreateMaxCardsSkill{
  name = "xiahui",
  exclude_from = function(self, player, card)
    return player:hasSkill(self.name) and card.color == Card.Black
  end,
}
local xiahui_record = fk.CreateTriggerSkill{
  name = "#xiahui_record",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.HpChanged},
  can_trigger = function(self, event, target, player, data)
    if event == fk.AfterCardsMove and player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black then
              return true
            end
          end
        end
      end
    elseif event == fk.HpChanged then
      return target == player and player:getMark("xiahui") ~= 0 and data.num < 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
          local to = room:getPlayerById(move.to)
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black then
              local mark = to:getMark("xiahui")
              if mark == 0 then mark = {} end
              table.insertIfNeed(mark, info.cardId)
              room:setPlayerMark(to, "xiahui", mark)
            end
          end
        end
      end
    else
      room:setPlayerMark(player, "xiahui", 0)
    end
  end,
}
local xiahui_prohibit = fk.CreateProhibitSkill{
  name = "#xiahui_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("xiahui") ~= 0 then
      return table.contains(player:getMark("xiahui"), card.id)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("xiahui") ~= 0 then
      return table.contains(player:getMark("xiahui"), card.id)
    end
  end,
  prohibit_discard = function(self, player, card)
    if player:getMark("xiahui") ~= 0 then
      return table.contains(player:getMark("xiahui"), card.id)
    end
  end,
}
xiahui:addRelatedSkill(xiahui_record)
xiahui:addRelatedSkill(xiahui_prohibit)
dongbai:addSkill(lianzhu)
dongbai:addSkill(xiahui)
Fk:loadTranslationTable{
  ["dongbai"] = "董白",
  ["lianzhu"] = "连诛",
  [":lianzhu"] = "出牌阶段限一次，你可以展示并交给一名其他角色一张牌，若该牌为黑色，其选择一项：1.你摸两张牌；2.弃置两张牌。",
  ["xiahui"] = "黠慧",
  [":xiahui"] = "锁定技，你的黑色牌不占用手牌上限；其他角色获得你的黑色牌时，其不能使用、打出、弃置这些牌直到其体力值减少为止。",
  ["#lianzhu-discard"] = "连诛：你需弃置两张牌，否则 %src 摸两张牌",

  ["$lianzhu1"] = "若有不臣之心，定当株连九族。",
  ["$lianzhu2"] = "你们都是一条绳上的蚂蚱~",
  ["~dongbai"] = "放肆，我要让爷爷赐你们死罪！",
}

local zhaoxiang = General(extension, "zhaoxiang", "shu", 4, 4, General.Female)
local fanghun = fk.CreateViewAsSkill{
  name = "fanghun",
  pattern = "slash,jink",
  card_filter = function(self, to_select, selected)
    if #selected == 1 then return false end
    local c = Fk:getCardById(to_select)
    return c.trueName == "slash" or c.name == "jink"
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local _c = Fk:getCardById(cards[1])
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    end
    c.skillNames = c.skillNames or {}
    table.insert(c.skillNames, "fanghun")
    table.insert(c.skillNames, "longdan")
    c:addSubcard(cards[1])
    return c
  end,
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@meiying", 1)
    player:drawCards(1, self.name)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  enabled_at_response = function(self, player, response)
    return player:getMark("@meiying") > 0
  end,
}
local fanghun_record = fk.CreateTriggerSkill{
  name = "#fanghun_record",

  refresh_events = {fk.Damage, fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@meiying", data.damage)
  end,
}
local fuhan = fk.CreateTriggerSkill{
  name = "fuhan",
  anim_type = "special",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player:getMark("@meiying") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local maxHp = math.max(player:usedSkillTimes("fanghun", Player.HistoryGame), 2)
    maxHp = math.min(maxHp, 8)
    return player.room:askForSkillInvoke(player, self.name, nil, "#fuhan-invoke:::"..maxHp)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@meiying")
    room:setPlayerMark(player, "@meiying", 0)
    local generals = table.map(Fk:getGeneralsRandomly(5, Fk:getAllGenerals(), table.map(room:getAllPlayers(), function(p)
      return p.general end), (function(p) return (p.kingdom ~= "shu") end)), function(g) return g.name end)
    local general = room:askForGeneral(player, generals, 1)
    if general == nil then
      general = table.random(generals)
    end
    room:changeHero(player, general, false, false, true)
    local maxHp = math.max(n + player:usedSkillTimes("fanghun", Player.HistoryGame), 2)
    maxHp = math.min(maxHp, 8)
    room:changeMaxHp(player, maxHp - player.maxHp)
    player.gender = Fk.generals[player.general].gender
    room:broadcastProperty(player, "gender")
    if player.hp == 0 then
      room:killPlayer({who = player.id,})
    end
    if table.every(player.room:getOtherPlayers(player), function(p) return p.hp >= player.hp end) and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
fanghun:addRelatedSkill(fanghun_record)
zhaoxiang:addSkill(fanghun)
zhaoxiang:addSkill(fuhan)
Fk:loadTranslationTable{
  ["zhaoxiang"] = "赵襄",
  ["fanghun"] = "芳魂",
  [":fanghun"] = "当你使用【杀】造成伤害后或受到【杀】造成的伤害后，你获得等于伤害值的“梅影”标记；你可以移去1个“梅影”标记发动〖龙胆〗并摸一张牌。",
  ["fuhan"] = "扶汉",
  [":fuhan"] = "限定技，准备阶段开始时，你可以移去所有“梅影”标记，随机观看五名未登场的蜀势力角色，将武将牌替换为其中一名角色，"..
  "并将体力上限数调整为本局游戏中移去“梅影”标记的数量（至少2，至多8），然后若你是体力值最低的角色，你回复1点体力。",
  ["@meiying"] = "梅影",
  ["#fuhan-invoke"] = "扶汉：你可以变身为一名蜀势力武将！（体力上限为%arg）",

  ["$fanghun1"] = "万花凋落尽，一梅独傲霜。",
  ["$fanghun2"] = "暗香疏影处，凌风踏雪来！",
  ["$fuhan1"] = "承先父之志，扶汉兴刘。",
  ["$fuhan2"] = "天将降大任于我。",
  ["~zhaoxiang"] = "遁入阴影之中……",
}

local dongyun = General(extension, "dongyun", "shu", 3)
local bingzheng = fk.CreateTriggerSkill{
  name = "bingzheng",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and
      not table.every(player.room:getAlivePlayers(), function(p) return p:getHandcardNum() == p.hp end)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(table.filter(player.room:getAlivePlayers(), function(p)
      return p:getHandcardNum() ~= p.hp end), function(p) return p.id end), 1, 1, "#bingzheng-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {"bingzheng_draw"}
    if not to:isKongcheng() then
      table.insert(choices, 1, "bingzheng_discard")
    end
    local choice = room:askForChoice(player, choices, self.name, "#bingzheng-choice::"..to.id)
    if choice == "bingzheng_draw" then
      to:drawCards(1, self.name)
    else
      room:askForDiscard(to, 1, 1, false, self.name, false)
    end
    if #to.player_cards[Player.Hand] == to.hp then
      player:drawCards(1, self.name)
      if to ~= player then
        local card = room:askForCard(player, 1, 1, true, self.name, true, ".", "#bingzheng-card::"..to.id)
        if #card > 0 then
          room:obtainCard(to, card[1], false, fk.ReasonGive)
        end
      end
    end
  end,
}
local sheyan = fk.CreateTriggerSkill{
  name = "sheyan",
  anim_type = "control",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card:isCommonTrick()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = AskForAddTarget(player, room:getAlivePlayers(), 1, true, "#sheyan-choose:::"..data.card:toLogString(), self.name, data)
    if #targets > 0 then
      self.cost_data = targets[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if table.contains(AimGroup:getAllTargets(data.tos), self.cost_data) then
      TargetGroup:removeTarget(data.targetGroup, self.cost_data)
    else
      TargetGroup:pushTargets(data.targetGroup, self.cost_data)
    end
  end,
}
dongyun:addSkill(bingzheng)
dongyun:addSkill(sheyan)
Fk:loadTranslationTable{
  ["dongyun"] = "董允",
  ["bingzheng"] = "秉正",
  [":bingzheng"] = "出牌阶段结束时，你可以令手牌数不等于体力值的一名角色弃置一张手牌或摸一张牌。然后若其手牌数等于体力值，你摸一张牌，且可以交给该角色一张牌。",
  ["sheyan"] = "舍宴",
  [":sheyan"] = "当你成为一张普通锦囊牌的目标时，你可以为此牌增加一个目标或减少一个目标（目标数至少为一）。",
  ["#bingzheng-choose"] = "秉正：令一名角色弃一张手牌或摸一张牌，然后若其手牌数等于体力值，你摸一张牌且可以交给其一张牌",
  ["#bingzheng-choice"] = "秉正：选择令 %dest 执行的一项",
  ["bingzheng_discard"] = "其弃置一张手牌",
  ["bingzheng_draw"] = "其摸一张牌",
  ["#bingzheng-card"] = "秉正：你可以交给 %dest 一张牌",
  ["#sheyan-choose"] = "舍宴：你可以为%arg增加/减少一个目标",
  ["#collateral-choose"] = "请为对 %dest 使用的%arg指定被杀的目标",

  ["$bingzheng1"] = "自古，就是邪不胜正！",
  ["$bingzheng2"] = "主公面前，岂容小人搬弄是非！",
  ["$sheyan1"] = "公事为重，宴席不去也罢。",
  ["$sheyan2"] = "还是改日吧。",
  ["~dongyun"] = "大汉，要亡于宦官之手了……",
}

local mazhong = General(extension, "mazhong", "shu", 4)
local fuman = fk.CreateActiveSkill{
  name = "fuman",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("fuman-turn") == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target, effect.cards[1], false, fk.ReasonGive)
    room:addPlayerMark(target, "fuman-turn", 1)
    room:setPlayerMark(target, self.name, effect.cards[1])
  end,
}
local fuman_record = fk.CreateTriggerSkill{
  name = "#fuman_record",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name, true) and target:getMark("fuman") ~= 0 then
      if data.card:isVirtual() then
        if #data.card.subcards > 0 then
          for _, id in ipairs(data.card.subcards) do
            if target:getMark("fuman") == id then
              return true
            end
          end
        end
      else
        return data.card:getEffectiveId() == target:getMark("fuman")
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "fuman", 0)
    player:drawCards(1, "fuman")
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("fuman") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fuman", 0)
  end,
}
fuman:addRelatedSkill(fuman_record)
mazhong:addSkill(fuman)
Fk:loadTranslationTable{
  ["mazhong"] = "马忠",
  ["fuman"] = "抚蛮",
  [":fuman"] = "出牌阶段，你可以将一张【杀】交给一名本回合未获得过“抚蛮”牌的其他角色，然后其于下个回合结束之前使用“抚蛮”牌时，你摸一张牌。",
  ["#fuman_record"] = "抚蛮",

  ["$fuman1"] = "恩威并施，蛮夷可为我所用！",
  ["$fuman2"] = "发兵器啦！",
  ["~mazhong"] = "丞相不在，你们竟然……",
}

local heqi = General(extension, "heqi", "wu", 4)
local function QizhouChange(player, num, skill_name)
  local room = player.room
	local skills = player.tag["qizhou"]
  if type(skills) ~= "table" then skills = {} end
  local suits = {}
  for _, e in ipairs(player.player_cards[Player.Equip]) do
    table.insertIfNeed(suits, Fk:getCardById(e).suit)
  end
	if #suits >= num then
		if not table.contains(skills, skill_name) then
      room:handleAddLoseSkills(player, skill_name, "qizhou")
			table.insert(skills, skill_name)
		end
	else
		if table.contains(skills, skill_name) then
      room:handleAddLoseSkills(player, "-"..skill_name, nil)
			table.removeOne(skills, skill_name)
		end
	end
	player.tag["qizhou"] = skills
end
local qizhou = fk.CreateTriggerSkill{
  name = "qizhou",
  mute = true,
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
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
    end
  end,
  on_trigger = function(self, event, target, player, data)
    QizhouChange(player, 1, "mashu")
    QizhouChange(player, 2, "ex__yingzi")
    QizhouChange(player, 3, "duanbing")
    QizhouChange(player, 4, "fenwei")
  end,
}
local shanxi = fk.CreateActiveSkill{
  name = "shanxi",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red and Fk:getCardById(to_select).type == Card.TypeBasic
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and Self:inMyAttackRange(target) and not target:isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    local id = room:askForCardChosen(player, target, "he", self.name)
    room:throwCard(id, self.name, target, player)
    local card = Fk:getCardById(id)
    if card.name == "jink" and not target:isKongcheng() then
      room:fillAG(player, target.player_cards[Player.Hand])
      room:delay(3000)
      room:closeAG(player)
    elseif card.name ~= "jink" and not player:isKongcheng() then
      room:fillAG(target, player.player_cards[Player.Hand])
      room:delay(3000)
      room:closeAG(target)
    end
  end,
}
heqi:addSkill(qizhou)
heqi:addSkill(shanxi)
heqi:addRelatedSkill("mashu")
heqi:addRelatedSkill("ex__yingzi")
heqi:addRelatedSkill("duanbing")
heqi:addRelatedSkill("fenwei")
Fk:loadTranslationTable{
  ["heqi"] = "贺齐",
  ["qizhou"] = "绮胄",
  [":qizhou"] = "锁定技，你根据装备区里牌的花色数获得以下技能：1种以上-〖马术〗；2种以上-〖英姿〗；3种以上-〖短兵〗；4种-〖奋威〗。",
  ["shanxi"] = "闪袭",
  [":shanxi"] = "出牌阶段限一次，你可以弃置一张红色基本牌，然后弃置攻击范围内的一名其他角色的一张牌，若弃置的牌是【闪】，你观看其手牌，"..
  "若弃置的不是【闪】，其观看你的手牌。",

  --["$ex__yingzi1"] = "人靠衣装马靠鞍！",
  --["$duanbing1"] = "可真是一把好刀啊！",
  --["$fenwei1"] = "恩威并施，蛮夷可为我所用！",
  ["$shanxi1"] = "敌援未到，需要速战速决！",
  ["$shanxi2"] = "快马加鞭，赶在敌人戒备之前！",
  ["~heqi"] = "别拿走我的装备！",
}

local kanze = General(extension, "kanze", "wu", 3)
local xiashu = fk.CreateTriggerSkill{
  name = "xiashu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#xiashu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player.player_cards[Player.Hand])
    room:obtainCard(to, dummy, false, fk.ReasonGive)
    local cards = room:askForCard(to, 1, #to.player_cards[Player.Hand], false, self.name, false, ".", "#xiashu-card:"..player.id)
    if #cards == 0 then
      cards = table.random(to.player_cards[Player.Hand])
    end
    to:showCards(cards)
    local choice = room:askForChoice(player, {"xiashu_show", "xiashu_noshow"}, self.name, "#xiashu-choice::"..to.id)
    local dummy2 = Fk:cloneCard("dilu")
    if choice == "xiashu_show" then
      dummy2:addSubcards(cards)
    else
      for _, id in ipairs(to.player_cards[Player.Hand]) do
        if not table.contains(cards, id) then
          dummy2:addSubcard(id)
        end
      end
    end
    room:obtainCard(player, dummy2, false, fk.ReasonPrey)
  end,
}
local kuanshi = fk.CreateTriggerSkill{
  name = "kuanshi",
  anim_type = "defensive",
  events = {fk.EventPhaseStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
    else
      return player:hasSkill(self.name, true) and data.damage > 1 and target:getMark(self.name) == player.id
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
        return p.id end), 1, 1, "#kuanshi-choose", self.name, true, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:setPlayerMark(room:getPlayerById(self.cost_data), self.name, player.id)
    else
      room:setPlayerMark(target, self.name, 0)
      room:setPlayerMark(player, "kuanshi_trigger", 1)
      return true
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and data.from == Player.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:getMark(self.name) ~= 0 then
        room:setPlayerMark(p, self.name, 0)
      end
    end
    if player:getMark("kuanshi_trigger") > 0 then
      room:setPlayerMark(player, "kuanshi_trigger", 0)
      player:skip(Player.Draw)
    end
  end,
}
kanze:addSkill(xiashu)
kanze:addSkill(kuanshi)
Fk:loadTranslationTable{
  ["kanze"] = "阚泽",
  ["xiashu"] = "下书",
  [":xiashu"] = "出牌阶段开始时，你可以将所有手牌交给一名其他角色，然后该角色亮出任意数量的手牌（至少一张），令你选择一项："..
  "1.获得其亮出的手牌；2.获得其未亮出的手牌。",
  ["kuanshi"] = "宽释",
  [":kuanshi"] = "结束阶段，你可以选择一名角色。直到你的下回合开始，该角色下一次受到超过1点的伤害时，防止此伤害，然后你跳过下个回合的摸牌阶段。",
  ["#xiashu-choose"] = "下书：将所有手牌交给一名角色，其展示任意张手牌，你获得展示或未展示的牌",
  ["#xiashu-card"] = "下书：展示任意张手牌，%src 选择获得你展示的牌或未展示的牌",
  ["xiashu_show"] = "获得展示的牌",
  ["xiashu_noshow"] = "获得未展示的牌",
  ["#xiashu-choice"] = "下书：选择获得 %dest 的牌",
  ["#kuanshi-choose"] = "宽释：你可以选择一名角色，直到你下回合开始，防止其下次受到超过1点的伤害",
  ["@@kuanshi"] = "宽释",

  ["$xiashu1"] = "吾有密信，特来献于将军。",
  ["$xiashu2"] = "将军若不信，可亲自验看！",
  ["$kuanshi1"] = "不知者，无罪。",
  ["$kuanshi2"] = "罚酒三杯，下不为例。",
  ["~kanze"] = "我早已做好了牺牲的准备。",
}

local liuqi = General(extension, "liuqi", "qun", 3)
liuqi.subkingdom = "shu"
local wenji = fk.CreateTriggerSkill{
  name = "wenji",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and
      not table.every(player.room:getOtherPlayers(player), function(p) return (p:isNude()) end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), function(p) return p.id end), 1, 1, "#wenji-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCard(to, 1, 1, true, self.name, false, ".", "#wenji-give::"..player.id)
    room:setPlayerMark(player, "wenji-turn", Fk:getCardById(card[1]).trueName)
    room:obtainCard(player.id, card[1], false, fk.ReasonGive)
  end,
}
local wenji_record = fk.CreateTriggerSkill{
  name = "#wenji_record",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("wenji", Player.HistoryTurn) > 0 and player:getMark("wenji-turn") ~= 0 and
      player:getMark("wenji-turn") == data.card.trueName
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      table.insertIfNeed(data.disresponsiveList, p.id)
    end
  end,
}
local tunjiang = fk.CreateTriggerSkill{
  name = "tunjiang",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and
      player:getMark("tunjiang-turn") == 0 and not player.skipped_phases[Player.Play]
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    player:drawCards(#kingdoms)
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:getMark("tunjiang-turn") == 0 and
      data.firstTarget and data.card.type ~= Card.TypeEquip
  end,
  on_refresh = function(self, event, target, player, data)
    if #AimGroup:getAllTargets(data.tos) == 0 then return end
    for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
      if id ~= player.id then
        player.room:addPlayerMark(player, "tunjiang-turn", 1)
        break
      end
    end
  end,
}
wenji:addRelatedSkill(wenji_record)
liuqi:addSkill(wenji)
liuqi:addSkill(tunjiang)
Fk:loadTranslationTable{
  ["liuqi"] = "刘琦",
  ["wenji"] = "问计",
  [":wenji"] = "出牌阶段开始时，你可以令一名其他角色交给你一张牌，你于本回合内使用与该牌同名的牌不能被其他角色响应。",
  ["tunjiang"] = "屯江",
  [":tunjiang"] = "结束阶段，若你未跳过本回合的出牌阶段，且你于本回合出牌阶段内未使用牌指定过其他角色为目标，则你可以摸X张牌（X为全场势力数）。",
  ["#wenji-choose"] = "问计：你可以令一名其他角色交给你一张牌",
  ["#wenji-give"] = "问计：你需交给 %dest 一张牌",

  ["$wenji1"] = "言出子口，入于吾耳，可以言未？",
  ["$wenji2"] = "还望先生救我！",
  ["$tunjiang1"] = "皇叔勿惊，吾与关将军已到。",
  ["$tunjiang2"] = "江夏冲要之地，孩儿愿往守之。",
  ["~liuqi"] = "父亲，孩儿来见你了。",
}

local tangzi = General(extension, "tangzi", "wei", 4)
tangzi.subkingdom = "wu"
local xingzhao = fk.CreateTriggerSkill{
  name = "xingzhao",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.HpChanged, fk.MaxHpChanged, fk.CardUsing, fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.HpChanged or event == fk.MaxHpChanged then
        return (player:hasSkill("xunxun", true) and #table.filter(player.room.alive_players, function(p) return p:isWounded() end) == 0) or
          (not player:hasSkill("xunxun", true) and #table.filter(player.room.alive_players, function(p) return p:isWounded() end) > 0)
      elseif event == fk.CardUsing then
        return target == player and data.card.type == Card.TypeEquip and
          #table.filter(player.room.alive_players, function(p) return p:isWounded() end) > 1
      else
        return target == player and data.to == Player.Discard and
          #table.filter(player.room.alive_players, function(p) return p:isWounded() end) > 2
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.HpChanged or event == fk.MaxHpChanged then
      if player:hasSkill("xunxun", true) then
        player.room:handleAddLoseSkills(player, "-xunxun", self.name, true, false)
      else
        player.room:handleAddLoseSkills(player, "xunxun", self.name, true, false)
      end
    elseif event == fk.CardUsing then
      player:drawCards(1, self.name)
    else
      return true
    end
  end,
}
tangzi:addSkill(xingzhao)
Fk:loadTranslationTable{
  ["tangzi"] = "唐咨",
  ["xingzhao"] = "兴棹",
  [":xingzhao"] = "锁定技，场上受伤的角色为：1个或以上，你拥有技能〖恂恂〗；2个或以上，你使用装备牌时摸一张牌；3个或以上，你跳过弃牌阶段。",

  ["$xingzhao1"] = "精挑细选，方能成百年之计。",
  ["$xingzhao2"] = "拿些上好的木料来。",
  --["$xunxun1"] = "让我先探他一探。",
  --["$xunxun2"] = "船，也不是一天就能造出来的。",
  ["~tangzi"] = "偷工减料要不得啊……",
}

local wangyun = General(extension, "wangyun", "qun", 4)
local lianji = fk.CreateActiveSkill{
  name = "lianji",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    local cards = {}
    for i = 1, #room.draw_pile, 1 do
      local card = Fk:getCardById(room.draw_pile[i])
      if card.sub_type == Card.SubtypeWeapon then
        table.insertIfNeed(cards, room.draw_pile[i])
      end
    end
    if #cards > 0 then
      local card = Fk:getCardById(table.random(cards))
      if card.name == "qinggang_sword" then
        for _, id in ipairs(Fk:getAllCardIds()) do
          if Fk:getCardById(id).name == "seven_stars_sword" then
            card = Fk:getCardById(id)
            break
          end
        end
      end
      room:useCard({
        from = target.id,
        tos = {{target.id}},
        card = card,
      })
    end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if target:inMyAttackRange(p) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then
      if target:getEquipment(Card.SubtypeWeapon) then
        local alivePlayerIds = table.map(room.alive_players, function(p) return p.id end)
        local tos = room:askForChoosePlayers(player, alivePlayerIds, 1, 1, "#lianji-card::"..target.id, self.name, false)
        local to
        if #tos > 0 then
          to = tos[1]
        else
          to = table.random(alivePlayerIds)
        end
        room:moveCards({
          from = target.id,
          ids = {target:getEquipment(Card.SubtypeWeapon)},
          to = to,
          toArea = Player.Hand,
          moveReason = fk.ReasonGive,
          proposer = player.id,
          skillName = self.name,
        })
      end
    else
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#lianji-choose::"..target.id, self.name, false)
      local victim
      if #tos > 0 then
        victim = tos[1]
      else
        victim = table.random(targets)
      end
      room:doIndicate(target.id, {victim})
      local use = room:askForUseCard(target, "slash", "slash", "#lianji-slash:"..player.id..":"..victim, true, {must_targets = {victim}})
      if use then
        room:useCard(use)
        if use.damageDealt then
          room:addPlayerMark(player, "moucheng", 1)
        end
      else
        if target:getEquipment(Card.SubtypeWeapon) then
          local alivePlayerIds = table.map(room.alive_players, function(p) return p.id end)
          local tos = room:askForChoosePlayers(player, alivePlayerIds, 1, 1, "#lianji-card::"..target.id, self.name, false)
          local to
          if #tos > 0 then
            to = tos[1]
          else
            to = table.random(alivePlayerIds)
          end
          room:moveCards({
            from = target.id,
            ids = {target:getEquipment(Card.SubtypeWeapon)},
            to = to,
            toArea = Player.Hand,
            moveReason = fk.ReasonGive,
            proposer = player.id,
            skillName = self.name,
          })
        end
      end
    end
  end,
}
local lianji_destruct = fk.CreateTriggerSkill{
  name = "#lianji_destruct",
  priority = 1.1,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name, true, true) then
      for _, move in ipairs(data) do
        return move.toArea == Card.DiscardPile
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      local ids = {}
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == "seven_stars_sword" then
            table.insert(ids, info.cardId)
          end
        end
      end
      if #ids > 0 then
        for _, id in ipairs(ids) do
          table.insert(player.room.void, id)
          player.room:setCardArea(id, Card.Void, nil)
        end
      end
    end
  end,
}
local moucheng = fk.CreateTriggerSkill{
  name = "moucheng",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark(self.name) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-lianji|jingong", nil, true, false)
  end,
}
local jingong = fk.CreateViewAsSkill{
  name = "jingong",
  anim_type = "control",
  interaction = function()
    local names = Self:getMark("jingong-phase")
    if names == 0 then
      names = {"dismantlement", "ex_nihilo", "daggar_in_smile"}  --很难想象什么时候会用到这个默认值
    end
    return UI.ComboBox {choices = names}
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and (card.trueName == "slash" or card.type == Card.TypeEquip)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
}
local jingong_record = fk.CreateTriggerSkill{
  name = "#jingong_record",

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived and
        not table.contains({"nullification", "adaptation"}, card.name) then
        table.insertIfNeed(names, card.name)
      end
    end
    local cards = table.random(names, 2)
    names = {cards[1], cards[2], table.random({"honey_trap", "daggar_in_smile"})}
    player.room:setPlayerMark(player, "jingong-phase", names)
  end,
}
lianji:addRelatedSkill(lianji_destruct)
jingong:addRelatedSkill(jingong_record)
wangyun:addSkill(lianji)
wangyun:addSkill(moucheng)
wangyun:addRelatedSkill(jingong)
Fk:loadTranslationTable{
  ["wangyun"] = "王允",
  ["lianji"] = "连计",
  [":lianji"] = "出牌阶段限一次，你可以弃置一张手牌并指定一名其他角色，其使用牌堆中的一张随机武器牌，然后令其选择一项：1.对其攻击范围内你指定的一名角色"..
  "使用【杀】；2.你将其装备区的武器牌交给任意一名角色。",
  ["moucheng"] = "谋逞",
  [":moucheng"] = "觉醒技，准备阶段，若你发动〖连计〗令目标角色使用【杀】造成过伤害，则你失去〖连计〗，获得〖矜功〗。",
  ["jingong"] = "矜功",
  [":jingong"] = "出牌阶段限一次，你可以将一张装备牌或【杀】当一张锦囊牌使用（从两种随机普通锦囊牌和【美人计】、【笑里藏刀】随机一种中三选一）。",
  ["#lianji-choose"] = "连计：选择令 %dest 使用【杀】的目标",
  ["#lianji-slash"] = "连计：你需对 %dest 使用【杀】，否则 %src 将你的武器牌交给任意角色",
  ["#lianji-card"] = "连计：将 %dest 的武器交给一名角色",

  ["$lianji1"] = "两计扣用，以催强势。",
  ["$lianji2"] = "容老夫细细思量。",
  ["$moucheng1"] = "董贼伏诛，天下太平！",
  ["$moucheng2"] = "叫天不应，叫地不灵，今天就是你的死期！",
  ["$jingong1"] = "董贼旧部，可尽诛之！",
  ["$jingong2"] = "若无老夫之谋，尔等皆化为腐土也。",
  ["~wangyun"] = "努力谢关东诸公，勤以国家为念！",
}

local quyi = General(extension, "quyi", "qun", 4)
local fuji = fk.CreateTriggerSkill{
  name = "fuji",
  anim_type = "offensive",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      #table.filter(player.room:getOtherPlayers(player), function(p) return p:distanceTo(player) == 1 end) > 0
  end,
  on_use = function(self, event, target, player, data)
    local targets = table.filter(player.room:getOtherPlayers(player), function(p) return p:distanceTo(player) == 1 end)
    if #targets > 0 then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, p in ipairs(targets) do
        table.insertIfNeed(data.disresponsiveList, p.id)
      end
    end
  end,
}
local jiaozi = fk.CreateTriggerSkill{
  name = "jiaozi",
  anim_type = "offensive",
  events = {fk.DamageCaused, fk.DamageInflicted},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      table.every(player.room:getOtherPlayers(player), function(p)
        return #player:getCardIds(Player.Hand) > #p:getCardIds(Player.Hand) end)
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
quyi:addSkill(fuji)
quyi:addSkill(jiaozi)
Fk:loadTranslationTable{
  ["quyi"] = "麴义",
  ["fuji"] = "伏骑",
  [":fuji"] = "锁定技，当你使用【杀】或普通锦囊牌时，你令所有至你距离为1的角色不能响应此牌。",
  ["jiaozi"] = "骄恣",
  [":jiaozi"] = "锁定技，当你造成或受到伤害时，若你的手牌为全场唯一最多，则此伤害+1。",

  ["$fuji1"] = "白马？不足挂齿！",
  ["$fuji2"] = "掌握之中，岂可逃之？",
  ["$jiaozi1"] = "数战之功，吾应得此赏！",
  ["$jiaozi2"] = "无我出力，怎会连胜？",
  ["~quyi"] = "主公，我无异心啊！",
}

local xizhicai = General(extension, "xizhicai", "wei", 3)
local xianfu = fk.CreateTriggerSkill{
  name = "xianfu",
  events = {fk.GameStart, fk.Damaged, fk.HpRecover},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      else
        return target:getMark(self.name) == player.id and not target.dead
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:notifySkillInvoked(player, self.name)
      room:broadcastSkillInvoke(self.name, math.random(2))
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#xianfu-choose", self.name, false, true)
      local to
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      room:setPlayerMark(to, self.name, player.id)
    elseif event == fk.Damaged then
      room:notifySkillInvoked(player, self.name, "negative")
      room:broadcastSkillInvoke(self.name, math.random(2)+2)
      if player:getMark("@xianfu") == 0 then
        room:setPlayerMark(player, "@xianfu", target.general)
      end
      room:damage{
        to = player,
        damage = data.damage,
        skillName = self.name,
      }
    elseif event == fk.HpRecover then
      room:notifySkillInvoked(player, self.name, "support")
      room:broadcastSkillInvoke(self.name, math.random(2)+4)
      if player:getMark("@xianfu") == 0 then
        room:setPlayerMark(player, "@xianfu", target.general)
      end
      if player:isWounded() then
        room:recover{
          who = player,
          num = data.num,
          recoverBy = player,
          skillName = self.name,
        }
      end
    end
  end,
}
local chouce = fk.CreateTriggerSkill{
  name = "chouce",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if self.cancel_cost then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name, data) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      local targets = table.map(room:getAlivePlayers(), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#chouce-draw", self.name, false)
      local to
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      to:drawCards(1 + (to:getMark("xianfu") == player.id and 1 or 0), self.name)
    elseif judge.card.color == Card.Black then
      local targets = table.map(table.filter(room:getAlivePlayers(), function(p) return not p:isAllNude() end), function(p) return p.id end)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#chouce-discard", self.name, false)
      local to
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      local card = room:askForCardChosen(player, to, "hej", self.name)
      room:throwCard(card, self.name, to, player)
    end
  end,
}
xizhicai:addSkill("tiandu")
xizhicai:addSkill(xianfu)
xizhicai:addSkill(chouce)
Fk:loadTranslationTable{
  ["xizhicai"] = "戏志才",
  ["xianfu"] = "先辅",
  ["@xianfu"] = "先辅",
  [":xianfu"] = "锁定技，游戏开始时，你选择一名其他角色，当其受到伤害后，你受到等量的伤害；当其回复体力后，你回复等量的体力。",
  ["chouce"] = "筹策",
  [":chouce"] = "当你受到1点伤害后，你可以进行判定，若结果为：黑色，你弃置一名角色区域里的一张牌；红色，你令一名角色摸一张牌（先辅的角色摸两张）。",
  ["#xianfu-choose"] = "先辅: 请选择要先辅的角色",
  ["#chouce-draw"] = "筹策: 令一名角色摸一张牌（若为先辅角色则摸两张）",
  ["#chouce-discard"] = "筹策: 弃置一名角色区域里的一张牌",

  -- ["$tiandu1"] = "天意不可逆。",
  -- ["$tiandu2"] = "既是如此。",
  ["$xianfu1"] = "辅佐明君，从一而终。",
	["$xianfu2"] = "吾于此生，竭尽所能。",
	["$xianfu3"] = "春蚕至死，蜡炬成灰！",
	["$xianfu4"] = "愿为主公，尽我所能。",
	["$xianfu5"] = "赠人玫瑰，手有余香。",
	["$xianfu6"] = "主公之幸，我之幸也。",
  ["$chouce1"] = "一筹一划，一策一略。",
  ["$chouce2"] = "主公之忧，吾之所思也。",
  ["~xizhicai"] = "为何……不再给我……一点点时间……",
}

local sunqian = General(extension, "sunqian", "shu", 3)
local qianya = fk.CreateTriggerSkill{
  name = "qianya",
  anim_type = "support",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.type == Card.TypeTrick and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    player.room:askForUseActiveSkill(player, "#qianya_active", "#qianya-invoke", true)
  end,
}
local qianya_active = fk.CreateActiveSkill{
  name = "#qianya_active",
  anim_type = "support",
  max_card_num = function ()
    return #Self.player_cards[Player.Hand]
  end,
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected, targets)
    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(effect.cards)
    room:obtainCard(target, dummy, false, fk.ReasonGive)
  end,
}
local shuimeng = fk.CreateTriggerSkill{
  name = "shuimeng",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isKongcheng() end), function(p) return p.id end),
      1, 1, "#shuimeng-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local pindian = player:pindian({to}, self.name)
    if pindian.results[to.id].winner == player then
      room:useVirtualCard("ex_nihilo", nil, player, player, self.name)
    else
      if player:isAllNude() then return end
      room:useVirtualCard("dismantlement", nil, to, player, self.name)
    end
  end,
}
Fk:addSkill(qianya_active)
sunqian:addSkill(qianya)
sunqian:addSkill(shuimeng)
Fk:loadTranslationTable{
  ["sunqian"] = "孙乾",
  ["qianya"] = "谦雅",
  [":qianya"] = "当你成为锦囊牌的目标后，你可以将任意张手牌交给一名其他角色。",
  ["shuimeng"] = "说盟",
  [":shuimeng"] = "出牌阶段结束时，你可以与一名角色拼点，若你赢，视为你使用【无中生有】；若你没赢，视为其对你使用【过河拆桥】。",
  ["#qianya_active"] = "谦雅",
  ["#qianya-invoke"] = "谦雅：你可以将任意张手牌交给一名其他角色",
  ["#shuimeng-choose"] = "说盟：你可以拼点，若赢，视为你使用【无中生有】；若没赢，视为其对你使用【过河拆桥】",
}

local shenpei = General(extension, "ol__shenpei", "qun", 3)
local gangzhi = fk.CreateTriggerSkill{
  name = "gangzhi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.PreDamage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and ((target == player and data.to ~= player) or (data.from and data.from ~= player and data.to == player))
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(data.to, data.damage, self.name)
    return true
  end,
}
local beizhan = fk.CreateTriggerSkill{
  name = "beizhan",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.NotActive
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function (p)
      return p.id end), 1, 1, "#beizhan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = player.room:getPlayerById(self.cost_data)
    local n = math.min(to.maxHp, 5) - #to.player_cards[Player.Hand]
    if n > 0 then
      to:drawCards(n)
    end
    player.room:addPlayerMark(to, self.name, 1)
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target:getMark(self.name) > 0 and data.to == Player.Start
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, self.name, 0)
    if table.every(room:getOtherPlayers(player), function(p) return player:getHandcardNum() >= p:getHandcardNum() end) then
    room:addPlayerMark(target, "@@beizhan-turn", 1)
    end
  end,
}
local beizhan_prohibit = fk.CreateProhibitSkill{
  name = "#beizhan_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:getMark("@@beizhan-turn") > 0 and from ~= to
  end,
}
beizhan:addRelatedSkill(beizhan_prohibit)
shenpei:addSkill(gangzhi)
shenpei:addSkill(beizhan)
Fk:loadTranslationTable{
  ["ol__shenpei"] = "审配",
  ["gangzhi"] = "刚直",
  [":gangzhi"] = "锁定技，其他角色对你造成的伤害，和你对其他角色造成的伤害均视为体力流失。",
  ["beizhan"] = "备战",
  [":beizhan"] = "回合结束后，你可以指定一名角色：若其手牌数少于X，其将手牌补至X（X为其体力上限且最多为5）；"..
  "该角色回合开始时，若其手牌数为全场最多，则其本回合内不能使用牌指定其他角色为目标。",
  ["#beizhan-choose"] = "备战：指定一名角色，若手牌少于X则补至X张（X为其体力上限且最多为5）；<br>"..
  "若其回合开始时手牌数为最多，则使用牌不能指定其他角色为目标",
  ["@@beizhan-turn"] = "备战",

  ["$gangzhi1"] = "只恨箭支太少，不能射杀汝等！",
	["$gangzhi2"] = "死便死，降？断不能降！",
	["$beizhan1"] = "十，则围之；五，则攻之！",
	["$beizhan2"] = "今伐曹氏，譬如覆手之举。",
  ["~ol__shenpei"] = "吾君在北，但求面北而亡。",
}

local xunchen = General(extension, "ol__xunchen", "qun", 3)
local fenglve = fk.CreateTriggerSkill{
  name = "fenglve",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.PindianResultConfirmed},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Play and not player:isKongcheng()
      else
        self.fenglve_data = {}
        if data.from == player then
          self.fenglve_data = {data.to, data.fromCard.id}
        elseif data.to == player then
          self.fenglve_data = {data.from, data.toCard.id}
        end
        return self.fenglve_data and player.room:getCardArea(self.fenglve_data[2]) == Card.Processing
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not p:isKongcheng() end), function(p) return p.id end),
        1, 1, "#fenglve-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      return room:askForSkillInvoke(player, self.name, data, "#fenglve-give::"..self.fenglve_data[1].id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local to = room:getPlayerById(self.cost_data)
      local pindian = player:pindian({to}, self.name)
      if pindian.results[to.id].winner == player then
        if to:isAllNude() then return end
        local dummy = Fk:cloneCard("dilu")
        local areas = {Player.Hand, Player.Equip, Player.Judge}
        for i = 1, 3, 1 do
          if #to.player_cards[areas[i]] > 0 then
            local flag = {"h", "e", "j"}
            local id = room:askForCardChosen(to, to, flag[i], self.name)
            dummy:addSubcard(id)
          end
        end
        room:obtainCard(player, dummy, false, fk.ReasonGive)
      else
        if player:isNude() then return end
        local id = room:askForCardChosen(player, player, "he", self.name)
        room:obtainCard(to, id, false, fk.ReasonGive)
      end
    else
      room:obtainCard(self.fenglve_data[1], self.fenglve_data[2], true, fk.ReasonGive)
    end
  end,
}
local moushi = fk.CreateActiveSkill{
  name = "moushi",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target, effect.cards[1], false, fk.ReasonGive)
    room:addPlayerMark(target, self.name, 1)
  end,
}
local moushi_record = fk.CreateTriggerSkill{
  name = "#moushi_record",

  refresh_events = {fk.EventPhaseStart, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return target:getMark("moushi") > 0
      else
        return target:getMark("moushi_p-phase") > 0 and data.to:getMark("moushi-phase") == 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:setPlayerMark(target, "moushi", 0)
      room:addPlayerMark(target, "moushi_p-phase", 1)
    else
      room:addPlayerMark(data.to, "moushi-phase", 1)
      player:drawCards(1, self.name)
    end
  end,
}
moushi:addRelatedSkill(moushi_record)
xunchen:addSkill(fenglve)
xunchen:addSkill(moushi)
Fk:loadTranslationTable{
  ["ol__xunchen"] = "荀谌",
  ["fenglve"] = "锋略",
  [":fenglve"] = "出牌阶段开始时，你可以与一名角色拼点：若你赢，该角色将每个区域内各一张牌交给你；若你没赢，你交给其一张牌。"..
  "你与其他角色的拼点结果确定后，你可以将你的拼点牌交给该角色。",
  ["moushi"] = "谋识",
  [":moushi"] = "出牌阶段限一次，你可以将一张手牌交给一名其他角色。若如此做，当该角色于其下个出牌阶段对每名角色第一次造成伤害后，你摸一张牌。",
  ["#fenglve-choose"] = "锋略：你可以拼点，若赢，其交给你每个区域各一张牌；没赢，你交给其一张牌",
  ["#fenglve-give"] = "锋略：你可以将你的拼点牌交给%dest",
}

--刘晔

local sufei = General(extension, "ol__sufei", "wu", 4)
sufei.subkingdom = "qun"
local lianpian = fk.CreateTriggerSkill{
  name = "lianpian",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play and data.firstTarget and
      player:usedSkillTimes(self.name, Player.HistoryPhase) < 3 then
      return self.cost_data and #self.cost_data > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = player:drawCards(1, self.name)
    if (#self.cost_data > 1 or self.cost_data[1] ~= player.id) and 
      room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand then
      local tos = room:askForChoosePlayers(player, self.cost_data, 1, 1, "#lianpian-choose", self.name, true)
      if #tos > 0 and tos[1] ~= player.id then
        room:obtainCard(tos[1], card[1], false, fk.ReasonGive)
      end
    end
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and data.firstTarget
  end,
  on_refresh = function(self, event, target, player, data)
    self.cost_data = {}
    local mark = player:getMark("lianpian-phase")
    if mark ~= 0 and #mark > 0 and #AimGroup:getAllTargets(data.tos) > 0 then
      for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
        if table.contains(mark, id) then
          table.insert(self.cost_data, id)
        end
      end
    end
    if #AimGroup:getAllTargets(data.tos) > 0 then
      mark = AimGroup:getAllTargets(data.tos)
    else
      mark = 0
    end
    player.room:setPlayerMark(player, "lianpian-phase", mark)
  end,
}
sufei:addSkill(lianpian)
Fk:loadTranslationTable{
  ["ol__sufei"] = "苏飞",
  ["lianpian"] = "联翩",
  [":lianpian"] = "每回合限三次，当你于出牌阶段使用牌连续指定相同角色为目标后，你可以摸一张牌，若如此做，你可以将此牌交给该角色。",
  ["#lianpian-choose"] = "联翩：你可以将这张牌交给其中一名角色",
}

local huangquan = General(extension, "ol__huangquan", "shu", 3)
huangquan.subkingdom = "wei"
local dianhu = fk.CreateTriggerSkill{
  name = "dianhu",
  events = {fk.GameStart, fk.Damage, fk.HpRecover},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      elseif event == fk.Damage then
        return target == player and player.tag[self.name][1] == data.to.id
      else
        return player.tag[self.name][1] == target.id
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#dianhu-choose", self.name, false)
      local to
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
      room:doIndicate(player.id, {to})
      room:setPlayerMark(room:getPlayerById(to), "@dianhu", 1)
      player.tag[self.name] = {to}
    else
      player:drawCards(1, self.name)
    end
  end,
}
local jianji = fk.CreateActiveSkill{
  name = "jianji",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local id = target:drawCards(1, self.name)[1]
    if room:getCardOwner(id) == target and room:getCardArea(id) == Card.PlayerHand then
      local card = Fk:getCardById(id)
      if not target:prohibitUse(card) and target:canUse(card) then
        local use = room:askForUseCard(target,card.name, ".|.|.|.|.|.|"..tostring(id), "#jianji-invoke", true)
        if use then
          room:useCard(use)
        end
      end
    end
  end,
}
huangquan:addSkill(dianhu)
huangquan:addSkill(jianji)
Fk:loadTranslationTable{
  ["ol__huangquan"] = "黄权",
  ["dianhu"] = "点虎",
  [":dianhu"] = "锁定技，游戏开始时，你指定一名其他角色；当你对该角色造成伤害后或该角色回复体力后，你摸一张牌。",
  ["jianji"] = "谏计",
  [":jianji"] = "出牌阶段限一次，你可以令一名其他角色摸一张牌，然后其可以使用该牌。",
  ["@dianhu"] = "点虎",
  ["#dianhu-choose"] = "点虎：指定一名角色，本局当你对其造成伤害或其回复体力后，你摸一张牌",
  ["#jianji-invoke"] = "谏计：你可以使用这张牌",
}

--卑弥呼 2018.6.8

local luzhi = General(extension, "luzhiw", "wei", 3)
local qingzhong = fk.CreateTriggerSkill{
  name = "qingzhong",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,

  refresh_events = {fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 and not player:isKongcheng()
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local n = player:getHandcardNum()
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:getHandcardNum() < n then
        n = p:getHandcardNum()
      end
    end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:getHandcardNum() == n then
        table.insert(targets, p.id)
      end
    end
    local to
    if #targets == 0 then
      return
    elseif #targets == 1 then
      to = targets[1]
    else
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#qingzhong-choose", self.name, false)
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
local weijing = fk.CreateViewAsSkill{
  name = "weijing",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and
      player:usedSkillTimes("#weijing_record", Player.HistoryRound) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and
      player:usedSkillTimes("#weijing_record", Player.HistoryRound) == 0
  end,
}
local weijing_record = fk.CreateTriggerSkill{
  name = "#weijing_record",
  events = {fk.AskForCardUse},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
    player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and player:usedSkillTimes("weijing", Player.HistoryRound) == 0 and
    (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none")))
  end,
  on_use = function(self, event, target, player, data)
    data.result = {
      from = player.id,
      card = Fk:cloneCard(data.cardName),
    }
    data.result.card.skillName = "weijing"
    if data.eventData then
      data.result.toCard = data.eventData.toCard
      data.result.responseToEvent = data.eventData.responseToEvent
    end
    return true
  end
}
weijing:addRelatedSkill(weijing_record)
luzhi:addSkill(qingzhong)
luzhi:addSkill(weijing)
Fk:loadTranslationTable{
  ["luzhiw"] = "鲁芝",
  ["qingzhong"] = "清忠",
  [":qingzhong"] = "出牌阶段开始时，你可以摸两张牌，然后本阶段结束时，你与一名全场手牌数最少的其他角色交换手牌。",
  ["weijing"] = "卫境",
  [":weijing"] = "每轮限一次，当你需要使用【杀】或【闪】时，你可以视为使用之。",
  ["#qingzhong-choose"] = "清忠：选择一名手牌数最少的其他角色，与其交换手牌",
  ["#weijing_record"] = "卫境",
}

local baosanniang = General(extension, "ol__baosanniang", "shu", 4, 4, General.Female)
local ol__wuniang = fk.CreateTriggerSkill{
  name = "ol__wuniang",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and player.phase == Player.Play and
      #TargetGroup:getRealTargets(data.tos) == 1 and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ol__wuniang-invoke::"..TargetGroup:getRealTargets(data.tos)[1])
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if not to.dead then
      local use = room:askForUseCard(to, "slash", "slash", "#ol__wuniang-use:"..player.id, true, {must_targets = {player.id}})
      if use then
        room:useCard(use)
      end
    end
    if not player.dead then
      player:drawCards(1, self.name)
    end
  end,
}
local ol__wuniang_targetmod = fk.CreateTargetModSkill{
  name = "#ol__wuniang_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:usedSkillTimes("ol__wuniang", Player.HistoryPhase) > 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return 1
    end
  end,
}
local ol__xushen = fk.CreateTriggerSkill{
  name = "ol__xushen",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = 1 - player.hp,
      recoverBy = player,
      skillName = self.name
    })
    room:handleAddLoseSkills(player, "ol__zhennan", nil, true, false)
    for _, p in ipairs(room:getAlivePlayers()) do
      if string.find(p.general, "guansuo") then
        return
      end
    end
    local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
      return p.gender == General.Male end), function(p) return p.id end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#ol__xushen-choose", self.name, true)
    if #to > 0 then
      to = room:getPlayerById(to[1])
      if room:askForSkillInvoke(to, self.name, nil, "#ol__xushen-invoke") then
        room:changeHero(to, "guansuo", false, false, true)
      end
    end
  end,
}
local ol__zhennan = fk.CreateActiveSkill{
  name = "ol__zhennan",
  anim_type = "offensive",
  min_card_num = 1,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected, selected_targets)
    if Fk:currentRoom():getCardArea(to_select) == Player.Equip then return end
    return #selected < #Fk:currentRoom().alive_players - 1
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    local card = Fk:cloneCard("savage_assault")
    card:addSubcards(selected_cards)
    return to_select ~= Self.id and #selected < #selected_cards and not Self:isProhibited(Fk:currentRoom():getPlayerById(to_select), card)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:useVirtualCard("savage_assault", effect.cards, player,
      table.map(effect.tos, function(id) return room:getPlayerById(id) end), self.name)
  end
}
local ol__zhennan_trigger = fk.CreateTriggerSkill{
  name = "#ol__zhennan_trigger",
  anim_type = "defensive",
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.id == data.to and data.card.name == "savage_assault"
  end,
  on_cost = function()
    return true
  end,
  on_use = function()
    return true
  end,
}
ol__wuniang:addRelatedSkill(ol__wuniang_targetmod)
ol__zhennan:addRelatedSkill(ol__zhennan_trigger)
baosanniang:addSkill(ol__wuniang)
baosanniang:addSkill(ol__xushen)
baosanniang:addRelatedSkill(ol__zhennan)
Fk:loadTranslationTable{
  ["ol__baosanniang"] = "鲍三娘",
  ["ol__wuniang"] = "武娘",
  [":ol__wuniang"] = "你的出牌阶段内限一次，当你使用指定唯一目标的【杀】结算后，你可以令其选择是否对你使用一张【杀】，"..
  "然后你摸一张牌并令你本阶段使用【杀】次数上限+1。",
  ["ol__xushen"] = "许身",
  [":ol__xushen"] = "限定技，当你进入濒死状态时，你可以回复体力至1并获得〖镇南〗，然后若关索不在场，你可以令一名男性角色选择是否用关索代替其武将牌。",
  ["ol__zhennan"] = "镇南",
  [":ol__zhennan"] = "【南蛮入侵】对你无效。出牌阶段限一次，你可以将至多X张手牌当目标数为X的【南蛮入侵】使用（X为其他角色数）。",
  ["#ol__wuniang-invoke"] = "武娘：你可以令 %dest 对你使用一张【杀】，你摸一张牌并使用【杀】次数上限+1",
  ["#ol__wuniang-use"] = "武娘：你可以对 %src 使用一张【杀】",
  ["#ol__xushen-choose"] = "许身：你可以令一名男性角色选择是否变身为关索！",
  ["#ol__xushen-invoke"]= "许身：你可以变身为关索！",
  ["#ol__zhennan_trigger"] = "镇南",

  ["$ol__wuniang1"] = "虽为女子身，不输男儿郎。",
  ["$ol__wuniang2"] = "剑舞轻盈，沙场克敌。",
  ["$ol__xushen1"] = "救命之恩，涌泉相报。",
  ["$ol__xushen2"] = "解我危难，报君华彩。",
  ["$ol__zhennan1"] = "镇守南中，夫君无忧。",
  ["$ol__zhennan2"] = "与君携手，定平蛮夷。",
  ["~ol__baosanniang"] = "我还想与你，共骑这雪花驹……",
}

local caoying = General(extension, "caoying", "wei", 4, 4, General.Female)
local lingren = fk.CreateTriggerSkill{
  name = "lingren",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and data.firstTarget and data.card.is_damage_card and
      #AimGroup:getAllTargets(data.tos) > 0 and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, data.tos[1], 1, 1, "#lingren-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {"lingren_basic", "lingren_trick", "lingren_equip", "lingren_end"}
    local yes = {}
    for i = 1, 3, 1 do
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "lingren_end" then
        break
      else
        table.insert(yes, choice)
        table.removeOne(choices, choice)
      end
    end
    table.removeOne(choices, "lingren_end")
    local right = 0
    for _, id in ipairs(to.player_cards[Player.Hand]) do
      local str = "lingren_"..Fk:getCardById(id):getTypeString()
      if table.contains(yes, str) then
        right = right + 1
        table.removeOne(yes, str)
      else
        table.removeOne(choices, str)
      end
    end
    right = right + #choices
    if right > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.lingren = {player.id, self.cost_data}
    end
    if right > 1 then
      player:drawCards(2, self.name)
    end
    if right > 2 then
      local skills = {}
      if not player:hasSkill("ex__jianxiong", true) then
        table.insert(skills, "ex__jianxiong")
      end
      if not player:hasSkill("xingshang", true) then
        table.insert(skills, "xingshang")
      end
      room:setPlayerMark(player, self.name, skills)
      room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
    end
  end,
}
local lingren_trigger = fk.CreateTriggerSkill {
  name = "#lingren_trigger",
  mute = true,
  events = {fk.DamageCaused, fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.DamageCaused then
        local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        if e then
          local use = e.data[1]
          return use.extra_data and use.extra_data.lingren and
            use.extra_data.lingren[1] == player.id and use.extra_data.lingren[2] == data.to.id
        end
      else
        return data.from == Player.RoundStart and player:getMark("lingren") ~= 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      data.damage = data.damage + 1
    else
      local room = player.room
      local skills = player:getMark("lingren")
      room:setPlayerMark(player, "lingren", 0)
      room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"), nil, true, false)
    end
  end,
}
local fujian = fk.CreateTriggerSkill {
  name = "fujian",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and
      not table.find(player.room.alive_players, function(p) return p:isKongcheng() and p ~= player end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getHandcardNum()
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      if p:getHandcardNum() < n then
        n = p:getHandcardNum()
      end
    end
    local to = table.random(room:getOtherPlayers(player))
    room:doIndicate(player.id, {to.id})
    local cards = table.random(to.player_cards[Player.Hand], n)
    room:fillAG(player, cards)
    room:delay(5000)
    room:closeAG(player)
  end,
}
lingren:addRelatedSkill(lingren_trigger)
caoying:addSkill(lingren)
caoying:addSkill(fujian)
caoying:addRelatedSkill("ex__jianxiong")
caoying:addRelatedSkill("xingshang")
Fk:loadTranslationTable{
  ["caoying"] = "曹婴",
  ["lingren"] = "凌人",
  [":lingren"] = "出牌阶段限一次，当你使用【杀】或伤害类锦囊牌指定目标后，你可以猜测其中一名目标角色的手牌区中是否有基本牌、锦囊牌或装备牌。"..
  "若你猜对：至少一项，此牌对其造成的伤害+1；至少两项，你摸两张牌；三项，你获得技能〖奸雄〗和〖行殇〗直到你的下个回合开始。",
  ["fujian"] = "伏间",
  [":fujian"] = "锁定技，结束阶段，你随机观看一名其他角色的X张手牌（X为全场手牌数最小的角色的手牌数）。",
  ["#lingren-choose"] = "凌人：你可以猜测其中一名目标角色的手牌中是否有基本牌、锦囊牌或装备牌",
  ["lingren_basic"] = "有基本牌",
  ["lingren_trick"] = "有锦囊牌",
  ["lingren_equip"] = "有装备牌",
  ["lingren_end"] = "结束",

  ["$lingren1"] = "敌势已缓，休要走了老贼！",
  ["$lingren2"] = "精兵如炬，困龙难飞！",
  ["$fujian1"] = "兵者，诡道也。",
  ["$fujian2"] = "粮资军备，一览无遗。",
  --["$ex__jianxiong1"] = "且收此弩箭，不日奉还。",
  --["$xingshang1"] = "此刀枪军械，尽归我有。",
  ["~caoying"] = "曹魏天下存，魂归故土安……",
}

local xujing = General(extension, "ol__xujing", "shu", 3)
local yuxu = fk.CreateTriggerSkill{
  name = "yuxu",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    if player:getMark("yuxu-phase") == 0 then
      return player.room:askForSkillInvoke(player, self.name, data, "#yuxu-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("yuxu-phase") == 0 then
      player:drawCards(1, self.name)
      room:addPlayerMark(player, "yuxu-phase", 1)
    else
      if not player:isNude() then
        room:askForDiscard(player, 1, 1, true, self.name, false)
      end
      room:removePlayerMark(player, "yuxu-phase", 1)
    end
  end,
}
local shijian = fk.CreateTriggerSkill{
  name = "shijian",
  anim_type = "support",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self.name) and target.phase == Player.Play and target:getMark("shijian-phase") == 2 and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#shijian-invoke::"..target.id) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(target, "shijian_invoke", 1)
    player.room:handleAddLoseSkills(target, "yuxu", nil, true, false)
  end,

  refresh_events = {fk.CardUseFinished, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      return player:hasSkill(self.name) and target ~= player and target.phase == Player.Play
    else
      return target == player and player:getMark("shijian_invoke") > 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      room:addPlayerMark(target, "shijian-phase", 1)
    else
      room:setPlayerMark(player, "shijian_invoke", 0)
      room:handleAddLoseSkills(player, "-yuxu", nil, true, false)
    end
  end,
}
xujing:addSkill(yuxu)
xujing:addSkill(shijian)
Fk:loadTranslationTable{
  ["ol__xujing"] = "许靖",
  ["yuxu"] = "誉虚",
  [":yuxu"] = "出牌阶段，你使用一张牌后，可以摸一张牌。若如此做，你使用下一张牌后，弃置一张牌。",
  ["shijian"] = "实荐",
  [":shijian"] = "一名其他角色的出牌阶段，该角色在本阶段使用的第二张牌结算结束后，你可以弃置一张牌，令其获得〖誉虚〗直到回合结束。",
  ["#yuxu-invoke"] = "誉虚：你可以摸一张牌，然后你使用下一张牌后需弃置一张牌",
  ["#shijian-invoke"] = "实荐：你可以弃置一张牌，令%dest获得〖誉虚〗直到回合结束",
}

local yuantanyuanshang = General(extension, "yuantanyuanshang", "qun", 4)
local neifa = fk.CreateTriggerSkill{
  name = "neifa",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
      return #p:getCardIds{Player.Equip, Player.Judge} > 0 end), function (p) return p.id end)
    if #targets == 0 then
      player:drawCards(2, self.name)
    else
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#neifa-choose", self.name, true)
      if #to > 0 then
        local id = room:askForCardChosen(player, room:getPlayerById(to[1]), "ej", self.name)
        room:obtainCard(player, id, true, fk.ReasonPrey)
      else
        player:drawCards(2, self.name)
      end
    end
    local card = room:askForDiscard(player, 1, 1, true, self.name, false)
    if Fk:getCardById(card[1]).type == Card.TypeBasic then
      local cards = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).type ~= Card.TypeBasic end)
      room:setPlayerMark(player, "@neifa-turn", "basic")
      room:setPlayerMark(player, "neifa-turn", math.min(#cards, 5))
    else
      local cards = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).type == Card.TypeBasic end)
      room:setPlayerMark(player, "@neifa-turn", "non_basic")
      room:setPlayerMark(player, "neifa-turn", math.min(#cards, 5))
    end
  end,
}
local neifa_trigger = fk.CreateTriggerSkill{
  name = "#neifa_trigger",
  anim_type = "control",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@neifa-turn") == "non_basic" and data.card:isCommonTrick() and data.firstTarget
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = AskForAddTarget(player, room:getAlivePlayers(), 1, true,
      "#neifa_trigger-choose:::"..data.card:toLogString(), self.name, data)
    if #targets > 0 then
      self.cost_data = targets[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if table.contains(AimGroup:getAllTargets(data.tos), self.cost_data) then
      TargetGroup:removeTarget(data.targetGroup, self.cost_data)
    else
      TargetGroup:pushTargets(data.targetGroup, self.cost_data)
    end
  end,
}
local neifa_draw = fk.CreateTriggerSkill{
  name = "#neifa_draw",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@neifa-turn") == "non_basic" and data.card.type == Card.TypeEquip and
      player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getMark("neifa-turn")
    if n > 0 then
      player:drawCards(n, "neifa")
    end
  end,
}
local neifa_targetmod = fk.CreateTargetModSkill{
  name = "#neifa_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@neifa-turn") == "basic" and scope == Player.HistoryPhase then
      return player:getMark("neifa-turn")
    end
  end,
  extra_target_func = function(self, player, skill)
    if skill.trueName == "slash_skill" and player:getMark("@neifa-turn") == "basic" then
      return 1
    end
  end,
}
local neifa_prohibit = fk.CreateProhibitSkill{
  name = "#neifa_prohibit",
  prohibit_use = function(self, player, card)
    return (player:getMark("@neifa-turn") == "basic" and card.type ~= Card.TypeBasic) or
      (player:getMark("@neifa-turn") == "non_basic" and card.type == Card.TypeBasic)
  end,
}
neifa:addRelatedSkill(neifa_targetmod)
neifa:addRelatedSkill(neifa_prohibit)
neifa:addRelatedSkill(neifa_trigger)
neifa:addRelatedSkill(neifa_draw)
yuantanyuanshang:addSkill(neifa)
Fk:loadTranslationTable{
  ["yuantanyuanshang"] = "袁谭袁尚",
  ["neifa"] = "内伐",
  [":neifa"] = "出牌阶段开始时，你可以摸两张牌或获得场上一张牌，然后弃置一张牌。若弃置的牌：是基本牌，你本回合不能使用非基本牌，"..
  "本阶段使用【杀】次数上限+X，目标上限+1；不是基本牌，你本回合不能使用基本牌，使用普通锦囊牌的目标+1或-1，前两次使用装备牌时摸X张牌"..
  "（X为发动技能时手牌中因本技能不能使用的牌且至多为5）。",
  ["#neifa-choose"] = "内伐：获得场上的一张牌，或点“取消”摸两张牌",
  ["@neifa-turn"] = "内伐",
  ["non_basic"] = "非基本牌",
  ["#neifa_trigger-choose"] = "内伐：你可以为%arg增加/减少一个目标",
  ["#neifa_trigger"] = "内伐",
  ["#neifa_draw"] = "内伐",

  ["$neifa1"] = "自相恩残，相煎何急。",
  ["$neifa2"] = "同室内伐，贻笑外人。",
  ["~yuantanyuanshang"] = "兄弟难齐心，该有此果……",
}

local sunshao = General(extension, "ol__sunshao", "wu", 3)
local bizheng = fk.CreateTriggerSkill{
  name = "bizheng",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#bizheng-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    to:drawCards(2, self.name)
    for _, p in ipairs({player, to}) do
      if p:getHandcardNum() > p.maxHp then
        room:askForDiscard(p, 2, 2, true, self.name, false)
      end
    end
  end,
}
local yidian = fk.CreateTriggerSkill{
  name = "yidian",
  anim_type = "offensive",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.targetGroup and data.firstTarget and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) then
      for _, id in ipairs(player.room.discard_pile) do
        if data.card.name == Fk:getCardById(id).name then
          return
        end
      end
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = AskForAddTarget(player, room:getAlivePlayers(), 1, false, "#yidian-choose:::"..data.card:toLogString(), self.name, data)
    if #targets > 0 then
      self.cost_data = targets[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    TargetGroup:pushTargets(data.targetGroup, self.cost_data)
  end,
}
sunshao:addSkill(bizheng)
sunshao:addSkill(yidian)
Fk:loadTranslationTable{
  ["ol__sunshao"] = "孙邵",
  ["bizheng"] = "弼政",
  [":bizheng"] = "摸牌阶段结束时，你可令一名其他角色摸两张牌，然后你与其之中，手牌数大于体力上限的角色弃置两张牌。",
  ["yidian"] = "佚典",
  [":yidian"] = "若你使用的基本牌或普通锦囊在弃牌堆中没有同名牌，你可以为此牌指定一个额外目标（无视距离）。",
  ["#bizheng-choose"] = "弼政：你可以令一名其他角色摸两张牌，然后你与其中手牌数大于体力上限的角色弃置两张牌",
  ["#yidian-choose"] = "佚典：你可以为此%arg额外指定一个目标",
}

local gaolan = General(extension, "ol__gaolan", "qun", 4)
local xiying = fk.CreateTriggerSkill{
  name = "xiying",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Play and not player:isKongcheng()
      else
        return player.phase == Player.Finish and player:getMark("xiying_damage-turn") > 0 and
        player:usedSkillTimes(self.name, Player.HistoryTurn) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return #player.room:askForDiscard(player, 1, 1, false, self.name, true, ".|.|.|hand|.|^basic", "#xiying-invoke") > 0
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if #room:askForDiscard(p, 1, 1, true, self.name, true, ".", "#xiying-discard") == 0 then
          room:addPlayerMark(p, "xiying-turn", 1)
        end
      end
    else
      local cards = {}
      for i = 1, #room.draw_pile, 1 do
        local card = Fk:getCardById(room.draw_pile[i])
        if card.is_damage_card then
          table.insertIfNeed(cards, room.draw_pile[i])
        end
      end
      if #cards > 0 then
        local card = table.random(cards)
        room:moveCards({
          ids = {card},
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true, true) and player:usedSkillTimes(self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "xiying_damage-turn", 1)
  end,
}
local xiying_prohibit = fk.CreateProhibitSkill{
  name = "#xiying_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("xiying-turn") > 0
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("xiying-turn") > 0
  end,
}
xiying:addRelatedSkill(xiying_prohibit)
gaolan:addSkill(xiying)
Fk:loadTranslationTable{
  ["ol__gaolan"] = "高览",
  ["xiying"] = "袭营",
  [":xiying"] = "出牌阶段开始时，你可以弃置手中一张非基本牌，令所有其他角色选择一项：1.弃置一张牌；2.本回合不能使用或打出牌。"..
  "若如此做，结束阶段，若你于本回合出牌阶段造成过伤害，你获得牌堆中一张【杀】或伤害锦囊牌。",
  ["#xiying-invoke"] = "袭营：你可以弃置一张非基本手牌，所有其他角色需弃置一张牌，否则其本回合不能使用或打出牌",
  ["#xiying-discard"] = "袭营：你需弃置一张牌，否则本回合不能使用或打出牌",
}

return extension
