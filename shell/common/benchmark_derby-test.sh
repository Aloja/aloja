# Benchmark to test derby installation, data load and query completion
source_file "$ALOJA_REPO_PATH/shell/common/common_derby.sh"
set_derby_requires

#BENCH_REQUIRED_FILES["tpch-hive"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/tpch-hive.tar.gz"
[ ! "$BENCH_LIST" ] && BENCH_LIST="create_table insert_table query_table"

benchmark_suite_config() {
    logger "WARNING: Using Derby DB in client/server mode"
    initialize_derby_vars "test_DB"
    start_derby
}

benchmark_suite_cleanup() {
  clean_derby
}

benchmark_create_table(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  query_file=$(get_local_bench_path)/query_create.sql
  url=$(get_database_connection_url)
  echo "connect '$url';" > $query_file
  echo "CREATE TABLE Persons
       (
       PersonID int,
       LastName varchar(255),
       FirstName varchar(255),
       Address varchar(255),
       City varchar(255)
       );" >> $query_file

  execute_derby "$bench_name"  "$query_file" "time"
}

benchmark_validate_create_table(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  query_file=$(get_local_bench_path)/show_tables.sql
  url=$(get_database_connection_url)
  echo "connect '$url';" > $query_file
  echo "show tables;" >> $query_file

  execute_derby "$bench_name"  "$query_file" "time"
}

benchmark_insert_table(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  query_file=$(get_local_bench_path)/query_insert.sql
  url=$(get_database_connection_url)
  echo "connect '$url';" > $query_file
  echo "INSERT into Persons (PersonID, LastName, FirstName, Address, City)
        VALUES (1, 'Montero', 'Alejandro', 'C/Jordi Girona', 'Barcelona'),
        (2, 'Poggi', 'Nicolas', 'C/Jordi Girona', 'Barcelona'),
        (3, 'Fenech', 'Thomas', 'C/Jordi Girona', 'Barcelona'),
        (4, 'Brini', 'Davide', 'C/Jordi Girona', 'Barcelona')
       ;" >> $query_file

  execute_derby "$bench_name" "$query_file" "time"
}

benchmark_query_table(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  query_file=$(get_local_bench_path)/query_select.sql
  url=$(get_database_connection_url)
  echo "connect '$url';" > $query_file
  echo "SELECT FirstName, LastName
        FROM Persons
        WHERE City = 'Barcelona'
       ;" >> $query_file

  execute_derby "$bench_name" "$query_file" "time"
}

