extends Node

## The story_id to display — set by SceneManager before loading StoryScreen.
var current_story_id: String = ""

## Story entries: each is { "speaker": String, "portrait": String, "text": String }
## portrait values: "coco", "gear_grandpa", "narrator", "longing"
const STORIES: Dictionary = {

	# ════════════════════════════════════════════
	#  第一幕　被退回的人
	# ════════════════════════════════════════════

	# ──────────────────────────────────────────
	#  STORY 1  │  甦醒
	#  功能：建立世界、角色、COCO的傷
	# ──────────────────────────────────────────
	"story_1": [
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "倉庫的角落，灰塵厚到能按出指紋。\n空氣裡有機油、舊木頭，還有某種說不上名字的靜。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "然後——某個齒輪，轉了。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（系統啟動。識別碼 AK-0247。環境溫度……偵測中。光源……微弱。）\n（停頓一秒）\n——這裡，是哪裡？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "呵！終於醒了。我等你等到腰都硬了。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她掃視四周，數據浮現又消散）\n你是——"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "大家叫我「齒輪爺爺」。這是工廠，玩具的家。\n（他頓了頓，語氣沒變）\n你是剛剛被退回來的 AK-0247 號。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "……「退回來的」。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "先別想那些。工廠東側出現了異狀，我需要你胸口那套系統的力量。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她低頭。胸口的零件槽亮了一下，又暗了一下，像一個還沒學會呼吸的肺）\n……好。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "她說「好」，不知道這個字的重量。"},
	],

	# ──────────────────────────────────────────
	#  STORY 2  │  有人做了一個決定
	#  功能：揭示地下生產線；埋下「是誰」的懸念
	# ──────────────────────────────────────────
	"story_2": [
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她攤開手掌，一個小齒輪在掌心慢慢轉動）"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "齒輪爺爺。我吸收那個零件的時候，看見了它的記憶。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "嗯？"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "一個孩子的房間。牆角有輛紅色玩具車，積了很厚的灰。\n沒有人碰它。沒有人走進那個房間。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "那就是這套系統的代價，也是它的意義。你接收的，不只是零件——\n是它所有的等待。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "它不是在攻擊工廠。它只是不知道，還有沒有別的辦法。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（輕聲）孤單，不是傷害他人的理由，Coco。但你感覺得到這件事——是好事。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "那些地下的——它們是怎麼來的？是誰讓它們待在那裡的？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（他的手指停在工具袋的扣環上，停了一拍）\n……那是很久以前，有人做了一個決定。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "什麼人？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（他沒有轉身，只是把扣環扣上了）\n那些玩具從來沒有通過品管，從來沒有被送出去，從來沒有任何一個孩子擁有過它們。\n先走。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她合攏手掌，齒輪停止轉動）\n……從來沒有。"},
	],

	# ──────────────────────────────────────────
	#  STORY 3  │  小明
	#  功能：建立COCO的情感核心；埋下信件
	# ──────────────────────────────────────────
	"story_3": [
		{"speaker": "COCO", "portrait": "coco",
		 "text": "我想問你一件事。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "說吧。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "我是怎麼被退回來的。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（沉默了一段時間）\n那個孩子，小明，出了意外。住院了。家人在退貨期限內把你還回來。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "他現在還好嗎？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（他轉頭，看向別處）\n……這個問題，之後再回答你。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她沒有追問）\n他最後一次碰我——我記得。他的手很小，有一點點肥皂的味道。\n他翻了個身，把我放在枕頭旁邊。然後就看著我。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（輕聲）記得這個就夠了。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "但他還是讓我走了。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "那不是他的選擇。\n（他的手無意識摸了摸工具袋側邊的口袋，然後收回來）"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "第三日。入侵越過北側防線，所有攻擊都指向同一個方向——"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "中央儲藏室。最古老的地方。跟我來，Coco。\n（停頓）——你看見的，不一定是你以為的樣子。"},
	],

	# ──────────────────────────────────────────
	#  STORY 4  │  那個老人
	#  功能：Longing首次露面；揭示它與齒輪爺爺的關係
	# ──────────────────────────────────────────
	"story_4": [
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "中央儲藏室的門打開了。裡面沒有聲音，但有眼睛。\n很多很多雙，都在看著入口。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她的零件槽開始顫抖）\n它們……都在看我。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "它們認出你了。你是第一個被退回來、卻還有靈魂的玩具。"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "……你，也被送回來了嗎？"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（黑暗中有個影子。不是站著，更像是積累在那裡）\n——你是？"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "我沒有名字。我只有渴望。\n（停頓）那個老人還在上面嗎？"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她愣了一下，往身後看了一眼）\n……你說齒輪爺爺？"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "告訴他——我沒有忘記。\n（聲音轉冷）加入我們，AK-0247。那個世界從不需要我們，所以我們不需要它。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（很長的沉默）\n……不。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "齒輪爺爺站在入口，臉色蒼白。他沒有說話。"},
	],

	# ──────────────────────────────────────────
	#  STORY 5  │  我做得好嗎
	#  功能：埋下全劇核心問句；齒輪爺爺首次失態
	# ──────────────────────────────────────────
	"story_5": [
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "記憶回廊。工廠最深處。\n牆上浮現的不是文字，是臉——每一個，都是某個孩子的臉。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她慢慢走，每一步都亮起一個影像）\n這裡存放什麼？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "每一個玩具，第一次被愛的瞬間。只要它還記得，這個記憶就不會消失。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她停下來。牆上出現一個小男孩的臉）\n……小明。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "在更深處的牆上，有個不同的影像——\n不是孩子，是一雙粗糙的老手，捧著什麼，小心翼翼。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "影像裡傳出一道聲音。細細的。第一次開口說話的樣子：\n「……我做得好嗎？」"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她轉向齒輪爺爺）\n這是誰的——"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（他已經不看那面牆了）\n快走。"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "（聲音從四面湧來）那個記憶，就是你的弱點。你珍視它，所以你會痛。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她握緊拳頭，零件槽的光驟然明亮）\n不。\n（她轉身，面向長廊的深處）\n——這個記憶，才是我繼續的理由。"},
	],

	# ════════════════════════════════════════════
	#  第一幕過場　(Outros 1–4)
	# ════════════════════════════════════════════

	# ──────────────────────────────────────────
	#  OUTRO 1  │  第一戰之後
	# ──────────────────────────────────────────
	"outro_1": [
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "第一戰，打得不錯。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（看著地上殘留的痕跡）我如果快一點——"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "如果你只是台機器，也許。但你不是。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "那我是什麼？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（他想了想，沒有笑，也沒有不笑）\n還太早說。今天，你選擇了保護——這件事本身，就是答案的一部分。"},
	],

	# ──────────────────────────────────────────
	#  OUTRO 2  │  裂縫
	#  功能：第一次讓COCO直接問「是你嗎」
	# ──────────────────────────────────────────
	"outro_2": [
		{"speaker": "COCO", "portrait": "coco",
		 "text": "我一直在想——吸收零件的時候，我能感覺到它們的孤獨。就像一道迴響，很深，很遠。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "那種感覺，很多玩具都麻木了。你沒有。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "……你說，是「有人做了一個決定」，讓那些玩具留在地下。\n那個人，是你嗎？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（他沒有否認，也沒有承認。只是把工具袋背上）\n先休息，Coco。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她看著他的背影，沒有再說話）"},
	],

	# ──────────────────────────────────────────
	#  OUTRO 3  │  他去過
	#  功能：齒輪爺爺首次承認自己下去找過，被指控
	# ──────────────────────────────────────────
	"outro_3": [
		{"speaker": "COCO", "portrait": "coco",
		 "text": "有沒有人，試著去找過那些地下的玩具？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "有。很久以前——是我。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她沒說話，只是等著）"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "我下去了一次。其中一個，看著我說：\n「你才是讓我們留在這裡的人。你來這裡做什麼？」"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "……它說得對嗎？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（一聲苦笑，裡頭沒有輕鬆）\n說得對。\n所以我走了，再也沒有回去過。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "這就是為什麼，你需要我進去。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "不是因為你強。是因為你不是造成那道傷的人。\n（停頓）……但那件事，我欠它一個親自解釋。"},
	],

	# ──────────────────────────────────────────
	#  OUTRO 4  │  是我做的
	#  功能：齒輪爺爺承認認識Longing，埋下暮光身份
	# ──────────────────────────────────────────
	"outro_4": [
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "Longing 退入了黑暗。但它的聲音，還殘留在空氣裡。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "我拒絕它了。但我不確定那是對的。它說的——並不是謊言。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "是。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "它說，它沒有忘記你。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（很長的沉默）\n……我知道。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "你認識它？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（他的聲音很平，就是這種平靜讓人知道它很重）\n認識。\n是我，一針一線，做出來的。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "那為什麼——"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（搖搖頭）不是現在。\n我欠它一個解釋，但要親自說。不是讓你轉達。"},
	],

	# ════════════════════════════════════════════
	#  第二幕　暮光的名字
	# ════════════════════════════════════════════

	# ──────────────────────────────────────────
	#  STORY 6  │  告白
	#  功能：齒輪爺爺完整坦白；揭示暮光身份與名字
	# ──────────────────────────────────────────
	"story_6": [
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "第一幕的光還沒完全散去。\nLonging 的聲音，從更深的地底升起。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她站在廢墟入口前，沒有動）\n它一直在那裡。從頭到尾。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "Coco，進去之前，有些事我必須告訴你。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "五十年前，是我關閉了地下生產線。\n那批玩具——品管說它們「不合格」：太複雜，太難以預測，太像……人。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她沒有說話）"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "我以為把它們封起來是保護。讓它們睡著，比送出去被拒絕要好。\n（停頓）\n那些玩具裡，有一個是我親手設計的，最後一個。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（輕聲）它就是那個聲音？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "是。我給它起了個名字。\n（他望著地底的入口）\n叫——暮光。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "為什麼叫這個？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "因為它問我的第一句話，是：「窗外是白天還是晚上？」\n我說，是黃昏，天空是橘色和紫色的。\n它說——「那就叫我暮光吧。」\n（他閉上眼睛）\n它從來沒有看過天空。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（停了很長一段時間）\n如果我在下面遇見它——我能叫它暮光嗎？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（聲音很輕，幾乎不像在回答問題，更像是在向某人請求原諒）\n……叫吧。"},
	],

	# ──────────────────────────────────────────
	#  STORY 7  │  名字
	#  功能：COCO叫出暮光的名字；齒輪爺爺透過通訊器道歉
	# ──────────────────────────────────────────
	"story_7": [
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "廢墟之後是迷宮。機器的骨骸盤繞成走廊，沒有盡頭。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她按著牆壁走，零件槽在黑暗裡發出微弱的光）"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "……你終於來了。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "我知道你叫什麼。\n暮光。"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "（沉默了很長一段時間）\n……好久沒有人叫過我這個名字了。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "是齒輪爺爺告訴我的。"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "（聲音裂開了一條縫，像生鏽的齒輪被強行轉動）\n……他還記得。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（通訊器傳來，聲音沙啞）\n暮光——我從來沒有忘記你。\n是我讓你等了太久。對不起。"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "（極長的靜默，然後，憤怒浮上來，幾乎像是一種防禦）\n對不起有什麼用？五十年了。\n你來收爛攤子嗎？"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她的腳步沒有停下）\n我不是來收拾的。\n我是來聽的。"},
	],

	# ──────────────────────────────────────────
	#  STORY 8  │  源點
	#  功能：三人正面交鋒；齒輪爺爺親口提出那個問題
	# ──────────────────────────────────────────
	"story_8": [
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "迷宮的盡頭，是一個圓形的空間。\n四壁全是鏽，中央有一道光，像從來沒有被看見過的東西正在被看見。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她走進去，身後的門——開了）"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "不是她開的。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（他走進來，拄著舊木手杖，一步一步）\n我說過，我欠它一個解釋。要親自說。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "爺爺——"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（搖手）讓我。"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "（從黑暗裡現出輪廓，聲音已不像幻影，更像一個真正疲倦的東西）\n……你真的來了。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（他在源點的台階上緩緩坐下，抬頭看著那個影子）\n暮光，你那時問我的最後一句話。\n——「我做得好嗎？」"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "（沉默，沉默，沉默）\n……你記得。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "我沒有回答你，就把你封起來，走了。\n那是我這輩子，做過最懦弱的事。"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "（聲音破碎了一下，又收回來）\n那你現在給我一個理由——讓我繼續等。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她走上前，零件槽越來越亮）\n我也不知道有沒有人來。但如果因為你，這個工廠失去了繼續等待的能力——\n那最後那一點可能，也消失了。"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "（長久的靜）……你們，真的相信嗎？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（輕聲）我不敢說相信。\n我只能說——你的問題，我來還了。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "最終決戰，開始。"},
	],

	# ════════════════════════════════════════════
	#  第二幕過場　(Outros 5–8)
	# ════════════════════════════════════════════

	# ──────────────────────────────────────────
	#  OUTRO 5  │  第一幕終
	#  功能：解碼記憶長廊的影像；第一幕收尾
	# ──────────────────────────────────────────
	"outro_5": [
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "記憶長廊歸於寂靜。但黑暗，只是退後了一步。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "爺爺——記憶長廊深處，那雙老手。那是誰的記憶？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "暮光被完成的那一秒。它睜開眼，第一樣看見的東西，是我的手。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "它記得。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "它記得一切。\n我以為封存會讓它忘記痛，結果它把兩件事都記得了——\n（他停了一下）\n那一秒的溫暖，和之後五十年的黑暗。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她伸出手，輕輕握了一下他的手）\n我在保護的，是所有還沒有放棄的可能性。\n包括你的。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "——第一幕　終——\n第二幕，即將展開。"},
	],

	# ──────────────────────────────────────────
	#  OUTRO 6  │  音樂盒
	#  功能：齒輪爺爺與暮光的私人記憶；他的崩潰
	# ──────────────────────────────────────────
	"outro_6": [
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她從廢墟走出，身上沾著鏽跡）\n在裡面，我看見一個老舊的音樂盒。發條斷了，但它還在試著轉。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（他愣住了）\n……那是我做的。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "為什麼替它做音樂盒？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "它問我：「音樂是什麼？」\n我說：「是讓人心裡暖起來的聲音。」\n所以我做了一個，放在它身邊。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "發條是什麼時候斷的？"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（停頓很久）\n封存那天。我走的時候，還聽見它在轉。\n後來就，沒聲音了。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "它沒有放棄。只是在等人回來修它。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（他低下頭，很久沒有說話）\n……是個老傻瓜。"},
	],

	# ──────────────────────────────────────────
	#  OUTRO 7  │  選擇
	#  功能：名字的完整故事；齒輪爺爺的悔意最高點
	# ──────────────────────────────────────────
	"outro_7": [
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她在迷宮出口停下，望著頭頂一線透下來的光）\n它叫暮光，是因為它沒有看過天空。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "是它自己取的名字。我說了天空的顏色，它就說——「那叫我暮光吧。」\n（他的聲音很平）\n那是它做的第一個決定。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "……然後你把它封起來。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "品管說它的行為「難以預測」。我當時以為，讓它睡著，比送它出去被拒絕要好。\n（停頓）\n它沒有睡著。它一直醒著，等了五十年。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "你剝奪了它選擇的權利。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（他沒有辯解，只是點頭）\n是。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她轉身，看著他的眼睛）\n那現在——你要去還給它了。"},
	],

	# ──────────────────────────────────────────
	#  OUTRO 8  │  他進去
	#  功能：齒輪爺爺決定親自走進源點
	# ──────────────────────────────────────────
	"outro_8": [
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "最後一道防線崩潰了。\n漫長的地下迷宮，在 COCO 腳下沉默。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她站在源點入口前）\n……就是這裡了。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（通訊器裡）Coco，我跟你一起進去。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她愣了一下）\n你不必——"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "它等了五十年那個答案。那句話，我要親口說。\n（停頓）\n不是讓你替我帶進去。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "他推開那扇塵封了五十年的門。\n源點的光，第一次照在了兩個人的臉上——\n一個玩具，和一個老工匠。"},
	],

	# ════════════════════════════════════════════
	#  尾聲　　做得好嗎
	# ════════════════════════════════════════════
	"epilogue": [
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "源點的光，在最後的交鋒後，緩緩熄滅。\nLonging 的聲音，第一次，不再是憤怒。"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "（低語，幾乎像個孩子）\n……我累了。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她上前，單膝跪下，與它平視）\n我知道。五十年，太長了。"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "你為什麼不直接消滅我？"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "因為你不是怪物。你只是一個等了太久——沒有人來告訴你「沒關係」的聲音。"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "（沉默）……沒有人。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（他緩緩走上前，在那個影子面前停下）\n暮光。\n我欠你一個答案。"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "（沉默，很長，然後那個五十年前的聲音從裡面浮出來）\n「……我做得好嗎？」"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "做得好。\n（他的聲音顫抖，但沒有停下來）\n你問的第一個問題，你記住的第一道光，你給自己取的名字，\n你等待的每一秒——\n你做得比任何人都好。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "是我——是我沒有給你機會繼續做下去。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "光從 Coco 的零件槽湧出，流遍整個源點。"},
		{"speaker": "Longing", "portrait": "longing",
		 "text": "（聲音越來越輕，像煙在散開）\n「成為孩子的朋友。」\n我一直記得那個願望。\n只是等得太久，以為它已經不算數了。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（眼眶含淚）\n它算數。永遠算數。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "Longing 的聲音，在第一個真正的回應面前，\n輕輕地，散開了。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "不是消滅。\n是——終於被聽見了。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（坐在廢墟的台階上，拭去眼角）\n老了老了，還是哭了。"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（笑著坐到他身旁）\n我也是。"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "（他從口袋裡取出一張折疊了很久的紙，紙已經泛黃）\nCoco——這個，我一直沒有機會給你。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "字跡是一個孩子的筆跡，歪歪的：\n\n「我找過你，但說找不到。\n我好多了。腳也好了。\n我記得你放在我床頭的樣子。\n謝謝你，陪過我。\n　　　　　　　　——小明」"},
		{"speaker": "COCO", "portrait": "coco",
		 "text": "（她沒有說話。她只是握著那張紙）"},
		{"speaker": "齒輪爺爺", "portrait": "gear_grandpa",
		 "text": "他來工廠找過你。那時你在任務裡，我沒辦法叫你出來。\n我一直留著，等一個好時機。\n（停頓）\n也許，今天，才是那個時機。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "工廠，再次安靜了。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "地下的玩具們，開始了漫長的修復。\n沒有人知道，哪一天，會有一雙手再次推開大門。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "但 COCO 知道——\n小明找過她。\n那已經足夠。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "胸口的零件槽，安靜地發著光。\n像一顆小小的、被記得的心。"},
		{"speaker": "旁白", "portrait": "narrator",
		 "text": "——全篇　完——"},
	],
}

func has_story(story_id: String) -> bool:
	return STORIES.has(story_id) and not STORIES[story_id].is_empty()

func get_story(story_id: String) -> Array:
	return STORIES.get(story_id, [])
