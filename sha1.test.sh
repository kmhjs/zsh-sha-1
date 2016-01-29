#! /usr/bin/env zsh

source './sha1.sh'

function test::sha1::integer::fromChar()
{
    local result=$(sha1::integer::fromChar 'a')

    [[ ${result} == 97 ]] && return 0 || return 1
}

function test::sha1::binary::fromChar()
{
    local result=$(sha1::binary::fromChar 'a')

    [[ "${result}" == "01100001" ]] && return 0 || return 1
}

function test::sha1::binary::fromString()
{
    local result=$(sha1::binary::fromString 'Hello world')

    [[ "${result}" == "0100100001100101011011000110110001101111001000000111011101101111011100100110110001100100" ]] && return 0 || return 1
}

function sha1.test
{
    local test_file_name="${0}.sh"

    foreach function_name ($(cat ${test_file_name} | sed -n 's!^function  *test!test!p' | tr -d '()')); do
        ${function_name}

        [[ ${?} != 0 ]] && {
            echo "TEST FAILED: ${function_name} finished with invalid exit code." > /dev/stderr
        }
    ; done
}
