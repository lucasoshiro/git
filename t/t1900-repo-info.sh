#!/bin/sh

test_description='test git repo-info'

. ./test-lib.sh

parse_json () {
	tr '\n' ' ' | "$PERL_PATH" "$TEST_DIRECTORY/t0019/parse_json.perl"
}

test_lazy_prereq PERLJSON '
	perl -MJSON -e "exit 0"
'

# Test if a field is correctly returned in both null-terminated and json formats.
#
# Usage: test_repo_info <label> <init command> <key> <expected value>
#
# Arguments:
#   label: the label of the test
#   init command: a command that creates a repository called 'repo', configured
#      accordingly to what is being tested
#   key: the key of the field that is being tested
#   expected value: the value that the field should contain
test_repo_info () {
        label=$1
        init_command=$2
        key=$3
        expected_value=$4

        test_expect_success PERLJSON "json: $label" '
		test_when_finished "rm -rf repo" &&
		eval "$init_command" &&
		echo "$expected_value" >expect &&
		git -C repo repo-info "$key" >output &&
		parse_json <output >parsed &&
		grep -F "row[0].$key" parsed | cut -d " " -f 2 >value &&
		sed -n -e "/row[0].$key/{
			s/^[^ ]* //
			s/^1\$/true/
			s/^0\$/false/
			p;
			}" parsed >actual &&
		sed "s/^0$/false/" <value| sed "s/^1$/true/" >actual &&
		test_cmp expect actual
        '

        test_expect_success "null-terminated: $label" '
		test_when_finished "rm -rf repo" &&
		eval "$init_command" &&
		echo "$expected_value" | lf_to_nul >expect &&
		git -C repo repo-info --format=null-terminated "$key" >output &&
		tail -n 1 output >actual &&
		test_cmp expect actual
	'
}

test_repo_info 'ref format files is retrieved correctly' '
	git init --ref-format=files repo' 'references.format' 'files'

test_repo_info 'ref format reftable is retrieved correctly' '
	git init --ref-format=reftable repo' 'references.format' 'reftable'

test_repo_info 'bare repository = false is retrieved correctly' '
	git init repo' 'layout.bare' 'false'

test_repo_info 'bare repository = true is retrieved correctly' '
	git init --bare repo' 'layout.bare' 'true'

test_done
