# Macの設定と開発環境を復元する

Apple Silicon搭載Macの設定を、Nix・Flakes・nix-darwin・Home Managerで管理します。
macOSの初期セットアップ後、このリポジトリからアプリ、開発ツール、管理対象の設定を導入する手順です。
対象はmacOS 26系です。

| 管理対象 | 担当 |
| --- | --- |
| Dock・Finder・キーボード・トラックパッド・外観など | nix-darwinの`system.defaults` |
| Chrome・ChatGPT・VS Code、Hack Nerd Font | nix-darwin |
| Codex CLI・Neovim・Node.js・npm・Rustと開発用コマンド | Home Manager |
| LazyVimの起動設定 | Home Manager |
| Chromeの保存設定、Terminalのフォント | nix-darwinから専用スクリプトを実行 |

Mac全体を復元する構成ではありません。Apple Account・Google等へのログイン、Chromeの同期、
パスワード、Cookie、閲覧履歴、ブックマーク、写真・文書、壁紙、ディスプレイ、ネットワーク、
入力ソース、プライバシー権限などは別途復元・設定してください。
`system.defaults`に書いていない項目は管理対象外です。macOS内部キーはOSの版によって動作が変わる場合があります。

## ファイルの役割

| ファイル | 役割 |
| --- | --- |
| `flake.nix` | Nixpkgs・nix-darwin・Home Managerの依存とMacの構成名 |
| `configuration.nix` | CPU種別、対象ユーザー、Nix設定、Home Managerとの統合 |
| `macos.nix` | macOS設定、Hack Nerd Fontの導入、Terminalのフォント設定 |
| `apps.nix` | GUIアプリの導入と非自由ライセンスの許可 |
| `home.nix` | 開発ツールとLazyVimの設定を対象ユーザーに導入 |
| `nvim/` | LazyVimをデフォルト設定で起動するLuaファイル |
| `chrome.nix` | Chromeの復元元データと復元コマンド |
| `scripts/` | Chrome設定のマージとTerminalフォントの変更 |
| `tests/` | 復元スクリプトのユニットテスト |
| `.github/workflows/tests.yml` | PR時のテストとNix・Luaの構文確認 |
| `.gitignore` | ローカルの依存ロック、ビルド結果などの除外 |

Home Managerはnix-darwinに組み込んでいるため、両方を`darwin-rebuild switch`で適用します。
Chrome用JSONはNixストア内で生成します。JSONや取り込みスクリプトを用意する必要はありません。

## 0. 今のMacを初期化する場合の準備

初期化を行わず現在のMacに導入する場合、または新しいMacで作業中の場合は「1」へ進んでください。

現在のリポジトリのルートへ移動し、変更と保存対象を確認します。
以下の`~/Documents/nix`は標準の作業場所です。別の場所にある場合は、その配置先に読み替えてください。

```sh
cd ~/Documents/nix
git status
git diff
git diff --cached
```

変更を確認してからGitHubへ保存します。バックアップや認証情報を追加しないでください。

```sh
git add -A
git diff --cached
git commit -m "Save Mac configuration for restoration"
git push origin main
```

コミットする変更がなければ`git commit`は不要です。GitHubに必要な設定が保存されていることを確認します。
文書・写真などは別にバックアップし、GitHubやApple Accountにも新しいMacからログインできるようにします。
このREADMEではMacの消去を実行しません。

## 1. macOSとCommand Line Toolsを準備する

macOSのセットアップを終え、管理者権限を持つユーザーでログインし、インターネットに接続します。
対象のCPU・OS・ユーザーを確認してください。

```sh
uname -m
sw_vers
id -un
```

CPUは`arm64`、OSはmacOS 26系が対象です。Intel Mac向けの手順ではありません。
元のユーザー名は`yanmakazuki`ですが、別のユーザー名でも「4」で構成を変更できます。

Gitと、構文解析器などのビルドに使うCコンパイラを導入します。

```sh
xcode-select --install
```

すでに導入済みならそのまま進みます。インストール完了後に確認します。

```sh
xcode-select -p
git --version
clang --version
```

## 2. リポジトリを取得する

新しいMacでは、作業場所を`~/Documents/nix`とします。すでに取得済みなら、そのリポジトリへ移動してください。

```sh
mkdir -p ~/Documents
git clone https://github.com/yanmakazuki/nix.git ~/Documents/nix
cd ~/Documents/nix
```

非公開リポジトリの場合はGitHub認証が必要です。HTTPSのPassword欄には、GitHubのログインパスワードではなく、
このリポジトリを読み取れるPersonal Access Tokenを使用します。SSH設定済みならSSH URLも使えます。
認証情報を設定ファイルやREADMEに保存しないでください。

以降のコマンドは、このリポジトリのルートで実行します。

## 3. Nixを導入する

まず導入済みか確認します。

```sh
nix --version
```

使える場合は再インストールせず「4」へ進みます。未導入の場合は、[Lixの公式インストーラー](https://lix.systems/install/)を使用します。
Lixでも`nix`コマンドが使えます。

```sh
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
```

インストーラーの案内に従い、必要な管理者認証を行います。
完了後はTerminalを終了して開き直し、リポジトリへ戻って確認します。

```sh
cd ~/Documents/nix
nix --version
```

この構成は`nix.package = pkgs.nixVersions.latest;`を指定しているため、初回適用後は通常のupstream Nixを管理します。
Lixを継続使用する設定ではありません。導入に使うLixと、構成適用後に管理するNixを区別してください。

## 4. 対象ユーザーと設定を確認する

`configuration.nix`の次の値を、`id -un`で確認したユーザー名に合わせます。

```nix
system.primaryUser = "yanmakazuki";
```

macOSで作成済みのユーザーを指定します。この指定でアカウントを新規作成するわけではありません。
Home Managerも同じユーザーを対象にし、ホームディレクトリを`/Users/<ユーザー名>`として管理します。
実際のホームディレクトリが異なる場合は、`configuration.nix`の`users.users`の指定も変更してください。

`system.stateVersion = 7;`と`home.stateVersion = "26.05";`は互換性の基準です。
パッケージの更新に合わせて変更する値ではありません。
構成名`Kazukis-MacBook-Air`はNix側の識別名です。実際のMac名が異なっても、以下のコマンドで構成名を指定すれば選択できます。
この構成はMacのコンピュータ名を変更しません。

導入するGUIアプリはChrome・ChatGPT・VS Codeです。事前の手動インストールは不要です。
非自由ライセンスは、`apps.nix`でこの3パッケージに限って許可します。
アプリは`/Applications/Nix Apps`へ配置し、既存のHomebrewや手動導入済みアプリは削除しません。
同名アプリが複数ある場合は、Nix Apps側を起動してください。

DockにはChrome・Terminal・ChatGPT・Appsを固定します。OS側のアプリのパスを確認してください。

```sh
ls -d /System/Applications/Utilities/Terminal.app /System/Applications/Apps.app
```

存在しないアプリや不要な項目は、適用前に`macos.nix`の`persistent-apps`から外すか、実際のパスに変更します。

設定の変更・新規ファイルの追加がある場合は、ビルド前にGitの管理対象へ追加します。コミットはまだ不要です。

```sh
git status
git add -A
git diff --cached
```

Git管理のFlakeは未追跡ファイルを含めません。`home.nix`などを新しく作った場合も、この操作が必要です。
ステージしたファイルに認証情報やバックアップが含まれていないことを確認してください。

## 5. 依存を取得してビルドする

Nixpkgsの`nixpkgs-unstable`、nix-darwinとHome Managerの`master`を取得します。
このリポジトリは、復元・更新前に依存を最新へ更新する運用です。

```sh
nix --extra-experimental-features 'nix-command flakes' flake update
```

`flake.lock`をローカルに生成・更新します。Git管理には含めません。
同じロックをビルドと適用で使い、途中で依存が変わらないようにします。
次回更新まではこのロックが使われますが、別のMacで同じ依存を再現する運用にはなっていません。

設定を適用せず、まずビルドします。

```sh
nix --extra-experimental-features 'nix-command flakes' build \
  '.#darwinConfigurations.Kazukis-MacBook-Air.system' \
  --no-update-lock-file
```

成功すると`result`リンクが作られます。失敗したらエラーを解決し、成功するまで適用へ進みません。
ビルド後から適用まで、設定ファイルと`flake.lock`を変更しないでください。

## 6. 構成を適用する

Chromeをメニューの「終了」またはCommand+Qで完全に終了します。
ウィンドウを閉じるだけではプロセスが残ることがあります。復元が終わるまで起動しないでください。
Chromeが起動していれば、事前確認で適用を止めます。

初回は、ビルド結果に含まれる`darwin-rebuild`を使います。

```sh
sudo ./result/sw/bin/darwin-rebuild switch \
  --flake '.#Kazukis-MacBook-Air' \
  --no-update-lock-file
```

管理者パスワードを入力します。入力中の文字は表示されません。
このコマンドは構成のビルドも行うため、依存取得が必要になる場合に備えてインターネット接続を維持します。
macOS設定、GUIアプリ、フォント、Home Managerの開発ツールと設定、ChromeとTerminalの復元処理を適用します。
Nixデーモンやシェル初期化などもnix-darwinが管理します。

Home Managerへの初回移行では、競合する既存設定ファイルを隣の`<ファイル名>.before-home-manager`へ退避します。
同名のバックアップがすでにあると、上書きせず停止します。その場合は既存バックアップを別名で保管して再実行してください。
途中で失敗した場合、一部の処理は適用済みの可能性があります。ログのエラーを解決してから再実行します。

完了後はログアウト・ログインし直し、Terminalも終了して開き直します。
再起動が必要な項目はMacを再起動して確認してください。

## 7. アプリと開発ツールを確認する

対象ユーザーのTerminalで実行します。

```sh
ls -d "/Applications/Nix Apps/Google Chrome.app" "/Applications/Nix Apps/ChatGPT.app" "/Applications/Nix Apps/Visual Studio Code.app"
nix --version
command -v darwin-rebuild
codex --version
code --version
nvim --version
node --version
npm --version
npx --version
rustc --version
cargo --version
rust-analyzer --version
rustfmt --version
cargo clippy --version
```

ChatGPT・Codex CLIは起動して必要なログインを行います。VS Codeでは`code .`でフォルダーを開けます。
既存のツールがPATHで優先される場合は、`command -v node`などで実際に使われるコマンドを確認してください。

### LazyVim

```sh
nvim
```

初回起動でlazy.nvim・LazyVimとプラグインを取得するため、インターネット接続が必要です。
完了後、Neovim内で`:LazyHealth`を実行します。必要な言語サーバー等はMasonから追加します。
構文解析器のビルドには「1」で導入したCコンパイラを使用します。

設定はLazyVimのデフォルトです。`home.nix`が`nvim/init.lua`と`nvim/lua/config/lazy.lua`を読み込んで管理します。
配置された設定は読み取り専用なので、変更はリポジトリ側で行って再適用してください。
ファイル単位の管理により、`~/.config/nvim/lazy-lock.json`は書き込み可能です。
管理対象外の既存ファイルは保持されるため、以前の独自設定があればその影響も確認してください。

### Rustのビルド

バージョン確認に加え、コンパイラとCargoが動くことを一時プロジェクトで確認できます。

```sh
rust_check_dir="$(mktemp -d)"
cargo new --bin "$rust_check_dir/check"
cargo test --manifest-path "$rust_check_dir/check/Cargo.toml"
cargo clippy --manifest-path "$rust_check_dir/check/Cargo.toml"
```

### Terminalのフォント

Terminalの「設定 → プロファイル → テキスト」で、Hack Nerd Font Mono・13ptになっているか確認します。
全プロファイルのフォントを変更し、色などの既存設定は保持します。
反映されない場合はTerminalを完全に終了して再起動してください。
Terminal.appにはLazyVim推奨端末との表示機能の差があります。詳しい要件は[LazyVim公式ドキュメント](https://www.lazyvim.org/)を参照してください。

## 8. ChromeとmacOS設定を確認する

Chromeを起動して、外観、言語、スペルチェック、サイト権限などを確認します。
復元先は対象ユーザーの`~/Library/Application Support/Google/Chrome/<プロファイル名>/Preferences`です。
`chrome.nix`の通常の`preferences`だけをマージし、保存データにない設定は保持します。
プロファイルがなければ作成し、値が一致していれば書き込みません。

拡張機能関連などの保護対象と`policyCandidates`は適用しません。
`extensions.theme.id`は必要に応じて手動設定してください。
Chromeの同期・ポリシー・内部キーの変更により、保存値がGUIへ反映されない場合があります。
アカウントへのログイン、ブックマークやパスワードの同期・復元は別途行います。

主要なmacOS設定を確認します。

```sh
defaults read com.apple.dock autohide
defaults read com.apple.dock tilesize
defaults read com.apple.finder FXPreferredViewStyle
defaults read -g KeyRepeat
defaults read -g InitialKeyRepeat
defaults read com.apple.AppleMultitouchTrackpad Clicking
```

現在の期待値は順に`1`、`50`、`Nlsv`、`2`、`15`、`1`です。設定を変更した場合は変更後の値と比較します。
GUIでもDockの並びと起動先、Finderの表示、キーボード、トラックパッド、外観、言語・地域、時計、ウィンドウ配置を確認します。
別に復元した個人データが開けることも確認してください。

## 日常の変更・更新

リポジトリのルートで設定を編集し、新規ファイルもGitの管理対象へ追加してから依存を更新・ビルドします。

```sh
git status
git add -A
git diff --cached
nix flake update
darwin-rebuild build --flake '.#Kazukis-MacBook-Air' --no-update-lock-file
```

ビルドが成功したらChromeを完全に終了し、設定とロックを変更せずに適用します。

```sh
sudo darwin-rebuild switch --flake '.#Kazukis-MacBook-Air' --no-update-lock-file
```

管理対象のGUI設定は次回適用でNixの指定値へ戻ります。
Nixから項目を削除してもmacOSの既定値へ戻るとは限りません。戻したい値を明示して適用してください。
成功後、設定変更をコミットしてpushします。`flake.lock`はコミットしません。
パッケージの版はNixpkgsへの収録状況に依存し、配布元の最新版と一致しない場合があります。

## 復元処理だけを実行する

最後にビルド・適用した設定を使用します。リポジトリを編集しただけではコマンド内の設定は更新されません。
対象ユーザーとして実行し、以下のコマンドに`sudo`は付けません。

Chromeを完全に終了してから、変更予定の確認または復元を行います。

```sh
restore-chrome-settings --dry-run
restore-chrome-settings
```

Terminalのフォントを再適用する場合は、以下を実行してからTerminalを終了・再起動します。

```sh
setup-terminal-font
```

## バックアップとロールバック

| 対象 | バックアップ |
| --- | --- |
| Chrome | プロファイル内の`Preferences.before-nix-<日時>` |
| Terminal | `~/Library/Application Support/nix-settings/terminal-backups/`内のplist |
| Home Manager移行時の既存設定 | 管理対象ファイルの隣の`<ファイル名>.before-home-manager` |

バックアップには個人情報が含まれる可能性があります。Gitへ追加せず、Mac内や別のバックアップ先で保管してください。

過去に適用した世代がある場合は、Chromeを完全に終了してから戻せます。

```sh
sudo darwin-rebuild switch --rollback
```

構成のロールバックは、アプリが保持するデータの復元ではありません。
前の世代に含まれるChrome・Terminalの復元処理が再実行される場合があります。
初回適用前のMac全体や、管理対象から外れたmacOS設定を自動で元に戻すものでもありません。

Chromeを適用前の状態に戻すには、Chromeを終了し、選んだバックアップを同じプロファイルの`Preferences`へコピーします。
Terminalを戻すには、Terminalを終了した状態で別のターミナルアプリから、選んだplistを対象ユーザーとしてインポートします。

```sh
defaults import com.apple.Terminal "/実際のパス/選んだバックアップ.plist"
```

その後Terminalを起動してください。Nix設定にも戻したい値を反映しない限り、次回適用で再び構成の指定値に変わります。

## 困ったとき

| 症状 | 確認すること |
| --- | --- |
| `nix`が見つからない | 導入完了とTerminalの開き直しを確認。インストーラーのシェル初期化の案内に従う |
| `darwin-rebuild`が見つからない | 初回は`./result/sw/bin/darwin-rebuild`。適用後は`/run/current-system/sw/bin/darwin-rebuild`の存在を確認 |
| 新しい設定ファイルが見つからない | `git status`を確認し、必要なファイルを`git add`して再ビルド |
| GitHubの認証エラー | リポジトリへのアクセス権と認証方法を確認 |
| Home Managerのバックアップ名が衝突 | 既存の`.before-home-manager`ファイルを別名で保管して再適用 |
| `/etc`の既存ファイルと衝突 | 指定されたファイルの内容・差分を確認し、バックアップして個別に対処 |
| Nix Apps更新時の権限エラー | システム設定の「プライバシーとセキュリティ → アプリ管理」で適用に使うターミナルの権限を確認 |
| 設定がGUIへ反映されない | ログアウト・ログイン、対象アプリの再起動、OSの版、MDM等の管理設定を確認 |

適用途中の失敗はMacの設定全体を自動で戻す処理ではありません。ログを確認し、原因を解消して再実行してください。

## 自動テストと検証状況

PRの作成・更新・再オープン時に、GitHub Actionsで以下を実行します。Actions画面から手動実行もできます。

- Linux・macOSでPythonのユニットテスト（Python 3.13）。
- Git管理しているNix・Luaファイルの構文確認。

ローカルではリポジトリのルートで実行します。

```sh
python3 -B -m unittest discover -s tests -v
```

Chrome設定のマージ、バックアップ、再適用、Chrome起動中や不正な設定への書き込み拒否、
Terminal設定の保持を検証します。実際のChrome・Terminal設定へは書き込みません。
テスト成功をマージの条件にする場合は、GitHubのブランチ保護またはRulesetsで以下を必須チェックに指定します。

- `Python tests (ubuntu-24.04)`
- `Python tests (macos-15)`
- `Nix and Lua syntax`

2026年10月8日時点で、Home Managerを含むNix構成全体の評価とPythonテスト12件の成功を確認しています。
Nix構成の評価成功はビルド成功を意味しません。ビルド、実機への適用、Chromeの実画面、
初期状態のMacから一連の復元を行うテストは未確認です。
CIも依存解決・nix-darwinのビルド・実機の設定適用までは検証しません。

## 参考資料

- [nix-darwinの導入手順](https://github.com/nix-darwin/nix-darwin)
- [nix-darwinの設定オプション](https://nix-darwin.github.io/nix-darwin/manual/)
- [Home Managerとnix-darwinの統合](https://github.com/nix-community/home-manager/blob/master/docs/manual/nix-flakes/nix-darwin.md)
- [Lixのインストール](https://lix.systems/install/)
- [Git管理のFlake](https://nix.dev/manual/nix/2.28/command-ref/new-cli/nix3-flake.html)
- [darwin-rebuildの実装](https://github.com/nix-darwin/nix-darwin/blob/master/pkgs/nix-tools/darwin-rebuild.sh)
- [Chromeの通常設定とポリシー](https://www.chromium.org/administrators/configuring-other-preferences/)
- [LazyVimの要件](https://www.lazyvim.org/)
