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
sudo curl -fsSL https://repo.amar.kim/public.key -o /etc/apt/keyrings/amrkmn.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/amrkmn.asc] https://repo.amar.kim/apt stable main" | sudo tee /etc/apt/sources.list.d/amrkmn.list >/dev/null
sudo apt update
```
