# このMacの設定をNixで管理する

Apple Silicon / macOS 26.7.1 / ユーザー `yanmakazuki` 向けの nix-darwin 構成です。
対象は macOS の設定です。Homebrew、アプリ、dotfiles はこの構成に含めていません。

## 現在の状態

構成ファイルを準備しました。Nix のインストール、ビルド、設定の適用はまだ実行していません。
Nix 未導入のため、構成の評価とビルドは未検証です。最初の `nix flake lock` で
依存バージョンを固定し、`flake.lock` も構成ファイルと一緒に保存してください。

現在の保存値から **73項目** を `captured-defaults.nix` に取り込み、
`configuration.nix` から読み込む構成にしました。

- Dock: 表示、拡大、Mission Control、固定アプリの順序。
- Finder: 表示形式、新規ウィンドウの場所、デスクトップ上のディスク表示。
- 全体・キーボード: ダークモード、アイコン外観、キーリピート、文字入力の補助、Fnキー。
- トラックパッド: クリック、ドラッグ、スクロール、各種ジェスチャー。
- ウィンドウ: Stage Manager関連、タイル配置の余白、ウィジェット表示。
- その他: 言語・地域、時計、メニューバーの一部表示項目、テキスト置換。

公式の型付きオプションを優先し、それがない一部の設定は
`system.defaults.CustomUserPreferences` に元のキーと値を保存しています。
後者はmacOSのバージョンに依存し、適用の実動作は未検証です。

`capture-report.json` に取り込んだ値、変換後の値、保存値がなかった候補項目を記録しました。
0/1は必要に応じて真偽値に、整数相当の小数値は整数に、Finderの `PfHm` は `Home` に変換しています。
DockのアプリはGUIDやブックマークを除いてパスと順序を取り込みました。
アプリ本体のインストールは行いません。

## 再取り込み

```sh
python3 /Users/yanmakazuki/Documents/Codex/2026-10-07/ko/outputs/mac-settings/nix/import-settings.py
```

このスクリプトはMacの設定を読み取り、`captured-defaults.nix` と `capture-report.json` を上書きします。
設定の日本語コメントは、同じフォルダーの `nix_comments.py` から生成します。
Chromeの取り込みスクリプトもこのファイルを使うため、一緒にGitで管理してください。
`configuration.nix` は編集しません。生成ファイルを手動編集した場合は再取り込み前に保存してください。
再取り込み後は差分を確認してからビルド・適用します。

これはMac全体の完全な複製ではありません。未保存のOS標準値、ByHost設定、MDMによる設定、
壁紙、ディスプレイ、電源、ネットワーク、プライバシー権限、キーボードショートカット、
入力ソース一覧などは取り込んでいません。履歴、キャッシュ、ウィンドウ位置なども対象外です。

## 初回導入

以下をMacのターミナルで実行します。インストールと適用には管理者認証が必要です。

1. Nix互換のLixをインストールします。nix-darwin公式READMEが推奨するインストーラーです。

   ```sh
   curl -sSf -L https://install.lix.systems/lix | sh -s -- install
   ```

   インストーラーの案内を確認し、完了後にターミナルを開き直します。
   この構成では、nix-darwin の標準動作に従い、初回適用から upstream Nix を管理します。

2. 構成を固定し、適用せずにビルドします。

   ```sh
   cd /Users/yanmakazuki/Documents/Codex/2026-10-07/ko/outputs/mac-settings/nix
   nix --extra-experimental-features 'nix-command flakes' flake lock
   nix --extra-experimental-features 'nix-command flakes' build '.#darwinConfigurations.Kazukis-MacBook-Air.system'
   ```

3. ビルド成功後に適用します。

   ```sh
   sudo ./result/sw/bin/darwin-rebuild switch --flake '.#Kazukis-MacBook-Air'
   ```

   nix-darwin は設定値以外に、Nixデーモンとシステムのシェル初期化などの基盤も管理します。
   既存の `/etc` ファイルとの衝突が出たら、エラー内容を確認し、上書きせずに解決してください。
   設定によってはアプリの再起動やログインし直しが必要です。

## 設定を変える

`captured-defaults.nix` の値を編集してから、同じフォルダーで次を実行します。

```sh
darwin-rebuild build --flake '.#Kazukis-MacBook-Air'
sudo darwin-rebuild switch --flake '.#Kazukis-MacBook-Air'
```

例: `dock.autohide = false;` にすればDockを常時表示できます。
GUIで変更した管理対象の値は、次の適用時にNixの値に戻ります。
Nixから項目を削除しても、そのmacOS設定が以前の値に戻るとは限りません。
戻す場合は希望する値を明示して適用してください。

## 依存バージョンを更新する

```sh
nix flake update
darwin-rebuild build --flake '.#Kazukis-MacBook-Air'
sudo darwin-rebuild switch --flake '.#Kazukis-MacBook-Air'
```

`flake.nix`、`configuration.nix`、`captured-defaults.nix`、`flake.lock` をGitで保存すれば、変更履歴も管理できます。

## 参考

- [nix-darwin公式README](https://github.com/nix-darwin/nix-darwin)
- [設定オプション一覧](https://nix-darwin.github.io/nix-darwin/manual/)
- [Lixインストール手順](https://lix.systems/install/)

システム設定のすべてが宣言的に管理できるわけではありません。
まずは対応する `system.defaults` オプションから増やしていく構成です。

## Chromeの設定の取り込み

`captured-chrome.nix` にChromeの保存設定をNix形式のデータとして保存しています。
初回取り込みはDefaultプロファイルの30項目と拡張機能10件です。
拡張機能にはChromeの内蔵機能も含まれます。アプリや拡張機能のインストールは行いません。

対象は表示、テーマ、スペルチェック、言語、サイト権限の既定値、拡張機能の一覧と
ピン留め、検索エンジンのテンプレートなどです。保存値がない項目は推測しません。
サイト別の権限は明示的な設定値だけを対象にし、サイトの利用状況・履歴は除外しています。
パスワード、Cookie、ログイン情報、拡張機能内部の設定データも対象外です。

再取り込み:

```sh
python3 import-chrome-settings.py
```

生成ファイルは`captured-chrome.nix`と`chrome-capture-report.json`です。
後者は確認用でGit管理から除外しています。
スクリプトは自身のフォルダーに出力するため、別の場所からも実行できます。

`captured-chrome.nix`はnix-darwinモジュールではなく、データのスナップショットです。
必要なモジュールから `import ./captured-chrome.nix` でデータを参照できますが、
`configuration.nix`の`imports`には追加していません。現在の構成を適用してもChrome設定は変わりません。
`policyCandidates`に通知・センサー・USB権限・スペルチェックの4つのポリシー候補も保存しました。
これらは再設定方法を検討するための参照用で、自動適用しません。
macOSのdefaults経由では推奨レベルとして扱われ、対応しないポリシーは無視される場合があります。

ブックマークバーの「常時表示オフ」と管理ポリシーの「表示しない」は動作が異なるため、
機械的に変換していません。検索URLの内部テンプレートもそのまま保存しています。
Chrome起動中の保存ファイルを読み取るため、直前のGUI変更がまだ保存されていない場合があります。
今回の取り込みはChromeへの適用とNixでの評価・ビルドを行っていません。

参考:

- [ChromeのmacOS向けポリシー設定](https://www.chromium.org/administrators/mac-quick-start/)
- [ブックマークバーのポリシー](https://chromeenterprise.google/policies/bookmark-bar-enabled/)
- [Chromeポリシー定義](https://github.com/chromium/chromium/tree/main/components/policy/resources/templates/policy_definitions)
