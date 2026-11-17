# EPIVÍOSI SECURITY : chiffrement, vie privée et documentation hors-ligne.
#
# - Chiffrement de disques et de clés USB (LUKS) : GNOME Disques, cryptsetup.
# - Chiffrement de fichiers : Picocrypt (simple), GnuPG + GPA, age.
# - Métadonnées et traces : Metadata Cleaner (mat2), BleachBit, GtkHash.
# - Documentation : `epiviosi-security-docs` télécharge des archives de
#   sécurité dans la bibliothèque d'EPIVÍOSI WIKI (si le module est activé).
# - Guide « EPIVÍOSI SECURITY » (FR/EN) dans le menu.
#
# Pas d'outils d'anonymat en ligne (Tor…) : EPIVÍOSI reste centré sur
# l'usage hors-ligne. Ce module implémente `epiviosi.security.enable`,
# déclarée par le socle EPIVÍOSI OS (modules/epiviosi-modules.nix).
{ config, lib, pkgs, ... }:
let
  cfg = config.epiviosi.security;

  # Archives Kiwix (≈ 0,8 Go), servies par le Kiwix d'EPIVÍOSI WIKI.
  docs = [
    "stack_exchange/security.stackexchange.com_en_all"
    "stack_exchange/crypto.stackexchange.com_en_all"
    "zimit/privacydefence.org_en_opsecbible"
  ];

  securityDocs = pkgs.writeShellScriptBin "epiviosi-security-docs" ''
    # Télécharge la documentation de sécurité dans /wiki (EPIVÍOSI WIKI).
    # Options transmises à epiviosi-wiki-fetch (ex. --dry-run).
    exec epiviosi-wiki-fetch "$@" ${lib.escapeShellArgs docs}
  '';

  guide = pkgs.writeShellScriptBin "epiviosi-security" ''
    exec firefox file:///etc/epiviosi/security/guide.html
  '';

  desktopItem = pkgs.makeDesktopItem {
    name = "epiviosi-security";
    desktopName = "EPIVÍOSI SECURITY";
    genericName = "Guide de sécurité";
    comment = "Chiffrer une clé USB ou des fichiers, effacer les métadonnées, documentation";
    exec = "epiviosi-security";
    icon = "security-high";
    categories = [
      "System"
      "Security"
    ];
    keywords = [
      "chiffrement"
      "encryption"
      "luks"
      "gpg"
      "métadonnées"
      "metadata"
    ];
  };
in
{
  config = lib.mkIf cfg.enable {
    # Chiffrement de disques : dm-crypt dans le noyau, udisks pour GNOME Disques.
    boot.initrd.availableKernelModules = [ "dm_crypt" ];
    services.udisks2.enable = true;

    programs.gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-gtk2;
    };

    environment.etc."epiviosi/security/guide.html".source = ./assets/guide.html;

    environment.systemPackages =
      (with pkgs; [
        # Disques et clés USB chiffrés (LUKS)
        gnome-disk-utility
        cryptsetup
        # Fichiers chiffrés
        picocrypt
        gnupg
        gpa
        age
        # Métadonnées, traces, empreintes
        metadata-cleaner
        mat2
        bleachbit
        gtkhash
      ])
      ++ [
        guide
        desktopItem
      ]
      ++ lib.optional config.epiviosi.wiki.enable securityDocs;
  };
}
