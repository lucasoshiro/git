#!/bin/sh

test_description='test git repo-info'
GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME=main
export GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME

. ./test-lib.sh

TOTAL_FIELDS=2

parse_json () {
	tr '\n' ' ' | perl $TEST_DIRECTORY/t0019/parse_json.perl
}

test_repo_info () {
	label=$1
	init_args=$2
	key=$3
	expected_value=$4

	test_expect_success "json: $label" "
		git init $init_args repo &&
		cd repo &&
		echo '$expected_value' >expect &&
		git repo-info '$key'| parse_json >output &&
		grep -F 'row[0].$key' output | cut -d ' ' -f 2 >actual &&
		test_cmp expect actual
	"

	test_expect_success "plaintext: $label" "
		git init $init_args repo &&
		cd repo &&
		echo '$expected_value' >expect &&
		git repo-info --format=plaintext '$key' >actual &&
		test_cmp expect actual
	"
}

test_repo_info 'object format sha1 is retrieved correctly' \
	'' \
	'objects.format' 'sha1'

test_repo_info 'object format sha256 is retrieved correctly' \
	'--object-format=sha256' \
	'objects.format' 'sha256'

test_repo_info 'ref format files is retrieved correctly' \
	'' \
	'references.format' 'files'

test_repo_info 'ref format reftable is retrieved correctly' \
	'--ref-format=reftable' \
	'references.format' 'reftable'

test_expect_success 'plaintext: outputs in correct order' '
	git init --object-format=sha256 --ref-format=reftable repo &&
	cd repo &&
	echo "reftable\nsha256" >expect &&
	git repo-info --format=plaintext references.format objects.format >actual &&
	test_cmp expect actual
'

test_expect_success 'plaintext: outputs all fields when no specific field is requested' "
	git repo-info --format=plaintext >output &&
	test_line_count = $TOTAL_FIELDS output
"

test_expect_success 'json: outputs all fields when no specific field is requested' "
	git repo-info --format=json | parse_json | grep '.*[.].*[.].*' >output &&
	test_line_count = $TOTAL_FIELDS output
"

test_done
