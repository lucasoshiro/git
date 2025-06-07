#!/bin/sh

test_description='test git repo-info'
GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME=main
export GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME

. ./test-lib.sh

DEFAULT_NUMBER_OF_FIELDS=3

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
		echo '$expected_value' | sed 's/^false$/0/' | sed 's/^true$/1/' >expect &&
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

test_repo_info 'ref format files is retrieved correctly' \
	'' \
	'references.format' 'files'

test_repo_info 'ref format reftable is retrieved correctly' \
	'--ref-format=reftable' \
	'references.format' 'reftable'

test_repo_info 'bare repository = false is retrieved correctly' \
	'' \
	'layout.bare' 'false'

test_repo_info 'bare repository = true is retrieved correctly' \
	'--bare' \
	'layout.bare' 'true'

test_repo_info 'shallow repository = false is retrieved correctly' \
	'' \
	'layout.shallow' 'false'

test_expect_success 'json: shallow repository = true is retrieved correctly' '
	test_when_finished "rm -rf repo" &&
	git init repo &&
	cd repo &&
	echo x >x &&
	git add x &&
	git commit -m x &&
	git clone --depth 1 "file://$PWD" cloned &&
	cd cloned &&
	echo 1 >expect &&
	git repo-info "layout.shallow" | parse_json >output &&
	grep -F "row[0].layout.shallow" output | cut -d " " -f 2 >actual &&
	cat actual > /dev/ttys001 &&
	test_cmp expect actual
'

test_expect_success 'plaintext: shallow repository = true is retrieved correctly' '
	test_when_finished "rm -rf repo" &&
	git init repo &&
	cd repo &&
	echo x >x &&
	git add x &&
	git commit -m x &&
	test_commit "commit" &&
	git clone --depth=1 "file://$PWD" cloned &&
	cd cloned &&
       	echo true >expect &&
       	git repo-info --format=plaintext "layout.shallow" >actual &&
       	test_cmp expect actual
'

test_expect_success 'plaintext: output all default fields' "
	git repo-info --format=plaintext >actual &&
	test_line_count = $DEFAULT_NUMBER_OF_FIELDS actual
"

test_expect_success 'json: output all default fields' "
	git repo-info --format=json | parse_json | grep '.*\..*\..*' >actual &&
	test_line_count = $DEFAULT_NUMBER_OF_FIELDS actual
"

test_expect_success 'plaintext: output all default fields' "
	git repo-info --format=plaintext >actual &&
	test_line_count = $DEFAULT_NUMBER_OF_FIELDS actual
"

test_expect_success 'json: output all default fields' "
	git repo-info --format=json | parse_json | grep '.*\..*\..*' >actual &&
	test_line_count = $DEFAULT_NUMBER_OF_FIELDS actual
"


test_done
