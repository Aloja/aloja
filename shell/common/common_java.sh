#JAVA SPECIFIC FUNCTIONS

# Returns a list of required files
set_java_requires() {
  #download it from ALOJA's public file server as oracle requires licence acceptance
  BENCH_REQUIRED_FILES["$BENCH_JAVA_VERSION"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/$BENCH_JAVA_VERSION.tar.gz"
}