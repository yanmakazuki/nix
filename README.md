# 新しいMacのセットアップ

Apple Silicon・macOS 26向け。

## 1. Command Line Tools

```sh
xcode-select --install
```

インストール完了後、次へ進みます。

## 2. リポジトリの取得

```sh
mkdir -p ~/Documents
git clone https://github.com/yanmakazuki/nix.git ~/Documents/nix
cd ~/Documents/nix
```

## 3. Nixのインストール

```sh
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
```

完了後、Terminalを開き直します。

## 4. ユーザー名の設定

```sh
cd ~/Documents/nix
id -un
nano configuration.nix
```

`system.primaryUser`を`id -un`で表示されたユーザー名に変更します。

## 5. ビルド

```sh
git add -A
git diff --cached
nix --extra-experimental-features 'nix-command flakes' flake update
nix --extra-experimental-features 'nix-command flakes' build \
  '.#darwinConfigurations.Kazukis-MacBook-Air.system'
```

## 6. 適用

ビルド成功後、Chromeが起動していればCommand+Qで終了します。

```sh
sudo ./result/sw/bin/darwin-rebuild switch \
  --flake '.#Kazukis-MacBook-Air'
```

適用後はログアウト・ログインし直し、Terminalを開き直します。

## 7. 起動確認

```sh
codex --version
code --version
node --version
npm --version
rustc --version
cargo --version
nvim
```

Neovimのプラグイン取得完了後、以下を実行します。

```vim
:LazyHealth
```
