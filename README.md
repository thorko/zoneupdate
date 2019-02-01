# zoneupdate
# update zone on bind with nsupdate

## Install 
```
sudo make install
```

## run
```
zoneupdate.pl -z thorko.de -o add -n www.thorko.de -r A -t 300 -v 10.0.0.1
```
