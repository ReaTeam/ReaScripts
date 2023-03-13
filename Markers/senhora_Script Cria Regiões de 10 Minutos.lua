-- @description Script: Cria Regiões de 10 Minutos
-- @author Senhor A
-- @version 1.0

-- Defina a duração das regiões em minutos
local regionLength = 10

-- Encontre o tempo total de todas as faixas no projeto
local projectLength = reaper.GetProjectLength()

-- Calcule o número de regiões com base no comprimento do projeto e no comprimento da região
local numRegions = math.ceil(projectLength / (regionLength * 60))

-- Defina o nome base da região
local regionNameBase = "Parte "

-- Defina o número da primeira região
local regionNumber = 1

-- Crie cada região
for i = 1, numRegions do
  -- Calcule o tempo de início da região
  local regionStart = (i - 1) * regionLength * 60
  
  -- Calcule o tempo final da região
  local regionEnd = math.min(i * regionLength * 60, projectLength)
  
  -- Defina o nome da região
  local regionName = regionNameBase .. tostring(regionNumber)
  
  -- Crie a região em cada faixa
  for j = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, j)
    local item = reaper.GetTrackMediaItem(track, 0)
    if item then
      reaper.AddProjectMarker2(0, true, regionStart, regionEnd, regionName, regionNumber, reaper.GetTrackColor(track))
    end
  end
  
  -- Incremente o número da região
  regionNumber = regionNumber + 1
end

