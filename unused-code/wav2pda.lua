-- this function is unused for now, but could be used to convert wav files to pdas in the future!

function wav2pda(wavfile,pdafile)
  local fil = pd.file
  local wav = fil.open(wavfile, fil.kFileRead)
  local datalen = fil.getSize(wavfile) - 44
  local pda = fil.open(pdafile, fil.kFileWrite)
  
  wav:seek(44)
  pda:write("Playdate AUD\68\172\0\2") -- 44kHz 16 bit mono
  
  local offset = 0
  
  while offset < datalen do
      local n = math.min(datalen-offset, 1024)
      pda:write(wav:read(n))
      offset += n
  end
  
  wav:close()
  pda:close()
end
