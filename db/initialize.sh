createuser -U postgres --superuser dejima
psql -U postgres -c "alter user dejima with password 'barfoo'"

setup_files_dir="/etc/setup_files/$PEER_NAME"
common_files_dir="/etc/setup_files/common"

setup_files=$(find $setup_files_dir -maxdepth 1 -type f -name *.sql | sort)
common_files=$(find $common_files_dir -maxdepth 1 -type f -name *.sql | sort)

for file in $setup_files;
do
  psql -f $file
  echo "psql -f $file : completed"
done

psql -f $common_files_dir/00_terminate.sql

while read basetable
do
  sed "s/{}/$basetable/g" $common_files_dir/01_terminate_trigger.sql | psql
  echo "CREATE TABLE ${basetable}_lineage (ID int primary key, LINEAGE varchar(80));" | psql
done < $setup_files_dir/basetable_list.txt