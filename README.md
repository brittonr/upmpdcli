# upmpdcli for NixOS

A NixOS package and module for upmpdcli - UPnP Media Renderer front-end for MPD with Tidal support.

## Features

- UPnP/DLNA Media Renderer that controls MPD
- Tidal HiRes streaming (up to HI_RES_LOSSLESS quality)
- Qobuz, Subsonic, and other streaming services
- Works perfectly with MPD clients like rmpc
- Media Server mode for browsing streaming services

## Current Status

⚠️ **Work in Progress** - This package is being developed to provide Tidal integration for MPD on NixOS.

### TODO
- [ ] Fix package build issues
- [ ] Test libnpupnp and libupnpp compilation
- [ ] Add proper Python plugin wrapping
- [ ] Test Tidal OAuth authentication
- [ ] Create NixOS module for easy integration
- [ ] Add to nixpkgs

## Building

```bash
# Clone this repository
git clone https://github.com/yourusername/upmpdcli-nix
cd upmpdcli-nix

# Build the package
nix build

# Or build individual components
nix build .#libnpupnp
nix build .#libupnpp
nix build .#upmpdcli
```

## Usage (once working)

### As a NixOS Module

```nix
{
  inputs.upmpdcli.url = "github:yourusername/upmpdcli-nix";

  outputs = { self, nixpkgs, upmpdcli, ... }: {
    nixosConfigurations.yourmachine = nixpkgs.lib.nixosSystem {
      modules = [
        upmpdcli.nixosModules.default
        {
          services.upmpdcli = {
            enable = true;
            tidalEnable = true;
            tidalQuality = "HI_RES_LOSSLESS";
          };
        }
      ];
    };
  };
}
```

### With Tidal

1. Enable Tidal in configuration
2. Deploy and check logs: `journalctl -u upmpdcli -f`
3. Visit the OAuth URL shown in logs to authenticate
4. Use a UPnP control point to browse Tidal content
5. Control playback with rmpc or any MPD client

## Architecture

```
[Tidal API] <-> [upmpdcli] <-> [MPD] <-> [rmpc/MPD clients]
                     |
              [UPnP Media Server]
                     |
            [UPnP Control Points]
```

## Dependencies

- libnpupnp: Base UPnP library
- libupnpp: C++ UPnP wrapper
- python-tidal: For Tidal integration
- MPD: Music Player Daemon (must be running)

## Benefits over Mopidy

- Full modern MPD protocol support
- Better performance (C++ vs Python)
- Tidal HiRes support (HI_RES_LOSSLESS)
- UPnP/DLNA compatibility
- Lower resource usage

## Contributing

This package needs help! Areas that need work:

1. Package build configuration
2. Testing on different NixOS systems
3. Documentation improvements
4. Integration with nixpkgs

## License

GPL v2+ (same as upstream upmpdcli)