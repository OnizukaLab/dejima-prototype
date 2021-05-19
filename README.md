# Dejima Prototype
## How to run
本プログラムは docker によって DB (PostgreSQL) コンテナと，Dejima に関する処理を制御するプロキシサーバコンテナを各ピアごとに立てることによって実現しています．  
したがって，本 README の How to build a new application にしたがって適切な設定を行ったのち，`docker-compose up` コマンドによって起動できます．
## How to build a new application
以下に新たなアプリケーションを再現するための設定方法を記述しています．  
各設定するピア名や Dejima テーブル名などは必ず各手順で同一の文字列を設定してください．
### docker-compose.yml の編集
以下の項目を適切に設定してください．詳しくは本リポジトリの docker-compose.yml を参照してください．
#### プロキシサーバ
- container_name : \[ピア名]-proxy (コンテナ間通信の際にアドレスとして使用します)
- environment > PEER_NAME : ピア名
#### DB
- container_name : \[ピア名]-db (コンテナ間通信の際にアドレスとして使用します)
- environment > PEER_NAME : ピア名
- environment > DEJIMA_EXECUTION_ENDPOINT : \[ピア名]-proxy:8000/execution
- environment > DEJIMA_TERMINATION_ENDPOINT : \[ピア名]-proxy:8000/terminate
### proxy/dejima_config.json の編集
本ファイルは各ピアが，以下の情報を把握するためのコンフィグファイルです．  
本リポジトリの proxy/dejima_config.json にしたがって，適切に設定してください．
- 自身が参加している Dejima グループの Dejima テーブル
- 自身が保持しているベーステーブル
- 各ピアのプロキシサーバのアドレス

### ベーステーブルの定義等に関する SQL ファイルの配置
db/setup_files/\[ピア名] 以下に，ベーステーブルの定義などに関する SQL ファイルを配置してください．
本ディレクトリにある SQL ファイルは各 DB の起動時に一度だけ呼び出されます．
アルファベット順に呼び出される点に注意してください．

### BIRDS によって生成したトリガ生成用 SQL ファイルの配置
Dejima テーブルを定義するための BIRDS によって生成した SQL ファイルを，db/setup_files/\[ピア名] 以下に配置してください．