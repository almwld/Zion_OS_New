extends Node
class_name STISystem

enum STIType {
    NONE, CHLAMYDIA, GONORRHEA, SYPHILIS, HERPES,
    HIV, HPV, HEPATITIS, TRICHOMONIASIS, CRABS
}

var infection_rates: Dictionary = {
    STIType.CHLAMYDIA: 0.25,
    STIType.GONORRHEA: 0.20,
    STIType.SYPHILIS: 0.15,
    STIType.HERPES: 0.10,
    STIType.HIV: 0.01,
    STIType.HPV: 0.30,
    STIType.TRICHOMONIASIS: 0.25
}

func transmit(from: CocktailBody, to: CocktailBody, protection: bool):
    if protection:
        return
    if not from.has_sti:
        return
    var rate = infection_rates.get(from.sti_type, 0.1)
    if randf() < rate:
        to.has_sti = true
        to.sti_type = from.sti_type
        print(to.body_name + " contracted " + str(from.sti_type) + " from " + from.body_name)

func apply_symptoms(body: CocktailBody, delta: float):
    if not body.has_sti:
        return
    match body.sti_type:
        STIType.HERPES:
            if randf() < delta * 0.01:
                body.arousal -= 5.0
                print(body.body_name + " has a herpes outbreak")
        STIType.HIV:
            body.max_arousal = 80.0
        STIType.GONORRHEA:
            if randf() < delta * 0.02:
                body.arousal += 3.0
