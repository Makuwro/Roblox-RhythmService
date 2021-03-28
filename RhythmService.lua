-- RhythmService
-- Created by Christian Toney / Draguwro

local RunService = game:GetService("RunService");
local RhythmService = {
  Tolerance = {0.1, 0.2} 
  -- The first tolerance level is considered a perfect, 
  -- while the last tolerance level is considered right before the player misses the beat
  -- You can add more tolerance levels if you'd like
};
local Song = {Sound = nil, Keys = {}, KeyPosition = 1, StopwatchEvent = nil};
local Events = {};

function RhythmService:SetSound(sound: Sound, keepKeys: boolean?, startStopwatchOnPlay: boolean?)
  -- Set sound and remove keys if necessary
  Song.Sound = sound;
  if not keepKeys then
    Song.Keys = {};
  end;
  
  if startStopwatchOnPlay then
    local PlayEvent;
    PlayEvent = sound.Played:Connect(function()
      PlayEvent:Disconnect();
      RhythmService:StartStopwatch();
    end);
  end;
end;

function RhythmService:AddKey(timePosition: number, index: number?)
  assert(Song.Sound, "A sound instance must be defined before adding a key");
  
  -- Add key
  local Key = {timePosition, 1};
  if index then
    table.insert(Song.Keys, index, Key);
  else
    table.insert(Song.Keys, Key);
  end;
end;

function RhythmService:SetKeys(keys: {number}?)
  -- Set keys
  Song.Keys = {};
  if keys then
    for _, timePosition in ipairs(keys) do
      table.insert(Song.Keys, {timePosition, 1})
    end;
  end;
end;

function RhythmService:RemoveKey(index: number)
  table.remove(Song.Keys, index);
end;

function RhythmService:CheckRhythm()
  assert(#Song.Keys > 0, "There has to be at least one key!");
  assert(Song.StopwatchEvent and Song.StopwatchEvent.Connected, "The stopwatch hasn't started!");
  
  local SongPosition = Song.Sound.TimePosition;
  local Goal = Song.Keys[Song.KeyPosition];
  local Result = {
    GoalTime = Goal[1];
    HitTime = SongPosition;
  };
  
  -- Check the time
  for level, tolerance in ipairs(RhythmService.Tolerance) do
    if Goal[2] ~= 0 then
      if Goal[1] - tolerance <= SongPosition and SongPosition <= Goal[1] + tolerance then
        Result.Rating = level;
        RhythmService:ToggleKey(true);
        break;
      end;
    end;
  end;
  
  return Result;
end;

function RhythmService:ToggleKey(disable: boolean?, index: number?, keepPosition: number?)
  -- Toggle key and shift position
  Song.Keys[Song.KeyPosition or index][2] = (disable and 0) or 1;
  if not keepPosition and #Song.Keys >= Song.KeyPosition + 1 then
    Song.KeyPosition = Song.KeyPosition + 1;
  elseif #Song.Keys < Song.KeyPosition + 2 then
    RhythmService:StopStopwatch();
  end;
end;

function RhythmService:ResetKeys()
  for i, key in ipairs(Song.Keys) do
    Song.Keys[i] = {key[1], 1};
  end;
end;

function RhythmService:StopStopwatch()
  if Song.StopwatchEvent and Song.StopwatchEvent.Connected then
    Song.StopwatchEvent:Disconnect();
  end;
  
  Song.StopwatchEvent = nil;
end;

function RhythmService:StartStopwatch()
  assert(Song.Sound, "A sound hasn't been defined!");
  assert(#Song.Keys > 0, "There has to be at least one key!");
  
  RhythmService:StopStopwatch();
  RhythmService:ResetKeys();
  Song.KeyPosition = 1;
  
  -- Add a new SW
  Song.StopwatchEvent = RunService.Heartbeat:Connect(function()
    for i, v in ipairs(Song.Keys) do
      if v[2] ~= 0 and v[1] + RhythmService.Tolerance[#RhythmService.Tolerance] < Song.Sound.TimePosition then 
        RhythmService:ToggleKey(true);
        Events.OnIdle:Fire();
        break;
      end;
    end;
  end);
end;

-- Events
for _, eventName in ipairs({"OnIdle"}) do
  Events[eventName] = Instance.new("BindableEvent");
  RhythmService[eventName] = Events[eventName].Event;
end;

return RhythmService;
