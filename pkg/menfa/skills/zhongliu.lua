local zhongliu = fk.CreateSkill{
  name = "zhongliu",
  tags = { "Family", Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhongliu"] = "中流",
  [":zhongliu"] = "宗族技，锁定技，当你使用牌时，若不为同族角色的手牌，你视为未发动此武将牌上的技能。",
}

local U = require "packages/utility/utility"

zhongliu:addEffect(fk.CardUsing, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhongliu.name) and player == target then
      local no_skill = true
      local all_skills = Fk.generals[player.general]:getSkillNameList()
      if table.contains(all_skills, zhongliu.name) then
        for _, skill_name in ipairs(all_skills) do
          local skill = Fk.skills[skill_name]
          local zhongliu_type = skill:getSkeleton().zhongliu_type
          if zhongliu_type == nil and skill:hasTag(Skill.Limited) then
            zhongliu_type = Player.HistoryGame
          end
          if zhongliu_type and player:usedSkillTimes(skill_name, zhongliu_type) > 0 then
            no_skill = false
            break
          end
        end
      end
      if no_skill and player.deputyGeneral and player.deputyGeneral ~= "" then
        all_skills = Fk.generals[player.deputyGeneral]:getSkillNameList()
        if table.contains(all_skills, zhongliu.name) then
          for _, skill_name in ipairs(all_skills) do
            local skill = Fk.skills[skill_name]
            local zhongliu_type = skill:getSkeleton().zhongliu_type
            if zhongliu_type == nil and skill:hasTag(Skill.Limited) then
              zhongliu_type = Player.HistoryGame
            end
            if zhongliu_type and player:usedSkillTimes(skill_name, zhongliu_type) > 0 then
              no_skill = false
              break
            end
          end
        end
      end
      if no_skill then return false end
      local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
      if #cardlist == 0 then return true end
      local room = player.room
      local use_event = room.logic:getCurrentEvent()
      use_event:searchEvents(GameEvent.MoveCards, 1, function(e)
        if e.parent and e.parent.id == use_event.id then
          local subcheck = table.simpleClone(cardlist)
          for _, move in ipairs(e.data) do
            if move.moveReason == fk.ReasonUse then
              local wang_family = false
              if move.from and U.FamilyMember(player, move.from) then
                wang_family = true
              end
              for _, info in ipairs(move.moveInfo) do
                if table.removeOne(subcheck, info.cardId) and info.fromArea == Card.PlayerHand then
                  if wang_family then
                    no_skill = true
                  end
                end
              end
            end
          end
          if #subcheck == 0 then
            return true
          end
        end
      end)
      return not no_skill
    end
  end,
  on_use = function(self, event, target, player, data)
    local all_skills = Fk.generals[player.general]:getSkillNameList()
    if table.contains(all_skills, zhongliu.name) then
      for _, skill_name in ipairs(all_skills) do
        local skill = Fk.skills[skill_name]
        local zhongliu_type = skill:getSkeleton().zhongliu_type
        if zhongliu_type == nil and skill:hasTag(Skill.Limited) then
          zhongliu_type = Player.HistoryGame
        end
        if zhongliu_type and player:usedSkillTimes(skill_name, zhongliu_type) > 0 then
          player:setSkillUseHistory(skill_name, 0, zhongliu_type)
        end
      end
    end
    if player.deputyGeneral and player.deputyGeneral ~= "" then
      all_skills = Fk.generals[player.deputyGeneral]:getSkillNameList()
      if table.contains(all_skills, zhongliu.name) then
        for _, skill_name in ipairs(all_skills) do
          local skill = Fk.skills[skill_name]
          local zhongliu_type = skill:getSkeleton().zhongliu_type
          if zhongliu_type == nil and skill:hasTag(Skill.Limited) then
            zhongliu_type = Player.HistoryGame
          end
          if zhongliu_type and player:usedSkillTimes(skill_name, zhongliu_type) > 0 then
            player:setSkillUseHistory(skill_name, 0, zhongliu_type)
          end
        end
      end
    end
  end,
})

return zhongliu
