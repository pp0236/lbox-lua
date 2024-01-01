-- for who has shitty pc like me and lag spike everytime someone send message in party chat

-- https://github.com/lnx00/Lua-Protobuf/blob/dc940e457f92143efabb648892b86a7d458a1c76/src/Protobuf.lua
local ProtoBuf = (function()
	local a={}local b={Varint=0,Fixed64=1,LengthDelimited=2,StartGroup=3,EndGroup=4,Fixed32=5}local function c(table,d)d=d or 0;for e,f in pairs(table)do if type(f)=="table"then print(string.rep(" ",d)..e.." = {")c(f,d+2)print(string.rep(" ",d).."}")elseif type(f)=="string"then print(string.rep(" ",d)..e.." = \""..f.."\"")else print(string.rep(" ",d)..e.." = "..f)end end end;local function g(h,i,f)local j=h[i]if j then if type(j)=="table"then table.insert(j,f)else h[i]={j,f}end else h[i]=f end end;local function k(l,m)local f,n=0,string.byte;f=n(l,m)|(n(l,m+1)<<8)|(n(l,m+2)<<16)|(n(l,m+3)<<24)return f end;local function o(l,m)local f,p=0,0;repeat local q=string.byte(l,m)f=f+q&0x7F<<p;p=p+7;m=m+1 until q<128;return f,m end;local function r(l,m)return k(l,m),m+4 end;local function s(l,m)local f=k(l,m)m=m+4;f=f|(k(l,m)<<32)m=m+4;return f,m end;local function t(l,m)local u=0;u,m=o(l,m)local f=string.sub(l,m,m+u-1)m=m+u;return f,m end;local function v(l,m)local w,i,x=0,0,0;local y={}local f=nil;while m<#l do w,m=o(l,m)i=w>>3;x=w&0x07;if x==b.Varint then f,m=o(l,m)g(y,i,f)elseif x==b.Fixed64 then f,m=s(l,m)g(y,i,f)elseif x==b.LengthDelimited then f,m=t(l,m)if string.byte(f,1)==0x0A then f=v(f,1)end;g(y,i,f)elseif x==b.StartGroup then m=m+1 elseif x==b.EndGroup then m=m+1 elseif x==b.Fixed32 then f,m=r(l,m)g(y,i,f)else print("Unknown wire type: "..x)break end end;return y end;function a.Decode(l,m)m=m or 1;return v(l,m)end;function a.Dump(l)local z={}for A=1,#l do local q=string.byte(l,A)z[A]=string.format("%02X",q)end;print(table.concat(z," "))end;return a
end)()

local config = {
	color = "51fd6b",
	notfi_sound = "ui/chat_display_text.wav",
}

callbacks.Unregister("GCRetrieveMessage", "catt_gc_recv")
callbacks.Register("GCRetrieveMessage", "catt_gc_recv", function(typeID, data)
	if typeID == 6563 then -- k_EMsgGCParty_ChatMsg
		local data = ProtoBuf.Decode(data)
		local username = steam.GetPlayerName(data[2])
		local message = data[3]

		print(string.format("(Party) %s: %s", username, message))
		client.ChatPrintf(string.format("\x07%s(Party) %s: %s", config.color, username, message))
		engine.PlaySound(config.notfi_sound)

		return E_GCResults.k_EGCResultNoMessage
	end

	return E_GCResults.k_EGCResultOK
end)