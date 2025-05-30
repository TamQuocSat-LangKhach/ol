local extension = Package:new("ol_test")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_test/skills")

Fk:loadTranslationTable{
  ["ol_test"] = "OL-测试服",
}

General:new(extension, "dongtuna", "qun", 4):addSkills { "jianman" }
Fk:loadTranslationTable{
  ["dongtuna"] = "董荼那",
  ["#dongtuna"] = "铅刀拿云",
  ["designer:dongtuna"] = "大宝",
  ["illustrator:dongtuna"] = "monkey",

  ["~dongtuna"] = "孟获小儿，安敢杀我！",
}

General:new(extension, "ol__peixiu", "wei", 4):addSkills { "maozhu", "jinlan" }
Fk:loadTranslationTable{
  ["ol__peixiu"] = "裴秀",
  ["#ol__peixiu"] = "勋德茂著",
  ["illustrator:ol__peixiu"] = "塔普",

  ["~ol__peixiu"] = "",
}

General:new(extension, "budugen", "qun", 4):addSkills { "kouchao" }
Fk:loadTranslationTable{
  ["budugen"] = "步度根",
  ["#budugen"] = "秋城雁阵",

  ["~budugen"] = "",
}

General:new(extension, "kongshu", "qun", 3, 3, General.Female):addSkills { "leiluan", "fuchao" }
Fk:loadTranslationTable{
  ["kongshu"] = "孔淑",
  --["#kongshu"] = "",

  ["~kongshu"] = "",
}

General:new(extension, "ol__liuzhang", "qun", 3):addSkills { "fengwei", "zonghu" }
Fk:loadTranslationTable{
  ["ol__liuzhang"] = "刘璋",
  --["#ol__liuzhang"] = "",

  ["~ol__liuzhang"] = "",
}

General:new(extension, "ol__yangfeng", "qun", 4):addSkills { "jiawei" }
Fk:loadTranslationTable{
  ["ol__yangfeng"] = "杨奉",
  --["#ol__yangfeng"] = "",

  ["~ol__yangfeng"] = "",
}

General:new(extension, "hanshiwuhu", "wei", 4):addSkills { "juejueh", "pimi" }
Fk:loadTranslationTable{
  ["hanshiwuhu"] = "韩氏五虎",
  --["#hanshiwuhu"] = "",

  ["~hanshiwuhu"] = "我的儿呀！好你个老匹夫！",
}

General:new(extension, "ol__xiahouen", "wei", 4):addSkills { "yinfeng", "fulux" }
Fk:loadTranslationTable{
  ["ol__xiahouen"] = "夏侯恩",
  --["#ol__xiahouen"] = "",

  ["~ol__xiahouen"] = "丞相！就是他抢咱们东西！",
}

local zhaozhong = General:new(extension, "ol__zhaozhong", "qun", 3)
zhaozhong:addSkills { "pengbi", "dici" }
zhaozhong:addRelatedSkills { "yintian", "biri" }
Fk:loadTranslationTable{
  ["ol__zhaozhong"] = "赵忠",
  ["#ol__zhaozhong"] = "环佩动帷帟",

  ["~ol__zhaozhong"] = "",
}

General:new(extension, "ol__yangfu", "wei", 4):addSkills { "pingzhong", "suyi" }
Fk:loadTranslationTable{
  ["ol__yangfu"] = "杨阜",
  --["#ol__yangfu"] = "",

  ["~ol__yangfu"] = "",
}

General:new(extension, "ol__lifeng", "shu", 3):addSkills { "jiyun", "ol__shuliang" }
Fk:loadTranslationTable{
  ["ol__lifeng"] = "李丰",
  --["#ol__lifeng"] = "",

  ["~ol__lifeng"] = "",
}

General:new(extension, "ol__zhangmancheng", "qun", 5):addSkills { "kuangxin", "leishi" }
Fk:loadTranslationTable{
  ["ol__zhangmancheng"] = "张曼成",
  --["#ol__zhangmancheng"] = "",

  ["~ol__zhangmancheng"] = "",
}

General:new(extension, "ol__guanhai", "qun", 4):addSkills { "xiewei", "youque" }
Fk:loadTranslationTable{
  ["ol__guanhai"] = "管亥",
  --["#ol__guanhai"] = "",

  ["~ol__guanhai"] = "",
}

General:new(extension, "ol__caizhenji", "wei", 3, 3, General.Female):addSkills { "kedi", "cunze" }
Fk:loadTranslationTable{
  ["ol__caizhenji"] = "蔡贞姬",
  --["#ol__caizhenji"] = "",

  ["~ol__caizhenji"] = "",
}

return extension
