local shengong = fk.CreateSkill{
  name = "shengong",
}

Fk:loadTranslationTable{
  ["shengong"] = "神工",
  [":shengong"] = "出牌阶段各限一次，你可以弃置一张武器/防具/坐骑或宝物牌，进行一次“锻造”，选择一张武器/防具/宝物牌置于一名角色的装备区"..
  "（替换原装备）。当以此法获得的装备牌进入弃牌堆时，销毁之，然后此回合结束阶段，你摸一张牌。",

  ["#shengong"] = "神工：你可以弃置一张武器/防具/坐骑或宝物，进行一次“锻造”",
  ["#shengong-help"] = "神工：选择助力或妨害 %src 的锻造",
  ["shengong_good"] = "助力锻造",
  ["shengong_bad"] = "妨害锻造",
  ["shengong_active"] = "神工",
  ["#shengong-choose"] = "选择一张“神工”装备，置于一名角色的装备区（取消则随机置入）",
  ["#shengongChoice"] = "%from 选择 %arg，点数：%arg2",
  ["#shengongResult"] = "%from 发动了“神工”，助力锻造点数：%arg，妨害锻造点数：%arg2，结果：%arg3",
  ["shengongPerfect"] = "完美锻造",
  ["shengongSuccess"] = "锻造成功",
  ["shengongFail"] = "锻造失败",

  ["$shengong1"] = "技艺若神，大巧不工。",
  ["$shengong2"] = "千锤百炼，始得神兵。",
}

local U = require "packages/utility/utility"

local weapons = {
  {"py_halberd", Card.Diamond, 12},
  {"py_blade", Card.Spade, 5},
  {"blood_sword", Card.Spade, 6},
  {"py_double_halberd", Card.Diamond, 13},
  {"black_chain", Card.Spade, 13},
  {"five_elements_fan", Card.Diamond, 1},
}
local armors = {
  {"py_belt", Card.Spade, 2},
  {"py_robe", Card.Club, 1},
  {"py_cloak", Card.Spade, 9},
  {"py_diagram", Card.Spade, 2},
  {"breastplate", Card.Club, 1},
  {"dark_armor", Card.Club, 2},
}
local treasures = {
  {"py_hat", Card.Diamond, 1},
  {"py_coronet", Card.Club, 4},
  {"py_threebook", Card.Spade, 5},
  {"py_mirror", Card.Diamond, 1},
  {"wonder_map", Card.Club, 12},
  {"taigong_tactics", Card.Spade, 1},
}

shengong:addEffect("active", {
  anim_type = "support",
  prompt = "shengong",
  can_use = function(self, player)
    return #player:getTableMark("shengong-phase") < 3
  end,
  card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    local card = Fk:getCardById(to_select)
    if #selected == 0 and not player:prohibitDiscard(card) then
      if table.contains(player:getTableMark("shengong-phase"), card.sub_type) then
        return false
      end
      if card.sub_type > 4 then
        return not table.contains(player:getTableMark("shengong-phase"), 5)
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local card = Fk:getCardById(effect.cards[1])
    room:throwCard(effect.cards, shengong.name, player, player)
    if player.dead then return end
    room:addTableMark(player, "shengong-phase", card.sub_type)
    local cards = {}
    if card.sub_type == Card.SubtypeWeapon then
      cards = table.filter(U.prepareDeriveCards(room, weapons, "ol__puyuan_weapons"), function (id)
        return room:getCardArea(id) == Card.Void
      end)
    elseif card.sub_type == Card.SubtypeArmor then
      cards = table.filter(U.prepareDeriveCards(room, armors, "ol__puyuan_armors"), function (id)
        return room:getCardArea(id) == Card.Void
      end)
    else
      room:addTableMark(player, "shengong-phase", 5)
      cards = table.filter(U.prepareDeriveCards(room, treasures, "ol__puyuan_treasures"), function (id)
        return room:getCardArea(id) == Card.Void
      end)
    end
    if #cards == 0 then return end
    local players = room:getAlivePlayers()
    local others = {}
    local choiceMap = {}
    -- 明身份时，友方自动选择助力，敌方自动选择妨碍
    for _, p in ipairs(players) do
      if p == player or (player.role == p.role and player.role_shown and p.role_shown) then
        choiceMap[p.id] = "shengong_good"
      else
        table.insert(others, p)
      end
    end
    if #others > 0 then
      local result = room:askToJointChoice(player, {
        players = others,
        choices = {"shengong_good", "shengong_bad", "Cancel"},
        skill_name = shengong.name,
        prompt = "#shengong-help:"..player.id,
      })
      for _, p in ipairs(others) do
        choiceMap[p.id] = result[p]
      end
    end
    local good, bad = 0, 0
    local show = room:getNCards(#players)
    room:turnOverCardsFromDrawPile(player, show, shengong.name)
    for i, p in ipairs(players) do
      room:delay(200)
      local num = Fk:getCardById(show[i]).number
      local choice = choiceMap[p.id]
      if choice ~= "Cancel" then
        room:sendLog{
          type = "#shengongChoice",
          from = p.id,
          arg = choice,
          arg2 = num,
        }
      end
      if choice == "shengong_good" then
        room:setCardEmotion(show[i], "judgegood")
        good = good + num
      elseif choice == "shengong_bad" then
        room:setCardEmotion(show[i], "judgebad")
        bad = bad + num
      end
    end
    room:cleanProcessingArea(show)
    local choose_num = 1
    local result = "shengongFail"
    if bad == 0 then
      choose_num = 3
      result = "shengongPerfect"
    elseif good >= bad then
      choose_num = 2
      result = "shengongSuccess"
    end
    room:sendLog{
      type = "#shengongResult",
      from = player.id,
      arg = good,
      arg2 = bad,
      arg3 = result,
    }
    local list = table.random(cards, choose_num)
    room:setPlayerMark(player, "shengong-tmp", list)
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "shengong_active",
      prompt = "#shengong-choose",
      no_indicate = false,
    })
    room:setPlayerMark(player, "shengong-tmp", 0)
    local cardId, to
    if success and dat then
      cardId = dat.cards[1]
      to = dat.targets[1]
    else
      cardId = list[1]
      to = table.find(room.alive_players, function (p) return p:canMoveCardIntoEquip(cardId, true) end)
      if not to then return end
    end
    room:setCardMark(Fk:getCardById(cardId), MarkEnum.DestructIntoDiscard, 1)
    room:moveCardIntoEquip(to, cardId, shengong.name, true, player)
  end,
})
shengong:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target.phase == Player.Finish and player:hasSkill(shengong.name) then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.Void then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(U.prepareDeriveCards(player.room, weapons, "ol__puyuan_weapons"), info.cardId) or
                table.contains(U.prepareDeriveCards(player.room, armors, "ol__puyuan_armors"), info.cardId) or
                table.contains(U.prepareDeriveCards(player.room, treasures, "ol__puyuan_treasures"), info.cardId) then
                n = n + 1
              end
            end
          end
        end
      end, Player.HistoryTurn)
      if n > 0 then
        event:setCostData(self, {choice = n})
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(event:getCostData(self).choice, shengong.name)
  end,
})

return shengong
