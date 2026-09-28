extends Node
class_name SexualDialogueSystem

var dialogue_db: Dictionary = {
    "dominant": {
        "foreplay": [
            "أريدك الآن...", "انظري إلي...", "جسدك لي الليلة.",
            "لا تقاومي...", "أنت ملكي..."
        ],
        "penetration": [
            "خذيه كله...", "أشعر بك... آه...", "قولي اسمي...",
            "أعمق...", "أنت ضيقة جداً..."
        ],
        "orgasm": ["أنا قادم...!", "سأملؤك...!", "خذي كل شيء..."],
        "afterglow": ["كنت رائعة...", "لا تتحركي...", "ابقِ هكذا..."]
    },
    "submissive": {
        "foreplay": [
            "المسني أرجوك...", "أنا لك...", "استخدمني...",
            "افعل ما تشاء...", "أنا في خدمتك..."
        ],
        "penetration": [
            "أعمق...!", "لا تتوقف...!", "أكثر أرجوك...",
            "أشعر بك في أعماقي...", "أنت كبير جداً..."
        ],
        "orgasm": ["سأبلغ...!", "أنا قادم...!", "اللعنة..."],
        "afterglow": ["شكراً لك...", "احضني...", "أنا أحبك..."]
    },
    "neutral": {
        "foreplay": [
            "هل أنت مستعد؟", "هذا جميل...", "أحب هذا...",
            "استمر...", "هكذا..."
        ],
        "penetration": [
            "هذا جيد...", "أسرع قليلاً...", "أبطئ...",
            "هناك...", "ممتاز..."
        ],
        "orgasm": ["آه...!", "يا إلهي...!", "الآن...!"],
        "afterglow": ["كان جميلاً...", "شكراً...", "لنفعل هذا مجدداً..."]
    },
    "daddy": {
        "foreplay": [
            "تعالي إلى دادي...", "فتاتي الصغيرة...", "دعيني أعتني بك..."
        ],
        "penetration": [
            "خذيه كله...", "أنت فتاة جيدة...", "داداي يحبك..."
        ],
        "orgasm": ["داداي سيملؤك...!"],
        "afterglow": ["نامي بين ذراعي...", "فتاتي الجميلة..."]
    },
    "little_girl": {
        "foreplay": [
            "دادي...", "أنا خائفة قليلاً...", "هل ستكون لطيفاً؟"
        ],
        "penetration": [
            "دادي...!", "أكثر...", "أشعر به..."
        ],
        "orgasm": ["دادي!"],
        "afterglow": ["أحبك دادي...", "ابقَ معي..."]
    }
}

func get_dialogue(body: CocktailBody, action_type: String) -> String:
    var role = "neutral"
    if body.personality["dominance"] > 0.6:
        role = "dominant"
    elif body.personality["dominance"] < 0.4:
        role = "submissive"
    if body.has_meta("kink_role"):
        var krole = body.get_meta("kink_role")
        if krole in dialogue_db:
            role = krole
    if dialogue_db.has(role) and dialogue_db[role].has(action_type):
        var phrases = dialogue_db[role][action_type]
        return phrases[randi() % phrases.size()]
    if dialogue_db["neutral"].has(action_type):
        var phrases = dialogue_db["neutral"][action_type]
        return phrases[randi() % phrases.size()]
    return "..."
