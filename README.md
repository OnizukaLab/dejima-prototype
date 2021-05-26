# Dejima Prototype
## How to run
本プログラムは docker によって DB (PostgreSQL) コンテナと，Dejima に関する処理を制御するプロキシサーバコンテナを各ピアごとに立てることによって実現しています．  
したがって，本 README の How to build a new application にしたがって適切な設定を行ったのち，`docker-compose up` コマンドによって起動できます．  
## How to build a new application
以下に新たなアプリケーションを再現するための設定方法を記述しています．  
各ピア名や Dejima テーブル名などは必ず各設定で同一の文字列を設定してください．
なお，指定するピア名にはアンダースコアを含めないでください．
### docker-compose.yml の編集
以下の項目を適切に設定してください．詳しくは本リポジトリの docker-compose.yml を参考にしてください．
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
本リポジトリの proxy/dejima_config.json を参照して，適切に設定してください．
- 自身が参加している Dejima グループの Dejima テーブル
- 自身が保持しているベーステーブル
- 各ピアのプロキシサーバのアドレス

### ベーステーブルの定義等に関する SQL ファイルの配置
db/setup_files/\[ピア名] 以下に，ベーステーブルの定義などに関する SQL ファイルを配置してください．
本ディレクトリにある SQL ファイルは各 DB の起動時に一度だけ呼び出されます．
アルファベット順に呼び出される点に注意してください．

## BIRDS によるトリガ生成 SQL ファイルの生成
Dejima テーブルを更新可能とするためのトリガー群を生成するには，BIRDS を利用してください．
なお，BIRDS コマンド実行時に必要なオプションは以下の通りです．
* `--dejiima` オプション
* `-b [file_path]` オプション  
このオプションについては，以下の通りのシェルスクリプトファイルを用意したのち，このパスを引数として与えてください．

```sh
#!/bin/sh

result=$(curl -s -X POST -H "Content-Type: application/json" $DEJIMA_EXECUTION_ENDPOINT -d "$1")
if  [ "$result" = "true" ];  then
    echo "true"
else 
    echo $result
fi
```

### BIRDS によって生成したトリガ生成用 SQL ファイルの配置
Dejima テーブルを定義するための BIRDS によって生成した SQL ファイルを，db/setup_files/\[ピア名] 以下に配置してください．

### db/setup_file/[Peer name]/basetable_list.txt の編集
本ファイルに, 各ピアで定義されているベーステーブルを記述してください．  
一行につき 1 テーブル記述してください．
## How to execute a transaction
トランザクションを実行する際は，SELECT 文には必ず `FOR SHARE` キーワードを付けてください．
これにより Dejima システム全体に渡って直列化可能なトランザクションの実行が可能となります．
## Restrictions
- ユーザは Dejima テーブルを直接更新できません．必ずベーステーブルに対する更新のみにしてください．
- PostgreSQL に接続する際のユーザ名は 'dejima' 以外を使用してください．('dejima' はプロキシサーバによる接続を区別するために使用されています)