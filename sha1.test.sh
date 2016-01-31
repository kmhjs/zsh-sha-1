#! /usr/bin/env zsh

source './sha1.sh'

function test::converter::decimal::from_char()
{
}

function test::converter::decimal::from_binary()
{
}

function test::converter::hex::from_binary()
{
}

function test::converter::binary::from_hex()
{
}

function test::converter::binary::from_decimal()
{
}

function test::converter::binary::from_char()
{
}

function test::converter::binary::from_string()
{
}

function test::converter::binary::split()
{
}

function test::sha1::binary::constant::initial_internal_states()
{
}

function test::sha1::binary::constant::step_coef()
{
}

function test::sha1::binary::mapping::step_mapping()
{
}

function test::sha1::binary::mapping::to_blocks()
{
}

function test::sha1::binary::mapping::to_rotated_blocks()
{
}

function test::sha1::binary::mapping::to_sha1_hex()
{
}

function test::sha1::binary::mapping::update_internal_states()
{
    local step_id=79
    local current_state=('10100001100010001000100001011011' \
                         '00111100100011001111000100100000' \
                         '01111011000001100010000001010010' \
                         '11001100010010110000111001010011' \
                         '11101001001001111110100110101011')
    local input_block='10110111011010010100111100111110'

    local expected_result=('00100111110001101110010101010100' \
                           '10100001100010001000100001011011' \
                           '00001111001000110011110001001000' \
                           '01111011000001100010000001010010' \
                           '11001100010010110000111001010011')

    local result=$(sha1::binary::mapping::update_internal_states ${step_id} "${current_state}" ${input_block})

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi

    return 0
}

function test::sha1::main()
{
    local input_message='A Test'
    local expected_result='8F0C0855915633E4A7DE19468B3874C8901DF043'

    local result=$(sha1::main ${input_message})

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi

    return 0
}

function run_test()
{
    local self_file_name=${1}

    local succeeded=0
    local failed=0

    foreach function_name ($(cat ${self_file_name} | sed -n 's!^function  *test!test!p' | tr -d '()')); do
        ${function_name}
    
        if [[ ${?} != 0 ]]; then
            echo -e "\e[1;31mFAIL\e[0m: ${function_name} finished with invalid exit code." > /dev/stderr
            failed=$((++failed))
        else
            echo -e "\e[1;32mPASS\e[0m: ${function_name} passed the test." > /dev/stderr
            succeeded=$((++succeeded++))
        fi
    ; done

    echo ${(l.${COLUMNS}..-.)}
    if [[ ${failed} != 0 ]]; then
        echo -e "\e[1;31mFAILED\e[0m the test." > /dev/stderr
    fi
    echo "REPORT: PASS (${succeeded}), FAIL (${failed})" > /dev/stderr
}

run_test ${0}
