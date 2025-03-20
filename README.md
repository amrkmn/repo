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
curl -fsSL https://repo.amar.kim/public.key | sudo gpg --dearmor -o /etc/apt/keyrings/amrkmn.gpg
echo "deb [signed-by=/etc/apt/keyrings/amrkmn.gpg] https://repo.amar.kim/apt stable main" | sudo tee /etc/apt/sources.list.d/amrkmn.list >/dev/null
sudo apt update
```
