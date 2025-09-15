# DevContainer セットアップ実行ログ

目的: バックエンド開発用の Dev Container と、ローカルで同時起動可能な 2 種類のフロントエンド（.NET）環境を docker-compose で用意。

## 追加・更新したファイル

- .devcontainer/devcontainer.json
- .devcontainer/docker-compose.yml
- .devcontainer/init.sh
- .devcontainer/run-backend.sh

## 設計の要点

- backend-dev コンテナを Dev Container として使用（Node 20 / Python 3.11 / .NET SDK 8 / Git 付き、pnpm 追加）。
- フロントエンドは .NET SDK イメージで別サービス（frontend1: 3000, frontend2: 5173）として docker-compose で並行起動。
- `runServices` により Dev Container 起動時に frontend1/2 が自動起動。
- `postStartCommand` でバックエンド起動スクリプトを実行（.NET なら `dotnet watch run`、Node なら `npm run dev`、Python なら `uvicorn` を自動検出して起動）。
- ホスト⇔コンテナのボリュームはワークスペースを bind mount（consistency=cached）。
- ポート転送: Backend 8000 / Frontend1 3000 / Frontend2 5173。
- compose ネットワークは `devnet` を使用、`host.docker.internal` を extra_hosts で解決可能に設定。

## 実行した処理

1. Dev Container 設定ファイルを作成
   - 追加: `.devcontainer/devcontainer.json`
   - 概要: docker-compose 利用、features（common-utils, node 20, python 3.11, dotnet 8, git）定義、pnpm 追加、port フォワード、`postCreateCommand`/`postStartCommand` 設定、`containerEnv`（`FRONTEND1_DIR`/`FRONTEND2_DIR`/`BACKEND_DIR`）。

2. docker-compose 定義を作成
   - 追加: `.devcontainer/docker-compose.yml`
   - 概要:
     - `backend-dev`: ベースイメージ、ワークスペース bind、`sleep infinity` で常駐。
     - `frontend1`/`frontend2`: .NET SDK 8.0、`*.csproj` を検出して `dotnet restore` の後に `dotnet watch run --no-restore --urls $ASPNETCORE_URLS` を実行、各ポート公開。
     - 共通: `devnet` ブリッジネットワーク、`host.docker.internal` を extra_hosts で解決。

3. 初期化スクリプトを作成
   - 追加: `.devcontainer/init.sh`
   - 概要: 進捗メッセージのみ（フロント/バックのインストールは起動時に実施）。
   - 実行権限付与: `chmod +x .devcontainer/init.sh`

4. バックエンド起動スクリプトを作成
   - 追加: `.devcontainer/run-backend.sh`
   - 概要: `BACKEND_DIR` を基準に .NET/Node/Python を自動検出して開発サーバ起動。
     - .NET: `*.csproj` があれば `dotnet restore` → `dotnet watch run --urls http://0.0.0.0:8000` で起動。
     - Node: `package.json` があれば `npm ci|install` の後に `npm run dev` があれば起動。
     - Python: `requirements.txt`/`pyproject.toml` を検出、venv 作成→依存インストール→`uvicorn app.main:app --reload` を試行。
   - 実行権限付与: `chmod +x .devcontainer/run-backend.sh`

## ディレクトリ想定

- バックエンド: `backend`（環境変数 `BACKEND_DIR` で変更可能）
- フロントエンド1: `apps/frontend1`
- フロントエンド2: `apps/frontend2`

必要に応じて `docker-compose.yml` の `working_dir` と `volumes`、`devcontainer.json` の `containerEnv` を変更してください。

## 使い方（Cursor/VS Code）

1. 「Reopen in Container」で Dev Container を起動。
2. frontend1/2 は `.csproj` を検出後に `dotnet restore` を実行し、`dotnet watch run` で開発サーバを起動（初回は少し時間がかかります）。
3. バックエンドは `run-backend.sh` が .NET/Node/Python を自動検出し起動。未対応の起動方法ならコンテナ内ターミナルから手動で起動してください。
4. アクセス:
   - Backend: http://localhost:8000
   - Frontend1: http://localhost:3000
   - Frontend2: http://localhost:5173

## カスタマイズポイント

- バックエンド起動コマンド: `.devcontainer/run-backend.sh` を調整。
- フロントエンドのポート/コマンド: `.devcontainer/docker-compose.yml` の `frontend1`/`frontend2`（`ASPNETCORE_URLS` と `dotnet watch run`）を調整。
- ディレクトリ配置: `.devcontainer/devcontainer.json` の `containerEnv` と docker-compose の `working_dir`/`volumes` を揃える。

## 既知の前提/注意

- `apps/frontend1`・`apps/frontend2` に `*.csproj` が存在することを前提にしています（存在しない場合は該当サービスは待機します）。
- バックエンドは `.csproj`（.NET）/`package.json`（Node）/`requirements.txt` or `pyproject.toml`（Python）のいずれかを前提とします。別エントリなら `run-backend.sh` を修正してください。
- ネットワーク外部アクセスや追加パッケージの取得は行っていません（各サービスの `dotnet restore` はコンテナ内で実行）。
