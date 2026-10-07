{ config, lib, pkgs, ... }:
let
  # 保存したChrome設定を、復元スクリプトが読み込めるJSONへ変換する。
  # JSONはNixストア内で生成されるため、Git管理する必要はない。
  snapshot = pkgs.writeText "chrome-settings.json"
    (builtins.toJSON (import ./captured-chrome.nix));

  # Nixが用意するPythonを使うため、Mac側にPythonを手動導入する必要はない。
  restoreChrome = pkgs.writeShellApplication {
    name = "restore-chrome-settings";
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./scripts/restore_chrome_settings.py} \
        --snapshot ${snapshot} "$@"
    '';
  };

  # Chromeプロファイルを所有するユーザーとして実行し、root所有のファイルを作らない。
  runAsUser = "/usr/bin/sudo -H -u ${lib.escapeShellArg config.system.primaryUser} -- ${restoreChrome}/bin/restore-chrome-settings";
in
{
  # 適用後に手動で復元・変更予定の確認を行えるコマンドをインストールする。
  environment.systemPackages = [ restoreChrome ];

  # 設定適用前にChromeの終了を確認する。起動中なら適用処理を止める。
  system.activationScripts.preActivation.text = lib.mkBefore ''
    ${runAsUser} --check-closed
  '';

  # darwin-rebuild switchの最後に、保存済みのChrome設定を復元する。
  # policyCandidatesは使わず、通常のpreferencesのみを対象とする。
  system.activationScripts.postActivation.text = lib.mkAfter ''
    ${runAsUser}
  '';
}
