lock=false

function onLoad()
 local selfScale=self.getScale()
 local params={
 function_owner=self,
 label='Sort A-Z',
 tooltip='Sort any deck on the tile alphabetically.',
 font_size=200,
 width=1500,
 height=220,
 scale={1/selfScale.x,1/selfScale.y,1/selfScale.z},
 position={0,0,1.2},
 click_function='sortAlph'
 }
 self.createButton(params)

 params.label="Sort Z-A"
 params.position[3]=1.5
 params.click_function='sortRev'
 self.createButton(params)
 
 params.tooltip="Sort cards into a format prefered for Pokemon TCG decklists"
 params.label="Sort a PTCG Deck"
 params.position[3]=1.8
 params.click_function='sortPoke'
 self.createButton(params)
 
 params.tooltip="Removes duplicates in excess of what you can play"
 params.label="Remove 5+"
 params.position[3]=2.1
 params.click_function='filterFives'
 self.createButton(params)
 
 params.tooltip="Removes the lock if needed."
 params.label="Override lock"
 params.position[3]=2.4
 params.click_function='unlock'
 self.createButton(params)
end

function CheckForObjects()
 return Physics.cast({origin=self.positionToWorld{0,5.5,0},direction={0,1,0},type=3,size={2.5,1,3},max_distance=0,orientation=self.GetRotation()})
end

function getDeck(color)
 local zone=CheckForObjects()
 for _,collision in pairs(zone)do
  if collision.hit_object.type=="Deck"then
   return collision.hit_object
  end
 end
 broadcastToColor("No Deck Found",color,{1,0,0})
end

function sortAlph(obj,color,alt)
 if checkLock(color) then sortDeck(function(a,b)return a.Nickname<b.Nickname end,color)end
end

function sortRev(obj,color,alt)
 if checkLock(color) then sortDeck(function(a,b)return a.Nickname>b.Nickname end,color)end
end

function sortPoke(obj,color,alt)
 if checkLock(color) then sortDeck(function(a,b)return sortByPoke(a,b) end,color)end
end

function sortByPoke(a,b)
aNotes=tonumber(a.GMNotes)
bNotes=tonumber(b.GMNotes)
 if aNotes and bNotes and aNotes~=bNotes then
  return aNotes<bNotes
 elseif a.Nickname~=b.Nickname then
  return a.Nickname<b.Nickname
 else
  aMemo=tonumber(a.Memo)
  bMemo=tonumber(b.Memo)
  if aMemo and bMemo then
   return aMemo<bMemo
  end
 end
 return a.CardID<b.CardID
end

function sortDeck(sortFunc,color)--credit to dzikakulka
 local deck=getDeck(color)
 if deck then
  local data=deck.getData()
  table.sort(data.ContainedObjects,sortFunc)
  data.DeckIDs={}
  for _,card in ipairs(data.ContainedObjects)do
   table.insert(data.DeckIDs,card.CardID)
  end
  deckRot=deck.GetRotation()
  selfRot=self.GetRotation()
  deck.destruct()
  spawnObjectData({position=self.positionToWorld({2.3,2,0}),rotation={x=deckRot.x,y=selfRot.y,z=deckRot.z},data=data})
 end
 lock=false
end

function filterFives(sortFunc,color)
 if checkLock(color) then
  local deck=getDeck(color)
  excess=nil
  RemoveExcess(deck,deck.getData(),1,{},0,nil)
 end
end

function RemoveExcess(deck,data,pos,counts,posInDeck)
 for position=pos,#data.DeckIDs do
  local cardID=tostring(data.DeckIDs[position]%100)..data.CustomDeck[math.floor(data.DeckIDs[position]/100)].FaceURL
  if not counts[cardID]then
   counts[cardID]=1
   posInDeck=posInDeck+1
  elseif counts[cardID]<4 then
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

function checkLock(color)
 if lock==false then
  lock=true
  return true
 end
 broadcastToColor("Tile in use.",color,{1,0,0})
 return false
end

function unlock(obj,color,alt)
 lock=false
end
