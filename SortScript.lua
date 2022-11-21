lock=false
rev=false
dupeNum=5

function onLoad(state)
 if state and state!=""then
  state=json.parse(state)
  rev=state.rev or false
  dupeNum=state.dupeNum or 5
 end
 setUp()
end

function setUp()
 self.clearContextMenu()
 self.clearButtons()
 for c=2,5 do
  if c!=dupeNum then
   self.addContextMenuItem("Set Dupe filter to "..tostring(c).."+",||setDupeCount(c))
  end
 end
 self.addContextMenuItem("Override lock",function()lock=false end)
 local params={
 function_owner=self,
 font_size=197,
 width=1500,
 height=220,
 scale={0.75,1,0.5},
 }
 butWrapper(params,{0,0,1.2},"Sort By Name","Sort any deck on the tile alphabetically",'sortAlph')
 butWrapper(params,{0,0,1.5},"Sort a PTCG Deck","Sort cards into a format prefered for Pokemon TCG decklists",'sortPoke')
 butWrapper(params,{0,0,1.8},"Sort by Rarity","Sort cards by Rarity",'sortRare')
 butWrapper(params,{0,0,2.1},"Sort by Type","Sort cards by Type",'sortType')
 butWrapper(params,{0,0,2.4},"Remove "..tostring(dupeNum).."+","Removes duplicates in excess of what you can play",'filterDupes')
 if rev then params.color={0,1,0}else params.color={1,0,0}end
 butWrapper(params,{0,0,2.7},"Reverse Sort","Reverse the sorting.",'toggleReverse')
end

function butWrapper(params,pos,label,tool,func)
 params.position=pos
 params.label=label
 params.tooltip=tool
 params.click_function=func
 self.createButton(params)
end

function setDupeCount(num)
 dupeNum=num
 saveData()
 setUp()
end

function CheckForObjects()
 return Physics.cast({origin=self.positionToWorld{0,5.5,0},direction={0,1,0},type=3,size={2.5,1,3},max_distance=0,orientation=self.GetRotation()})
end

function getDeck(color)
 local zone=CheckForObjects()
 for _,collision in pairs(zone)do
  if collision.hit_object.type=="Deck"then return collision.hit_object end
 end
 broadcastToColor("No Deck Found",color,{1,0,0})
end

function sortAlph(obj,color,alt)
 sortDeck(function(a,b)if rev then return a.Nickname>b.Nickname else return a.Nickname<b.Nickname end end,color)
end

function sortPoke(obj,color,alt)
 sortDeck(function(a,b)return sortByPoke(orderArgs(a,b))end,color)
end

function sortRare(obj,color,alt)
 sortDeck(function(a,b)return sortByRare(orderArgs(a,b))end,color)
end

function sortType(obj,color,alt)
 sortDeck(function(a,b)return sortByType(orderArgs(a,b))end,color)
end

function orderArgs(a,b)
 if rev then return b,a else return a,b end
end

function sortByPoke(a,b)
 local aNotes=tonumber(a.GMNotes)
 local bNotes=tonumber(b.GMNotes)
 if #a.GMNotes==6 then aNotes=aNotes*100 end
 if #b.GMNotes==6 then bNotes=bNotes*100 end
 if aNotes and bNotes and aNotes~=bNotes then
  return aNotes<bNotes
 elseif a.Nickname~=b.Nickname then
  return a.Nickname<b.Nickname
 else
  local aMemo=tonumber(a.Memo)
  local bMemo=tonumber(b.Memo)
  if aMemo and bMemo then return aMemo<bMemo end
 end
 return a.CardID<b.CardID
end

function sortByRare(a,b)
 local aRare=rarityTable[string.match(a.Description,"%u+$")]
 local bRare=rarityTable[string.match(b.Description,"%u+$")]
 if(aRare or bRare)and(aRare!=bRare)then return(aRare or 0)<(bRare or 0)else return sortByPoke(a,b)end
end

function sortByType(a,b)
 local aType=tonumber(a.LuaScriptState)
 local bType=tonumber(b.LuaScriptState)
 if(aType or bType)and(aType!=bType)then return(aType or 0)<(bType or 0)else return sortByPoke(a,b)end
end

function sortDeck(sortFunc,color)--credit to dzikakulka
 if checkLock(color)then
  local deck=getDeck(color)
  if deck then
   local data=deck.getData()
   table.sort(data.ContainedObjects,sortFunc)
   data.DeckIDs={}
   for c=1,#data.ContainedObjects do
    table.insert(data.DeckIDs,data.ContainedObjects[c].CardID)
   end
   deckRot=deck.GetRotation()
   selfRot=self.GetRotation()
   deck.destruct()
   spawnObjectData({position=self.positionToWorld({2.3,2,0}),rotation={x=deckRot.x,y=selfRot.y,z=deckRot.z},data=data})
  end
  lock=false
 end
end

function filterDupes(sortFunc,color)
 if checkLock(color)then
  local deck=getDeck(color)
  excess=nil
  if deck then RemoveExcess(deck,deck.getData(),1,{},0,nil)else lock=false end
 end
end

function RemoveExcess(deck,data,pos,counts,posInDeck)
 for position=pos,#data.DeckIDs do
  local cardID=tostring(data.DeckIDs[position]%100)..data.CustomDeck[math.floor(data.DeckIDs[position]/100)].FaceURL
  if not counts[cardID]then
   counts[cardID]=1
   posInDeck=posInDeck+1
  elseif counts[cardID]<dupeNum-1 then
   counts[cardID]=counts[cardID]+1
   posInDeck=posInDeck+1
  else
   local card=deck.takeObject({position=self.positionToWorld({2.3,1+(position*0.01),0}),rotation=self.GetRotation(),index=posInDeck,smooth=false})
   if excess==nil then
    excess=card
   elseif excess.type=="Card"then
    excess=excess.putObject(card)
   else
    excess=excess.putObject(card)
    card.destruct()
   end
  end
  if position%20==0 then
   Wait.frames(function()RemoveExcess(deck,data,position+1,counts,posInDeck)end,1)
   return
  end
 end
 lock=false
end

function toggleReverse()
 if rev then rev=false else rev=true end
 setUp()
 saveData()
end

function saveData()
 self.script_state=json.serialize({rev=rev,dupeNum=dupeNum})
end

function checkLock(color)
 if lock==false then
  lock=true
  return true
 end
 broadcastToColor("Tile in use.",color,{1,0,0})
 return false
end

rarityTable={
 C=29,
 U=28,
 R=27,
 RH=26,
 TGRH=25,
 RHEX=24,
 RHLVX=23,
 RHGX=22,
 RHV=21,
 TGRHV=20,
 RHVMAX=19,
 RHVSTAR=18,
 RP=17,
 LEGEND=16,
 RACE=15,
 RBREAK=14,
 RPS=13,
 AR=12,
 CC=11,
 RR=10,
 RU=9,
 TGRU=8,
 RHS=7,
 RS=6,
 TGRS=5,
 RSGX=4,
 RSV=3,
 RSVMAX=2,
 P=1,
 }
