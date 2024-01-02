-- https://github.com/lnx00/Lua-Protobuf/blob/dc940e457f92143efabb648892b86a7d458a1c76/src/Protobuf.lua
local ProtoBuf = (function()
	local a={}local b={Varint=0,Fixed64=1,LengthDelimited=2,StartGroup=3,EndGroup=4,Fixed32=5}local function c(table,d)d=d or 0;for e,f in pairs(table)do if type(f)=="table"then print(string.rep(" ",d)..e.." = {")c(f,d+2)print(string.rep(" ",d).."}")elseif type(f)=="string"then print(string.rep(" ",d)..e.." = \""..f.."\"")else print(string.rep(" ",d)..e.." = "..f)end end end;local function g(h,i,f)local j=h[i]if j then if type(j)=="table"then table.insert(j,f)else h[i]={j,f}end else h[i]=f end end;local function k(l,m)local f,n=0,string.byte;f=n(l,m)|(n(l,m+1)<<8)|(n(l,m+2)<<16)|(n(l,m+3)<<24)return f end;local function o(l,m)local f,p=0,0;repeat local q=string.byte(l,m)f=f+q&0x7F<<p;p=p+7;m=m+1 until q<128;return f,m end;local function r(l,m)return k(l,m),m+4 end;local function s(l,m)local f=k(l,m)m=m+4;f=f|(k(l,m)<<32)m=m+4;return f,m end;local function t(l,m)local u=0;u,m=o(l,m)local f=string.sub(l,m,m+u-1)m=m+u;return f,m end;local function v(l,m)local w,i,x=0,0,0;local y={}local f=nil;while m<#l do w,m=o(l,m)i=w>>3;x=w&0x07;if x==b.Varint then f,m=o(l,m)g(y,i,f)elseif x==b.Fixed64 then f,m=s(l,m)g(y,i,f)elseif x==b.LengthDelimited then f,m=t(l,m)if string.byte(f,1)==0x0A then f=v(f,1)end;g(y,i,f)elseif x==b.StartGroup then m=m+1 elseif x==b.EndGroup then m=m+1 elseif x==b.Fixed32 then f,m=r(l,m)g(y,i,f)else print("Unknown wire type: "..x)break end end;return y end;function a.Decode(l,m)m=m or 1;return v(l,m)end;function a.Dump(l)local z={}for A=1,#l do local q=string.byte(l,A)z[A]=string.format("%02X",q)end;print(table.concat(z," "))end;return a
end)()


local w, h = draw.GetScreenSize()
local config = {
	x = 30, -- 1280x1024 is perfect for this other res not sure
	y = h / 2.2,
	font = draw.CreateFont("Verdana", 24, 400),
	joinKey = E_ButtonCode.KEY_J,
}

local gc = gamecoordinator
local allowAcceptMatchInvite = false
local timer = nil
local join = nil

local function formatTime(t)
	local min = math.floor(t / 60)
	local sec = math.floor(t % 60)

	return string.format("%d:%02d", min, sec)
end

callbacks.Unregister("GCSendMessage", "catt_gc_send2")
callbacks.Register("GCSendMessage", "catt_gc_send2", function(typeID, data)
	if typeID == 6578 then -- k_EMsgGC_AcceptLobbyInvite
		if not allowAcceptMatchInvite then
			return E_GCResults.k_EGCResultNoMessage
		end
		allowAcceptMatchInvite = false
	end

	return E_GCResults.k_EGCResultOK
end)

callbacks.Unregister("GCRetrieveMessage", "catt_gc_recv2")
callbacks.Register("GCRetrieveMessage", "catt_gc_recv2", function(typeID, data)
	if typeID == 21 then
		data = ProtoBuf.Decode(data)
		--[[
			{
				[1] = 628510141098033, //mm invite id
				[2] = {
					[1] = 8388608,
					[2] = 7
				},
				[4] = 628510210635546,
				[0] = {
					[1] = 0,
					[2] = 9,
					[3] = 128,
					[4] = 799969304467542016
				}
			}
		]]
		if #data == 4 and type(data[0]) == "table" and #data[0] == 4 and type(data[2]) == "table"
				and #data[2] == 2 and data[3] == nil then
			timer = globals.CurTime() + 160
		end
	end

	return E_GCResults.k_EGCResultOK
end)

callbacks.Unregister("Draw", "catt_render2")
callbacks.Register("Draw", "catt_render2", function()
	if join and join - globals.CurTime() <= 0 then
		join = nil
		gc.JoinMatchmakingMatch()
	end

	if timer then
		if input.IsButtonPressed(config.joinKey) then
			timer = nil
			allowAcceptMatchInvite = true

			if gc.IsConnectedToMatchServer() then gc.AbandonMatch() end
			gc.AcceptMatchInvites() -- i hate async
			join = globals.CurTime() + 1

			return
		end

		local diff = timer - globals.CurTime()
		if diff <= 0 then
			timer = nil
			return
		end

		draw.Color(255, 255, 255, 255)
		draw.SetFont(config.font)
		
		draw.TextShadow(math.floor(config.x), math.floor(config.y), formatTime(diff))
	end
end)

function fix_gc()
	allowAcceptMatchInvite = true
	print("oki !")
end