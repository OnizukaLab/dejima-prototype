createuser -U postgres --superuser dejima
psql -U postgres -c "alter user dejima with password 'barfoo'"

setup_files_dir="/etc/setup_files/$PEER_NAME"
setup_files=$(find $setup_files_dir -maxdepth 1 -type f -name *.sql | sort)
for file in $setup_files;
do
  psql -f $file
  echo "psql -f $file : completed"
done