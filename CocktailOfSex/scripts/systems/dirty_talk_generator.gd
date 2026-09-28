extends Node
class_name DirtyTalkGenerator

var phrases: Dictionary = {
    "compliment": [
        "أنت جميل جداً...", "جسدك مثالي...", "عيناك تذيبانني...",
        "أحب الطريقة التي تلمسني بها...", "أنت الأفضل..."
    ],
    "command": [
        "أسرع!", "أبطئ!", "أعمق!", "توقف!", "استمر!",
        "انظر إلي!", "المسني هناك!", "اقلبني!"
    ],
    "degradation": [
        "أنا عاهرتك...", "استخدمني...", "أنا لك...",
        "املأني...", "أنا لعبتك..."
    ],
    "praise": [
        "أنت كبير جداً...", "لا أستطيع التحمل...", "أنت عميق جداً...",
        "أنت تجعلني أفقد عقلي...", "لم أشعر بهذا من قبل..."
    ],
    "begging": [
        "أرجوك...", "لا تتوقف...", "أعطني المزيد...",
        "أحتاجك...", "خذني الآن..."
    ],
    "orgasm_warning": [
        "سأبلغ...!", "أنا قادم...!", "لا أستطيع التوقف...!",
        "اللعنة...!", "الآن...!"
    ]
}

func generate(category: String) -> String:
    if phrases.has(category):
        var pool = phrases[category]
        return pool[randi() % pool.size()]
    return "..."

func generate_contextual(body: CocktailBody, partner: CocktailBody) -> String:
    if body.is_climaxing:
        return generate("orgasm_warning")
    elif body.arousal > 80:
        if body.personality["dominance"] > 0.6:
            return generate("command")
        else:
            return generate("begging")
    elif body.arousal > 50:
        if body.personality["dominance"] > 0.5:
            return generate("compliment")
        else:
            return generate("praise")
    else:
        return generate("compliment")
