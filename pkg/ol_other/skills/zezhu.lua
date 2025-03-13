local zezhu = fk.CreateSkill{
  name = "guandu__zezhu",
}

Fk:loadTranslationTable{
  ["fushix"] = "附势",
  [":fushix"] = "锁定技，根据场上角色数较多的势力，你视为拥有对应的技能：群势力-〖择主〗；魏势力-〖逞功〗。",

  ["guandu__zezhu"] = "择主",
  [":guandu__zezhu"] = "出牌阶段限一次，你可以获得主公和一号位区域内各一张牌（无牌则你摸一张牌），然后交给其各一张牌。",

  ["#guandu__zezhu"] = "择主：获得主公和一号位区域内各一张牌（无牌则你摸一张牌），然后交给其各一张牌",
  ["#guandu__zezhu-prey"] = "择主：获得 %dest 区域内一张牌",
  ["#guandu__zezhu-give"] = "择主：交给 %dest 一张牌",

}

zezhu:addEffect("active", {
  anim_type = "control",
  prompt = "#guandu__zezhu",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(zezhu.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().alive_players, function (p)
        return p.seat == 1 or p.role == "lord" or p.role:endsWith("marshal")
      end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return p.seat == 1 or p.role == "lord" or p.role:endsWith("marshal")
    end)
    room:doIndicate(player, targets)
    for _, p in ipairs(targets) do
      if player.dead then return end
      if not p.dead then
        if p.role == "lord" or p.role:endsWith("marshal") then
          if p:isNude() then
            player:drawCards(1, zezhu.name)
          else
            if p == player then
              if #player:getCardIds("ej") > 0 then
                local card = room:askToChooseCard(player, {
                  target = p,
                  flag = "ej",
                  skill_name = zezhu.name,
                  prompt = "#guandu__zezhu-prey::"..p.id,
                })
                room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, zezhu.name, nil, false, player)
              end
            else
              local card = room:askToChooseCard(player, {
                target = p,
                flag = "hej",
                skill_name = zezhu.name,
                prompt = "#guandu__zezhu-prey::"..p.id,
              })
              room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, zezhu.name, nil, false, player)
            end
          end
        end
      end
      if player.dead then return end
      if p.seat == 1 then
        if p:isNude() then
          player:drawCards(1, zezhu.name)
        else
          if p == player then
            if #player:getCardIds("ej") > 0 then
              local card = room:askToChooseCard(player, {
                target = p,
                flag = "ej",
                skill_name = zezhu.name,
                prompt = "#guandu__zezhu-prey::"..p.id,
              })
              room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, zezhu.name, nil, false, player)
            end
          else
            local card = room:askToChooseCard(player, {
              target = p,
              flag = "hej",
              skill_name = zezhu.name,
              prompt = "#guandu__zezhu-prey::"..p.id,
            })
            room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, zezhu.name, nil, false, player)
          end
        end
      end
    end
    for _, p in ipairs(targets) do
      if player.dead or player:isNude() then return end
      if not p.dead then
        if p.role == "lord" or p.role:endsWith("marshal") then
          if p == player then
            if #player:getCardIds("e") > 0 then
              local card = room:askToCards(player, {
                min_num = 1,
                max_num = 1,
                include_equip = true,
                skill_name = zezhu.name,
                pattern = ".|.|.|equip",
                prompt = "#guandu__zezhu-give::"..p.id,
                cancelable = false,
              })
              room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonGive, zezhu.name, nil, false, player)
            end
          else
            local card = room:askToCards(player, {
              min_num = 1,
              max_num = 1,
              include_equip = true,
              skill_name = zezhu.name,
              prompt = "#guandu__zezhu-give::"..p.id,
              cancelable = false,
            })
            room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonGive, zezhu.name, nil, false, player)
          end
        end
      end
      if player.dead or player:isNude() then return end
      if p.seat == 1 then
        if p == player then
          if #player:getCardIds("e") > 0 then
            local card = room:askToCards(player, {
              min_num = 1,
              max_num = 1,
              include_equip = true,
              skill_name = zezhu.name,
              pattern = ".|.|.|equip",
              prompt = "#guandu__zezhu-give::"..p.id,
              cancelable = false,
            })
            room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonGive, zezhu.name, nil, false, player)
          end
        else
          local card = room:askToCards(player, {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            skill_name = zezhu.name,
            prompt = "#guandu__zezhu-give::"..p.id,
            cancelable = false,
          })
          room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonGive, zezhu.name, nil, false, player)
        end
      end
    end
  end,
})

return zezhu
