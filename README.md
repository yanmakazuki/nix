# Macの設定を復元する

このリポジトリは、Apple Silicon搭載Macの設定をnix-darwin、開発ツールとユーザー設定をHome Managerで管理します。
初期設定が完了したMacにNixを導入し、このリポジトリを取得して設定を適用するまでの手順です。

対象はmacOS 26系です。元のMacではmacOS 26.7.1から設定を取り込みました。
**現時点ではMac全体の完全な復元ではありません。** macOSの管理対象設定はNixで適用し、
Chromeの保存設定もNix適用時に復元します。Chrome・ChatGPT・VS CodeのGUIとCodex CLI、Neovim・LazyVim、Hack Nerd Font、Node.js・npm、Rust・rust-analyzerも導入します。
保護対象のChrome設定、拡張機能、アカウントへのログインなどは手動で補います。

## 復元できる範囲

| 対象 | 復元方法 |
| --- | --- |
| Dock・Finder・キーリピート・トラックパッド | nix-darwinで適用 |
| macOSの外観・言語・地域・時計・一部のメニューバー設定 | nix-darwinで適用。再ログインが必要な場合あり |
| ウィンドウ配置の動作・Stage Manager関連設定 | nix-darwinで適用 |
| Dockに固定するアプリの順序 | nix-darwinで適用。Chrome・ChatGPT本体も同じ適用処理で導入 |
| Chromeの表示・入力・サイト権限の保存設定 | Chromeを終了し、Nix適用時に復元。保護対象は除外 |
| Chrome・ChatGPT・VS CodeのGUI、VS Codeのコマンド | nix-darwinから導入・更新 |
| Codex CLI・Neovim・Node.js・Rustと開発用コマンド | Home Managerから導入・更新 |
| LazyVimの起動設定 | Home Managerで設定ファイルを管理 |
| その他のアプリ、拡張機能、Apple Account・Google等のログイン | 手動で導入・設定 |
| 文書・写真・パスワード・Cookie・閲覧履歴・ブックマーク | このリポジトリの対象外。別のバックアップや同期から復元 |
| 壁紙・ディスプレイ・電源・ネットワーク・入力ソース・プライバシー権限 | 必要に応じて手動設定 |

`system.defaults`で指定した項目だけが管理対象です。指定していないmacOSの設定は、この構成から復元できません。
`CustomUserPreferences`にあるmacOS内部キーは、OSのバージョンによって動作が変わる場合があります。

## ファイルの役割

| ファイル | 役割 |
| --- | --- |
| `flake.nix` | 最新を取得するNixpkgs・nix-darwin・Home Managerの参照先、およびMacの構成名 |
| `configuration.nix` | CPU種別、対象ユーザー、Nixの機能設定、読み込むモジュール |
| `apps.nix` | GUIアプリの導入・更新と非自由ライセンスの許可 |
| `macos.nix` | macOS設定、Hack Nerd Fontの導入、Terminalのフォント設定 |
| `home.nix` | Home Managerで開発ツールとLazyVimの設定ファイルを管理 |
| `nvim/` | LazyVimをデフォルト設定で起動するためのLuaファイル |
| `scripts/setup_terminal_font.py` | Terminalの既存プロファイルのフォントを変更 |
| `chrome.nix` | Chromeの復元元データと復元コマンドを定義し、Nix適用時に通常の`preferences`を復元するモジュール |
| `scripts/restore_chrome_settings.py` | Chromeの終了確認、設定のマージ、バックアップを行う処理 |
| `tests/test_restore_chrome_settings.py` | 復元処理のテスト |
| `flake.lock` | 今回取得した依存の版をローカルで保持。Git管理には含めない |
| `.gitignore` | 依存のロックファイル、ビルド結果などをGit管理から除外 |

適用時は `flake.nix` → `configuration.nix` から、macOS用の`macos.nix`、Chrome用の`chrome.nix`、GUIアプリ用の`apps.nix`を読み込みます。
`flake.nix`でHome Managerをnix-darwinに組み込み、`configuration.nix`で対象ユーザーの`home.nix`を読み込みます。
Home Managerも同じ`darwin-rebuild switch`で適用され、別の適用コマンドは不要です。
`chrome.nix`が内部の`chromeSettings`をJSONへ変換し、復元スクリプトに渡します。
JSONはNixストア内で生成するため、リポジトリにJSONファイルを追加する必要はありません。
確認用の`capture-report.json`と`chrome-capture-report.json`は復元に不要です。
取り込みスクリプトは現在の作業ディレクトリにはありません。以降の手順では使用しません。

## 0. 今のMacを初期化する前に

すでに初期状態のMacで作業している場合は、次の「1. macOSの初期設定」へ進みます。

現在のMacでは、まずリポジトリの最新状態をGitHubに保存します。

```sh
cd /Users/yanmakazuki/Documents/Codex/2026-10-07/ko/outputs/mac-settings/nix
git status
git diff
```

変更を確認してから保存します。コミットする変更がない場合は、`git commit`は不要です。

```sh
git add -A
git commit -m "Save Mac configuration for restoration"
git push origin main
```

GitHub上のファイルが最新であることを確認してください。
また、文書や写真などを別途バックアップし、GitHubやApple Accountなどに新しいMacからログインできる状態にします。
この手順ではMacの消去自体は実行しません。

依存バージョンは固定せず、復元・更新前に最新を取得します。`flake.lock`はGitには保存しません。
そのため、復元時に使用する依存は、初期化前に使用していたものと同じとは限りません。

## 1. macOSの初期設定

1. macOSのセットアップを完了し、インターネットに接続します。
2. 管理者権限のあるユーザーを作成します。元と同じ設定を使う場合、アカウントの短い名前は`yanmakazuki`にします。
3. Apple Siliconで、macOS 26系であることを確認します。
4. 必要な個人データをバックアップや同期から戻します。

ターミナルで確認できます。

```sh
uname -m
sw_vers
id -un
```

元の構成では、CPUが`arm64`、ユーザーが`yanmakazuki`です。
ユーザー名が異なっていても、後で`configuration.nix`を修正すれば使用できます。
Intel Macはこの手順の対象外です。

## 2. Command Line Toolsを導入する

Gitを使うため、ターミナルで次を実行し、表示されるインストール案内に従います。

```sh
xcode-select --install
```

すでに導入済みと表示された場合は、そのまま進みます。インストール完了後に確認します。

```sh
xcode-select -p
git --version
```

## 3. リポジトリを取得する

新しいMacでは、作業場所を`~/Documents/nix`にします。元の日時付きフォルダーを再作成する必要はありません。

```sh
mkdir -p ~/Documents
git clone https://github.com/yanmakazuki/nix.git ~/Documents/nix
cd ~/Documents/nix
```

非公開リポジトリの場合はGitHub認証が必要です。HTTPS認証のPassword欄には、GitHubのログインパスワードではなく、
このリポジトリを読み取れるPersonal Access Tokenを入力します。SSH認証を設定済みならSSH URLで取得しても構いません。

以降のコマンドはリポジトリのルートで実行します。
別の場所にcloneした場合は、その場所に`cd`してください。

## 4. Nixを導入し、対象ユーザーとアプリを準備する

### Nixの導入

Nix未導入のMacでは、nix-darwin公式が案内するLixインストーラーで導入できます。
[Lixの公式手順](https://lix.systems/install/)も確認してください。

```sh
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
```

インストーラーの案内を確認し、必要な管理者認証を行います。
完了後はターミナルを開き直し、リポジトリに戻って確認します。

```sh
cd ~/Documents/nix
nix --version
```

この構成はnix-darwinの標準動作に従い、初回適用後はupstream Nixを管理します。
`nix.package = pkgs.nixVersions.latest;` により、取得したNixpkgsで提供される最新リリースのNixを使います。
上流の公開直後はNixpkgsへの反映を待つ場合があります。
Lixを継続して使う構成にはしていません。すでに動作するNixがある場合、再インストールは不要です。

### 対象ユーザーの確認

`configuration.nix`の次の行を、`id -un`の結果と合わせます。

```nix
system.primaryUser = "yanmakazuki";
```

この指定でユーザーを作成するわけではありません。macOSで作成済みのユーザーを指定してください。
`system.stateVersion = 7;`と`home.nix`の`home.stateVersion = "26.05";`は互換性の指定なので、通常は変更しません。
Home Managerのユーザー名とホームディレクトリは`system.primaryUser`から決まります。
ホームディレクトリが`/Users/<ユーザー名>`と異なる場合は、`configuration.nix`の`users.users`も修正してください。

構成名`Kazukis-MacBook-Air`はNix側の識別名です。
Macの実際のホスト名が違っていても、下記のコマンドでこの名前を明示していれば構成を選択できます。
この構成はMacのコンピュータ名を変更しません。

### アプリの導入設定

`macos.nix`の`persistent-apps`は、次のパスを参照します。

- `/Applications/Nix Apps/Google Chrome.app`
- `/System/Applications/Utilities/Terminal.app`
- `/Applications/Nix Apps/ChatGPT.app`
- `/System/Applications/Apps.app`

`apps.nix`（GUIアプリ）と`home.nix`（開発ツール）により、初回の`darwin-rebuild switch`で次を導入します。
事前にChromeやChatGPTを手動インストールする必要はありません。

| 用途 | 導入するもの |
| --- | --- |
| Chrome GUI | `/Applications/Nix Apps/Google Chrome.app` |
| ChatGPT GUI | `/Applications/Nix Apps/ChatGPT.app` |
| OpenAI CUI | Codex CLIの`codex`コマンド |
| VS Code GUI・CUI | `/Applications/Nix Apps/Visual Studio Code.app`と`code`コマンド |
| Node.js・npm | `node`・`npm`・`npx`コマンド（`pkgs.nodejs`から導入） |
| Rust開発 | `rustc`・`cargo`・`rust-analyzer`・`rustfmt`・Clippy |

ChatGPTのCUIとしてCodex CLIを採用しています。端末で使うコーディングエージェントで、
ChatGPT GUIの全機能を端末に再現するものではありません。ChromeのCUIは追加しません。

Chrome・ChatGPT・VS Codeの非自由ライセンスは、`apps.nix`で対象の3パッケージに限って許可します。
GUIアプリはnix-darwinが`/Applications/Nix Apps`へ配置します。
Chromeはアプリだけを公開し、`google-chrome`等のCUIコマンドは追加しません。

アプリも`nix flake update`→ビルド→適用で更新し、取得したNixpkgsに収録されている版を使用します。
配布元の新リリースがNixpkgsへ反映されるまで時間がかかる場合があります。
ビルド時にパッケージを取得・構築し、適用時にアプリとコマンドを配置します。
この構成はHomebrewを導入・使用しません。すでにMacにあるHomebrewや手動導入済みアプリは削除しません。
同名の手動導入済みアプリがある場合は、Dockの参照先と同じ`/Applications/Nix Apps`側を起動してください。

TerminalとAppsはmacOS側のアプリです。OSの版によってパスが異なる場合は、Nix設定側を実際のパスに合わせます。
適用後に次のコマンドでパスを確認できます。

```sh
ls -d "/Applications/Nix Apps/Google Chrome.app" "/Applications/Nix Apps/ChatGPT.app"
ls -d /System/Applications/Utilities/Terminal.app /System/Applications/Apps.app
```

使わないアプリや存在しないアプリは、`persistent-apps`からその項目を外してから適用してください。
アプリのインストール場所や名称が違う場合は、実際のパスに修正します。

## 5. 最新の依存を取得してビルドする

この構成はNixpkgsの`nixpkgs-unstable`とnix-darwinの`master`に追従します。
復元・更新のたびに、まず次を実行して最新の依存を取得します。

```sh
nix --extra-experimental-features 'nix-command flakes' flake update
```

`flake.lock`がローカルに生成・更新されますが、Git管理からは除外しています。
これは今回のビルドと適用で同じ依存を使うためのものです。
一度生成した後も、上の更新コマンドを実行しなければ最新には切り替わりません。
下記の`--no-update-lock-file`は、直前に取得した版をビルドから適用まで揃えるための指定です。
次回の更新を妨げるものではありません。

設定を適用する前に、まずビルドだけを実行します。

```sh
nix --extra-experimental-features 'nix-command flakes' build \
  '.#darwinConfigurations.Kazukis-MacBook-Air.system' \
  --no-update-lock-file
```

成功すると、このフォルダーに`result`というリンクが作られます。
失敗した場合は、エラーを解決してビルドが成功するまで、次の適用手順へ進みません。

## 6. macOS設定とアプリを適用する

**Chromeをメニューの「終了」またはCommand+Qで完全に終了してください。**
ウィンドウを閉じただけではプロセスが残る場合があります。復元が終わるまでChromeを起動しません。
Chromeのプロセスが残っていれば、事前確認で適用を止めます。

ビルドした構成に含まれる`darwin-rebuild`で初回適用します。

```sh
sudo ./result/sw/bin/darwin-rebuild switch \
  --flake '.#Kazukis-MacBook-Air' \
  --no-update-lock-file
```

管理者パスワードを入力します。入力中の文字はターミナルに表示されません。
この処理でアプリも導入・更新するため、インターネット接続が必要です。
nix-darwinは設定値に加えて、Nixデーモンやシステムのシェル初期化などの基盤も管理します。

適用後は一度ログアウトしてログインし直し、ターミナルも開き直します。
再起動が必要な項目は、Macを再起動して確認してください。

## 7. Chromeの復元結果を確認する

「6. macOS設定とアプリを適用する」の最後に、`system.primaryUser`のユーザーとしてChrome復元処理を実行します。
保存先はそのユーザーの`~/Library/Application Support/Google/Chrome/<プロファイル名>/Preferences`です。
現在の保存データはDefaultプロファイルの28項目で、このうち27項目を復元します。
設定を追加・削除した場合は、コマンドが表示する項目数を確認してください。

- 保存データにある通常の`preferences`だけを反映します。
- 保存データにない設定は維持します。辞書の一部を変更する場合も、対象外のキーは残します。
- プロファイルがまだない場合は、ディレクトリとPreferencesを作成します。
- 変更前のファイルを、同じディレクトリの`Preferences.before-nix-<日時>`へバックアップします。
- 既に値が一致している場合は書き込みもバックアップ作成も行いません。
- Chrome起動中、不正な既存ファイル、設定構造の衝突などがあれば復元を止めます。
- 拡張機能関連などの保護対象、`policyCandidates`、ログイン情報は適用しません。

現在の保存設定のうち、`extensions.theme.id`は自動適用せず、Chromeの外観設定で必要に応じて設定します。
Chromeのポリシーや同期、内部キーの変更によって、ファイルに書き込んだ値がGUIに反映されない場合があります。
適用後にChromeを起動して、外観・言語・スペルチェック・サイト権限などを確認してください。

復元処理だけを実行したい場合は、Nix構成の適用後、対象ユーザーのターミナルで次を実行します。
Chromeは終了しておきます。このコマンドに`sudo`は付けません。

変更予定の確認だけを行う場合：

```sh
restore-chrome-settings --dry-run
```

保存済み設定を復元する場合：

```sh
restore-chrome-settings
```

このコマンドは最後にビルド・適用した構成のデータを使用します。
`chrome.nix`の`chromeSettings`を編集した後は、再度ビルド・適用してコマンド側のデータも更新します。

バックアップから戻したい場合はChromeを終了し、ログに表示されたバックアップを
該当プロファイルの`Preferences`へコピーしてからChromeを起動します。
バックアップには元のプロファイルの設定が含まれるため、Gitへ追加せず、Mac内で保管してください。

必要なGoogleアカウントへのログイン、ブックマークやパスワードの同期・復元は別途行います。
このリポジトリにはCookie、パスワード、閲覧履歴、ブックマーク、拡張機能本体は保存していません。

## 8. 復元を確認する

アプリとコマンドを確認します。

```sh
ls -d "/Applications/Nix Apps/Google Chrome.app" "/Applications/Nix Apps/ChatGPT.app" "/Applications/Nix Apps/Visual Studio Code.app"
codex --version
code --version
```

ChatGPTはアプリを起動してログインします。Codex CLIは対象ユーザーのターミナルで`codex`を実行し、
案内に従ってChatGPTアカウントでログインしてください。認証情報はこのリポジトリに保存しません。
VS Codeでフォルダーを開くには`code .`を使います。

ターミナルで、主要な管理対象の値を確認します。

```sh
nix --version
command -v darwin-rebuild
defaults read com.apple.dock autohide
defaults read com.apple.dock tilesize
defaults read com.apple.finder FXPreferredViewStyle
defaults read -g KeyRepeat
defaults read -g InitialKeyRepeat
defaults read com.apple.AppleMultitouchTrackpad Clicking
```

現在の構成の期待値は、Dock自動非表示`1`、アイコンサイズ`50`、Finder表示`Nlsv`、
キーリピート`2`、開始待ち`15`、タップクリック`1`です。
設定ファイルを変更した場合は、変更後の値と比較してください。

さらにGUIで確認します。

- Dockの並びと、クリックしたアプリが正しく起動すること。
- Finderの表示形式と、新規ウィンドウがホームフォルダーを開くこと。
- キーボード、トラックパッド、外観、言語・地域の設定。
- 時計、メニューバー、ウィンドウ配置の動作。
- Chromeで復元した項目、手動設定した保護対象の項目、必要なログイン・同期状態。
- 別途復元した個人データが開けること。

これで、このリポジトリが対象にする設定の復元と、手動で補う作業の確認が完了です。
Mac全体を完全に再現したことを保証する手順ではありません。

## 日常の変更・更新

Nix設定を編集した後は、同じフォルダーでビルドしてから適用します。
Chromeを完全に終了してから`switch`を実行してください。

```sh
nix flake update
darwin-rebuild build --flake '.#Kazukis-MacBook-Air' --no-update-lock-file
sudo darwin-rebuild switch --flake '.#Kazukis-MacBook-Air' --no-update-lock-file
```

GUIで変更した管理対象の値は、次回適用時にNixの指定値へ戻ります。Chromeの復元対象も同様です。
Nixから項目を削除してもmacOSの既定値に戻るとは限りません。戻したい値を明示して適用してください。

上の手順は、設定変更の適用前にも依存を最新へ更新します。
最新の依存によって設定オプションや挙動が変わる場合があるため、ビルドの成功と適用後の動作を確認します。
成功後は変更したNixファイルをコミットしてpushします。`flake.lock`はコミットしません。
既存のNixファイルを編集して管理する構成なので、macOSやChromeからの再取り込みコマンドは現在ありません。

## 困ったとき

### `nix`が見つからない

インストールが完了していることを確認してターミナルを開き直します。
インストーラーがシェルの初期化方法を案内している場合は、その指示に従います。

### `darwin-rebuild`が見つからない

初回は「6. macOS設定とアプリを適用する」の`./result/sw/bin/darwin-rebuild`を使用します。
初回適用後にターミナルを開き直しても見つからない場合は、次を確認します。

```sh
ls -l /run/current-system/sw/bin/darwin-rebuild
```

存在すれば、その絶対パスで実行できます。

### GitHubの取得で認証エラーになる

非公開リポジトリなら、認証情報とリポジトリへのアクセス権を確認します。
認証情報はNixファイルやREADMEに保存しません。

### `/etc`の既存ファイルとの衝突で適用が止まる

エラーが指すファイルを読み、バックアップと差分を確認してから個別に解決します。
関係ないシステムファイルを一括削除して進めないでください。

### Nix Apps内のアプリの更新で権限エラーになる

適用に使うターミナルに、システム設定の「プライバシーとセキュリティ」→「アプリ管理」で権限を付与し、
再度適用します。nix-darwinのエラーに表示される案内も確認してください。

### 設定が反映されない

ログアウト・再ログイン、対象アプリの再起動を行います。
コマンドで保存値が一致しているのにGUIが違う場合、macOSの版や内部キーの対応を確認します。
MDMなど別の管理機構があるMacでは、その設定が優先される場合があります。

### 前のNix構成へ戻したい

過去に適用した世代がある場合は、次を実行できます。

```sh
sudo darwin-rebuild switch --rollback
```

Chromeプロファイルの変更もロールバック対象ではありません。前の構成のChrome設定が再適用されるため、
適用前の状態へ戻すにはChromeを終了して`Preferences.before-nix-<日時>`から戻します。
初回適用前のmacOS全体を復元するコマンドではありません。
前の構成に含まれないmacOS設定まで元に戻るとは限らないため、必要な値を明示して再適用します。

## 検証状況と参考資料

Chrome復元スクリプトは、初回作成、既存設定の保持、バックアップ、繰り返し実行、
Chrome起動中の拒否、不正ファイルや不正パスの拒否をテストしています。

```sh
python3 -B -m unittest discover -s tests -v
```

このMacにNixが未導入のため、Nixでの評価・ビルド・適用とChromeの実画面での確認は未検証です。
コマンドはnix-darwinとLixの公式手順・実装を参照しています。初期状態のMacでの一連の復元テストも未実施です。

- [nix-darwinの導入手順](https://github.com/nix-darwin/nix-darwin)
- [nix-darwinの設定オプション](https://nix-darwin.github.io/nix-darwin/manual/)
- [Lixのインストール](https://lix.systems/install/)
- [darwin-rebuildの実装](https://github.com/nix-darwin/nix-darwin/blob/master/pkgs/nix-tools/darwin-rebuild.sh)
- [Chromeの通常設定とポリシーの違い](https://www.chromium.org/administrators/configuring-other-preferences/)

- [Codex CLI](https://learn.chatgpt.com/docs/codex/cli)
- [nix-darwinのGUIアプリ配置処理](https://github.com/nix-darwin/nix-darwin/blob/master/modules/system/applications.nix)
- [NixpkgsのChrome（macOS対応）](https://github.com/NixOS/nixpkgs/blob/nixpkgs-unstable/pkgs/by-name/go/google-chrome/package.nix)
- [NixpkgsのChatGPT](https://github.com/NixOS/nixpkgs/blob/nixpkgs-unstable/pkgs/by-name/ch/chatgpt/package.nix)

## Neovim・LazyVim・Terminalのフォント

Home ManagerでNeovim、Codex CLI、Node.js・npm、Rustと開発用コマンドを対象ユーザーに導入します。
LazyVimの起動設定は`programs.neovim.initLua`と`xdg.configFile`で管理し、
`~/.config/nvim/init.lua`と`~/.config/nvim/lua/config/lazy.lua`を配置します。
`xdg.configHome`を変更する場合は、その指定先が配置先になります。
エディタ設定はLazyVimのデフォルトを使用します。

移行時に競合する既存ファイルは、隣の`<ファイル名>.before-home-manager`へ退避します。
同名のバックアップがすでにある場合は上書きせず停止するので、退避済みファイルを別名で保管して再適用してください。
管理対象の設定は読み取り専用です。変更はリポジトリの`nvim/`で行い、再適用します。
ディレクトリ全体をリンクしないため、LazyVimの`lazy-lock.json`は引き続き書き込めます。
管理対象外の既存ファイルは保持されます。以前の独自設定があれば、その内容も読み込まれる可能性があります。

適用後に`nvim`を起動すると、lazy.nvim・LazyVimとプラグインをネットワークから取得します。
初回起動にはインターネット接続が必要です。起動後に`:LazyHealth`で確認してください。
構文解析器のコンパイルには「2」で導入するCommand Line ToolsのCコンパイラを使用します。
言語サーバー等はLazyVimのMasonから必要に応じて追加します。
詳しい要件は[LazyVim公式ドキュメント](https://www.lazyvim.org/)を参照してください。

Hack Nerd Fontは`fonts.packages`で導入します。
Terminalの既存プロファイルすべて（標準・起動用を含む）のフォントを
**Hack Nerd Font Mono・13pt**に変更し、色・その他の設定を保持します。
変更前のTerminal設定は`~/Library/Application Support/nix-settings/terminal-backups/`に保存します。
適用後はTerminalを完全に終了して再起動してください。
再適用だけを行う場合は、対象ユーザーで`setup-terminal-font`を実行できます。
Terminal.appはLazyVim推奨のtrue color・undercurl対応端末には含まれないため、表示には制限があります。

## プルリクエストの自動テスト

`.github/workflows/tests.yml`により、PRの作成・更新・再オープン時に以下を実行します。
Actions画面から手動実行することもできます。

- LinuxとmacOSでPythonのユニットテストを実行（Python 3.13）。
- Git管理しているNixファイルとLuaファイルの構文を確認。

テストでは一時ファイルとモックを使用します。Chrome・Terminalへの実際の設定適用や、
nix-darwinの依存解決・ビルドは検証対象に含まれません。
ローカルでPythonテストを実行する場合は、リポジトリのルートで以下を実行します。

```sh
python3 -m unittest discover -s tests -v
```

テスト成功をマージの必須条件にする場合は、GitHubのブランチ保護またはRulesetsで
`Python tests (ubuntu-24.04)`、`Python tests (macos-15)`、`Nix and Lua syntax`を必須チェックに指定します。

Home Managerの構成は[nix-darwinへの公式統合手順](https://github.com/nix-community/home-manager/blob/master/docs/manual/nix-flakes/nix-darwin.md)に沿っています。
Chrome設定のマージとTerminalフォントの変更は、引き続きnix-darwinの適用処理から専用スクリプトを実行します。
