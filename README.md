# Ujol's APT Repository

### List of Packages:
- [restic](https://github.com/restic/restic)
- [runitor](https://github.com/bdd/runitor)
- [croc](https://github.com/schollz/croc)
- [regclient](https://github.com/regclient/regclient)

# Usage
```bash
echo "deb [signed-by=/usr/share/keyrings/amrkmn.gpg] https://repo.amar.kim/apt stable main" | sudo tee /etc/apt/sources.list.d/amrkmn.list >/dev/null
sudo curl -SsL https://repo.amar.kim/pubkey.asc | gpg --dearmor | sudo tee /usr/share/keyrings/amrkmn.gpg >/dev/null
sudo apt update
```
