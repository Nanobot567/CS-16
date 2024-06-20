default: build run

[private]
incrementBuildNumber:
  #! /bin/python3
  from sys import argv

  f = open("src/pdxinfo","r")
  content = f.read()
  f.close()

  splitnl = content.split("\n")
  sc = splitnl[5].split("=")
  buildnum = sc[1]

  splitnl[5] = f"buildNumber={str(int(buildnum)+1)}"

  f = open("src/pdxinfo","w")

  for i in splitnl:
      if splitnl[len(splitnl)-1] == i:
          f.write(f"{i}")
      else:
          f.write(f"{i}\n")

  print(splitnl)


build:
  @just incrementBuildNumber

  pdc -q -sdkpath ~/Documents/PlaydateSDK/ src CS-16

run:
  PlaydateSimulator CS-16.pdx

release:
  just build
  -rm CS-16.pdx.zip
  zip -rq CS-16.pdx.zip CS-16.pdx
