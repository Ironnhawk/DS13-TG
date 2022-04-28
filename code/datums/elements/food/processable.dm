// If an item has the processable item, it can be processed into another item with a specific tool. This adds generic behavior for those actions to make it easier to set-up generically.
/datum/element/processable
	element_flags = ELEMENT_BESPOKE
	id_arg_index = 2
	///The type of atom this creates when the processing recipe is used.
	var/atom/result_atom_type
	///The tool behaviour for this processing recipe
	var/tool_behaviour
	///Time to process the atom
	var/time_to_process
	///Amount of the resulting actor this will create
	var/amount_created
	///Whether or not the atom being processed has to be on a table or tray to process it
	var/table_required

/datum/element/processable/Attach(datum/target, tool_behaviour, result_atom_type, amount_created = 3, time_to_process = 20, table_required = FALSE)
	. = ..()
	if(!isatom(target))
		return ELEMENT_INCOMPATIBLE

	src.tool_behaviour = tool_behaviour
	src.amount_created = amount_created
	src.time_to_process = time_to_process
	src.result_atom_type = result_atom_type
	src.table_required = table_required

	RegisterSignal(target, COMSIG_ATOM_TOOL_ACT(tool_behaviour), .proc/try_process)
	RegisterSignal(target, COMSIG_PARENT_EXAMINE, .proc/OnExamine)

/datum/element/processable/Detach(datum/target)
	. = ..()
	UnregisterSignal(target, list(COMSIG_ATOM_TOOL_ACT(tool_behaviour), COMSIG_PARENT_EXAMINE))

/datum/element/processable/proc/try_process(datum/source, mob/living/user, obj/item/I, list/mutable_recipes)
	SIGNAL_HANDLER

	if(table_required)
		var/obj/item/found_item = source
		var/found_location = found_item.loc
		var/found_turf = isturf(found_location)
		var/found_table = locate(/obj/structure/table) in found_location
		var/found_tray = locate(/obj/item/storage/bag/tray) in found_location
		if(!found_turf && !istype(found_location, /obj/item/storage/bag/tray) || found_turf && !(found_table || found_tray))
			to_chat(user, span_notice("You cannot make [initial(result_atom_type.name)] here! You need a table or at least a tray."))
			return

	mutable_recipes += list(list(TOOL_PROCESSING_RESULT = result_atom_type, TOOL_PROCESSING_AMOUNT = amount_created, TOOL_PROCESSING_TIME = time_to_process))

///So people know what the frick they're doing without reading from a wiki page (I mean they will inevitably but i'm trying to help, ok?)
/datum/element/processable/proc/OnExamine(atom/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	if(amount_created > 1)
		examine_list += span_notice("It can be turned into [amount_created] [initial(result_atom_type.name)]s with <b>[tool_behaviour_name(tool_behaviour)]</b>!")
	else
		examine_list += span_notice("It can be turned into \a [initial(result_atom_type.name)] with <b>[tool_behaviour_name(tool_behaviour)]</b>!")
