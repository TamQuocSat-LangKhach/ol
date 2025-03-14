local extension = Package:new("ol_xinghe")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/xinghe/skills")

Fk:loadTranslationTable{
  ["ol_xinghe"] = "OL-璀璨星河",
}

--天极：刘协x 曹昂x 何太后√ 孙鲁育√ 孙皓√ 王荣? 左棻√ 刘琦√ 曹嵩x 卞夫人√ 刘辩x 清河公主√ 滕芳兰√ 芮姬√ 唐姬x 刘宏x 杜夫人x
--曹宇√ 曹腾√ 刘焉x 秦朗√ 袁姬√
General:new(extension, "ol__hetaihou", "qun", 3, 3, General.Female):addSkills { "ol__zhendu", "ol__qiluan" }
Fk:loadTranslationTable{
  ["ol__hetaihou"] = "何太后",
  ["#ol__hetaihou"] = "弄权之蛇蝎",
  ["illustrator:ol__hetaihou"] = "DH",

  ["~ol__hetaihou"] = "扰乱朝堂之事，我怎么会做……",
}

local sunluyu = General:new(extension, "ol__sunluyu", "wu", 3, 3, General.Female)
sunluyu:addSkills { "ol__meibu", "ol__mumu" }
sunluyu:addRelatedSkill("ol__zhixi")
Fk:loadTranslationTable{
  ["ol__sunluyu"] = "孙鲁育",
  ["#ol__sunluyu"] = "舍身饲虎",
  ["illustrator:ol__sunluyu"] = "玉生贝利",

  ["~ol__sunluyu"] = "姐妹之间，何必至此？",
}

General:new(extension, "sunhao", "wu", 5):addSkills { "canshi", "chouhai", "guiming" }
Fk:loadTranslationTable{
  ["sunhao"] = "孙皓",
  ["#sunhao"] = "时日曷丧",
  ["illustrator:sunhao"] = "LiuHeng",

  ["~sunhao"] = "命啊！命！",
}

General:new(extension, "zuofen", "jin", 3, 3, General.Female):addSkills { "zhaosong", "lisi" }
Fk:loadTranslationTable{
  ["zuofen"] = "左棻",
  ["#zuofen"] = "无宠的才女",
  ["illustrator:zuofen"] = "明暗交界",

  ["~zuofen"] = "惨怆愁悲……",
}

local liuqi = General:new(extension, "liuqi", "qun", 3)
liuqi.subkingdom = "shu"
liuqi:addSkills { "wenji", "tunjiang" }
Fk:loadTranslationTable{
  ["liuqi"] = "刘琦",
  ["#liuqi"] = "居外而安",
  ["cv:liuqi"] = "戴超行",
  ["illustrator:liuqi"] = "NOVART",

  ["~liuqi"] = "父亲，孩儿来见你了。",
}

General:new(extension, "ol__bianfuren", "wei", 3, 3, General.Female):addSkills { "ol__wanwei", "ol__yuejian" }
Fk:loadTranslationTable{
  ["ol__bianfuren"] = "卞夫人",
  ["#ol__bianfuren"] = "奕世之雍容",
  ["illustrator:ol__bianfuren"] = "罔両",

  ["~ol__bianfuren"] = "心肝涂地，惊愕断绝……",
}

General:new(extension, "qinghegongzhu", "wei", 3, 3, General.Female):addSkills { "zengou", "zhangjiq" }
Fk:loadTranslationTable{
  ["qinghegongzhu"] = "清河公主",
  ["#qinghegongzhu"] = "魏长公主",
  ["illustrator:qinghegongzhu"] = "君桓文化",

  ["~qinghegongzhu"] = "我言非虚，君上何疑于我？",
}

General:new(extension, "ol__tengfanglan", "wu", 3, 3, General.Female):addSkills { "luochong", "aichen" }
Fk:loadTranslationTable{
  ["ol__tengfanglan"] = "滕芳兰",
  ["#ol__tengfanglan"] = "铃兰凋落",
  ["designer:ol__tengfanglan"] = "步穗",
  ["illustrator:ol__tengfanglan"] = "DH",

  ["~ol__tengfanglan"] = "封侯归命，夫妻同归……",
}

General:new(extension, "ruiji", "wu", 3, 3, General.Female):addSkills { "qiaoli", "qingliang" }
Fk:loadTranslationTable{
  ["ruiji"] = "芮姬",
  ["#ruiji"] = "伶形俐影",
  ["illustrator:ruiji"] = "君桓文化",
  ["designer:ruiji"] = "豌豆帮帮主",

  ["~ruiji"] = "这斧头，怎么变这么重了……",
}

General:new(extension, "caoyu", "wei", 3):addSkills { "gongjie", "xiangxu", "xiangzuo" }
Fk:loadTranslationTable{
  ["caoyu"] = "曹宇",
  ["#caoyu"] = "大魏燕王",
  ["illustrator:caoyu"] = "匠人绘",
  ["designer:caoyu"] = "廷玉",

  ["~caoyu"] = "满园秋霜落，一人叹奈何……",
}

local caoteng = General:new(extension, "caoteng", "qun", 3)
caoteng:addSkills { "yongzu", "qingliu" }
caoteng:addRelatedSkills { "ex__jianxiong", "tianming" }
Fk:loadTranslationTable{
  ["caoteng"] = "曹腾",
  ["#caoteng"] = "魏高帝",
  ["illustrator:caoteng"] = "君桓文化",

  ["$ex__jianxiong_caoteng"] = "躬行禁闱，不敢争一时之气。",
  ["$tianming_caoteng"] = "天命在彼，事莫强为。",
  ["~caoteng"] = "种暠害我，望陛下明鉴！",
}

General:new(extension, "ol__qinlang", "wei", 3):addSkills { "xianying" }
Fk:loadTranslationTable{
  ["ol__qinlang"] = "秦朗",
  ["#ol__qinlang"] = "跼高蹐厚",

  ["~ol__qinlang"] = "我秦姓人，非属高门。",
}

General:new(extension, "ol__yuanji", "wu", 3, 3, General.Female):addSkills { "jieyan", "jinghua", "shuiyue" }
Fk:loadTranslationTable{
  ["ol__yuanji"] = "袁姬",
  ["#ol__yuanji"] = "日星隐曜",
  ["cv:ol__yuanji"] = "AI",

  ["~ol__yuanji"] = "空捧冰心抱玉壶……",
}

--四弼：伏完x 杨修x 陈琳x 诸葛瑾√ 马良√ 程昱√ 士燮√ 邓芝√ 董昭√ 司马朗x 步骘√ 董允√ 阚泽√ 王允√ 戏志才√ 孙乾√ 王粲x 吕虔x 孙邵√
--辛毗x 审配√ 荀谌√ 吕凯x 蒋干x 潘濬x 严峻x 杜袭√ 杨仪√ 陈登√ 羊祜√ 伊籍x 夏侯玄√ 马日磾x 屈晃√ 孙弘√ 谯周x 阎圃x
--张华√ 曹羲√ 王瓘√ 陆凯√ 田畴√ 郭图√ 陶谦√ 韩馥√
General:new(extension, "ol__zhugejin", "wu", 3):addSkills { "huanshi", "ol__hongyuan", "ol__mingzhe" }
Fk:loadTranslationTable{
  ["ol__zhugejin"] = "诸葛瑾",
  ["#ol__zhugejin"] = "联盟的维系者",
  ["designer:ol__zhugejin"] = "玄蝶既白",
  ["illustrator:ol__zhugejin"] = "G.G.G.",

  ["$huanshi_ol__zhugejin1"] = "不因困顿夷初志，肯为联蜀改阵营。",
  ["$huanshi_ol__zhugejin2"] = "合纵连横，只为天下苍生。",
  ["~ol__zhugejin"] = "联盟若能得以维系，吾……无他愿矣……",
}

General:new(extension, "ol__maliang", "shu", 3):addSkills { "zishu", "ol__yingyuan" }
Fk:loadTranslationTable{
  ["ol__maliang"] = "马良",
  ["#ol__maliang"] = "白眉智士",
  ["illustrator:ol__maliang"] = "depp",

  ["$zishu_ol__maliang1"] = "君子有德，当不以物喜，不以己悲。",
  ["$zishu_ol__maliang2"] = "身外之物，应泾渭分明，秋毫无犯。",
  ["~ol__maliang"] = "季常无能，没能辅佐主公复兴汉室……",
}

General:new(extension, "chengyu", "wei", 3):addSkills { "shefu", "benyu" }
Fk:loadTranslationTable{
  ["chengyu"] = "程昱",
  ["#chengyu"] = "泰山捧日",
  ["illustrator:chengyu"] = "GH",

  ["~chengyu"] = "此诚报效国家之时，吾却休矣！",
}

General:new(extension, "shixie", "qun", 3):addSkills { "biluan", "lixia" }
Fk:loadTranslationTable{
  ["shixie"] = "士燮",
  ["#shixie"] = "南交学祖",
  ["designer:shixie"] = "Rivers",
  ["illustrator:shixie"] = "銘zmy",

  ["~shixie"] = "我这一生，足矣……",
}

General:new(extension, "ol__dengzhi", "shu", 3):addSkills { "xiuhao", "sujian" }
Fk:loadTranslationTable{
  ["ol__dengzhi"] = "邓芝",
  ["#ol__dengzhi"] = "坚贞简亮",
  ["illustrator:ol__dengzhi"] = "游漫美绘",

  ["~ol__dengzhi"] = "修好未成，蜀汉恐危。",
}

General:new(extension, "ol__dongzhao", "wei", 3):addSkills { "xianlue", "zaowang" }
Fk:loadTranslationTable{
  ["ol__dongzhao"] = "董昭",
  ["#ol__dongzhao"] = "乐平侯",
  ["designer:ol__dongzhao"] = "GENTOVA",
  ["illustrator:ol__dongzhao"] = "游漫美绘",

  ["~ol__dongzhao"] = "昭，一心向魏，绝无二心……",
}

General:new(extension, "buzhi", "wu", 3):addSkills { "hongde", "dingpan" }
Fk:loadTranslationTable{
  ["buzhi"] = "步骘",
  ["#buzhi"] = "积跬靖边",
  ["illustrator:buzhi"] = "sinno",

  ["~buzhi"] = "交州已定，主公尽可放心。",
}

General:new(extension, "dongyun", "shu", 3):addSkills { "bingzheng", "sheyan" }
Fk:loadTranslationTable{
  ["dongyun"] = "董允",
  ["#dongyun"] = "骨鲠良相",
  ["designer:dongyun"] = "如释帆飞",
  ["illustrator:dongyun"] = "玖等仁品",

  ["~dongyun"] = "大汉，要亡于宦官之手了……",
}

General:new(extension, "kanze", "wu", 3):addSkills { "xiashu", "kuanshi" }
Fk:loadTranslationTable{
  ["kanze"] = "阚泽",
  ["#kanze"] = "慧眼的博士",
  ["illustrator:kanze"] = "LiuHeng",

  ["~kanze"] = "我早已做好了牺牲的准备。",
}

local wangyun = General:new(extension, "wangyun", "qun", 4)
wangyun:addSkills { "lianji", "moucheng" }
wangyun:addRelatedSkill("jingong")
Fk:loadTranslationTable{
  ["wangyun"] = "王允",
  ["#wangyun"] = "忠魂不泯",
  ["illustrator:wangyun"] = "Thinking",

  ["~wangyun"] = "努力谢关东诸公，勤以国家为念！",
}

General:new(extension, "xizhicai", "wei", 3):addSkills { "tiandu", "xianfu", "chouce" }
Fk:loadTranslationTable{
  ["xizhicai"] = "戏志才",
  ["#xizhicai"] = "负俗的夭才",
  ["cv:xizhicai"] = "曹真",
  ["designer:xizhicai"] = "荼蘼",
  ["illustrator:xizhicai"] = "眉毛子",

  ["$tiandu_xizhicai1"] = "天意，不可逆。",
  ["$tiandu_xizhicai2"] = "既是如此。",
  ["~xizhicai"] = "为何……不再给我……一点点时间……",
}

General:new(extension, "sunqian", "shu", 3):addSkills { "qianya", "shuimeng" }
Fk:loadTranslationTable{
  ["sunqian"] = "孙乾",
  ["#sunqian"] = "折冲樽俎",
  ["illustrator:sunqian"] = "Thinking",

  ["~sunqian"] = "恨不能……得见皇叔早登大宝，咳咳咳……",
}

General:new(extension, "ol__sunshao", "wu", 3):addSkills { "bizheng", "yidian" }
Fk:loadTranslationTable{
  ["ol__sunshao"] = "孙邵",
  ["#ol__sunshao"] = "廊庙才",
  ["illustrator:ol__sunshao"] = "紫剑-h",

  ["~ol__sunshao"] = "此去一别，难见文举……",
}

General:new(extension, "ol__shenpei", "qun", 3):addSkills { "gangzhi", "beizhan" }
Fk:loadTranslationTable{
  ["ol__shenpei"] = "审配",
  ["#ol__shenpei"] = "正南义北",
  ["illustrator:ol__shenpei"] = "PCC",

  ["~ol__shenpei"] = "吾君在北，但求面北而亡。",
}

General:new(extension, "ol__xunchen", "qun", 3):addSkills { "fenglue", "moushi" }
Fk:loadTranslationTable{
  ["ol__xunchen"] = "荀谌",
  ["#ol__xunchen"] = "单锋谋孤城",
  ["illustrator:ol__xunchen"] = "zoo",

  ["~ol__xunchen"] = "吾欲赴死，断不做背主之事……",
}

General:new(extension, "duxi", "wei", 3):addSkills { "quxi", "bixiong" }
Fk:loadTranslationTable{
  ["duxi"] = "杜袭",
  ["#duxi"] = "平阳乡侯",
  ["illustrator:duxi"] = "明暗交界",

  ["~duxi"] = "避凶不及，难……也……",
}

General:new(extension, "ol__yangyi", "shu", 3):addSkills { "juanxia", "dingcuo" }
Fk:loadTranslationTable{
  ["ol__yangyi"] = "杨仪",
  ["#ol__yangyi"] = "武侯长史",
  ["designer:ol__yangyi"] = "步穗",
  ["illustrator:ol__yangyi"] = "游漫美绘",

  ["~ol__yangyi"] = "魏延庸奴，吾，誓杀汝！",
}

General:new(extension, "ol__chendeng", "qun", 4):addSkills { "fengji", "xuanhui" }
Fk:loadTranslationTable{
  ["ol__chendeng"] = "陈登",
  ["#ol__chendeng"] = "湖海豪气",
  ["illustrator:ol__chendeng"] = "君桓文化",

  ["~ol__chendeng"] = "可无命，不可无脍……",
}

local yanghu = General:new(extension, "ol__yanghu", "jin", 4)
yanghu:addSkills { "huaiyuan", "chongxin", "dezhang" }
yanghu:addRelatedSkills { "weishu" }
Fk:loadTranslationTable{
  ["ol__yanghu"] = "羊祜",
  ["#ol__yanghu"] = "执德清劭",
  ["illustrator:ol__yanghu"] = "匠人绘",

  ["~ol__yanghu"] = "当断不断，反受其乱……",
}

General:new(extension, "xiahouxuan", "wei", 3):addSkills { "huanfu", "qingyix", "zeyue" }
Fk:loadTranslationTable{
  ["xiahouxuan"] = "夏侯玄",
  ["#xiahouxuan"] = "朗朗日月",
  ["cv:xiahouxuan"] = "虞晓旭",
  ["illustrator:xiahouxuan"] = "君桓文化",
  ["designer:xiahouxuan"] = "豌豆帮帮主",

  ["~xiahouxuan"] = "玉山倾颓心无尘……",
}

General:new(extension, "quhuang", "wu", 3):addSkills { "qiejian", "nishou" }
Fk:loadTranslationTable{
  ["quhuang"] = "屈晃",
  ["#quhuang"] = "泥头自缚",
  ["illustrator:quhuang"] = "夜小雨",
  ["designer:quhuang"] = "玄蝶既白",

  ["~quhuang"] = "臣死谏于斯，死得其所……",
}

General:new(extension, "sunhong", "wu", 3):addSkills { "xianbi", "zenrun" }
Fk:loadTranslationTable{
  ["sunhong"] = "孙弘",
  ["#sunhong"] = "谮诉构争",
  ["designer:sunhong"] = "zzcclll朱苦力",
  ["illustrator:sunhong"] = "匠人绘",

  ["~sunhong"] = "诸葛公何至于此……",
}

General:new(extension, "zhanghua", "jin", 3):addSkills { "bihun", "jianhe", "chuanwu" }
Fk:loadTranslationTable{
  ["zhanghua"] = "张华",
  ["#zhanghua"] = "双剑化龙",
  ["designer:zhanghua"] = "玄蝶既白",
  ["illustrator:zhanghua"] = "匠人绘",
  ["cv:zhanghua"] = "苏至豪",

  ["~zhanghua"] = "桑化为柏，此非不祥乎？",
}

General:new(extension, "caoxi", "wei", 3):addSkills { "gangshu", "jianxuan" }
Fk:loadTranslationTable{
  ["caoxi"] = "曹羲",
  ["#caoxi"] = "魁立倾厦",
  ["designer:caoxi"] = "玄蝶既白",
  ["illustrator:caoxi"] = "匠人绘",

  ["~caoxi"] = "曹氏亡矣，大魏亡矣！",
}

General:new(extension, "wangguan", "wei", 3):addSkills { "miuyan", "shilu" }
Fk:loadTranslationTable{
  ["wangguan"] = "王瓘",
  ["#wangguan"] = "假降误撞",
  ["designer:wangguan"] = "zzcclll朱苦力",
  ["illustrator:wangguan"] = "匠人绘",

  ["~wangguan"] = "我本魏将，将军救我！",
}

General:new(extension, "ol__lukai", "wu", 3):addSkills { "xuanzhu", "jiane" }
Fk:loadTranslationTable{
  ["ol__lukai"] = "陆凯",
  ["#ol__lukai"] = "节概梗梗",
  ["illustrator:ol__lukai"] = "空山MBYK",
  ["designer:ol__lukai"] = "扬林",

  ["~ol__lukai"] = "注经之人，终寄身于土……",
}

General:new(extension, "tianchou", "qun", 4):addSkills { "shandao" }
Fk:loadTranslationTable{
  ["tianchou"] = "田畴",
  ["#tianchou"] = "乱世族隐",
  ["illustrator:tianchou"] = "君桓文化",
  ["designer:tianchou"] = "扬林",

  ["~tianchou"] = "吾罪大矣，何堪封侯之荣……",
}

General:new(extension, "guotu", "qun", 3):addSkills { "qushi", "weijie" }
Fk:loadTranslationTable{
  ["guotu"] = "郭图",
  ["#guotu"] = "凶臣",
  ["illustrator:guotu"] = "厦门塔普",
  ["cv:guotu"] = "杨超然",

  ["~guotu"] = "工于心计而不成事，匹夫怀其罪……",
}

General:new(extension, "ol__taoqian", "qun", 3):addSkills { "zongluan", "ol__zhaohuo", "wenren" }
Fk:loadTranslationTable{
  ["ol__taoqian"] = "陶谦",
  ["#ol__taoqian"] = "恭谦忍顺",

  ["~ol__taoqian"] = "玄德……徐州就交给你了……",
}

General:new(extension, "ol__hanfu", "qun", 4):addSkills { "shuzi", "kuangshou" }
Fk:loadTranslationTable{
  ["ol__hanfu"] = "韩馥",
  ["#ol__hanfu"] = "挈瓶之知",

  ["~ol__hanfu"] = "本初，我可是请你吃过饭的！",
}

--天柱：潘凤x 诸葛诞√ 兀突骨√ 蹋顿√ 严白虎√ 李傕x 张济x 樊稠√ 郭汜x 沙摩柯x 丁原x 黄祖√ 高干√ 王双x 范疆张达√ 梁兴x 阿会喃√ 马玩√ 文钦√ 雅丹√ 张燕√
--何进√ 牛金√ 韩遂√ 李异√ 刘辟√ 轲比能√ 吴景x 马元义x
local zhugedan = General:new(extension, "ol__zhugedan", "wei", 4)
zhugedan:addSkills { "gongao", "ol__juyi" }
zhugedan:addRelatedSkills { "benghuai", "ol__weizhong" }
Fk:loadTranslationTable{
  ["ol__zhugedan"] = "诸葛诞",
  ["#ol__zhugedan"] = "薤露蒿里",
  ["illustrator:ol__zhugedan"] = "君桓文化",

  ["$gongao_ol__zhugedan1"] = "大魏獒犬，恪忠于国。",
  ["$gongao_ol__zhugedan2"] = "斯人已逝，余者奋威。",
  ["$benghuai_ol__zhugedan"] = "诞，能得诸位死力，无憾矣。",
  ["~ol__zhugedan"] = "成功！成仁！",
}

General:new(extension, "wutugu", "qun", 15):addSkills { "ranshang", "hanyong" }
Fk:loadTranslationTable{
  ["wutugu"] = "兀突骨",
  ["#wutugu"] = "霸体金刚",
  ["designer:wutugu"] = "韩旭",
  ["illustrator:wutugu"] = "biou09&KayaK",

  ["~wutugu"] = "撤，快撤！",
}

General:new(extension, "tadun", "qun", 4):addSkills { "luanzhan" }
Fk:loadTranslationTable{
  ["tadun"] = "蹋顿",
  ["#tadun"] = "北狄王",
  ["illustrator:tadun"] = "NOVART",
  ["designer:tadun"] = "Rivers",

  ["~tadun"] = "呃……不该趟曹袁之争的浑水……",
}

General:new(extension, "yanbaihu", "qun", 4):addSkills { "zhidao", "jili" }
Fk:loadTranslationTable{
  ["yanbaihu"] = "严白虎",
  ["#yanbaihu"] = "豺牙落涧",
  ["designer:yanbaihu"] = "Rivers",
  ["illustrator:yanbaihu"] = "NOVART",

  ["~yanbaihu"] = "严舆吾弟，为兄来陪你了。",
}

General:new(extension, "ol__fanchou", "qun", 4):addSkills { "ol__xingluan" }
Fk:loadTranslationTable{
  ["ol__fanchou"] = "樊稠",
  ["#ol__fanchou"] = "庸生变难",
  ["illustrator:ol__fanchou"] = "心中一凛",

  ["~ol__fanchou"] = "唉，稚然，疑心甚重。",
}

General:new(extension, "ol__huangzu", "qun", 4):addSkills { "wangong" }
Fk:loadTranslationTable{
  ["ol__huangzu"] = "黄祖",
  ["#ol__huangzu"] = "虎踞江夏",
  ["illustrator:ol__huangzu"] = "磐蒲",

  ["~ol__huangzu"] = "命也……势也……",
}

General:new(extension, "gaogan", "qun", 4):addSkills { "juguan" }
Fk:loadTranslationTable{
  ["gaogan"] = "高干",
  ["#gaogan"] = "才志弘邈",
  ["illustrator:gaogan"] = "猎枭",

  ["~gaogan"] = "天不助我！",
}

local fanjiangzhangda = General:new(extension, "fanjiangzhangda", "wu", 4)
fanjiangzhangda.subkingdom = "shu"
fanjiangzhangda:addSkills { "yuanchou", "juesheng" }
Fk:loadTranslationTable{
  ["fanjiangzhangda"] = "范疆张达",
  ["#fanjiangzhangda"] = "你死我亡",
  ["designer:fanjiangzhangda"] = "七哀",
  ["cv:fanjiangzhangda"] = "虞晓旭/段杰达",
  ["illustrator:fanjiangzhangda"] = "游漫美绘",

  ["~fanjiangzhangda"] = "吴侯救我！",
}

General:new(extension, "ahuinan", "qun", 4):addSkills { "jueman" }
Fk:loadTranslationTable{
  ["ahuinan"] = "阿会喃",
  ["#ahuinan"] = "维绳握雾",
  ["designer:ahuinan"] = "大宝",
  ["illustrator:ahuinan"] = "monkey",

  ["~ahuinan"] = "什么？大王要杀我？",
}

General:new(extension, "mawan", "qun", 4):addSkills { "hunjiang" }
Fk:loadTranslationTable{
  ["mawan"] = "马玩",
  ["#mawan"] = "驱率羌胡",
  ["illustrator:mawan"] = "君桓文化",
  ["designer:mawan"] = "大宝",

  ["~mawan"] = "曹贼势大，唯避其锋芒。",
}

local wenqin = General:new(extension, "ol__wenqin", "wei", 4)
wenqin.subkingdom = "wu"
wenqin:addSkills { "guangao", "huiqi" }
wenqin:addRelatedSkill("xieju")
Fk:loadTranslationTable{
  ["ol__wenqin"] = "文钦",
  ["#ol__wenqin"] = "困兽鸱张",
  ["designer:ol__wenqin"] = "玄蝶既白",
  ["illustrator:ol__wenqin"] = "匠人绘",

  ["~ol__wenqin"] = "天不佑国魏！天不佑族文！",
}

General:new(extension, "yadan", "qun", 4):addSkills { "qingya", "tielun" }
Fk:loadTranslationTable{
  ["yadan"] = "雅丹",
  ["#yadan"] = "西羌相",
  ["illustrator:yadan"] = "匠人绘",
  ["designer:yadan"] = "cyc",

  ["~yadan"] = "多谢丞相不杀之恩……",
}

General:new(extension, "zhangyan", "qun", 4):addSkills { "suji", "langdao" }
Fk:loadTranslationTable{
  ["zhangyan"] = "张燕",
  ["#zhangyan"] = "飞燕",
  ["designer:zhangyan"] = "廷玉",
  ["illustrator:zhangyan"] = "君桓文化",

  ["~zhangyan"] = "草莽之辈，难登大雅之堂……",
}

General:new(extension, "ol__hejin", "qun", 4):addSkills { "ol__mouzhu", "ol__yanhuo" }
Fk:loadTranslationTable{
  ["ol__hejin"] = "何进",
  ["#ol__hejin"] = "色厉内荏",
  ["cv:ol__hejin"] = "冷泉月夜",
  ["illustrator:ol__hejin"] = "鬼画府",

  ["~ol__hejin"] = "阉人造反啦！护卫！呀——",
}

General:new(extension, "ol__niujin", "wei", 4):addSkills { "ol__cuorui", "ol__liewei" }
Fk:loadTranslationTable{
  ["ol__niujin"] = "牛金",
  ["#ol__niujin"] = "独进的兵胆",
  ["illustrator:ol__niujin"] = "凡果_棉鞋",

  ["~ol__niujin"] = "司马氏负我！",
}

General:new(extension, "ol__hansui", "qun", 4):addSkills { "ol__niluan", "ol__xiaoxi" }
Fk:loadTranslationTable{
  ["ol__hansui"] = "韩遂",
  ["#ol__hansui"] = "雄踞北疆",
  ["illustrator:ol__hansui"] = "Thinking",

  ["~ol__hansui"] = "英雄一世，奈何祸起萧墙……",
}

General:new(extension, "liyi", "wu", 4):addSkills { "chanshuang", "zhanjin" }
Fk:loadTranslationTable{
  ["liyi"] = "李异",
  ["#liyi"] = "兼人之勇",
  ["illustrator:liyi"] = "匠人绘",
  ["designer:liyi"] = "玄蝶既白",

  ["~liyi"] = "此人竟如此勇猛……",
}

General:new(extension, "ol__liupi", "qun", 4):addSkills { "yichengl" }
Fk:loadTranslationTable{
  ["ol__liupi"] = "刘辟",
  ["#ol__liupi"] = "易城报君",
  ["illustrator:ol__liupi"] = "君桓文化",
  ["designer:ol__liupi"] = "那个背影",

  ["~ol__liupi"] = "玄德公速行，曹军某自当之！",
}

General:new(extension, "ol__kebineng", "qun", 4):addSkills { "pingduan" }
Fk:loadTranslationTable{
  ["ol__kebineng"] = "轲比能",
  ["#ol__kebineng"] = "瀚海鲸波",
  ["illustrator:ol__kebineng"] = "黯荧岛",
  ["designer:ol__kebineng"] = "cyc",

  ["~ol__kebineng"] = "未驱青马饮于黄河，死难瞑目。",
}

--女史：灵雎√ 关银屏√ 大乔小乔x 张星彩x 马云騄√ 董白√ 赵襄√ 花鬘x 张昌蒲x 杨婉x 郭槐√ 陆郁生√ 丁尚涴√ 李婉√ 胡金定√ 孙茹√ 董翓√ 阮慧x
General:new(extension, "ol__lingju", "qun", 3, 3, General.Female):addSkills { "ol__jieyuan", "ol__fenxin" }
Fk:loadTranslationTable{
  ["ol__lingju"] = "灵雎",
  ["#ol__lingju"] = "情随梦逝",
  ["illustrator:ol__lingju"] = "疾速k",

  ["~ol__lingju"] = "情随梦境散，花随时节落。",
}

General:new(extension, "ol__guanyinping", "shu", 3, 3, General.Female):addSkills { "ol__xuehen", "ol__huxiao", "ol__wuji" }
Fk:loadTranslationTable{
  ["ol__guanyinping"] = "关银屏",
  ["#ol__guanyinping"] = "武姬",
  ["designer:ol__guanyinping"] = "千幻",
  ["illustrator:ol__guanyinping"] = "光域鹿鸣",

  ["~ol__guanyinping"] = "红已花残，此仇未能报……",
}

General:new(extension, "mayunlu", "shu", 4, 4, General.Female):addSkills { "mashu", "fengpo" }
Fk:loadTranslationTable{
  ["mayunlu"] = "马云騄",
  ["#mayunlu"] = "剑胆琴心",
  ["cv:mayunlu"] = "水原",
  ["illustrator:mayunlu"] = "木美人",

  ["~mayunlu"] = "呜呜……是你们欺负人……",
}

General:new(extension, "dongbai", "qun", 3, 3, General.Female):addSkills { "lianzhu", "xiahui" }
Fk:loadTranslationTable{
  ["dongbai"] = "董白",
  ["#dongbai"] = "魔姬",
  ["illustrator:dongbai"] = "alien",

  ["~dongbai"] = "放肆，我要让爷爷赐你们死罪！",
}

General:new(extension, "zhaoxiang", "shu", 4, 4, General.Female):addSkills { "fanghun", "fuhan" }
Fk:loadTranslationTable{
  ["zhaoxiang"] = "赵襄",
  ["#zhaoxiang"] = "拾梅鹊影",
  ["designer:zhaoxiang"] = "千幻",
  ["illustrator:zhaoxiang"] = "木美人",

  ["~zhaoxiang"] = "遁入阴影之中……",
}

General:new(extension, "guohuaij", "jin", 3, 3, General.Female):addSkills { "zhefu", "yidu" }
Fk:loadTranslationTable{
  ["guohuaij"] = "郭槐",
  ["#guohuaij"] = "嫉贤妒能",
  ["illustrator:guohuaij"] = "凝聚永恒",

  ["~guohuaij"] = "我死后，切勿从粲、午之言。",
}

General:new(extension, "ol__luyusheng", "wu", 3, 3, General.Female):addSkills { "cangxin", "runwei" }
Fk:loadTranslationTable{
  ["ol__luyusheng"] = "陆郁生",
  ["#ol__luyusheng"] = "义姑",
  ["designer:ol__luyusheng"] = "zzcclll朱苦力",
  ["illustrator:ol__luyusheng"] = "土豆",

  ["~ol__luyusheng"] = "郁生既为张妇，誓不再许……",
}

General:new(extension, "ol__dingfuren", "wei", 3, 3, General.Female):addSkills { "ol__fudao", "ol__fengyan" }
Fk:loadTranslationTable{
  ["ol__dingfuren"] = "丁尚涴",
  ["#ol__dingfuren"] = "我心匪席",
  ["cv:ol__dingfuren"] = "闲踏梧桐",
  ["designer:ol__dingfuren"] = "幽蝶化烬",
  ["illustrator:ol__dingfuren"] = "匠人绘",

  ["~ol__dingfuren"] = "今生与曹，不复相见……",
}

General:new(extension, "ol__liwan", "wei", 3, 3, General.Female):addSkills { "lianju", "silv" }
Fk:loadTranslationTable{
  ["ol__liwan"] = "李婉",
  ["#ol__liwan"] = "遐雁归迩",
  ["designer:ol__liwan"] = "对勾对勾w",
  ["illustrator:ol__liwan"] = "游卡",

  ["~ol__liwan"] = "及尔偕老，老使我怨……",
}

General:new(extension, "ol__hujinding", "shu", 3, 3, General.Female):addSkills { "qingyuan", "chongshen" }
Fk:loadTranslationTable{
  ["ol__hujinding"] = "胡金定",
  ["#ol__hujinding"] = "怀子求怜",
  ["illustrator:ol__hujinding"] = "君桓文化",

  ["~ol__hujinding"] = "君无愧于天下，可有悔于妻儿？",
}

General:new(extension, "ol__sunru", "wu", 3, 3, General.Female):addSkills { "chishi", "weimian" }
Fk:loadTranslationTable{
  ["ol__sunru"] = "孙茹",
  ["#ol__sunru"] = "淑慎温良",
  ["illustrator:ol__sunru"] = "土豆",

  ["~ol__sunru"] = "从来无情者，皆出帝王家……",
}

General:new(extension, "ol__dongxie", "qun", 3, 5, General.Female):addSkills { "jiaoweid", "bianyu", "fengyao" }
Fk:loadTranslationTable{
  ["ol__dongxie"] = "董翓",
  ["#ol__dongxie"] = "魔女",

  ["~ol__dongxie"] = "牛家哥哥，我来……与你黄泉作伴……",
}

--少微：张宝√ 张鲁√ 诸葛果√ 卑弥呼x 司马徽x 许靖√ 张陵√ 黄承彦√ 张芝√ 卢氏√ 彭羕√
General:new(extension, "ol__zhangbao", "qun", 3):addSkills { "ol__zhoufu", "ol__yingbing" }
Fk:loadTranslationTable{
  ["ol__zhangbao"] = "张宝",
  ["#ol__zhangbao"] = "地公将军",
  ["illustrator:ol__zhangbao"] = "alien",

  ["~ol__zhangbao"] = "符咒不够用了……",
}

General:new(extension, "zhanglu", "qun", 3):addSkills { "yishe", "bushi", "midao" }
Fk:loadTranslationTable{
  ["zhanglu"] = "张鲁",
  ["#zhanglu"] = "政宽教惠",
  ["designer:zhanglu"] = "逍遥鱼叔",
  ["illustrator:zhanglu"] = "銘zmy",

  ["~zhanglu"] = "但，归置于道，无意凡事争斗。",
}

General:new(extension, "ol__zhugeguo", "shu", 3, 3, General.Female):addSkills { "ol__qirang", "ol__yuhua" }
Fk:loadTranslationTable{
  ["ol__zhugeguo"] = "诸葛果",
  ["#ol__zhugeguo"] = "凤阁乘烟",
  ["illustrator:ol__zhugeguo"] = "木美人",

  ["~ol__zhugeguo"] = "化羽难成，仙境已逝。",
}

General:new(extension, "ol__xujing", "shu", 3):addSkills { "yuxu", "shijian" }
Fk:loadTranslationTable{
  ["ol__xujing"] = "许靖",
  ["#ol__xujing"] = "品评名士",
  ["designer:ol__xujing"] = "pui980178",
  ["illustrator:ol__xujing"] = "君桓文化",

  ["~ol__xujing"] = "漂薄风波，绝粮茹草……",
}

General:new(extension, "zhangling", "qun", 3):addSkills { "huqi", "shoufu" }
Fk:loadTranslationTable{
  ["zhangling"] = "张陵",
  ["#zhangling"] = "祖天师",
  ["illustrator:zhangling"] = "匠人绘",
  ["cv:zhangling"] = "虞晓旭",

  ["~zhangling"] = "羽化登仙，遗世独立……",
}

General:new(extension, "ol__huangchengyan", "qun", 3):addSkills { "guanxu", "yashi" }
Fk:loadTranslationTable{
  ["ol__huangchengyan"] = "黄承彦",
  ["#ol__huangchengyan"] = "沔阳雅士",
  ["illustrator:ol__huangchengyan"] = "游漫美绘",

  ["~ol__huangchengyan"] = "皆为虚妄……",
}

local zhangzhi = General:new(extension, "zhangzhi", "qun", 3)
zhangzhi:addSkills { "bixin", "ximo" }
zhangzhi:addRelatedSkill("feibai")
Fk:loadTranslationTable{
  ["zhangzhi"] = "张芝",
  ["#zhangzhi"] = "草圣",
  ["designer:zhangzhi"] = "玄蝶既白",
  ["illustrator:zhangzhi"] = "君桓文化",

  ["~zhangzhi"] = "力透三分，何以言老……",
}

General:new(extension, "lushi", "qun", 3, 3, General.Female):addSkills { "zhuyan", "leijie" }
Fk:loadTranslationTable{
  ["lushi"] = "卢氏",
  ["#lushi"] = "蝉蜕蛇解",
  ["illustrator:lushi"] = "君桓文化",

  ["~lushi"] = "人世寻大道，何其愚也……",
}

General:new(extension, "ol__pengyang", "shu", 3):addSkills { "xiaofan", "tuoshi", "cunmu" }
Fk:loadTranslationTable{
  ["ol__pengyang"] = "彭羕",
  ["#ol__pengyang"] = "翻然轻举",
  ["designer:ol__pengyang"] = "玄蝶既白",
  ["illustrator:ol__pengyang"] = "君桓文化",

  ["$cunmu_ol__pengyang1"] = "腹有锦绣千里，奈何偏居一隅。",
  ["$cunmu_ol__pengyang2"] = "心大志广之人，必难以保安。",
  ["~ol__pengyang"] = "羕酒后失言，主公勿怪……",
}

--虎贲：公孙瓒x 曹洪x 夏侯霸x 诸葛恪√ 乐进x 祖茂x 丁奉√ 文聘x 吾彦√ 李通√ 贺齐√ 马忠√ 麹义√ 鲁芝√ 苏飞√ 黄权√ 唐咨√ 吕旷吕翔√ 高览√
--周鲂x 曹性x 朱灵√ 田豫√ 赵俨√ 邓忠√ 霍峻√ 文鸯x 阎柔x 朱儁√ 马承√ 傅肜√ 胡班√ 马休马铁√ 张翼√ 罗宪√ 郝普√ 孟达√ 段熲√ 牵招√ 凌操√
--刘磐√ 蔡瑁√ 王匡√ 成公英√ 武安国√
General:new(extension, "zhugeke", "wu", 3):addSkills { "aocai", "duwu" }
Fk:loadTranslationTable{
  ["zhugeke"] = "诸葛恪",
  ["#zhugeke"] = "兴家赤族",
  ["designer:zhugeke"] = "韩旭",
  ["illustrator:zhugeke"] = "LiuHeng",

  ["~zhugeke"] = "重权震主，是我疏忽了……",
}

General:new(extension, "ol__dingfeng", "wu", 4):addSkills { "ol__duanbing", "ol__fenxun" }
Fk:loadTranslationTable{
  ["ol__dingfeng"] = "丁奉",
  ["#ol__dingfeng"] = "清侧重臣",
  ["illustrator:ol__dingfeng"] = "枭瞳",

  ["~ol__dingfeng"] = "命乎！命乎……",
}

General:new(extension, "wuyanw", "wu", 4):addSkills { "lanjiang" }
Fk:loadTranslationTable{
  ["wuyanw"] = "吾彦",
  ["#wuyanw"] = "断浪南竹",
  ["designer:wuyanw"] = "七哀",
  ["illustrator:wuyanw"] = "匠人绘",

  ["~wuyanw"] = "世间再无擒虎客……",
}

General:new(extension, "litong", "wei", 4):addSkills { "tuifeng" }
Fk:loadTranslationTable{
  ["litong"] = "李通",
  ["#litong"] = "万亿吾独往",
  ["illustrator:litong"] = "瞎子Ghe",

  ["~litong"] = "战死沙场，快哉。",
}

local heqi = General:new(extension, "heqi", "wu", 4)
heqi:addSkills { "qizhou", "shanxi" }
heqi:addRelatedSkills { "ol__duanbing", "ex__yingzi", "fenwei", "lanjiang" }
Fk:loadTranslationTable{
  ["heqi"] = "贺齐",
  ["#heqi"] = "马踏群峦",
  ["designer:heqi"] = "千幻",
  ["illustrator:heqi"] = "DH",

  ["~heqi"] = "别拿走……我的装备！",
}

General:new(extension, "ol__mazhong", "shu", 4):addSkills { "ol__fuman" }
Fk:loadTranslationTable{
  ["ol__mazhong"] = "马忠",
  ["#ol__mazhong"] = "笑合南中",
  ["illustrator:ol__mazhong"] = "青岛磐蒲",

  ["~ol__mazhong"] = "南中不定，后患无穷……",
}

General:new(extension, "quyi", "qun", 4):addSkills { "fuji", "jiaozi" }
Fk:loadTranslationTable{
  ["quyi"] = "麴义",
  ["#quyi"] = "名门的骁将",
  ["cv:quyi"] = "冷泉月夜",
  ["illustrator:quyi"] = "王立雄",
  ["designer:quyi"] = "荼蘼",

  ["~quyi"] = "主公，我无异心啊！",
}

General:new(extension, "luzhiw", "wei", 3):addSkills { "qingzhong", "weijing" }
Fk:loadTranslationTable{
  ["luzhiw"] = "鲁芝",
  ["#luzhiw"] = "夷夏慕德",
  ["designer:luzhiw"] = "世外高v狼",
  ["illustrator:luzhiw"] = "秋呆呆",

  ["~luzhiw"] = "年迈力微，是该告老还乡了……",
}

local sufei = General:new(extension, "ol__sufei", "wu", 4)
sufei.subkingdom = "qun"
sufei:addSkills { "lianpian" }
Fk:loadTranslationTable{
  ["ol__sufei"] = "苏飞",
  ["#ol__sufei"] = "与子同袍",
  ["illustrator:ol__sufei"] = "兴游",

  ["~ol__sufei"] = "恐不能再与兴霸兄……并肩奋战了……",
}

local huangquan = General:new(extension, "ol__huangquan", "shu", 3)
huangquan.subkingdom = "wei"
huangquan:addSkills { "dianhu", "jianji" }
Fk:loadTranslationTable{
  ["ol__huangquan"] = "黄权",
  ["#ol__huangquan"] = "道绝殊途",
  ["illustrator:ol__huangquan"] = "兴游",

  ["~ol__huangquan"] = "魏王厚待于我，降魏又有何错？",
}

local tangzi = General:new(extension, "tangzi", "wei", 3)
tangzi.subkingdom = "wu"
tangzi:addSkills { "xingzhao" }
tangzi:addRelatedSkill("xunxun")
Fk:loadTranslationTable{
  ["tangzi"] = "唐咨",
  ["#tangzi"] = "工学之奇才",
  ["designer:tangzi"] = "荼蘼",
  ["illustrator:tangzi"] = "NOVART",

  ["$xunxun_tangzi1"] = "让我先探他一探。",
  ["$xunxun_tangzi2"] = "船，也不是一天就能造出来的。",
  ["~tangzi"] = "偷工减料要不得啊……",
}

General:new(extension, "ol__lvkuanglvxiang", "qun", 4):addSkills { "qigong", "liehou" }
Fk:loadTranslationTable{
  ["ol__lvkuanglvxiang"] = "吕旷吕翔",
  ["#ol__lvkuanglvxiang"] = "降将列侯",
  ["illustrator:ol__lvkuanglvxiang"] = "王立雄",

  ["~ol__lvkuanglvxiang"] = "此处可是新野……",
}

General:new(extension, "ol__gaolan", "qun", 4):addSkills { "xiying" }
Fk:loadTranslationTable{
  ["ol__gaolan"] = "高览",
  ["#ol__gaolan"] = "名门的峦柱",
  ["designer:ol__gaolan"] = "七哀",
  ["illustrator:ol__gaolan"] = "兴游",

  ["~ol__gaolan"] = "郭图小辈之计……误军呐！",
}

General:new(extension, "ol__zhuling", "wei", 4):addSkills { "jixian" }
Fk:loadTranslationTable{
  ["ol__zhuling"] = "朱灵",
  ["#ol__zhuling"] = "良将之亚",
  ["illustrator:ol__zhuling"] = "君桓文化",

  ["~ol__zhuling"] = "母亲，弟弟，我来了……",
}

General:new(extension, "ol__tianyu", "wei", 4):addSkills { "saodi", "zhuitao" }
Fk:loadTranslationTable{
  ["ol__tianyu"] = "田豫",
  ["#ol__tianyu"] = "威震北疆",
  ["illustrator:ol__tianyu"] = "游漫美绘",

  ["~ol__tianyu"] = "命数之沙，已尽矣……",
}

General:new(extension, "ol__zhaoyan", "wei", 4):addSkills { "tongxie" }
Fk:loadTranslationTable{
  ["ol__zhaoyan"] = "赵俨",
  ["#ol__zhaoyan"] = "刚毅有度",
  ["illustrator:ol__zhaoyan"] = "君桓文化",

  ["~ol__zhaoyan"] = "援军不至，樊城之围难解……",
}

General:new(extension, "dengzhong", "wei", 4):addSkills { "kanpod", "gengzhan" }
Fk:loadTranslationTable{
  ["dengzhong"] = "邓忠",
  ["#dengzhong"] = "惠唐亭侯",
  ["illustrator:dengzhong"] = "六道目",

  ["~dengzhong"] = "杀身报国，死得其所。",
}

General:new(extension, "ol__huojun", "shu", 4):addSkills { "qiongshou", "fenrui" }
Fk:loadTranslationTable{
  ["ol__huojun"] = "霍峻",
  ["#ol__huojun"] = "葭萌铁狮",
  ["illustrator:ol__huojun"] = "梦回唐朝",

  ["~ol__huojun"] = "主公，峻有负所托！",
}

General:new(extension, "ol__zhujun", "qun", 4):addSkills { "cuipo" }
Fk:loadTranslationTable{
  ["ol__zhujun"] = "朱儁",
  ["#ol__zhujun"] = "钦明神武",
  ["illustrator:ol__zhujun"] = "梦回唐朝",

  ["~ol__zhujun"] = "李郭匹夫，安敢辱我！",
}

General:new(extension, "macheng", "shu", 4):addSkills { "mashu", "chenglie" }
Fk:loadTranslationTable{
  ["macheng"] = "马承",
  ["#macheng"] = "孤蹄踏乱",
  ["designer:macheng"] = "cyc",
  ["illustrator:macheng"] = "君桓文化",

  ["~macheng"] = "儿有辱父祖之威名……",
}

General:new(extension, "ol__furong", "shu", 4):addSkills { "xiaosi" }
Fk:loadTranslationTable{
  ["ol__furong"] = "傅肜",
  ["#ol__furong"] = "矢忠不二",
  ["illustrator:ol__furong"] = "君桓文化",

  ["~ol__furong"] = "吴狗！何有汉将军降者！",
}

General:new(extension, "ol__huban", "wei", 4):addSkills { "huiyun" }
Fk:loadTranslationTable{
  ["ol__huban"] = "胡班",
  ["#ol__huban"] = "险误忠良",
  ["designer:ol__huban"] = "cyc",
  ["illustrator:ol__huban"] = "鬼画府",

  ["~ol__huban"] = "无耻鼠辈，吾耻与为伍！",
}

General:new(extension, "maxiumatie", "qun", 4):addSkills { "mashu", "kenshang" }
Fk:loadTranslationTable{
  ["maxiumatie"] = "马休马铁",
  ["#maxiumatie"] = "颉翥三秦",
  ["illustrator:maxiumatie"] = "alien",

  ["~maxiumatie"] = "我兄弟，愿随父帅赴死。",
}

General:new(extension, "ol__zhangyiy", "shu", 4):addSkills { "dianjun", "kangrui" }
Fk:loadTranslationTable{
  ["ol__zhangyiy"] = "张翼",
  ["#ol__zhangyiy"] = "奉公弗怠",
  ["designer:ol__zhangyiy"] = "朔方的雪",
  ["illustrator:ol__zhangyiy"] = "君桓文化",

  ["~ol__zhangyiy"] = "伯约不见疲惫之国力乎？",
}

General:new(extension, "luoxian", "shu", 4):addSkills { "daili" }
Fk:loadTranslationTable{
  ["luoxian"] = "罗宪",
  ["#luoxian"] = "介然毕命",
  ["designer:luoxian"] = "玄蝶既白",
  ["cv:luoxian"] = "邵晨",
  ["illustrator:luoxian"] = "匠人绘",

  ["~luoxian"] = "汉亡矣，命休矣……",
}

General:new(extension, "haopu", "shu", 4):addSkills { "zhenying" }
Fk:loadTranslationTable{
  ["haopu"] = "郝普",
  ["#haopu"] = "惭恨入地",
  ["designer:haopu"] = "何如",
  ["illustrator:haopu"] = "匠人绘",

  ["~haopu"] = "徒做奔臣，死无其所……",
}

local mengda = General:new(extension, "ol__mengda", "shu", 4)
mengda.subkingdom = "wei"
mengda:addSkills { "goude" }
Fk:loadTranslationTable{
  ["ol__mengda"] = "孟达",
  ["#ol__mengda"] = "腾挪反复",
  ["designer:ol__mengda"] = "玄蝶既白",
  ["illustrator:ol__mengda"] = "匠人绘",

  ["~ol__mengda"] = "丞相援军何其远乎？",
}

General:new(extension, "duanjiong", "qun", 4):addSkills { "saogu" }
Fk:loadTranslationTable{
  ["duanjiong"] = "段颎",
  ["#duanjiong"] = "束马县锋",
  ["designer:duanjiong"] = "绯红的波罗",
  ["illustrator:duanjiong"] = "黯荧岛工作室",

  ["~duanjiong"] = "秋霜落，天下寒……",
}

General:new(extension, "ol__qianzhao", "wei", 4):addSkills { "weifu", "kuansai" }
Fk:loadTranslationTable{
  ["ol__qianzhao"] = "牵招",
  ["#ol__qianzhao"] = "雁门无烟",
  ["designer:ol__qianzhao"] = "玄蝶既白",
  ["illustrator:ol__qianzhao"] = "匠人绘",

  ["~ol__qianzhao"] = "玄德兄，弟……来迟矣……",
}

General:new(extension, "ol__lingcao", "wu", 4):addSkills { "ol__dujin" }
Fk:loadTranslationTable{
  ["ol__lingcao"] = "凌操",
  ["#ol__lingcao"] = "激流勇进",
  ["illustrator:ol__lingcao"] = "美有",

  ["~ol__lingcao"] = "不好，此处有埋伏……",
}

General:new(extension, "liupan", "qun", 4):addSkills { "pijingl" }
Fk:loadTranslationTable{
  ["liupan"] = "刘磐",
  ["#liupan"] = "骁隽悍勇",
  ["illustrator:liupan"] = "君桓文化",
  ["designer:liupan"] = "cyc",

  ["~liupan"] = "今袍泽离散，无以为战……",
}

General:new(extension, "caimao", "wei", 4):addSkills { "zuolian", "jingzhou" }
Fk:loadTranslationTable{
  ["caimao"] = "蔡瑁",
  ["#caimao"] = "蛟海腾云",
  ["illustrator:caimao"] = "depp",
  ["designer:caimao"] = "步穗",

  ["~caimao"] = "丞相！末将忠心耿耿呀！",
}

General:new(extension, "wangkuang", "qun", 4):addSkills { "renxia" }
Fk:loadTranslationTable{
  ["wangkuang"] = "王匡",
  ["#wangkuang"] = "任侠纵横",
  ["illustrator:wangkuang"] = "花狐貂",
  ["designer:wangkuang"] = "U",

  ["~wangkuang"] = "人心不古，世态炎凉。",
}

General:new(extension, "chenggongying", "qun", 4):addSkills { "kuangxiang" }
Fk:loadTranslationTable{
  ["chenggongying"] = "成公英",
  ["#chenggongying"] = "尽欢竭忠",

  ["~chenggongying"] = "假使英本主人在，实不来此也。",
}

General:new(extension, "ol__wuanguo", "qun", 4):addSkills { "liyongw" }
Fk:loadTranslationTable{
  ["ol__wuanguo"] = "武安国",
  ["#ol__wuanguo"] = "料脑编须",

  ["~ol__wuanguo"] = "",
}

--列肆：糜竺√ 卫兹√ 刘巴√ 张世平√ 吕伯奢√
General:new(extension, "mizhu", "shu", 3):addSkills { "ziyuan", "jugu" }
Fk:loadTranslationTable{
  ["mizhu"] = "糜竺",
  ["#mizhu"] = "挥金追义",
  ["designer:mizhu"] = "千幻",
  ["illustrator:mizhu"] = "瞎子Ghe",

  ["~mizhu"] = "劣弟背主，我之罪也。",
}

General:new(extension, "weizi", "qun", 3):addSkills { "yuanzi", "liejie" }
Fk:loadTranslationTable{
  ["weizi"] = "卫兹",
  ["#weizi"] = "倾家资君",
  ["illustrator:weizi"] = "君桓文化",

  ["~weizi"] = "敌军势众，速退！",
}

General:new(extension, "ol__liuba", "shu", 3):addSkills { "ol__tongdu", "ol__zhubi" }
Fk:loadTranslationTable{
  ["ol__liuba"] = "刘巴",
  ["#ol__liuba"] = "清尚之节",
  ["illustrator:ol__liuba"] = "匠人绘",

  ["~ol__liuba"] = "恨未见，铸兵为币之日……",
}

General:new(extension, "zhangshiping", "shu", 3):addSkills { "hongji", "xinggu" }
Fk:loadTranslationTable{
  ["zhangshiping"] = "张世平",
  ["#zhangshiping"] = "中山大商",
  ["illustrator:zhangshiping"] = "匠人绘",

  ["~zhangshiping"] = "奇货犹在，其人老矣……",
}

General:new(extension, "lvboshe", "qun", 4):addSkills { "fushi", "dongdao" }
Fk:loadTranslationTable{
  ["lvboshe"] = "吕伯奢",
  ["#lvboshe"] = "醉乡路稳",
  ["illustrator:lvboshe"] = "匠人绘",
  ["designer:lvboshe"] = "玄蝶既白",

  ["~lvboshe"] = "阿瞒，我沽酒回来……呃！",
}


return extension
