extends Node
class_name CosmicAscension

var body: CocktailBody

enum AscensionLevel {
    MORTAL,
    ENLIGHTENED,
    DEMIGOD,
    GOD,
    OVERLORD,
    COSMIC_ENTITY,
    OMNIPRESENT,
    ABSOLUTE
}

var current_level: AscensionLevel = AscensionLevel.MORTAL
var ascension_points: float = 0.0
var total_orgasms_needed: Dictionary = {
    AscensionLevel.ENLIGHTENED: 100,
    AscensionLevel.DEMIGOD: 500,
    AscensionLevel.GOD: 2000,
    AscensionLevel.OVERLORD: 10000,
    AscensionLevel.COSMIC_ENTITY: 50000,
    AscensionLevel.OMNIPRESENT: 250000,
    AscensionLevel.ABSOLUTE: 1000000
}

var divine_powers: Array[String] = []
var worshippers: int = 0
var divine_energy: float = 100.0

signal ascension_achieved(new_level: AscensionLevel)
signal divine_power_gained(power: String)
signal worshipper_gained(total: int)
signal ultimate_pleasure_unleashed()

func _init(_body: CocktailBody):
    body = _body

func add_orgasm_to_ascension():
    ascension_points += 1.0
    _check_ascension()

func _check_ascension():
    var next_level = current_level + 1
    if next_level in total_orgasms_needed:
        if ascension_points >= total_orgasms_needed[next_level]:
            current_level = next_level
            ascension_achieved.emit(current_level)
            _grant_divine_power()

func _grant_divine_power():
    var powers = {
        AscensionLevel.ENLIGHTENED: ["enhanced_sensitivity", "pleasure_aura"],
        AscensionLevel.DEMIGOD: ["multiple_orgasm_mastery", "partner_pleasure_boost"],
        AscensionLevel.GOD: ["instant_climax", "pleasure_manipulation"],
        AscensionLevel.OVERLORD: ["time_dilation_sex", "reality_pleasure_warp"],
        AscensionLevel.COSMIC_ENTITY: ["universe_creation", "pleasure_singularity"],
        AscensionLevel.OMNIPRESENT: ["omnipresent_orgasm", "infinite_stamina"],
        AscensionLevel.ABSOLUTE: ["absolute_pleasure", "existence_control"]
    }
    if current_level in powers:
        for power in powers[current_level]:
            if not power in divine_powers:
                divine_powers.append(power)
                divine_power_gained.emit(power)
                if power == "absolute_pleasure":
                    ultimate_pleasure_unleashed.emit()

func gain_worshipper():
    worshippers += 1
    divine_energy = min(1000.0, divine_energy + 0.1)
    worshipper_gained.emit(worshippers)

func use_divine_power(power_name: String) -> bool:
    if power_name in divine_powers:
        divine_energy -= 10.0
        match power_name:
            "instant_climax":
                body._achieve_orgasm()
            "pleasure_aura":
                body.arousal += 50.0
        return true
    return false

func get_ascension_report() -> Dictionary:
    var level_names = ["Mortal", "Enlightened", "Demigod", "God", "Overlord", "Cosmic Entity", "Omnipresent", "Absolute"]
    return {
        "level": level_names[current_level],
        "points": ascension_points,
        "powers": divine_powers.size(),
        "worshippers": worshippers,
        "divine_energy": divine_energy
    }
