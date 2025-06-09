#!/bin/sh

test_description='test git repo-info'
GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME=main
export GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME

. ./test-lib.sh

parse_json () {
	tr '\n' ' ' | "$PERL_PATH" "$TEST_DIRECTORY/t0019/parse_json.perl"
}

test_repo_info () {
	label=$1
	init_args=$2
	key=$3
	expected_value=$4

	test_expect_success "json: $label" "
		test_when_finished 'rm -rf repo' &&
		git init $init_args repo &&
		cd repo &&
		echo '$expected_value' >expect &&
		git repo-info '$key'| parse_json >output &&
		grep -F 'row[0].$key' output | cut -d ' ' -f 2 >actual &&
		test_cmp expect actual
	"

	test_expect_success "plaintext: $label" "
		test_when_finished 'rm -rf repo' &&
		git init $init_args repo &&
		cd repo &&
		echo '$expected_value' >expect &&
		git repo-info --format=plaintext '$key' >actual &&
		test_cmp expect actual
	"
}

test_expect_success 'json: returns empty output with allow-empty' '
	git repo-info --allow-empty --format=json >output &&
	test_line_count = 2 output
'

test_expect_success 'plaintext: returns empty output with allow-empty' '
	git repo-info --allow-empty --format=plaintext >output &&
	test_line_count = 0 output
'

test_done
