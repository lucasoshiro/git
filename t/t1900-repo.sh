#!/bin/sh

test_description='test git repo-info'

. ./test-lib.sh

# Test whether a key-value pair is correctly returned
#
# Usage: test_repo_info <label> <init command> <repo_name> <key> <expected value>
#
# Arguments:
#   label: the label of the test
#   init_command: a command which creates a repository
#   repo_name: the name of the repository that will be created in init_command
#   key: the key of the field that is being tested
#   expected_value: the value that the field should contain
test_repo_info () {
	label=$1
	init_command=$2
	repo_name=$3
	key=$4
	expected_value=$5

	test_expect_success "setup: $label" '
		eval "$init_command $repo_name"
	'

	test_expect_success "keyvalue: $label" '
		echo "$key=$expected_value" > expect &&
		git -C "$repo_name" repo info "$key" >actual &&
		test_cmp expect actual
	'

	test_expect_success "nul: $label" '
		printf "%s\n%s\0" "$key" "$expected_value" >expect &&
		git -C "$repo_name" repo info --format=nul "$key" >actual &&
		test_cmp_bin expect actual
	'
}

test_repo_info_path () {
	label=$1
	repo_name=$2
	key=$3
	relative_path=$4
	default=$5

	absolute_path=$(cd "$relative_path"; pwd)/"$repo_name"

	case $default in
	absolute)
		expected_value="$absolute_path"
		;;
	relative)
		expected_value="$relative_path"
		;;
	esac

	test_expect_success "setup: $label" '
		git init "$repo_name"
	'

	test_expect_success "nul: $label" '
		printf "%s\n%s\0" "$key" "$expected_value" >expected &&
		git -C "$repo_name" repo info --format=nul "$key" >actual &&
		test_cmp_bin expected actual
	'

	test_expect_success "default: $label" '
		echo "$key=$expected_value" > expected &&
		git -C "$repo_name" repo info "$key" >actual &&
		test_cmp_bin expected actual
	'

	test_expect_success "absolute: $label" '
		echo "$key=$absolute_path" > expected &&
		git -C "$repo_name" repo info --path-format=absolute "$key" >actual &&
		test_cmp_bin expected actual
	'

	test_expect_success "relative: $label" '
		echo "$key=$relative_path" > expected &&
		git -C "$repo_name" repo info --path-format=relative "$key" >actual &&
		test_cmp_bin expected actual
	'
}

test_repo_info 'ref format files is retrieved correctly' \
	'git init --ref-format=files' 'format-files' 'references.format' 'files'

test_repo_info 'ref format reftable is retrieved correctly' \
	'git init --ref-format=reftable' 'format-reftable' 'references.format' 'reftable'

test_repo_info 'bare repository = false is retrieved correctly' \
	'git init' 'nonbare' 'layout.bare' 'false'

test_repo_info 'bare repository = true is retrieved correctly' \
	'git init --bare' 'bare' 'layout.bare' 'true'

test_repo_info 'shallow repository = false is retrieved correctly' \
	'git init' 'nonshallow' 'layout.shallow' 'false'

test_expect_success 'setup remote' '
	git init remote &&
	echo x >remote/x &&
	git -C remote add x &&
	git -C remote commit -m x
'

test_repo_info 'shallow repository = true is retrieved correctly' \
	'git clone --depth 1 "file://$PWD/remote"' 'shallow' 'layout.shallow' 'true'

test_repo_info_path 'toplevel is retrieved correctly' \
	'toplevel' 'path.toplevel' './' 'absolute'

test_expect_success 'git-repo-info fails if an invalid key is requested' '
	echo "error: key ${SQ}foo${SQ} not found" >expected_err &&
	test_must_fail git repo info foo 2>actual_err &&
	test_cmp expected_err actual_err
'

test_expect_success 'git-repo-info outputs data even if there is an invalid field' '
	echo "references.format=$(test_detect_ref_format)" >expected &&
	test_must_fail git repo info foo references.format bar >actual &&
	test_cmp expected actual
'

test_expect_success 'values returned in order requested' '
	cat >expect <<-\EOF &&
	layout.bare=false
	references.format=files
	layout.bare=false
	EOF
	git init --ref-format=files ordered &&
	git -C ordered repo info layout.bare references.format layout.bare >actual &&
	test_cmp expect actual
'

test_expect_success 'git-repo-info fails if an invalid key is requested' '
	echo "error: key ${SQ}foo${SQ} not found" >expect &&
	test_must_fail git repo info foo 2>actual &&
	test_cmp expect actual
'

test_expect_success 'git-repo-info outputs data even if there is an invalid field' '
	echo "references.format=$(test_detect_ref_format)" >expect &&
	test_must_fail git repo info foo references.format bar >actual &&
	test_cmp expect actual
'

test_expect_success 'git-repo-info aborts when requesting an invalid format' '
	echo "fatal: invalid format ${SQ}foo${SQ}" >expect &&
	test_must_fail git repo info --format=foo 2>actual &&
	test_cmp expect actual
'

test_expect_success 'git-repo-info aborts when requesting an invalid path format' '
	test_when_finished "rm -f err expected" &&
	echo "fatal: invalid path format '\'foo\''" >expected &&
	test_must_fail git repo info --path-format=foo 2>err &&
	test_cmp expected err
'

test_done
