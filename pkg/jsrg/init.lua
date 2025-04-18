local extension = Package:new("ol_jsrg")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/jsrg/skills")

Fk:loadTranslationTable{
  ["ol_jsrg"] = "OL-江山如故",
  ["ol_js"] = "OL江山",
}

General:new(extension, "ol_js__zhaoyun", "shu", 4):addSkills { "ol__longlin", "ol__zhendan" }
Fk:loadTranslationTable{
  ["ol_js__zhaoyun"] = "闪赵云",
  ["#ol_js__zhaoyun"] = "北伐之柱",
  --["illustrator:ol_js__zhaoyun"] = "",

  ["~ol_js__zhaoyun"] = "北伐点将，丞相为何置我于不顾？",
}

local liuhong = General:new(extension, "ol_js__liuhong", "qun", 4)
liuhong:addSkills { "ol__chaozheng", "ol__shenchong", "ol__julian" }
liuhong:addRelatedSkills { "feiyang", "bahu" }
Fk:loadTranslationTable{
  ["ol_js__liuhong"] = "闪刘宏",
  ["#ol_js__liuhong"] = "轧庭焚礼",
  --["illustrator:ol_js__liuhong"] = "",

  --["~ol_js__liuhong"] = "",
}

return extension
