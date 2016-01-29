#! /usr/bin/env zsh

source './sha1.sh'

function test::sha1::integer::fromChar()
{
    local result=$(sha1::integer::fromChar 'a')

    [[ ${result} == 97 ]] && return 0 || return 1
}

function test::sha1::binary::fromInteger()
{
    local result=$(sha1::binary::fromInteger 97)

    [[ "${result}" == "1100001" ]] && return 0 || return 1
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

function test::sha1::binary::appendOne()
{
    local result=$(sha1::binary::appendOne '00000000')

    [[ "${result}" == "000000001" ]] && return 0 || return 1
}

function test::sha1::binary::splitIntoBitBlocks()
{
    local block_length=16
    local input_sample=${(l.33..0.)}
    local delimiter=' '

    local result=$(sha1::binary::splitIntoBitBlocks ${input_sample} ${block_length} ${delimiter})

    [[ "${result}" == "${(l.16..0.)} ${(l.16..0.)} ${(l.1..0.)}" ]] && return 0 || return 1
}

function test::sha1::binary::zeroPadding()
{
    local data_length=$((512 - 64))
    local input_sample=${(l.$((${data_length} + 1))..0.)}

    local result=$(sha1::binary::zeroPadding ${input_sample})

    [[ "${result}" == "${(l.${data_length}..0.)} 01${(l.$((${data_length} - 2))..0.)}" ]] && return 0 || return 1
}

foreach function_name ($(cat ${0} | sed -n 's!^function  *test!test!p' | tr -d '()')); do
    ${function_name}

    [[ ${?} != 0 ]] && {
    echo "TEST FAILED: ${function_name} finished with invalid exit code." > /dev/stderr
}
; done
