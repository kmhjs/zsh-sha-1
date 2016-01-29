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

function test::sha1::binary::createBlocks()
{
    local data_length=$((512 - 64))
    local input_sample=${(l.$((${data_length} + 1))..0.)}

    local result=$(sha1::binary::createBlocks ${input_sample})

    local expected_result_blocks=(
        "${(l.${data_length}..0.)}${(l.55..0.)}111000000"
        "01${(l.$((${data_length} - 2))..0.)}${(l.63..0.)}1"
    )

    [[ "${result}" == "${expected_result_blocks[1]} ${expected_result_blocks[2]}" ]] && return 0 || return 1
}

function test::sha1::binary::computeRotatedBlocks()
{
    local input_sample="11${(l.128..0.)}${(l.128..1.)}${(l.128..0.)}${(l.126..1.)}"
    local expected_result_blocks='11000000000000000000000000000000 00000000000000000000000000000000 00000000000000000000000000000000 00000000000000000000000000000000 00111111111111111111111111111111 11111111111111111111111111111111 11111111111111111111111111111111 11111111111111111111111111111111 11000000000000000000000000000000 00000000000000000000000000000000 00000000000000000000000000000000 00000000000000000000000000000000 00111111111111111111111111111111 11111111111111111111111111111111 11111111111111111111111111111111 11111111111111111111111111111111 11111111111111111111111111111111 11111111111111111111111111111111 10000000000000000000000000000001 00000000000000000000000000000000 00000000000000000000000000000000 11111111111111111111111111111100 10000000000000000000000000000001 00000000000000000000000000000000 10000000000000000000000000000111 11111111111111111111111111111100 01111111111111111111111111111101 11111111111111111111111111110000 01111111111111111111111111111000 00000000000000000000000000000011 11111111111111111111111111100010 11111111111111111111111111110000 11111111111111111111111111110101 11111111111111111111111111000011 00000000000000000000000000011000 11111111111111111111111111110011 00000000000000000000000001110100 11111111111111111111111111001111 00000000000000000000000000101110 00000000000000000000000011110000 11111111111111111111111110000001 11111111111111111111111111000011 00000000000000000000000111011010 11111111111111111111111100000011 11111111111111111111111101011010 00000000000000000000001111001100 11111111111111111111111001110101 11111111111111111111111100110011 00000000000000000000011101000000 00000000000000000000001100001100 11111111111111111111110100001011 11111111111111111111000011111111 11111111111111111111100000011001 00000000000000000000001111110000 11111111111111111110001001001011 11111111111111111111000000110011 11111111111111111111010111010111 11111111111111111100001100001111 11111111111111111110011101110001 11111111111111111111001111001111 00000000000000000111010001110010 00000000000000000011000011111100 11111111111111111101000101100011 00000000000000001111000011111100 00000000000000000111111011000000 11111111111111111100001100111111 11111111111111100010010100111111 00000000000000001111110000000000 11111111111111110101101000111111 00000000000000111100110000000000 11111111111111100111010111111111 11111111111111110011001111111111 00000000000001110100000011001100 00000000000000110000110000000000 11111111111111010000101110000111 11111111111100001111111111111111 00000000000001111110011001011100 11111111111111000000111100001111 11111111111000100100101101000111 00000000000011111100110011000000'

    local result=$(sha1::binary::block::computeRotatedBlocks ${input_sample})

    [[ "${result}" == "${expected_result_blocks}" ]] && return 0 || return 1
}

foreach function_name ($(cat ${0} | sed -n 's!^function  *test!test!p' | tr -d '()')); do
    ${function_name}

    [[ ${?} != 0 ]] && {
    echo "TEST FAILED: ${function_name} finished with invalid exit code." > /dev/stderr
}
; done
