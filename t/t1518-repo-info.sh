#!/bin/sh

test_description='test git repo-info'
GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME=main
export GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME

. ./test-lib.sh

parse_json () {
	tr '\n' ' ' | perl $TEST_DIRECTORY/t0019/parse_json.perl
}

test_repo_info () {
	label=$1
	init_args=$2
	key=$3
	expected_value=$4

	test_expect_success "$label" "
		git init $init_args repo &&
		cd repo &&
		echo '$expected_value' >expect &&
		git repo-info | parse_json >output &&
		grep -F '$key' output | cut -d ' ' -f 2 >actual &&
		test_cmp expect actual
	"
}

test_repo_info 'object format sha1 is retrieved correctly' \
	'' \
	'row[0].object-format' 'sha1'

test_repo_info 'object format sha256 is retrieved correctly' \
	'--object-format=sha256' \
	'row[0].object-format' 'sha256'

test_done
