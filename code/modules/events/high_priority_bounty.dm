/datum/round_event_control/high_priority_bounty
	name = "High Priority Bounty"
	typepath = /datum/round_event/high_priority_bounty
	weight = 20
	earliest_start = 0
	track = EVENT_TRACK_OBJECTIVES
	tags = list(TAG_COMMUNAL)
	category = EVENT_CATEGORY_BUREAUCRATIC
	description = "provides a high priority cargo bounty."

/datum/round_event/high_priority_bounty/announce(fake)
	priority_announce("Central Command has issued a high-priority cargo bounty. Details have been sent to all bounty consoles.", "Nanotrasen Bounty Program")

/datum/round_event/high_priority_bounty/start()
	var/datum/bounty/B
	for(var/attempts = 0; attempts < 50; ++attempts)
		B = random_bounty()
		if(!B)
			continue
		B.mark_high_priority(3)
		if(try_add_bounty(B))
			break

