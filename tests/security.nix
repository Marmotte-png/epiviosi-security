# Test NixOS du module EPIVÍOSI SECURITY : outils présents, conteneur LUKS
# (création, ouverture, écriture, fermeture), chiffrement age et GnuPG,
# nettoyage des métadonnées par mat2, guide installé.
{ pkgs, module }:
pkgs.testers.runNixOSTest {
  name = "epiviosi-security";

  nodes.machine =
    { lib, ... }:
    {
      imports = [ module ];
      # Options normalement déclarées par le socle EPIVÍOSI OS.
      options.epiviosi = {
        user = lib.mkOption {
          type = lib.types.str;
          default = "epiviosi";
        };
        security.enable = lib.mkEnableOption "EPIVÍOSI SECURITY";
        wiki.enable = lib.mkEnableOption "EPIVÍOSI WIKI";
      };
      config = {
        epiviosi.security.enable = true;
        epiviosi.wiki.enable = true;
        virtualisation.memorySize = 2048;
        environment.systemPackages = [ pkgs.imagemagick pkgs.e2fsprogs ];
      };
    };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    with subtest("outils et guide installés"):
        for cmd in ["gnome-disks", "cryptsetup", "picocrypt-gui", "gpg", "gpa", "age",
                    "metadata-cleaner", "mat2", "bleachbit", "gtkhash",
                    "epiviosi-security", "epiviosi-security-docs"]:
            machine.succeed(f"command -v {cmd}")
        machine.succeed("test -s /etc/epiviosi/security/guide.html")
        machine.succeed("test -f /run/current-system/sw/share/applications/epiviosi-security.desktop")
        machine.succeed("grep -q security.stackexchange $(command -v epiviosi-security-docs)")

    with subtest("conteneur LUKS : création, écriture, réouverture"):
        machine.succeed("truncate -s 64M /root/coffre.img && printf 'phrase de passe' > /root/cle")
        machine.succeed("cryptsetup luksFormat -q --pbkdf-memory 65536 /root/coffre.img /root/cle")
        machine.succeed("cryptsetup open --key-file /root/cle /root/coffre.img coffre")
        machine.succeed("mkfs.ext4 -q /dev/mapper/coffre && mkdir -p /mnt/c && mount /dev/mapper/coffre /mnt/c")
        machine.succeed("echo secret > /mnt/c/note && umount /mnt/c && cryptsetup close coffre")
        machine.fail("grep -a -q secret /root/coffre.img")
        machine.succeed("cryptsetup open --key-file /root/cle /root/coffre.img coffre && mount /dev/mapper/coffre /mnt/c")
        machine.succeed("grep -qx secret /mnt/c/note && umount /mnt/c && cryptsetup close coffre")

    with subtest("age : chiffrement et déchiffrement"):
        machine.succeed("age-keygen -o /root/age.key 2>/dev/null")
        machine.succeed("echo bonjour | age -r $(age-keygen -y /root/age.key) -o /root/m.age")
        machine.succeed("age -d -i /root/age.key /root/m.age | grep -qx bonjour")

    with subtest("GnuPG : chiffrement symétrique"):
        machine.succeed("echo bonjour > /root/g.txt")
        machine.succeed("gpg --batch --pinentry-mode loopback --passphrase pp -c -o /root/g.gpg /root/g.txt")
        machine.succeed("gpg --batch --pinentry-mode loopback --passphrase pp -d /root/g.gpg 2>/dev/null | grep -qx bonjour")

    with subtest("mat2 : métadonnées supprimées"):
        machine.succeed("magick -size 32x32 xc:red -set comment 'Auteur Secret' /root/photo.jpg")
        machine.succeed("mat2 --show /root/photo.jpg | grep -q 'Auteur Secret'")
        machine.succeed("mat2 /root/photo.jpg")
        machine.fail("mat2 --show /root/photo.cleaned.jpg | grep -q 'Auteur Secret'")
  '';
}
