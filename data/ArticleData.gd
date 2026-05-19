extends Node

const ARTICLES = {
	1: {
		"title": "Článek 1: Postoje uživatelů",
		"text": """(1) Uživatelé se musí Hře věnovat celým srdcem a aktivně si ji s nadšením užívat.

(2) Pokud Uživatel zapomene na původní účel Hry, tedy užívat si ji, automaticky ztrácí oprávnění Hru používat.

(3) Pokud Uživatel při honbě za soutěžením nebo výsledky ztratí ze zřetele, jak si Hru užívat, bude to považováno za odchýlení se od účelu Hry. Důrazně doporučujeme, aby si Uživatelé, kteří se v takové situaci ocitnou, dali od Hry pauzu, byť jen dočasně, a pokusili se znovu získat klid mysli."""
	},

	2: {
		"title": "Článek 2: Ohledy vůči vývojářům",
		"text": """(1) Při hraní Hry budou Uživatelé upřímně obdivovat úsilí a oddanost Vývojářů.

(2) Uživatelé budou chápat, že i Vývojáři jsou jen lidé, a přehlédnou drobné chyby, bugy a překlepy.

(3) Milé komentáře od Uživatelů, jako například „Bylo to zábavné“ nebo „Bylo to zajímavé“, zahřejí srdce Vývojářů, kteří čelí neznámým bugům a stále se blížícím deadlinům, jako jarní slunce — a pomohou zvýšit jejich motivaci pokračovat ve vývoji."""
	},

	3: {
		"title": "Článek 3: Postoj k chybám",
		"text": """(1) Uživatelé si uvědomují, jak obtížné je během vývoje hry úplně odstranit všechny bugy, a projeví vývojářům hluboké pochopení a soucit.

(2) Uživatelé, kteří ve Hře objeví bug, jej budou považovat za skrytou funkci hry a mohou sdílet svou radost z jeho objevení na sociálních sítích nebo jinými způsoby."""
	},

	4: {
		"title": "Článek 4: O sdílení zkušeností",
		"text": """(1) Uživatelé mají právo aktivně sdílet všechny zážitky, objevy a nečekané události, které ve Hře zažijí, s přáteli, rodinou, a dokonce i s cizími lidmi. Při sdílení však prosím dbejte na to, abyste na veřejných místech nekřičeli příliš nahlas nebo se nesmáli tak moc, že by to ostatním bylo nepříjemné.

(2) Vývojář nenese žádnou odpovědnost v případě, že sdílení vašich zážitků ze Hry ohrozí vaše vztahy."""
	},

	5: {
		"title": "Článek 5: Závislost",
		"text": """(1) Vývojář nenese žádnou odpovědnost v případě, že se Uživatel do této hry ponoří natolik, že mu začne zasahovat do práce, studia nebo společenského života.

(2) Vzhledem k potenciálně návykové povaze této hry jsou protesty, demonstrace nebo úmyslné ničení počítačů, chytrých telefonů či jiných používaných zařízení přísně zakázány.

(3) Pokud Uživatelé podlehnou kouzlu této hry natolik, že jejich chování v reálném světě začne být nevhodné, nesou za něj plnou odpovědnost. Vývojář nenese žádnou odpovědnost za jakékoli škody vzniklé v důsledku takového jednání."""
	},

	6: {
		"title": "Článek 6: Nakládání s osobními údaji",
		"text": """(1) Uživatelské jméno zadané Uživatelem bude zveřejněno například v herním žebříčku. Výmluvy typu „Byl to jen vtip“ nebo „Nemá to žádný hlubší význam“ nebudou přijaty. Jako zodpovědný dospělý si musíte zvolit jméno, na které můžete být hrdí bez ohledu na to, kdo ho uvidí.

(2) Po skončení hry mohou Uživatelé vyhnat svá data do hlubin digitálního vesmíru pomocí odříkání „zaklínadla pro smazání osobních údajů“. Toto zaklínadlo však musí být přesně odříkáno před počítačem za měsíční noci, přičemž třikrát dupnete levou nohou a dvakrát pravou. Buďte prosím opatrní, protože nesprávné odříkání může vést k neznámým následkům."""
	},

	7: {
		"title": "Článek 7: Nakládání s herními daty",
		"text": """(1) Herní data, jako jsou uživatelská jména Uživatelů, nejvyšší skóre a doba hraní, jsou automaticky odesílána na servery hry.

(2) Vývojáři cítí radost, když si prohlížejí herní data Uživatelů a zjišťují, že Uživatelé věnují této hře drahocenný čas svého života. Stejně jako třešňové květy tiše rozkvétající na jaře, i tato radost tiše, ale jistě zvyšuje motivaci Vývojářů a slouží jako zdroj pro další vývoj hry."""
	},

	8: {
		"title": "Článek 8: Ohledně podvodů / K podvodům",
		"text": """(1) Podvádění v této hře je přísně zakázáno. To zahrnuje používání magických schopností k nespravedlivému navýšení skóre, cestování časem za účelem vítězství v minulých hrách, hraní bez jakéhokoli pocitu radosti nebo používání hry k jakýmkoli nemravným účelům. Upozorňujeme, že toto není hra, ve které vám podvádění pomůže dostat se na vrchol žebříčku.

(2) Pokud budete v této hře podvádět, může na vás být za trest uvalena kletba, kvůli které se budete celý týden pouze smát."""
	}
}


static func get_title(article_number: int) -> String:
	if ARTICLES.has(article_number):
		return ARTICLES[article_number]["title"]

	return "Neznámý článek"


static func get_text(article_number: int) -> String:
	if ARTICLES.has(article_number):
		return ARTICLES[article_number]["text"]

	return "Text článku nebyl nalezen."
