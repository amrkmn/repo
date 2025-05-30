# Ujol's APT Repository

### List of Packages:
- [restic](https://github.com/restic/restic)
- [runitor](https://github.com/bdd/runitor)
- [croc](https://github.com/schollz/croc)
- [regclient](https://github.com/regclient/regclient)
- [wgcf](https://github.com/ViRb3/wgcf)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp)

# Usage
```bash
curl -fsSL https://repo.ujol.dev/amrkmn.asc | sudo tee /etc/apt/keyrings/amrkmn.asc > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/amrkmn.asc] https://repo.ujol.dev/apt stable main" | sudo tee /etc/apt/sources.list.d/amrkmn.list
sudo apt update
```
