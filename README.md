# EPIVÍOSI SECURITY

Chiffrement, vie privée et documentation hors-ligne pour
[EPIVÍOSI OS](https://github.com/Marmotte-png/epiviosi).

## Contenu

| Besoin | Outils |
| --- | --- |
| Clés USB et disques chiffrés (LUKS) | GNOME Disques, `cryptsetup` |
| Fichiers chiffrés | Picocrypt (le plus simple), GnuPG + GPA, `age` |
| Métadonnées des photos et documents | Metadata Cleaner, `mat2` |
| Traces et empreintes | BleachBit, GtkHash |
| Mots de passe | KeePassXC (fourni par le socle EPIVÍOSI OS) |
| Documentation | `epiviosi-security-docs` → archives dans EPIVÍOSI WIKI |

Le lanceur **EPIVÍOSI SECURITY** ouvre un guide pas à pas (français et anglais) : créer une clé
USB chiffrée, chiffrer un fichier, effacer les métadonnées avant de partager, vérifier une
empreinte, et pourquoi l'effacement « sûr » n'est pas garanti sur une clé USB ou un SSD.

Choix assumés : pas d'outils d'anonymat en ligne (Tor, OnionShare), EPIVÍOSI restant centré sur
l'usage hors-ligne ; pas de VeraCrypt (licence non libre dans nixpkgs), LUKS couvre le besoin.

## Documentation hors-ligne

Si EPIVÍOSI WIKI est activé, `epiviosi-security-docs` (connexion requise) télécharge dans `/wiki`
(≈ 0,8 Go, en anglais) :

| Archive | Taille |
| --- | --- |
| Information Security (Stack Exchange) | ≈ 440 Mo |
| Cryptography (Stack Exchange) | ≈ 190 Mo |
| The OpSec Bible | ≈ 175 Mo |

```sh
epiviosi-security-docs --dry-run   # tailles, sans télécharger
epiviosi-security-docs
```

## Utilisation dans un flake

Le module implémente l'option `epiviosi.security.enable`, déclarée par le socle EPIVÍOSI OS :

```nix
inputs.epiviosi-security = {
  url = "github:Marmotte-png/epiviosi-security";
  inputs.nixpkgs.follows = "nixpkgs";
};
# …
modules = [ epiviosi-security.nixosModules.default { epiviosi.security.enable = true; } ];
```

## Tests

```sh
nix flake check                      # test en VM (nécessite KVM dans le bac à sable Nix)
# Sans KVM dans le bac à sable, lancer le test sous son propre utilisateur :
$(nix build --no-link --print-out-paths .#checks.x86_64-linux.vm.driver)/bin/nixos-test-driver
```

Le test vérifie les outils et le guide, crée et rouvre un conteneur LUKS (le contenu n'apparaît
pas en clair), chiffre et déchiffre avec `age` et GnuPG, et contrôle que `mat2` supprime les
métadonnées d'une image.

## Structure

| Chemin | Rôle |
| --- | --- |
| `module.nix` | Module NixOS : outils, agent GnuPG, guide, `epiviosi-security-docs` |
| `assets/guide.html` | Guide EPIVÍOSI SECURITY (FR/EN) |
| `tests/security.nix` | Test NixOS en VM |

## Licence

[Hippocratic License 2.1](LICENSE).
