local party = {}
local mod_storage = minetest.get_mod_storage()
local player_list = {}

-- maintain a full player list
for _, player in next, minetest.get_dir_list(minetest.get_worldpath().."/players", false) do
		player_list[#player_list+1] = player
end
table.sort(player_list)
minetest.register_on_newplayer(function(ObjectRef)
	player_list[#player_list+1] = ObjectRef:get_player_name()
	table.sort(player_list)
end)

-- group notice
party.send_notice_all = function(name, message)
	for _,players in ipairs(minetest.get_connected_players()) do
		local names = players:get_player_name()
		if mod_storage:get_string(name.."_party") == mod_storage:get_string(names.."_party") then
			minetest.chat_send_player(names, minetest.colorize("green", "[Party] = PARTY-NOTICE = ")..""..message)
		end
	end
end

-- private notice
party.send_notice = function(name, message)
	minetest.chat_send_player(name, minetest.colorize("green", "[Party] = NOTICE = ")..""..message)
end

-- check if player is in a party [1], officer or leader [2], leader [3]
-- if not then return true
party.check = function(name, level)
	local player = minetest.get_player_by_name(name)
	local cparty = mod_storage:get_string(name.."_party")
	if level == 1 and cparty == (nil or "") then
		party.send_notice(name, "You are not in a party!")
		return true
	elseif level == 2 then
		if cparty == (nil or "") then
			party.send_notice(name, "You are not in a party!")
			return true
		
		elseif cparty ~= (nil or "") then
			local cparty_l = mod_storage:get_string(name.."_leader")
			local cparty_o = mod_storage:get_string(name.."_officer")
			if cparty_o == (nil or "") and cparty_l == (nil or "") then
				party.send_notice(name, "Not authorized to use this command! You are neither the party leader nor an officer of this party!")
				return true
			end
		end
	elseif level == 3 then
		local cparty_l = mod_storage:get_string(name.."_leader")
		if cparty == (nil or "") then
			party.send_notice(name, "You are not in a party!")
			return true
		elseif cparty ~= (nil or "") and cparty_l == (nil or "") then
			party.send_notice(name, "Not authorized to use this command! You are not the party leader!")
			return true
		end
	else
		return false
	end
end

-- check if party name exists
-- if it exists, return true
party.check_tag = function(name, tag)
	for _,playernames in ipairs(player_list) do
		if tag == mod_storage:get_string(playernames.."_leader") then
			return true
		end
	end
end

party.join = function(name, partyname)
	local cparty_l = mod_storage:get_string(partyname.."_leader")
	local player = minetest.get_player_by_name(name)
	mod_storage:set_string(name.."_party", partyname)
	player:set_attribute("partyinvite", nil)
	player:set_attribute("partypending", nil)
	player:set_nametag_attributes({text = "["..cparty_l.."] "..name})
	party.send_notice_all(name, name.." has joined "..partyname.."'s party ["..cparty_l.."].")
end


minetest.register_chatcommand("party", {
	description = "Create and join a party",
	
	func = function(name, param)
	
		local paramlist = {}
		local index = 1
		for param_split in param:gmatch("%S+") do
			paramlist[index] = param_split
			index = index + 1
		end

		local param1 = paramlist[1]
		local param2 = paramlist[2]
		local player = minetest.get_player_by_name(name)
		local cparty = mod_storage:get_string(name.."_party")
		local cparty_o = mod_storage:get_string(name.."_officer")
		
		if param1 == "help" then
			party.send_notice(name, "/party --- List your current party")
			party.send_notice(name, "/party list --- List online members of your party")
			party.send_notice(name, "/party list all --- List all members of your party")
			party.send_notice(name, "/party list <playername> --- List party of player")
			party.send_notice(name, "/party leave --- Leave your party")
			party.send_notice(name, "/party create <partyname> --- Create a party")
			party.send_notice(name, "/party join <partyname> --- Join a party")
			party.send_notice(name, "/party invite <yes/no> --- Accept/ reject a party invite")
			party.send_notice(name, "/party noinvite --- Reject all parties invites automatically")
			
			party.send_notice(name, " OFFICERS/ LEADER COMMANDS:")
			party.send_notice(name, "/party kick <playername> --- Kick a player out of your party")
			party.send_notice(name, "/party invite <playername> --- Invite a player to join your party")
			party.send_notice(name, "/party <accept/reject> <playername> --- Accept/ reject a join request (if joining method is set to [Request Mode])")

			party.send_notice(name, " LEADER-ONLY COMMANDS:")
			party.send_notice(name, "/party disband --- Disband your party")
			party.send_notice(name, "/party rename <new_partyname> --- Rename your party")
			party.send_notice(name, "/party officer <playername> --- Promote a player to officer. Officers can kick & invite.")
			party.send_notice(name, "/party lock <open/active/request/private> --- Change joining method for your party")
			
			-- TODO
			-- party.send_notice(name, "/party colour <colour> --- Change party colour in nametags/chat")
			-- formspecs equivalents
			-- Replace /all with a simpler method
			
		elseif param1 == nil then
			if party.check(name, 1) == true then
				return
			end
			local cparty_l = mod_storage:get_string(cparty.."_leader")
			party.send_notice(name, "You are currently in "..cparty.."'s party ["..cparty_l.."].")
			
		elseif param1 == "list" then			
			if param2 == "all" then
				if party.check(name, 1) == true then
					return
				end

				local listnames = ""
				local cparty_l = mod_storage:get_string(cparty.."_leader")
				party.send_notice(name, "Full member list of "..cparty.."'s party ["..cparty_l.."]:")
				for _,playernames in ipairs(player_list) do
					if cparty == mod_storage:get_string(playernames.."_party") then
						listnames = listnames .. playernames .. ", "
					end
				end
				party.send_notice(name, listnames)
			elseif param2 == "officer" then
				if party.check(name, 1) == true then
					return
				end

				local listnames = ""
				local cparty_l = mod_storage:get_string(cparty.."_leader")
				party.send_notice(name, "List of "..cparty.."'s party ["..cparty_l.."] officers:")
				for _,playernames in ipairs(player_list) do
					if cparty == mod_storage:get_string(playernames.."_party") then
						if mod_storage:get_string(playernames.."_officer") ~= (nil or "") or mod_storage:get_string(playernames.."_leader") ~= (nil or "") then
							listnames = listnames .. playernames .. ", "
						end
					end
				end
				party.send_notice(name, listnames)
			elseif param2 == nil then
				if party.check(name, 1) == true then
					return
				end

				local listnames = ""
				local cparty_l = mod_storage:get_string(cparty.."_leader")
				party.send_notice(name, "Online member list of "..cparty.."'s party ["..cparty_l.."]:")
				for _,players in ipairs(minetest.get_connected_players()) do
					local playernames = players:get_player_name()
					if cparty == mod_storage:get_string(playernames.."_party") then
						listnames = listnames .. playernames .. ", "
					end
				end
				party.send_notice(name, listnames)
			elseif param2 ~= nil then
				if minetest.player_exists(param2) then
					local cparty = mod_storage:get_string(param2.."_party")
					if cparty ~= (nil or "") then
						local cparty_l = mod_storage:get_string(cparty.."_leader")
						if cparty_l ~= (nil or "") then
							party.send_notice(name, param2.." is currently in "..cparty.."'s party ["..cparty_l.."].")
						elseif cparty == ("@" or "#") then
							party.send_notice(name, param2.." is currently not in any party.")
						local cparty_l = mod_storage:get_string(param2.."_leader")
						elseif cparty_l ~= (nil or "") then
							party.send_notice(name, param2.." is currently the leader of "..param2.."'s party ["..cparty_l.."].")
						end
					else party.send_notice(name, param2.." is currently not in any party.")
					end
				else party.send_notice(name, "Player does not exist!")
				end
			end
			
		
		elseif param1 == "leave" then
			if party.check(name, 1) == true then
				return
			end
			local cparty_l = mod_storage:get_string(cparty.."_leader")
			if mod_storage:get_string(name.."_leader") == (nil or "") then
				party.send_notice_all(name, name.." left "..cparty.."'s party ["..cparty_l.."].")
				-- clear storage and effects
				mod_storage:set_string(name.."_party", nil)
				mod_storage:set_string(name.."_officer", nil)
				player:set_nametag_attributes({text = name})
			else party.send_notice(name, "You cannot leave your own party! Use /party disband instead.")
			end
		
		elseif param1 == "create" and param2 ~= nil then
			if string.len(param2) > 8 then
				party.send_notice(name, "Nametag is too long! 8 is the maximum amount of characters")
				return
			end
			
			-- check if tag exists
			if party.check_tag(name, param2) == true then
				party.send_notice(name, "Party name selected already exists. Please choose another one.")
				return
			end
			
			
			if cparty == (nil or "") then
				mod_storage:set_string(name.."_party", name)
				mod_storage:set_string(name.."_leader", param2)
				player:set_attribute("partyinvite", nil)
				player:set_nametag_attributes({text = "["..param2.."] "..name})
				
				party.send_notice(name, "You created "..name.."'s party ["..param2.."].")
			else
				local cparty_l = mod_storage:get_string(cparty.."_leader")
				party.send_notice(name, "You are already in "..cparty.."'s party ["..cparty_l.."].")
			end
		
		-- /party join
		elseif param1 == "join" and param2 ~= nil then
			if cparty ~= (nil or "") then
				local cparty_l = mod_storage:get_string(cparty.."_leader")
				party.send_notice(name, "You are already in "..cparty.."'s party ["..cparty_l.."].")
				return
			end
			
			if party.check_tag(name, param2) == true then
				local leadername = ""
				for _,playernames in ipairs(player_list) do
					if param2 == mod_storage:get_string(playernames.."_leader") then
						leadername = leadername .. playernames
					end
				end
				local cparty = leadername
				local party_m = mod_storage:get_string(cparty.."_lock")
				-- active mode, only allow if leader is active
				if party_m == "active" then
					if minetest.get_player_by_name(cparty) == nil then
						party.send_notice(name, "Party leader is offline, try again when the party leader is online!")
					else party.join(name, cparty)
					end
				-- request mode, sends a request if officer/leader are online
				elseif party_m == "request" then
					if player:get_attribute("partypending") ~= nil then
						party.send_notice(name, "You have already requested to join another party. Only one join request is allowed to prevent spamming.")
						party.send_notice(name, "Please rejoin the game if you want to make an different request.")
						return
					end
					for _,players in ipairs(minetest.get_connected_players()) do
						local names = players:get_player_name()
						if cparty == mod_storage:get_string(names.."_party") then
							if mod_storage:get_string(names.."_officer") ~= (nil or "") or mod_storage:get_string(names.."_leader") ~= (nil or "") then
								local off_names = players:get_player_name()
								party.send_notice(off_names, name.." has requested to join the party. Use '/party accept <playername>' to accept, '/party reject <playername>' to reject.")
							end
						end
					end
					party.send_notice(name, "Your request to join "..cparty.."'s party ["..param2.."] has been sent.")
					party.send_notice(name, "Pending approval from an officer/leader. If you do not receive a reply soon, it is likely there's no one online to review your request.")
					party.send_notice(name, "Please do not leave the game, your join request will be rendered void if you do so.")
					player:set_attribute("partypending", cparty)
				-- private mode, denies all requests
				elseif party_m == "private" then
					party.send_notice(name, "Party is private! Public join requests are denied!")
				-- public mode, accept all requests
				else party.join(name, cparty)
				end
				
			else party.send_notice(name, "Party does not exist!")
			end
			
		-- /party noinvite
		elseif param1 == "noinvite" then
			if cparty == (nil or "") then
				if player:get_attribute("partynoinvite") == "true" then
					player:set_attribute("partynoinvite", nil)
					party.send_notice(name, "You have disabled noinvite - You will now receive party invites.")
				elseif player:get_attribute("partynoinvite") == nil then
					player:set_attribute("partyinvite", nil)
					player:set_attribute("partynoinvite", "true")
					party.send_notice(name, "You have enabled noinvite - You will now NOT receive party invites.")
				end
			else party.send_notice(name, "You are already in a party! Invites wouldn't be received when you are in a party!")
			end
			
		-- /party disband
		elseif param1 == "disband" then
			if party.check(name, 3) == true then
				return
			end
			if cparty == name then
				party.send_notice_all(name, name.."'s party ["..mod_storage:get_string(name.."_leader").."] has been disbanded.")
				-- remove online players
				for _,players in ipairs(minetest.get_connected_players()) do
					local names = players:get_player_name()
					if mod_storage:get_string(names.."_party") == cparty then
						players:set_nametag_attributes({text = names})
						mod_storage:set_string(names.."_party", nil)
						mod_storage:set_string(names.."_officer", nil)
					end
				end
				-- mark offline players so they would be notified when they login
				for _,playernames in ipairs(player_list) do
					if minetest.get_player_by_name(playernames) == nil then
						if mod_storage:get_string(playernames.."_party") == cparty then
							mod_storage:set_string(playernames.."_party", "@")
						end
					end
				end
				
				-- remove leader's powers
				mod_storage:set_string(name.."_party", nil)
				mod_storage:set_string(name.."_leader", nil)
				mod_storage:set_string(name.."_lock", nil)
				player:set_nametag_attributes({text = names})
			end
		
		elseif param1 == "rename" and param2 ~= nil then
			if party.check(name, 3) == true then
				return
			end
			-- check if new name is too long
			if string.len(param2) > 8 then
				party.send_notice(name, "Nametag is too long! 8 is the maximum amount of characters")
				return
			end
			if party.check_tag(name, param2) == true then
				return
			end
			-- if not, apply rename
			mod_storage:set_string(name.."_leader", param2)
			party.send_notice_all(name, name.." renamed the party tag to ["..param2.."].")
			
			-- update online player nametags
			for _,players in ipairs(minetest.get_connected_players()) do
				local names = players:get_player_name()
				if mod_storage:get_string(names.."_party") == cparty then
					players:set_nametag_attributes({text = "["..param2.."] "..names})
				end
			end
		
		elseif param1 == "lock" then
			if party.check(name, 3) == true then
				return
			end
			
			local cparty_l = mod_storage:get_string(name.."_leader")
			if param2 == "active" then
				mod_storage:set_string(name.."_lock", param2)
				party.send_notice_all(name, "[Active mode] Public joining (Only if leader is online) is enabled for "..name.."'s party ["..cparty_l.."].")
			elseif param2 == "request" then
				mod_storage:set_string(name.."_lock", param2)
				party.send_notice_all(name, "[Request mode] Join requests is enabled for "..name.."'s party ["..cparty_l.."].")
			elseif param2 == "private" then
				mod_storage:set_string(name.."_lock", param2)
				party.send_notice_all(name, "[Private mode] Joining is disabled for "..name.."'s party ["..cparty_l.."].")
			elseif param2 == "open" then
				mod_storage:set_string(name.."_lock", param2)
				party.send_notice_all(name, "[Public mode] Public joining is enabled for "..name.."'s party ["..cparty_l.."].")
			end
		
		-- /party officer
		elseif param1 == "officer" and param2 ~= nil then
			if party.check(name, 3) == true then
				return
			end
			
			local cparty_l = mod_storage:get_string(name.."_leader")
			if minetest.player_exists(param2) then
			
				local target_party = mod_storage:get_string(param2.."_party")
				
				-- if player is not in same party
				if target_party ~= cparty then
					party.send_notice(name, "Player "..param2.." does not exist or is not in your party! Case sensitive.")
					return
				-- if player is in same party then promote/demote accordingly
				elseif target_party == cparty then
					local target_status = mod_storage:get_string(param2.."_officer")
					if target_status == (nil or "") then
						mod_storage:set_string(param2.."_officer", "true")
						party.send_notice_all(name, param2.." has been promoted to an officer!")
					elseif target_status ~= (nil or "") then
						mod_storage:set_string(param2.."_officer", nil)
						party.send_notice_all(name, param2.." has been demoted to a member.")
					end
				end
				
			else party.send_notice(name, "Player "..param2.." does not exist! Case sensitive.")
			end
			
		-- /party kick
		elseif param1 == "kick"	and param2 ~= nil then
			if party.check(name, 2) == true then
				return
			end
			if minetest.player_exists(param2) then
				local cparty = mod_storage:get_string(param2.."_party")
				local self_cparty = mod_storage:get_string(name.."_party")
				-- attempt to kick self
				if param2 == name then
					party.send_notice(name, "You can't kick yourself!")
					return
				-- attempt to kick someone not from your party
				elseif self_cparty ~= cparty then
					party.send_notice(name, "Player "..param2.." does not exist or is not in your party! Case sensitive.")
					return
				-- attempt to kick leader
				elseif param2 == cparty then
					party.send_notice(name, "You can't kick the leader!")
					party.send_notice_all(name, name.." attempted to kick the leader.")
					return
				-- attempt to kick fellow officer (if officer too)
				elseif mod_storage:get_string(name.."_officer") ~= ("" or nil) and mod_storage:get_string(param2.."_officer") ~= ("" or nil) then
					party.send_notice(name, "You can't kick a fellow officer!")
					party.send_notice_all(name, name.." attempted to kick a fellow officer.")
					return
				end
				
				-- kicking offline player, give a mark to notify player when he logins
				if minetest.get_player_by_name(param2) == nil then
					if mod_storage:get_string(param2) == name then
						party.send_notice_all(name, param2.."[offline] was kicked from "..cparty.."'s party ["..mod_storage:get_string(cparty.."_leader").."].")
						mod_storage:set_string(param2.."_party", "#")
					end
					return
				end
				
				-- kicking online player
				if minetest.get_player_by_name(param2) ~= nil then
					party.send_notice_all(name, param2.." was kicked from "..cparty.."'s party ["..mod_storage:get_string(cparty.."_leader").."].")
					local kplayer = minetest.get_player_by_name(param2)
					kplayer:set_nametag_attributes({text = param2})
					mod_storage:set_string(param2.."_party", nil)
					mod_storage:set_string(param2.."_officer", nil)
					kplayer:set_nametag_attributes({text = param2})
				end
			
			-- if player doesn't exist
			else party.send_notice(name, "Player "..param2.." does not exist! Case sensitive.")
			end
			
		-- Accept/reject join request
		elseif (param1 == "accept" or param1 == "reject") and param2 ~= nil then
			if party.check(name, 2) == true then
				return
			end
			
			if minetest.player_exists(param2) then
				-- Reject if player is not online
				if minetest.get_player_by_name(param2) == nil then
					party.send_notice(name, "Player "..param2.." is not online right now.")
					return
				end
			
				local target_party = mod_storage:get_string(param2.."_party")
				-- Reject if player did not request to join the party
				if minetest.get_player_by_name(param2):get_attribute("partypending") ~= cparty then
					party.send_notice(name, "Player "..param2.." did not request to join the party!")
					return
				-- Reject if player is already in a party
				elseif target_party ~= (nil or "") then
					party.send_notice(name, "Player "..param2.." is already in a party!")
					return
				end
			
				local t_player = minetest.get_player_by_name(param2)
				local cparty_l = mod_storage:get_string(cparty.."_leader")
				if param1 == "accept" then
					t_player:set_attribute("partypending", nil)
					party.send_notice(param2, "Your request to join "..cparty.." ["..cparty_l.."] has been accepted!")
					party.join(param2, cparty)
				elseif param1 == "reject" then
					t_player:set_attribute("partypending", nil)
					party.send_notice(param2, "Your request to join "..cparty.." ["..cparty_l.."] was denied.")
					party.send_notice(name, "You have denied "..param2.."'s request.")
				end
			
			else party.send_notice(name, "Player "..param2.." does not exist!")
			end
		
		elseif param1 == "invite" then
			if cparty ~= (nil or "") then
				if party.check(name, 2) == true then
					return
				end
				if minetest.player_exists(param2) then
					-- reject if player is not online
					local target_party = mod_storage:get_string(param2.."_party")
					local t_player = minetest.get_player_by_name(param2)
					if minetest.get_player_by_name(param2) == nil then
						party.send_notice(name, "Player is not online!")
						return
					-- reject if player is already in a party
					elseif target_party ~= (nil or "") then
						party.send_notice(name, "Player is already in a party!")
						return
					-- reject if player disabled invites
					elseif t_player:get_attribute("partynoinvite") == "true" then
						party.send_notice(name, "Player has disabled invites!")
						return
					end
					
					local cparty_l = mod_storage:get_string(cparty.."_leader")
					t_player:set_attribute("partyinvite", name)
					party.send_notice(param2, name.." has invited you to "..cparty.."'s party ["..cparty_l.."]! '/party invite yes' to accept or '/party invite no' to decline.")
					party.send_notice(name, "You have invited "..param2.." to your party. Awaiting for their response.")
				
				-- player does not exist
				else party.send_notice(name, "Player "..param2.." does not exist! Case sensitive.")
				end
			elseif cparty == (nil or "") and param2 == "no" then
				if player:get_attribute("partyinvite") ~= nil then
					local iname = player:get_attribute("partyinvite")
					local iparty = mod_storage:get_string(iname.."_party")
					local iparty_l = mod_storage:get_string(iparty.."_leader")
					player:set_attribute("partyinvite", nil)
					party.send_notice(name, "You have rejected "..iname.."'s invite to join "..iparty.."'s party ["..iparty_l.."].")
					
					-- if player that sent request is online, send him a message.
					if minetest.get_player_by_name(iname) ~= nil then
						party.send_notice(iname, name.." has denied your invite request.")
					end
				else party.send_notice(name, "You have not received an invite!")
				end
			elseif cparty == (nil or "") and param2 == "yes" then
				if player:get_attribute("partyinvite") ~= nil then					
					local iname = player:get_attribute("partyinvite")
					local iparty = mod_storage:get_string(iname.."_party")
					local iparty_l = mod_storage:get_string(iparty.."_leader")
					
					-- if player that sent request is online, send him a message.
					if minetest.get_player_by_name(iparty) ~= nil then
						party.send_notice(iname, name.." has accepted your invite request.")
					end
					player:set_attribute("partyinvite", nil)
					party.join(name, iparty)
					
				else party.send_notice(name, "You have not received an invite!")
				end
			else party.send_notice(name, "You are not in a party!")
			end
		
		
		else party.send_notice(name, "ERROR: Command is invalid! For help, use the command '/party help'")
		end
		
	end,
})

minetest.register_chatcommand("all", {
	description = "Chat on main chat",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local cparty = mod_storage:get_string(name.."_party")
		if cparty == (nil or "") then
			party.send_notice(name, "You are not in a party! You can talk normally to main chat without commands.")
		else
			local cparty_l = mod_storage:get_string(cparty.."_leader")
			for _,players in ipairs(minetest.get_connected_players()) do
				local names = players:get_player_name()
				minetest.chat_send_player(names, "<Party:"..cparty_l.." | "..name.."> "..param)
			end
		end
	end,
})


minetest.register_on_chat_message(function(name, message)
	local player = minetest.get_player_by_name(name)
	local cparty = mod_storage:get_string(name.."_party")
	for _,players in ipairs(minetest.get_connected_players()) do
		local names = players:get_player_name()
		if cparty ~= (nil or "") and cparty == mod_storage:get_string(names.."_party") then
			minetest.chat_send_player(names, minetest.colorize("green", "[Party] ").."<"..name.."> " ..message)
		end
	end
	for _,players in ipairs(minetest.get_connected_players()) do
		local names = players:get_player_name()
		if cparty == (nil or "") then
			minetest.chat_send_player(names, "<"..name.."> " ..message)
		end
	end
	return true
end)

minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
	if player and hitter then
		local playername = player:get_player_name()
		local hittername = hitter:get_player_name()
		local p_party = mod_storage:get_string(playername.."_party")
		local h_party = mod_storage:get_string(hittername.."_party")
		if p_party ~= (nil or "") and p_party == h_party then
			party.send_notice(hitter:get_player_name(), player:get_player_name().." is in your party!")
			return true
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local cparty = mod_storage:get_string(name.."_party")
	-- delete invite/join request status when player join, just in case.
	player:set_attribute("partypending", nil)
	player:set_attribute("partyinvite", nil)
	
	-- clear all stats (just in case) if player get kick / party is disbanded / data is corrupted
	if cparty == "@" then
		party.send_notice(name, "While you were away, "..cparty.."'s party has disbanded!")
		mod_storage:set_string(name.."_party", nil)
		mod_storage:set_string(name.."_officer", nil)
		mod_storage:set_string(name.."_leader", nil)
		mod_storage:set_string(name.."_lock", nil)
	elseif cparty == "#" then
		local cparty_l = mod_storage:get_string(cparty.."_leader")
		party.send_notice(name, "While you were away, you were kicked from "..cparty.."'s party ["..cparty_l.."]!")
		mod_storage:set_string(name.."_party", nil)
		mod_storage:set_string(name.."_officer", nil)
		mod_storage:set_string(name.."_leader", nil)
		mod_storage:set_string(name.."_lock", nil)
	elseif cparty ~= (nil or "") then
		local cparty_l = mod_storage:get_string(cparty.."_leader")
		if cparty_l == (nil or "") then
			party.send_notice(name, "ERROR: Unable to load your party's name.")
			party.send_notice(name, "ERROR: While you are away, you were either kicked or the party disbanded and was recreated.")
			party.send_notice(name, "ERROR: Otherwise something became corrupted :/")
			party.send_notice(name, "ERROR: Your party info has been reset.")
			mod_storage:set_string(name.."_party", nil)
			mod_storage:set_string(name.."_officer", nil)
			mod_storage:set_string(name.."_leader", nil)
			mod_storage:set_string(name.."_lock", nil)
			return
		else
			player:set_nametag_attributes({text = "["..cparty_l.."] "..name})
		end
	end
end)


minetest.register_on_leaveplayer(function(player)
	-- delete invite/join request status when player leaves
	player:set_attribute("partypending", nil)
	player:set_attribute("partyinvite", nil)
end)