# Store homebrew formulae here.

## Spotifyd

It can be installed using :

```bash
brew install dvdmuckle/tap/spotifyd
```

## spc

It can be installed using :

```bash
brew install dvdmuckle/tap/spc
```

### Automated

The binaries and sha256s are already generated in the Spotifyd repository. Run the following script to fetch the latest sha256s and update `Formula/spotifyd.rb`. There is also a similar script to update the spc tap.

```
sh scripts/spotifyd.sh $VERSION
sh scripts/spc.sh $VERSION
```
