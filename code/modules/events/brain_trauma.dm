/datum/round_event_control/brain_trauma
	name = "Spontaneous Brain Trauma"
	typepath = /datum/round_event/brain_trauma
	weight = 25
	category = EVENT_CATEGORY_HEALTH
	description = "A crewmember gains a random trauma."
	min_wizard_trigger_potency = 2
	max_wizard_trigger_potency = 6
	track = EVENT_TRACK_MUNDANE
	tags = list(TAG_TARGETED, TAG_MAGICAL) //im putting magical on this because I think this can give the magic brain traumas

/datum/round_event/brain_trauma
	fakeable = FALSE

/datum/round_event/brain_trauma/start()
	for(var/mob/living/carbon/human/H in shuffle(GLOB.alive_mob_list))
		if(!H.client)
			continue
		if(H.stat == DEAD) // What are you doing in this list
			continue
		if(!H.getorgan(/obj/item/organ/brain)) // If only I had a brain
			continue

		traumatize(H)
		announce_to_ghosts(H)
		break

/datum/round_event/brain_trauma/proc/traumatize(mob/living/carbon/human/H)
	var/resistance = pick(
		50;TRAUMA_RESILIENCE_BASIC,
		30;TRAUMA_RESILIENCE_SURGERY,
		15;TRAUMA_RESILIENCE_LOBOTOMY,
		5;TRAUMA_RESILIENCE_MAGIC)

	var/trauma_type = pickweight(list(
		BRAIN_TRAUMA_MILD = 60,
		BRAIN_TRAUMA_SEVERE = 30,
		BRAIN_TRAUMA_SPECIAL = 10
	))

	H.gain_trauma_type(trauma_type, resistance)
