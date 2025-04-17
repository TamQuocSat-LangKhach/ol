local extension = Package:new("ol_exyj")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_exyj/skills")

Fk:loadTranslationTable{
  ["ol_exyj"] = "OL-界一将",
}

General:new(extension, "ol_ex__caozhi", "wei", 3):addSkills { "ol_ex__jiushi", "luoying" }
Fk:loadTranslationTable{
  ["ol_ex__caozhi"] = "界曹植",
  ["#ol_ex__caozhi"] = "才高八斗",
  --["illustrator:ol_ex__caozhi"] = "",

  --["~ol_ex__caozhi"] = "",
}

General:new(extension, "ol_ex__zhangchunhua", "wei", 3, 3, General.Female):addSkills { "jueqing", "shangshi", "jianmie" }
Fk:loadTranslationTable{
  ["ol_ex__zhangchunhua"] = "界张春华",
  ["#ol_ex__zhangchunhua"] = "翦草除根",
  ["illustrator:ol_ex__zhangchunhua"] = "君桓文化",

  ["$jueqing_ol_ex__zhangchunhua1"] = "情丝如雪，难当暖阳。",
  ["$jueqing_ol_ex__zhangchunhua2"] = "有情总被无情负，绝情方无软肋生。",
  ["$shangshi_ol_ex__zhangchunhua1"] = "伤我最深的，竟是你司马懿。",
  ["$shangshi_ol_ex__zhangchunhua2"] = "世间刀剑数万，何以情字伤人？",
  ["~ol_ex__zhangchunhua"] = "我不负懿，懿负我。",
}

General:new(extension, "ol_ex__fazheng", "shu", 3):addSkills { "ol_ex__xuanhuo", "ol_ex__enyuan" }
Fk:loadTranslationTable{
  ["ol_ex__fazheng"] = "界法正",
  ["#ol_ex__fazheng"] = "明理审事",
  --["illustrator:ol_ex__fazheng"] = "",

  ["~ol_ex__fazheng"] = "孝直不忠，不能佑主公复汉室了……",
}

General:new(extension, "ol_ex__lingtong", "wu", 4):addSkills { "ol_ex__xuanfeng" }
Fk:loadTranslationTable{
  ["ol_ex__lingtong"] = "界凌统",
  ["#ol_ex__lingtong"] = "血涕津渚",
  ["designer:ol_ex__lingtong"] = "玄蝶既白",
  ["illustrator:ol_ex__lingtong"] = "君桓文化",

  ["~ol_ex__lingtong"] = "先……停一下吧……",
}

General:new(extension, "ol_ex__wuguotai", "wu", 3, 3, General.Female):addSkills { "ol_ex__ganlu", "ol_ex__buyi" }
Fk:loadTranslationTable{
  ["ol_ex__wuguotai"] = "界吴国太",
  ["#ol_ex__wuguotai"] = "慈怀瑾瑜",
  --["illustrator:ol_ex__wuguotai"] = "",

  ["~ol_ex__wuguotai"] = "竖子，何以胞妹为饵乎？",
}

General:new(extension, "ol_ex__caozhang", "wei", 4):addSkills { "ol_ex__jiangchi" }
Fk:loadTranslationTable{
  ["ol_ex__caozhang"] = "界曹彰",
  ["#ol_ex__caozhang"] = "任城威王",
  ["designer:ol_ex__caozhang"] = "玄蝶既白",
  ["illustrator:ol_ex__caozhang"] = "枭瞳",

  ["~ol_ex__caozhang"] = "黄须儿，愧对父亲……",
}

General:new(extension, "ol_ex__wangyi", "wei", 3, 3, General.Female):addSkills { "ol_ex__zhenlie", "ol_ex__miji" }
Fk:loadTranslationTable{
  ["ol_ex__wangyi"] = "界王异",
  ["#ol_ex__wangyi"] = "决意的巾帼",
  --["illustrator:ol_ex__wangyi"] = "",

  --["~ol_ex__wangyi"] = "",
}

General:new(extension, "ol_ex__madai", "shu", 4):addSkills { "mashu", "ol_ex__qianxi" }
Fk:loadTranslationTable{
  ["ol_ex__madai"] = "界马岱",
  ["#ol_ex__madai"] = "临危受命",
  --["illustrator:ol_ex__madai"] = "",

  --["~ol_ex__madai"] = "",
}

General:new(extension, "ol_ex__liaohua", "shu", 4):addSkills { "ol_ex__dangxian", "ol_ex__fuli" }
Fk:loadTranslationTable{
  ["ol_ex__liaohua"] = "界廖化",
  ["#ol_ex__liaohua"] = "历尽沧桑",
  --["illustrator:ol_ex__liaohua"] = "",

  --["~ol_ex__liaohua"] = "",
}

General:new(extension, "ol_ex__guanxingzhangbao", "shu", 4):addSkills { "ol_ex__fuhun" }
Fk:loadTranslationTable{
  ["ol_ex__guanxingzhangbao"] = "界关兴张苞",
  ["#ol_ex__guanxingzhangbao"] = "将门虎子",
  --["illustrator:ol_ex__guanxingzhangbao"] = "",

  --["~ol_ex__guanxingzhangbao"] = "",
}

General:new(extension, "ol_ex__chengpu", "wu", 4):addSkills { "ol_ex__lihuo", "ol_ex__chunlao" }
Fk:loadTranslationTable{
  ["ol_ex__chengpu"] = "界程普",
  ["#ol_ex__chengpu"] = "三朝虎臣",
  ["illustrator:ol_ex__chengpu"] = "monkey",

  ["~ol_ex__chengpu"] = "以暴讨贼，竟遭报应吗？",
}

General:new(extension, "ol_ex__liubiao", "qun", 3):addSkills { "ol_ex__zishou", "ol_ex__zongshi" }
Fk:loadTranslationTable{
  ["ol_ex__liubiao"] = "界刘表",
  ["#ol_ex__liubiao"] = "跨蹈汉南",
  --["illustrator:ol_ex__liubiao"] = "",

  --["~ol_ex__liubiao"] = "",
}

General:new(extension, "ol_ex__caochong", "wei", 3):addSkills { "ol_ex__chengxiang", "ol_ex__renxin" }
Fk:loadTranslationTable{
  ["ol_ex__caochong"] = "界曹冲",
  ["#ol_ex__caochong"] = "聪察岐嶷",
  ["illustrator:ol_ex__caochong"] = "君桓文化",

  ["~ol_ex__caochong"] = "性慧早夭，为之奈何？",
}

General:new(extension, "ol_ex__guohuai", "wei", 3):addSkills { "ol_ex__jingce" }
Fk:loadTranslationTable{
  ["ol_ex__guohuai"] = "界郭淮",
  --["#ol_ex__guohuai"] = "",
  --["illustrator:ol_ex__guohuai"] = "",

  --["~ol_ex__guohuai"] = "",
}

General:new(extension, "ol_ex__yufan", "wu", 3):addSkills { "ol_ex__zongxuan", "ol_ex__zhiyan" }
Fk:loadTranslationTable{
  ["ol_ex__yufan"] = "界虞翻",
  ["#ol_ex__yufan"] = "犯颜谏争",
  ["illustrator:ol_ex__yufan"] = "YanBai",

  ["~ol_ex__yufan"] = "彼皆死人，何语神仙？",
}

General:new(extension, "ol_ex__jianyong", "shu", 3):addSkills { "ol_ex__qiaoshui", "zongshij" }
Fk:loadTranslationTable{
  ["ol_ex__jianyong"] = "界简雍",
  ["#ol_ex__jianyong"] = "简傲跌宕",
  ["illustrator:ol_ex__jianyong"] = "zoo",

  ["~ol_ex__jianyong"] = "行事无据，为人所误矣……",
}

General:new(extension, "ol_ex__fuhuanghou", "qun", 3, 3, General.Female):addSkills { "ol_ex__zhuikong", "ol_ex__qiuyuan" }
Fk:loadTranslationTable{
  ["ol_ex__fuhuanghou"] = "界伏皇后",
  ["#ol_ex__fuhuanghou"] = "巾帼拚生",
  --["illustrator:ol_ex__fuhuanghou"] = "",

  ["~ol_ex__fuhuanghou"] = "只恨邪风不静，不能杀了老贼……",
}

General:new(extension, "ol_ex__liru", "qun", 3):addSkills { "ol_ex__juece", "ol_ex__mieji", "ty_ex__fencheng" }
Fk:loadTranslationTable{
  ["ol_ex__liru"] = "界李儒",
  ["#ol_ex__liru"] = "坼地摧天",
  ["illustrator:ol_ex__liru"] = "君桓文化",

  ["$ty_ex__fencheng_ol_ex__liru1"] = "愿这火光，照亮董公西行之路！",
  ["$ty_ex__fencheng_ol_ex__liru2"] = "诸公且看，此火可戏天下诸侯否？",
  ["~ol_ex__liru"] = "火熄人亡，都结束了……",
}

General:new(extension, "ol_ex__caifuren", "qun", 3, 3, General.Female):addSkills { "ol_ex__qieting", "xianzhou" }
Fk:loadTranslationTable{
  ["ol_ex__caifuren"] = "界蔡夫人",
  ["#ol_ex__caifuren"] = "怙恩恃宠",
  --["illustrator:ol_ex__caifuren"] = "",

  ["$xianzhou_ol_ex__caifuren1"] = "今献州以降，请丞相善待我孤儿寡母。",
  ["$xianzhou_ol_ex__caifuren2"] = "我儿志短才疏，只求方寸之地安享富贵。",
  ["~ol_ex__caifuren"] = "这哪里是荆州，分明是黄泉……",
}

return extension
