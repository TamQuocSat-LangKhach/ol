local juetu = fk.CreateSkill{
  name = "juetu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["juetu"] = "绝途",
  [":juetu"] = "锁定技，弃牌阶段开始时，你改为保留每种花色的手牌各一张，将其余手牌置入弃牌堆。然后你令一名其他角色展示一张手牌，"..
  "若你手牌中：没有此花色的牌，你对其造成1点伤害；有此花色的牌，你将其展示牌当【过河拆桥】使用。",

  ["#juetu-invoke"] = "绝途：保留每种花色的手牌各一张，其余手牌置入弃牌堆",
  ["#juetu-choose"] = "绝途：令一名角色展示一张手牌，根据你手牌中有无其展示花色的牌执行效果",
  ["#juetu-show"] = "绝途：展示一张手牌，若 %src 手牌无此花色则对你造成伤害，若有则其将展示牌当【过河拆桥】使用",
  ["#juetu-use"] = "绝途：请将 %dest 展示的牌当【过河拆桥】使用",

  ["$juetu1"] = "",
  ["$juetu2"] = "",
}

juetu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juetu.name) and player.phase == Player.Discard
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.phase_end = true
    if table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).suit == Card.NoSuit or
      table.find(player:getCardIds("h"), function (id2)
        return Fk:getCardById(id):compareSuitWith(Fk:getCardById(id2))
      end) ~= nil
    end) then
      local success, dat = player.room:askToUseActiveSkill(player, {
        skill_name = "juetu_active",
        prompt = "#juetu-invoke",
        cancelable = false,
      })
      if not (success and dat) then
        dat = {}
        dat.cards = {}
        for _, id in ipairs(player:getCardIds("h")) do
          if Fk:getCardById(id).suit ~= Card.NoSuit and
            not table.find(dat.cards, function (id2)
              return Fk:getCardById(id):compareSuitWith(Fk:getCardById(id2))
            end) then
            table.insert(dat.cards, id)
          end
        end
      end
      local cards = table.filter(player:getCardIds("h"), function (id)
        return not table.contains(dat.cards, id)
      end)
      if #cards > 0 then
        room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, juetu.name, nil, true, player)
        if player.dead then return end
      end
    end
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isKongcheng()
    end)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = juetu.name,
      prompt = "#juetu-choose",
      cancelable = false,
    })[1]
    local card = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = juetu.name,
      prompt = "#juetu-show:"..player.id,
      cancelable = false,
    })
    to:showCards(card)
    if player.dead or to.dead then return end
    if table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):compareSuitWith(Fk:getCardById(card[1]))
    end) then
      if table.contains(to:getCardIds("h"), card[1]) then
        room:askToUseVirtualCard(player, {
          name = "dismantlement",
          skill_name = juetu.name,
          prompt = "#juetu-use::"..to.id,
          cancelable = false,
          extra_data = {
            expand_pile = card,
          },
          card_filter = {
            n = 1,
            cards = card,
          },
        })
      end
    else
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = juetu.name,
      }
    end
  end,
})

return juetu
