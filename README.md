# Ujol's APT Repository

### List of Packages:
- [restic](https://github.com/restic/restic)
- [runitor](https://github.com/bdd/runitor)

# Usage
```bash
echo "deb [signed-by=/usr/share/keyrings/amrkmn.gpg] https://pkgs.ujol.dev/apt stable main" | sudo tee /etc/apt/sources.list.d/amrkmn.list >/dev/null
sudo curl -SsL https://pkgs.ujol.dev/key.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/amrkmn.gpg >/dev/null
sudo apt update
```
