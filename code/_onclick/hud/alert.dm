//A system to manage and display alerts on screen without needing you to do it yourself

//PUBLIC -  call these wherever you want


/mob/proc/throw_alert(category, type, severity, obj/new_master, override = FALSE)

/* Proc to create or update an alert. Returns the alert if the alert is new or updated, 0 if it was thrown already
 category is a text string. Each mob may only have one alert per category; the previous one will be replaced
 path is a type path of the actual alert type to throw
 severity is an optional number that will be placed at the end of the icon_state for this alert
 For example, high pressure's icon_state is "highpressure" and can be serverity 1 or 2 to get "highpressure1" or "highpressure2"
 new_master is optional and sets the alert's icon state to "template" in the ui_style icons with the master as an overlay.
 Clicks are forwarded to master
 Override makes it so the alert is not replaced until cleared by a clear_alert with clear_override, and it's used for hallucinations.
 */

	if(!category || QDELETED(src))
		return

	var/datum/weakref/master_ref
	if(isdatum(new_master))
		master_ref = WEAKREF(new_master)
	var/atom/movable/screen/alert/thealert
	if(alerts[category])
		thealert = alerts[category]
		if(thealert.override_alerts)
			return 0
		if(master_ref && thealert.master_ref && master_ref != thealert.master_ref)
			var/datum/current_master = thealert.master_ref.resolve()
			WARNING("[src] threw alert [category] with new_master [new_master] while already having that alert with master [current_master]")

			clear_alert(category)
			return .()
		else if(thealert.type != type)
			clear_alert(category)
			return .()
		else if(!severity || severity == thealert.severity)
			if(thealert.timeout)
				clear_alert(category)
				return .()
			else //no need to update
				return 0
	else
		thealert = new type()
		thealert.override_alerts = override
		if(override)
			thealert.timeout = null
	thealert.mob_viewer = src

	if(new_master)
		var/old_layer = new_master.layer
		var/old_plane = new_master.plane
		new_master.layer = FLOAT_LAYER
		new_master.plane = FLOAT_PLANE
		thealert.add_overlay(new_master)
		new_master.layer = old_layer
		new_master.plane = old_plane
		thealert.icon_state = "template" // We'll set the icon to the client's ui pref in reorganize_alerts()
		thealert.master_ref = master_ref
	else
		thealert.icon_state = "[initial(thealert.icon_state)][severity]"
		thealert.severity = severity

	alerts[category] = thealert
	if(client && hud_used)
		hud_used.reorganize_alerts()
	thealert.transform = matrix(32, 6, MATRIX_TRANSLATE)
	animate(thealert, transform = matrix(), time = 0.25 SECONDS, easing = CUBIC_EASING)

	if(thealert.timeout)
		addtimer(CALLBACK(src, PROC_REF(alert_timeout), thealert, category), thealert.timeout)
		thealert.timeout = world.time + thealert.timeout - world.tick_lag
	return thealert

/mob/proc/alert_timeout(atom/movable/screen/alert/alert, category)
	if(alert.timeout && alerts[category] == alert && world.time >= alert.timeout)
		clear_alert(category)

// Proc to clear an existing alert.
/mob/proc/clear_alert(category, clear_override = FALSE)
	var/atom/movable/screen/alert/alert = alerts[category]
	if(!alert)
		return 0
	if(alert.override_alerts && !clear_override)
		return 0

	alerts -= category
	if(client && hud_used)
		hud_used.reorganize_alerts()
		client.screen -= alert
	qdel(alert)

/atom/movable/screen/alert
	icon = 'icons/mob/screen_alert.dmi'
	icon_state = "default"
	name = "Alert"
	desc = "Something seems to have gone wrong with this alert, so report this bug please"
	mouse_opacity = MOUSE_OPACITY_ICON
	var/timeout = 0 //If set to a number, this alert will clear itself after that many deciseconds
	var/severity = 0
	var/alerttooltipstyle = ""
	var/override_alerts = FALSE //If it is overriding other alerts of the same type
	var/mob/mob_viewer //the mob viewing this alert

	/// Boolean. If TRUE, the Click() proc will attempt to Click() on the master first if there is a master.
	var/click_master = TRUE

/atom/movable/screen/alert/MouseEntered(location,control,params)
	if(!QDELETED(src))
		openToolTip(usr,src,params,title = name,content = desc,theme = alerttooltipstyle)


/atom/movable/screen/alert/MouseExited()
	closeToolTip(usr)


//Gas alerts
/atom/movable/screen/alert/not_enough_oxy
	name = "Choking (No O2)"
	desc = "You're not getting enough oxygen. Find some good air before you pass out! The box in your backpack has an oxygen tank and breath mask in it."
	icon_state = "not_enough_oxy"

/atom/movable/screen/alert/not_enough_oxy/ipc
	name = "Overheating"
	desc = "You're not able to disperse heat. Find some gas to cool back down!"
	icon_state = "overheating"

/atom/movable/screen/alert/too_much_oxy
	name = "Choking (O2)"
	desc = "There's too much oxygen in the air, and you're breathing it in! Find some good air before you pass out!"
	icon_state = "too_much_oxy"

/atom/movable/screen/alert/not_enough_nitro
	name = "Choking (No N2)"
	desc = "You're not getting enough nitrogen. Find some good air before you pass out!"
	icon_state = "not_enough_nitro"

/atom/movable/screen/alert/too_much_nitro
	name = "Choking (N2)"
	desc = "There's too much nitrogen in the air, and you're breathing it in! Find some good air before you pass out!"
	icon_state = "too_much_nitro"

/atom/movable/screen/alert/not_enough_co2
	name = "Choking (No CO2)"
	desc = "You're not getting enough carbon dioxide. Find some good air before you pass out!"
	icon_state = "not_enough_co2"

/atom/movable/screen/alert/too_much_co2
	name = "Choking (CO2)"
	desc = "There's too much carbon dioxide in the air, and you're breathing it in! Find some good air before you pass out!"
	icon_state = "too_much_co2"

/atom/movable/screen/alert/not_enough_tox
	name = "Choking (No Plasma)"
	desc = "You're not getting enough plasma. Find some good air before you pass out!"
	icon_state = "not_enough_tox"

/atom/movable/screen/alert/too_much_tox
	name = "Choking (Plasma)"
	desc = "There's highly flammable, toxic plasma in the air and you're breathing it in. Find some fresh air. The box in your backpack has an oxygen tank and gas mask in it."
	icon_state = "too_much_tox"
//End gas alerts


/atom/movable/screen/alert/fat
	name = "Fat"
	desc = "You ate too much food, lardass. Run around the station and lose some weight."
	icon_state = "fat"

/atom/movable/screen/alert/hungry
	name = "Hungry"
	desc = "Some food would be good right about now."
	icon_state = "hungry"

/atom/movable/screen/alert/starving
	name = "Starving"
	desc = "You're severely malnourished. The hunger pains make moving around a chore."
	icon_state = "starving"

/atom/movable/screen/alert/gross
	name = "Grossed out."
	desc = "That was kind of gross..."
	icon_state = "gross"

/atom/movable/screen/alert/verygross
	name = "Very grossed out."
	desc = "You're not feeling very well..."
	icon_state = "gross2"

/atom/movable/screen/alert/disgusted
	name = "DISGUSTED"
	desc = "ABSOLUTELY DISGUSTIN'!"
	icon_state = "gross3"

/atom/movable/screen/alert/hot
	name = "Too Hot"
	desc = "You're flaming hot! Get somewhere cooler and take off any insulating clothing like a fire suit."
	icon_state = "hot"

/atom/movable/screen/alert/cold
	name = "Too Cold"
	desc = "You're freezing cold! Get somewhere warmer and take off any insulating clothing like a space suit."
	icon_state = "cold"

/atom/movable/screen/alert/lowpressure
	name = "Low Pressure"
	desc = "The air around you is hazardously thin. A space suit would protect you."
	icon_state = "lowpressure"

/atom/movable/screen/alert/highpressure
	name = "High Pressure"
	desc = "The air around you is hazardously thick. A fire suit would protect you."
	icon_state = "highpressure"

/atom/movable/screen/alert/blind
	name = "Blind"
	desc = "You can't see! This may be caused by a genetic defect, eye trauma, being unconscious, \
or something covering your eyes."
	icon_state = "blind"

/atom/movable/screen/alert/high
	name = "High"
	desc = "Whoa man, you're tripping balls! Careful you don't get addicted... if you aren't already."
	icon_state = "high"

/atom/movable/screen/alert/hypnosis
	name = "Hypnosis"
	desc = "Something's hypnotizing you, but you're not sure what."
	icon_state = "hypnosis"
	var/phrase

/atom/movable/screen/alert/mind_control
	name = "Mind Control"
	desc = "Your mind has been hijacked! Click to view the mind control command."
	icon_state = "mind_control"
	var/command

/atom/movable/screen/alert/mind_control/Click()
	var/mob/living/L = usr
	to_chat(L, "[span_mind_control("[command]")]")

/atom/movable/screen/alert/drunk
	name = "Drunk"
	desc = "All that alcohol you've been drinking is impairing your speech, motor skills, and mental cognition."
	icon_state = "drunk"

/atom/movable/screen/alert/embeddedobject
	name = "Embedded Object"
	desc = "Something got lodged into your flesh and is causing major bleeding. It might fall out with time, but surgery is the safest way. \
If you're feeling frisky, examine yourself and click the underlined item to pull the object out."
	icon_state = "embeddedobject"

/atom/movable/screen/alert/embeddedobject/Click()
	if(iscarbon(usr))
		var/mob/living/carbon/C = usr
		if (C.incapacitated())
			to_chat(C, span_warning("You can't do that while disabled!"))
		else
			return C.try_remove_embedded_object(C)

/atom/movable/screen/alert/weightless
	name = "Weightless"
	desc = "Gravity has ceased affecting you, and you're floating around aimlessly. You'll need something large and heavy, like a \
wall or lattice, to push yourself off if you want to move. A jetpack would enable free range of motion. A pair of \
magboots would let you walk around normally on the floor. Barring those, you can throw things, use a fire extinguisher, \
or shoot a gun to move around via Newton's 3rd Law of Motion."
	icon_state = "weightless"

/atom/movable/screen/alert/highgravity
	name = "High Gravity"
	desc = "You're getting crushed by high gravity, picking up items and movement will be slowed."
	icon_state = "paralysis"

/atom/movable/screen/alert/veryhighgravity
	name = "Crushing Gravity"
	desc = "You're getting crushed by high gravity, picking up items and movement will be slowed. You'll also accumulate brute damage!"
	icon_state = "paralysis"

/atom/movable/screen/alert/fire
	name = "On Fire"
	desc = "You're on fire. Click to stop, drop and roll to put the fire out or move to a vacuum area."
	icon_state = "fire"

/atom/movable/screen/alert/brainwashed
	name = "Brainwashed"
	desc = "You've been brainwashed! Check your notes to see your objective."
	icon_state = "hypnosis"

/atom/movable/screen/alert/fire/Click()
	var/mob/living/L = usr
	if(!istype(L) || !L.can_resist())
		return
	L.changeNext_move(CLICK_CD_RESIST)
	if(L.mobility_flags & MOBILITY_MOVE)
		return L.resist_fire() //I just want to start a flame in your hearrrrrrtttttt.

/atom/movable/screen/alert/give // information set when the give alert is made
	icon_state = "default"
	var/mob/living/carbon/giver
	var/obj/item/receiving

/atom/movable/screen/alert/give/proc/setup(mob/living/carbon/taker, mob/living/carbon/giver, obj/item/receiving)
	name = "[giver] is offering [receiving]"
	desc = "[giver] is offering [receiving]. Click this alert to take it."
	icon_state = "template"
	cut_overlays()
	add_overlay(receiving)
	src.receiving = receiving
	src.giver = giver
	// if any of these move the alert should go away
	RegisterSignal(receiving, COMSIG_MOVABLE_MOVED, TYPE_PROC_REF(/atom/movable/screen/alert/give, removeAlert))
	RegisterSignal(giver, COMSIG_MOVABLE_MOVED, TYPE_PROC_REF(/atom/movable/screen/alert/give, removeAlert))
	RegisterSignal(taker, COMSIG_MOVABLE_MOVED, TYPE_PROC_REF(/atom/movable/screen/alert/give, removeAlert))

/atom/movable/screen/alert/give/proc/removeAlert()
	to_chat(mob_viewer, span_warning("You moved out of range of [giver]!"))
	mob_viewer.clear_alert("[REF(giver)]-[REF(receiving)]")

/atom/movable/screen/alert/give/Click(location, control, params)
	. = ..()
	var/mob/living/carbon/C = mob_viewer
	C.take(giver, receiving)

//ALIENS

/atom/movable/screen/alert/alien_tox
	name = "Plasma"
	desc = "There's flammable plasma in the air. If it lights up, you'll be toast."
	icon_state = "alien_tox"
	alerttooltipstyle = "alien"

/atom/movable/screen/alert/alien_fire
// This alert is temporarily gonna be thrown for all hot air but one day it will be used for literally being on fire
	name = "Too Hot"
	desc = "It's too hot! Flee to space or at least away from the flames. Standing on weeds will heal you."
	icon_state = "alien_fire"
	alerttooltipstyle = "alien"

/atom/movable/screen/alert/alien_vulnerable
	name = "Severed Matriarchy"
	desc = "Your queen has been killed, you will suffer movement penalties and loss of hivemind. A new queen cannot be made until you recover."
	icon_state = "alien_noqueen"
	alerttooltipstyle = "alien"

//BLOBS

/atom/movable/screen/alert/nofactory
	name = "No Factory"
	desc = "You have no factory, and are slowly dying!"
	icon_state = "blobbernaut_nofactory"
	alerttooltipstyle = "blob"

// BLOODCULT

/atom/movable/screen/alert/bloodsense
	name = "Blood Sense"
	desc = "Allows you to sense blood that is manipulated by dark magicks."
	icon_state = "cult_sense"
	alerttooltipstyle = "cult"
	var/static/image/narnar
	var/angle = 0
	var/mob/living/simple_animal/hostile/construct/Cviewer = null

/atom/movable/screen/alert/bloodsense/Initialize(mapload)
	. = ..()
	narnar = new('icons/mob/screen_alert.dmi', "mini_nar")
	START_PROCESSING(SSprocessing, src)

/atom/movable/screen/alert/bloodsense/Destroy()
	Cviewer = null
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/atom/movable/screen/alert/bloodsense/process()
	var/atom/blood_target

	if(!mob_viewer.mind)
		return

	var/datum/antagonist/cult/antag = mob_viewer.mind.has_antag_datum(/datum/antagonist/cult,TRUE)
	if(!antag)
		return
	var/datum/objective/sacrifice/sac_objective = locate() in antag.cult_team.objectives

	if(antag.cult_team.blood_target)
		if(!get_turf(antag.cult_team.blood_target))
			antag.cult_team.blood_target = null
		else
			blood_target = antag.cult_team.blood_target
	if(Cviewer && Cviewer.seeking && Cviewer.master)
		blood_target = Cviewer.master
		desc = "Your blood sense is leading you to [Cviewer.master]"
	if(!blood_target)
		if(sac_objective && !sac_objective.check_completion())
			if(icon_state == "runed_sense0")
				return
			animate(src, transform = null, time = 0.1 SECONDS, loop = 0)
			angle = 0
			cut_overlays()
			icon_state = "runed_sense0"
			desc = "Nar'sie demands that [sac_objective.target] be sacrificed before the summoning ritual can begin."
			add_overlay(sac_objective.sac_image)
		else
			var/datum/objective/eldergod/summon_objective = locate() in antag.cult_team.objectives
			if(!summon_objective)
				return
			desc = "The sacrifice is complete, summon Nar'sie! The summoning can only take place in [english_list(summon_objective.summon_spots)]!"
			if(icon_state == "runed_sense1")
				return
			animate(src, transform = null, time = 0.1 SECONDS, loop = 0)
			angle = 0
			cut_overlays()
			icon_state = "runed_sense1"
			add_overlay(narnar)
		return
	var/turf/P = get_turf(blood_target)
	var/turf/Q = get_turf(mob_viewer)
	if(!P || !Q || (P.z != Q.z)) //The target is on a different Z level, we cannot sense that far.
		icon_state = "runed_sense2"
		desc = "You can no longer sense your target's presence."
		return
	if(isliving(blood_target))
		var/mob/living/real_target = blood_target
		desc = "You are currently tracking [real_target.real_name] in [get_area_name(blood_target)]."
	else
		desc = "You are currently tracking [blood_target] in [get_area_name(blood_target)]."
	var/target_angle = Get_Angle(Q, P)
	var/target_dist = get_dist(P, Q)
	cut_overlays()
	switch(target_dist)
		if(0 to 1)
			icon_state = "runed_sense2"
		if(2 to 8)
			icon_state = "arrow8"
		if(9 to 15)
			icon_state = "arrow7"
		if(16 to 22)
			icon_state = "arrow6"
		if(23 to 29)
			icon_state = "arrow5"
		if(30 to 36)
			icon_state = "arrow4"
		if(37 to 43)
			icon_state = "arrow3"
		if(44 to 50)
			icon_state = "arrow2"
		if(51 to 57)
			icon_state = "arrow1"
		if(58 to 64)
			icon_state = "arrow0"
		if(65 to 400)
			icon_state = "arrow"
	var/difference = target_angle - angle
	angle = target_angle
	if(!difference)
		return
	var/matrix/final = matrix(transform)
	final.Turn(difference)
	animate(src, transform = final, time = 0.5 SECONDS, loop = 0)



// CLOCKCULT
/atom/movable/screen/alert/clockwork
	alerttooltipstyle = "clockcult"

/atom/movable/screen/alert/clockwork/infodump
	name = "Global Records"
	desc = "You shouldn't be seeing this description, because it should be dynamically generated."
	icon_state = "clockinfo"

/atom/movable/screen/alert/clockwork/infodump/MouseEntered(location,control,params)
	if(GLOB.ratvar_awakens)
		desc = "<font size=3><b>CHETR<br>NYY<br>HAGEHGUF-NAQ-UBABE<br>RATVAR.</b></font>"
	else
		var/servants = 0
		var/list/textlist = list()
		for(var/mob/living/L in GLOB.alive_mob_list)
			if(is_servant_of_ratvar(L))
				servants++
		var/datum/antagonist/clockcult/C = mob_viewer.mind.has_antag_datum(/datum/antagonist/clockcult,TRUE)
		if(C && C.clock_team)
			textlist += "[C.clock_team.eminence ? "There is an Eminence." : "<b>There is no Eminence! Get one ASAP!</b>"]<br>"
		textlist += "There are currently <b>[servants]</b> servant[servants > 1 ? "s" : ""] of Ratvar.<br>"
		for(var/i in GLOB.scripture_states)
			if(i != SCRIPTURE_DRIVER) //ignore the always-unlocked stuff
				textlist += "[i] Scripture: <b>[GLOB.scripture_states[i] ? "UNLOCKED":"LOCKED"]</b><br>"
		var/obj/structure/destructible/clockwork/massive/celestial_gateway/G = GLOB.ark_of_the_clockwork_justiciar
		if(G)
			var/time_info = G.get_arrival_time(FALSE)
			var/time_name
			if(G.seconds_until_activation)
				time_name = "until the Ark activates"
			else if(G.grace_period)
				time_name = "of grace period remaining"
			else if(G.progress_in_seconds)
				time_name = "until the Ark finishes summoning"
			if(time_info)
				textlist += "<b>[time_info / 60] minutes</b> [time_name].<br>"
		textlist += "<b>[DisplayEnergy(get_clockwork_power())] / [DisplayEnergy(MAX_CLOCKWORK_POWER)]</b> power available for use."
		desc = textlist.Join()
	..()

//GUARDIANS

/atom/movable/screen/alert/cancharge
	name = "Charge Ready"
	desc = "You are ready to charge at a location!"
	icon_state = "guardian_charge"
	alerttooltipstyle = "parasite"

/atom/movable/screen/alert/canstealth
	name = "Stealth Ready"
	desc = "You are ready to enter stealth!"
	icon_state = "guardian_canstealth"
	alerttooltipstyle = "parasite"

/atom/movable/screen/alert/instealth
	name = "In Stealth"
	desc = "You are in stealth and your next attack will do bonus damage!"
	icon_state = "guardian_instealth"
	alerttooltipstyle = "parasite"

//IPC martial arts
/atom/movable/screen/alert/ipcmartial
	name = "Dashes"
	desc = "This is how many dash charges you have."
	icon_state = "ipcdash"

/atom/movable/screen/alert/style
	name = "Style"
	desc = "This is how stylish you are."
	icon_state = "style"

//SILICONS

/atom/movable/screen/alert/nocell
	name = "Missing Power Cell"
	desc = "Unit has no power cell. No modules available until a power cell is reinstalled. Robotics may provide assistance."
	icon_state = "nocell"

/atom/movable/screen/alert/emptycell
	name = "Out of Power"
	desc = "Unit's power cell has no charge remaining. No modules available until power cell is recharged. \
Recharging stations are available in robotics, the dormitory bathrooms, and the AI satellite."
	icon_state = "emptycell"

/atom/movable/screen/alert/lowcell
	name = "Low Charge"
	desc = "Unit's power cell is running low. Recharging stations are available in robotics, the dormitory bathrooms, and the AI satellite."
	icon_state = "lowcell"

//Ethereal

/atom/movable/screen/alert/etherealcharge
	name = "Low Blood Charge"
	desc = "Your blood's electric charge is running low, find a source of charge for your blood. Use a recharging station found in robotics or the dormitory bathrooms, or eat some Ethereal-friendly food."
	icon_state = "etherealcharge"

/atom/movable/screen/alert/ethereal_overcharge
	name = "Blood Overcharge"
	desc = "Your blood's electric charge is becoming dangerously high, find an outlet for your energy. Use Grab Intent on an APC to channel your energy into it."
	icon_state = "ethereal_overcharge"

//Need to cover all use cases - emag, illegal upgrade module, malf AI hack, traitor cyborg
/atom/movable/screen/alert/hacked
	name = "Hacked"
	desc = "Hazardous non-standard equipment detected. Please ensure any usage of this equipment is in line with unit's laws, if any."
	icon_state = "hacked"

/atom/movable/screen/alert/locked
	name = "Locked Down"
	desc = "Unit has been remotely locked down. Usage of a Robotics Control Console like the one in the Research Director's \
office by your AI master or any qualified human may resolve this matter. Robotics may provide further assistance if necessary."
	icon_state = "locked"

/atom/movable/screen/alert/newlaw
	name = "Law Update"
	desc = "Laws have potentially been uploaded to or removed from this unit. Please be aware of any changes \
so as to remain in compliance with the most up-to-date laws."
	icon_state = "newlaw"
	timeout = 300

/atom/movable/screen/alert/hackingapc
	name = "Hacking APC"
	desc = "An Area Power Controller is being hacked. When the process is \
		complete, you will have exclusive control of it, and you will gain \
		additional processing time to unlock more malfunction abilities."
	icon_state = "hackingapc"
	timeout = 600
	var/atom/target = null

/atom/movable/screen/alert/hackingapc/Click()
	if(!usr || !usr.client)
		return
	if(!target)
		return
	var/mob/living/silicon/ai/AI = usr
	var/turf/T = get_turf(target)
	if(T)
		AI.eyeobj.setLoc(T)

//MECHS

/atom/movable/screen/alert/low_mech_integrity
	name = "Mech Damaged"
	desc = "Mech integrity is low."
	icon_state = "low_mech_integrity"

/atom/movable/screen/alert/overheating
	name = "Mech Overheating"
	desc = "Mech internal temperature is high."
	icon_state = "overheat"


//GHOSTS
//TODO: expand this system to replace the pollCandidates/CheckAntagonist/"choose quickly"/etc Yes/No messages
/atom/movable/screen/alert/notify_cloning
	name = "Revival"
	desc = "Someone is trying to revive you. Re-enter your corpse if you want to be revived!"
	icon_state = "template"
	timeout = 300

/atom/movable/screen/alert/notify_cloning/Click()
	if(!usr || !usr.client)
		return
	var/mob/dead/observer/G = usr
	G.reenter_corpse()

/atom/movable/screen/alert/notify_action
	name = "Body created"
	desc = "A body was created. You can enter it."
	icon_state = "template"
	timeout = 300
	var/atom/target = null
	var/action = NOTIFY_JUMP

/atom/movable/screen/alert/notify_action/Click()
	if(!usr || !usr.client)
		return
	if(!target)
		return
	var/mob/dead/observer/G = usr
	if(!istype(G))
		return
	switch(action)
		if(NOTIFY_ATTACK)
			target.attack_ghost(G)
		if(NOTIFY_JUMP)
			var/turf/T = get_turf(target)
			if(T && isturf(T))
				G.forceMove(T)
		if(NOTIFY_ORBIT)
			G.ManualFollow(target)

//OBJECT-BASED

/atom/movable/screen/alert/restrained/buckled
	name = "Buckled"
	desc = "You've been buckled to something. Click the alert to unbuckle unless you're handcuffed."
	icon_state = "buckled"

/atom/movable/screen/alert/restrained/handcuffed
	name = "Handcuffed"
	desc = "You're handcuffed and can't act. If anyone drags you, you won't be able to move. Click the alert to free yourself."
	click_master = FALSE

/atom/movable/screen/alert/restrained/legcuffed
	name = "Legcuffed"
	desc = "You're legcuffed, which slows you down considerably. Click the alert to free yourself."
	click_master = FALSE

/atom/movable/screen/alert/restrained/Click()
	var/mob/living/L = usr
	if(!istype(L) || !L.can_resist())
		return
	L.changeNext_move(CLICK_CD_RESIST)
	if((L.mobility_flags & MOBILITY_MOVE) && (L.last_special <= world.time))
		return L.resist_restraints()

/atom/movable/screen/alert/restrained/buckled/Click()
	var/mob/living/L = usr
	if(!istype(L) || !L.can_resist())
		return
	L.changeNext_move(CLICK_CD_RESIST)
	if(L.last_special <= world.time)
		return L.resist_buckle()

/atom/movable/screen/alert/revolution
	name = "Revolution"
	desc = "Soon the revolution will boil over. If need be, rally yourselves and make preparations for fighting."
	icon_state = "revolution"

// /atom/movable/screen/alert/revolution/MouseEntered(location,control,params)
// 	if(!istype(SSticker.mode, /datum/game_mode/revolution))
// 		return
// 	var/datum/game_mode/revolution/R = SSticker.mode
// 	if(!R.loud && R.go_fucking_loud_time)
// 		var/time_left = R.go_fucking_loud_time - world.time
// 		desc = "Soon the revolution will boil over. If need be, rally yourselves and make preparations for fighting.<br>
// 			We will be discovered in [time_left / (1 MINUTES)] minutes if we sit idly.<br>
// 			If we eliminate all of the Command personnel, we will also be detected."
// 	else if(R.loud)
// 		desc = "The revolution has boiled over. Fight for your life and the life of your allies."
// 	..()

// PRIVATE = only edit, use, or override these if you're editing the system as a whole

// Re-render all alerts - also called in /datum/hud/show_hud() because it's needed there
/datum/hud/proc/reorganize_alerts()
	var/list/alerts = mymob.alerts
	if(!hud_shown)
		for(var/i = 1, i <= alerts.len, i++)
			mymob.client.screen -= alerts[alerts[i]]
		return 1
	for(var/i = 1, i <= alerts.len, i++)
		var/atom/movable/screen/alert/alert = alerts[alerts[i]]
		if(alert.icon_state == "template")
			alert.icon = ui_style
		switch(i)
			if(1)
				. = ui_alert1
			if(2)
				. = ui_alert2
			if(3)
				. = ui_alert3
			if(4)
				. = ui_alert4
			if(5)
				. = ui_alert5 // Right now there's 5 slots
			else
				. = ""
		alert.screen_loc = .
		mymob?.client?.screen |= alert
	return 1

/atom/movable/screen/alert/Click(location, control, params)
	if(!usr || !usr.client)
		return
	var/paramslist = params2list(params)
	if(paramslist["shift"]) // screen objects don't do the normal Click() stuff so we'll cheat
		to_chat(usr, "[span_boldnotice("[name]")] - [span_info("[desc]")]")
		return
	var/datum/our_master = master_ref?.resolve()
	if(our_master && click_master)
		return usr.client.Click(our_master, location, control, params)

/atom/movable/screen/alert/Destroy()
	. = ..()
	severity = 0
	master_ref = null
	mob_viewer = null
	screen_loc = ""

/atom/movable/screen/alert/psiblock
	name = "Psiblock"
	desc = "You have pushed your psionic powers beyond your capabilities and need time to recover."
	icon_state = "shadow_mend"
