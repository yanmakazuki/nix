# Macの設定を復元する

このリポジトリは、Apple Silicon搭載Macの設定をnix-darwinで管理します。
初期設定が完了したMacにNixを導入し、このリポジトリを取得して設定を適用するまでの手順です。

対象はmacOS 26系です。元のMacではmacOS 26.7.1から設定を取り込みました。
**現時点ではMac全体の完全な復元ではありません。** macOSの管理対象設定はNixで適用し、
アプリのインストール、Chromeの設定、アカウントへのログインなどは手動で補います。

## 復元できる範囲

| 対象 | 復元方法 |
| --- | --- |
| Dock・Finder・キーリピート・トラックパッド | nix-darwinで適用 |
| macOSの外観・言語・地域・時計・一部のメニューバー設定 | nix-darwinで適用。再ログインが必要な場合あり |
| ウィンドウ配置の動作・Stage Manager関連設定 | nix-darwinで適用 |
| Dockに固定するアプリの順序 | nix-darwinで適用。アプリ本体は事前にインストール |
| Chromeの表示・入力・サイト権限の設定 | `captured-chrome.nix`を参照して手動設定 |
| アプリ、拡張機能、Apple Account・Google等のログイン | 手動で導入・設定 |
| 文書・写真・パスワード・Cookie・閲覧履歴・ブックマーク | このリポジトリの対象外。別のバックアップや同期から復元 |
| 壁紙・ディスプレイ・電源・ネットワーク・入力ソース・プライバシー権限 | 必要に応じて手動設定 |

`system.defaults`で指定した項目だけが管理対象です。指定していないmacOSの設定は、この構成から復元できません。
`CustomUserPreferences`にあるmacOS内部キーは、OSのバージョンによって動作が変わる場合があります。

## ファイルの役割

| ファイル | 役割 |
| --- | --- |
| `flake.nix` | 最新を取得するNixpkgs・nix-darwinのブランチ、およびMacの構成名 |
| `configuration.nix` | CPU種別、対象ユーザー、Nixの機能設定、読み込むモジュール |
| `captured-defaults.nix` | 実際に適用するmacOS設定。各項目の意味は日本語コメントを参照 |
| `captured-chrome.nix` | Chrome設定の参照用データ。現在は自動適用しない |
| `flake.lock` | 今回取得した依存の版をローカルで保持。Git管理には含めない |
| `.gitignore` | 確認用JSON、ビルド結果などをGit管理から除外 |

適用時の読み込み順は `flake.nix` → `configuration.nix` → `captured-defaults.nix` です。
`captured-chrome.nix`はnix-darwinモジュールではないため、`configuration.nix`の`imports`には追加しません。
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
`system.stateVersion = 7;`は互換性の指定なので、通常は変更しません。

構成名`Kazukis-MacBook-Air`はNix側の識別名です。
Macの実際のホスト名が違っていても、下記のコマンドでこの名前を明示していれば構成を選択できます。
この構成はMacのコンピュータ名を変更しません。

### Dockのアプリの準備

`captured-defaults.nix`の`persistent-apps`は、次のパスを参照します。

- `/Applications/Google Chrome.app`
- `/System/Applications/Utilities/Terminal.app`
- `/Applications/ChatGPT.app`
- `/System/Applications/Apps.app`

Google ChromeとChatGPTは、各アプリの公式配布元からインストールします。
TerminalとAppsはmacOS側のアプリです。OSの版によってパスが異なる場合は、Nix設定側を実際のパスに合わせます。
このリポジトリにはHomebrewやアプリ本体を導入する設定はありません。

次のコマンドでパスを確認できます。

```sh
ls -d "/Applications/Google Chrome.app" "/Applications/ChatGPT.app"
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

## 6. macOS設定を適用する

ビルドした構成に含まれる`darwin-rebuild`で初回適用します。

```sh
sudo ./result/sw/bin/darwin-rebuild switch \
  --flake '.#Kazukis-MacBook-Air' \
  --no-update-lock-file
```

管理者パスワードを入力します。入力中の文字はターミナルに表示されません。
nix-darwinは設定値に加えて、Nixデーモンやシステムのシェル初期化などの基盤も管理します。

適用後は一度ログアウトしてログインし直し、ターミナルも開き直します。
再起動が必要な項目は、Macを再起動して確認してください。

## 7. Chromeの設定を手動で復元する

Chromeを起動し、必要ならGoogleアカウントにログインして、ブックマークなどの同期・復元を行います。
このリポジトリにはCookie、パスワード、閲覧履歴、ブックマーク、拡張機能本体は保存していません。

`captured-chrome.nix`の`profiles.Default.preferences`を参照し、Chromeの設定画面で対応する項目を戻します。
現在の保存内容は、おおむね次の設定です。数値の正確な保存値はNixファイルを正とします。

| 設定画面の対象 | 保存内容 |
| --- | --- |
| 外観 | テーマの配色・グレースケール、ブックマークバーの常時表示オフ |
| 言語・スペルチェック | 選択言語`en-US,en`、英語辞書、スペルチェックとオンラインサービス有効 |
| 支払い方法 | 自動入力時の再認証有効 |
| アクセシビリティ | Tabキーによるリンクへのフォーカス移動と字幕に関する設定 |
| プライバシー・サイトの設定 | 通知、センサー、USBなど、保存されている権限の既定値はブロック |
| パフォーマンス | ネットワーク予測・プリロードの内部設定 |
| 検索 | Googleセーフサーチの強制は無効 |

Chrome内部の数値やキーは、設定画面の選択肢と常に一対一で対応するとは限りません。
項目が見つからない場合は、同じ数値を推測で別の設定に当てはめず、使用中のChromeの仕様を確認します。

`policyCandidates`の4項目も参照用です。通常の設定を管理ポリシーに置き換えると動作が変わる場合があるため、
この手順では自動適用しません。Chrome設定の完全な自動復元には、別途実装と動作確認が必要です。

## 8. 復元を確認する

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
- Chromeで手動設定した項目と、必要なログイン・同期状態。
- 別途復元した個人データが開けること。

これで、このリポジトリが対象にする設定の復元と、手動で補う作業の確認が完了です。
Mac全体を完全に再現したことを保証する手順ではありません。

## 日常の変更・更新

Nix設定を編集した後は、同じフォルダーでビルドしてから適用します。

```sh
nix flake update
darwin-rebuild build --flake '.#Kazukis-MacBook-Air' --no-update-lock-file
sudo darwin-rebuild switch --flake '.#Kazukis-MacBook-Air' --no-update-lock-file
```

GUIで変更した管理対象の値は、次回適用時にNixの指定値へ戻ります。
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

初回は「6. macOS設定を適用する」の`./result/sw/bin/darwin-rebuild`を使用します。
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

### 設定が反映されない

ログアウト・再ログイン、対象アプリの再起動を行います。
コマンドで保存値が一致しているのにGUIが違う場合、macOSの版や内部キーの対応を確認します。
MDMなど別の管理機構があるMacでは、その設定が優先される場合があります。

### 前のNix構成へ戻したい

過去に適用した世代がある場合は、次を実行できます。

```sh
sudo darwin-rebuild switch --rollback
```

初回適用前のmacOS全体を復元するコマンドではありません。
前の構成に含まれないmacOS設定まで元に戻るとは限らないため、必要な値を明示して再適用します。

## 検証状況と参考資料

このREADMEの作成時点では、このMacにNixが未導入のため、Nixでの評価・ビルド・適用は未検証です。
コマンドはnix-darwinとLixの公式手順・実装を参照しています。初期状態のMacでの一連の復元テストも未実施です。

- [nix-darwinの導入手順](https://github.com/nix-darwin/nix-darwin)
- [nix-darwinの設定オプション](https://nix-darwin.github.io/nix-darwin/manual/)
- [Lixのインストール](https://lix.systems/install/)
- [darwin-rebuildの実装](https://github.com/nix-darwin/nix-darwin/blob/master/pkgs/nix-tools/darwin-rebuild.sh)
- [ChromeのmacOS向けポリシー設定](https://www.chromium.org/administrators/mac-quick-start/)
