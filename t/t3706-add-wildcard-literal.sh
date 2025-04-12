#!/bin/sh

test_description='git add: wildcard must not be shadowed by literal filename'

. ./test-lib.sh

test_expect_success 'setup: create files and initial commit' '
    mkdir testdir &&
    >testdir/f\* &&
    >testdir/f\*\* &&
    >testdir/foo &&
    git add testdir &&
    git commit -m "Initial setup with literal wildcard files"
'

test_expect_success 'clean slate before testing wildcard behavior' '
    git rm -rf testdir &&
    git commit -m "Clean state"
'

test_expect_success 'recreate files to test add behavior' '
    mkdir testdir &&
    >testdir/f\* &&
    >testdir/f\*\* &&
    >testdir/foo
'

test_expect_success 'quoted literal: git add "f\\*\\*" adds only f**' '
    git reset &&
    git add "testdir/f\\*\\*" &&
    git ls-files >actual &&
    echo "testdir/f**" >expected &&
    test_cmp expected actual
'

test_expect_success 'wildcard: git add f* adds f*, f** and foo' '
    git reset &&
    git add '\''testdir/f*'\'' &&
    git ls-files | sort >actual &&
    printf "%s\n" "testdir/f*" "testdir/f**" "testdir/foo" | sort >expected &&
    test_cmp expected actual
'

test_done