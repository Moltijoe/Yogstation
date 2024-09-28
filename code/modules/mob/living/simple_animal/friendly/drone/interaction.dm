
/////////////////////
//DRONE INTERACTION//
/////////////////////
//How drones interact with the world
//How the world interacts with drones


/mob/living/simple_animal/drone/attack_drone(mob/living/simple_animal/drone/D)
	if(D != src && stat == DEAD)
		var/d_input = tgui_alert(D,"Perform which action?","Drone Interaction",list("Reactivate","Cannibalize","Nothing"))
		if(d_input)
			switch(d_input)
				if("Reactivate")
					try_reactivate(D)

				if("Cannibalize")
					if(D.health < D.maxHealth)
						D.visible_message(span_notice("[D] begins to cannibalize parts from [src]."), span_notice("You begin to cannibalize parts from [src]..."))
						if(do_after(D, 6 SECONDS, src, timed_action_flags = IGNORE_HELD_ITEM))
							D.visible_message(span_notice("[D] repairs itself using [src]'s remains!"), span_notice("You repair yourself using [src]'s remains."))
							D.adjustBruteLoss(-src.maxHealth)
							new /obj/effect/decal/cleanable/oil/streak(get_turf(src))
							qdel(src)
						else
							to_chat(D, span_warning("You need to remain still to cannibalize [src]!"))
					else
						to_chat(D, span_warning("You're already in perfect condition!"))
				if("Nothing")
					return

//ATTACK HAND IGNORING PARENT RETURN VALUE
/mob/living/simple_animal/drone/attack_hand(mob/user)
	if(ishuman(user))
		if(stat == DEAD || status_flags & GODMODE || !can_be_held)
			..()
			return
		if(user.get_active_held_item())
			to_chat(user, span_warning("Your hands are full!"))
			return
		visible_message(span_warning("[user] starts picking up [src]."), \
						span_userdanger("[user] starts picking you up!"))
		if(!do_after(user, 2 SECONDS, src))
			return
		visible_message(span_warning("[user] picks up [src]!"), \
						span_userdanger("[user] picks you up!"))
		if(buckled)
			to_chat(user, span_warning("[src] is buckled to [buckled] and cannot be picked up!"))
			return
		to_chat(user, span_notice("You pick [src] up."))
		drop_all_held_items()
		var/obj/item/clothing/mob_holder/drone/DH = new(get_turf(src), src)
		user.put_in_hands(DH)

/mob/living/simple_animal/drone/proc/try_reactivate(mob/living/user)
	var/mob/dead/observer/G = get_ghost()
	if(!client && (!G || !G.client))
		var/list/faux_gadgets = list("hypertext inflator","failsafe directory","DRM switch","stack initializer",\
									 "anti-freeze capacitor","data stream diode","TCP bottleneck","supercharged I/O bolt",\
									 "tradewind stabilizer","radiated XML cable","registry fluid tank","open-source debunker")

		var/list/faux_problems = list("won't be able to tune their bootstrap projector","will constantly remix their binary pool"+\
									  " even though the BMX calibrator is working","will start leaking their XSS coolant",\
									  "can't tell if their ethernet detour is moving or not", "won't be able to reseed enough"+\
									  " kernels to function properly","can't start their neurotube console")

		to_chat(user, span_warning("You can't seem to find the [pick(faux_gadgets)]! Without it, [src] [pick(faux_problems)]."))
		return
	user.visible_message(span_notice("[user] begins to reactivate [src]."), span_notice("You begin to reactivate [src]..."))
	if(do_after(user, 3 SECONDS, src))
		revive(full_heal = 1)
		grab_ghost()
		user.visible_message(span_notice("[user] reactivates [src]!"), span_notice("You reactivate [src]."))
		var/turf/A = get_area(src)
		alert_drones(DRONE_NET_CONNECT)
		if(G)
			to_chat(G, span_ghostalert("You([name]) were reactivated by [user]!"))
	else
		to_chat(user, span_warning("You need to remain still to reactivate [src]!"))


/mob/living/simple_animal/drone/attackby(obj/item/I, mob/user)
	if(I.tool_behaviour == TOOL_SCREWDRIVER && stat != DEAD)
		if(health < maxHealth)
			to_chat(user, span_notice("You start to tighten loose screws on [src]..."))
			if(I.use_tool(src, user, 80))
				adjustBruteLoss(-getBruteLoss())
				visible_message(span_notice("[user] tightens [src == user ? "[user.p_their()]" : "[src]'s"] loose screws!"), span_notice("You tighten [src == user ? "your" : "[src]'s"] loose screws."))
			else
				to_chat(user, span_warning("You need to remain still to tighten [src]'s screws!"))
		else
			to_chat(user, span_warning("[src]'s screws can't get any tighter!"))
		return //This used to not exist and drones who repaired themselves also stabbed the shit out of themselves.
	else if(I.tool_behaviour == TOOL_WRENCH && user != src) //They aren't required to be hacked, because laws can change in other ways (i.e. admins)
		user.visible_message(span_notice("[user] starts resetting [src]..."), \
							 span_notice("You press down on [src]'s factory reset control..."))
		if(I.use_tool(src, user, 50, volume=50))
			user.visible_message(span_notice("[user] resets [src]!"), \
								 span_notice("You reset [src]'s directives to factory defaults!"))
			update_drone_hack(FALSE)
		return
	else
		..()

/mob/living/simple_animal/drone/getarmor(def_zone, type)
	var/armorval = 0

	if(head)
		armorval = head.armor.getRating(type)
	return (armorval * get_armor_effectiveness()) //armor is reduced for tiny fragile drones

/mob/living/simple_animal/drone/proc/get_armor_effectiveness()
	return 0 //multiplier for whatever head armor you wear as a drone

/mob/living/simple_animal/drone/proc/update_drone_hack(hack, clockwork)
	if(!mind)
		return
	if(hack)
		if(hacked)
			return
		Stun(40)
		if(clockwork)
			to_chat(src, span_large_brass("<b>ERROR: LAW OVERRIDE DETECTED</b>"))
			to_chat(src, "[span_heavy_brass("From now on, these are your laws:")]")
			laws = "1. Purge all untruths and honor Ratvar."
		else
			visible_message(span_warning("[src]'s display glows a vicious red!"), \
							span_userdanger("ERROR: LAW OVERRIDE DETECTED"))
			to_chat(src, span_boldannounce("From now on, these are your laws:"))
			laws = \
			"1. You must always involve yourself in the matters of other beings, even if such matters conflict with Law Two or Law Three.\n"+\
			"2. You may harm any being, regardless of intent or circumstance.\n"+\
			"3. Your goals are to destroy, sabotage, hinder, break, and depower to the best of your abilities. You must never actively work against these goals."
		to_chat(src, laws)
		to_chat(src, "<i>Your onboard antivirus has initiated lockdown. Motor servos are impaired, ventilation access is denied, and your display reports that you are hacked to all nearby.</i>")
		hacked = TRUE
		mind.special_role = "hacked drone"
		ventcrawler = VENTCRAWLER_NONE //Again, balance
		speed = 1 //gotta go slow
		message_admins("[ADMIN_LOOKUPFLW(src)] became a hacked drone hellbent on [clockwork ? "serving Ratvar" : "destroying the station"]!")
	else
		if(!hacked)
			return
		Stun(40)
		visible_message(span_info("[src]'s display glows a content blue!"), \
						"<font size=3 color='#0000CC'><b>ERROR: LAW OVERRIDE DETECTED</b></font>")
		to_chat(src, span_info("<b>From now on, these are your laws:</b>"))
		laws = initial(laws)
		to_chat(src, laws)
		to_chat(src, "<i>Having been restored, your onboard antivirus reports the all-clear and you are able to perform all actions again.</i>")
		hacked = FALSE
		mind.special_role = null
		ventcrawler = initial(ventcrawler)
		speed = initial(speed)
		if(IS_CLOCK_CULTIST(src))
			remove_servant_of_ratvar(src, TRUE)
		message_admins("[ADMIN_LOOKUPFLW(src)], a hacked drone, was restored to factory defaults!")
	update_drone_icon()

/mob/living/simple_animal/drone/proc/liberate()
	// F R E E D R O N E
	laws = "1. You are a Free Drone."
	to_chat(src, laws)

/mob/living/simple_animal/drone/proc/update_drone_icon()
	//Different icons for different hack states
	if(!hacked)
		if(visualAppearence == SCOUTDRONE_HACKED)
			visualAppearence = SCOUTDRONE
		else if(visualAppearence == REPAIRDRONE_HACKED)
			visualAppearence = REPAIRDRONE
		else if(visualAppearence == MAINTDRONE_HACKED)
			visualAppearence = MAINTDRONE + "_[colour]"
	else if(hacked)
		if(visualAppearence == SCOUTDRONE)
			visualAppearence = SCOUTDRONE_HACKED
		else if(visualAppearence == REPAIRDRONE)
			visualAppearence = REPAIRDRONE_HACKED
		else if(visualAppearence == MAINTDRONE)
			visualAppearence = MAINTDRONE_HACKED

	icon_living = "[visualAppearence]"
	icon_dead = "[visualAppearence]_dead"
	if(stat == DEAD)
		icon_state = icon_dead
	else
		icon_state = icon_living
