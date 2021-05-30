# Dejima Prototype
## How to run
本プロトタイプは docker によって DB (PostgreSQL) コンテナと，Dejima に関する処理を制御するプロキシサーバコンテナを各ピアごとに立てることによって実現しています．  
なお，本プロトタイプは ride-sharing alliance アプリケーションを実現するよう設定されており，本リポジトリをクローンしたのちトップディレクトリで `docker-compose up` コマンドを実行することによりコンテナが生成されます．  
生成したのち，起動した各ピアの postgreSQL コンテナのベーステーブルに対しさまざまな更新操作を行うと，Dejima テーブルを介したデータ共有が行われます．

ride-sharing alliance アプリケーションではなく，別のアプリケーションを実現したい場合は，下の how to build a new application にしたがって適切な設定を行ったのち，上記と同様の手順でコンテナを立ち上げてください．
## How to build a new application
新たなアプリケーションを設定するにあたり，編集・配置しなければならないファイルは以下の通りです．
- /docker-compose.yml
- /proxy/dejima_config.json
- /db/setup_files/\[ピア名]
    - 初期化用 SQL ファイル
    - BIRDS トリガ生成 SQL ファイル
    - basetable_list.txt

具体的な編集内容などは後述の内容を参照してください．
なお，各ピア名や Dejima テーブル名などは必ず各設定で同一の文字列を設定してください．  
また，指定するピア名にはアンダースコアを含めないでください．
### docker-compose.yml の編集
以下の項目を適切に設定してください．詳しくは本リポジトリにある ride-sharing alliance 用の docker-compose.yml を参考にしてください．
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

### BIRDS によるトリガ生成 SQL ファイルの生成
Dejima テーブルを更新可能とするためのトリガー群を生成するには，BIRDS を利用してください．
新たなアプリケーションを作成するための更新戦略は自身で記述したのち，BIRDS を用いて SQL ファイルにコンパイルしてください．
なお，BIRDS コマンド実行時に必要なオプションは以下の通りです．
- `-f [file_path]`  
更新戦略を記述した datalog ファイルのパスを引数として与えてください．
- `--dejiima`   
- `-b [file_path]`   
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
設定したいピア用に db/setup_files/\[ピア名] ディレクトリを作成し，Dejima テーブルを定義するための BIRDS によって生成した SQL ファイルをこのディレクトリに配置してください．
なお，db/setup_files/common は全ピアに共通して実行するべき SQL が配置されていますので，削除しないよう注意してください．

### db/setup_file/[Peer name]/basetable_list.txt の編集
本ファイルに, 各ピアで定義されているベーステーブルを記述してください．  
一行につき 1 テーブル記述してください．
## How to execute a transaction
トランザクションを実行する際は，SELECT 文には必ず `FOR SHARE` キーワードを付けてください．
これにより Dejima システム全体に渡って直列化可能なトランザクションの実行が可能となります．
## Restrictions
- ユーザは Dejima テーブルを直接更新できません．必ずベーステーブルに対する更新のみにしてください．
- PostgreSQL に接続する際のユーザ名は 'dejima' 以外を使用してください．('dejima' はプロキシサーバによる接続を区別するために使用されています)