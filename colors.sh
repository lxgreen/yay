FAIL="\033[31m"
SUCCESS="\033[32m"
REGULAR="\033[0m"

print_error() {
	echo -e "${FAIL}$1${REGULAR}"
}

print_success() {
	echo -e "${SUCCESS}$1${REGULAR}"
}
