#! /usr/bin/env zsh

source './sha1.sh'

function test::converter::decimal::from_char()
{
    local input_char='A'

    local expected_result='65'

    local result=$(converter::decimal::from_char ${input_char})

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi

    return 0
}

function test::converter::decimal::from_binary()
{
    local input_value='11111111'

    local expected_result='255'

    local result=$(converter::decimal::from_binary ${input_value})

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi

    return 0
}

function test::converter::hex::from_binary()
{
    local input_value='11111111'

    local expected_result='FF'

    local result=$(converter::hex::from_binary ${input_value})

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi

    return 0
}

function test::converter::binary::from_hex()
{
    local input_value='FF'

    local expected_result='11111111'

    local result=$(converter::binary::from_hex ${input_value})

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi

    return 0
}

function test::converter::binary::from_decimal()
{
    local input_value=15

    local expected_result='1111'

    local result=$(converter::binary::from_decimal ${input_value})

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi

    return 0
}

function test::converter::binary::from_char()
{
    local input_char='A'

    local expected_result='01000001'

    local result=$(converter::binary::from_char ${input_char})

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi

    return 0
}

function test::converter::binary::from_string()
{
    local input_string='A Test'

    local expected_result='010000010010000001010100011001010111001101110100'

    local result=$(converter::binary::from_string ${input_string})

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi

    return 0
}

function test::converter::binary::split()
{
    local input_block='010000010010000001010100011001010111001101110100'
    local block_length=8
    local delimiter=' '

    local expected_result='01000001 00100000 01010100 01100101 01110011 01110100'

    local result=$(converter::binary::split ${input_block} ${block_length} ${delimiter})

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi

    return 0
}

function test::sha1::binary::constant::initial_internal_states()
{
    local expected_result=('01100111010001010010001100000001' \
                           '11101111110011011010101110001001' \
                           '10011000101110101101110011111110' \
                           '00010000001100100101010001110110' \
                           '11000011110100101110000111110000')

    local result=($(sha1::binary::constant::initial_internal_states))

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi

    return 0
}

function test::sha1::binary::constant::step_coef()
{
    local expected_results=('01011010100000100111100110011001' \
                            '01101110110110011110101110100001' \
                            '10001111000110111011110011011100' \
                            '11001010011000101100000111010110')

    for i ({0..3}); do
        local current_step_id=$((${i} * 20))

        local expected_result=${expected_results[$((${i} + 1))]}
        local result=$(sha1::binary::constant::step_coef ${current_step_id})

        if [[ "${result}" != "${expected_result}" ]]; then
            return 1
        fi
    ; done

    return 0
}

function test::sha1::binary::mapping::step_mapping()
{
    local step_id=0

    local B='11101111110011011010101110001001'
    local C='10011000101110101101110011111110'
    local D='00010000001100100101010001110110'

    local expected_result='10011000101110101101110011111110'

    local result=$(sha1::binary::mapping::step_mapping ${step_id} ${B} ${C} ${D})

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi


    step_id=20

    B='11011100100010001001111001110101'
    C='10110101000101000100100011110000'
    D='01001110101011001011101010110111'

    expected_result='00100111001100000110110000110010'

    result=$(sha1::binary::mapping::step_mapping ${step_id} ${B} ${C} ${D})

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi


    step_id=40

    B='01000100110000000111111001110111'
    C='00011010100110110011101010111011'
    D='01010011011001010110101011100100'

    expected_result='01010010110000010111101011110111'

    result=$(sha1::binary::mapping::step_mapping ${step_id} ${B} ${C} ${D})

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi


    step_id=60

    B='11011100100010001001111001110101'
    C='10110101000101000100100011110000'
    D='01001110101011001011101010110111'

    expected_result='00100111001100000110110000110010'

    result=$(sha1::binary::mapping::step_mapping ${step_id} ${B} ${C} ${D})

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi

    return 0
}

function test::sha1::binary::mapping::to_blocks()
{
    local input_block='010000010010000001010100011001010111001101110100'
    local expected_result='01000001001000000101010001100101011100110111010010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000'

    local result=$(sha1::binary::mapping::to_blocks ${input_block})

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi

    return 0
}

function test::sha1::binary::mapping::to_rotated_blocks()
{
    local input_block='01000001001000000101010001100101011100110111010010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000'

    local expected_result=('01000001001000000101010001100101' \
                           '01110011011101001000000000000000' \
                           '00000000000000000000000000000000' \
                           '00000000000000000000000000000000' \
                           '00000000000000000000000000000000' \
                           '00000000000000000000000000000000' \
                           '00000000000000000000000000000000' \
                           '00000000000000000000000000000000' \
                           '00000000000000000000000000000000' \
                           '00000000000000000000000000000000' \
                           '00000000000000000000000000000000' \
                           '00000000000000000000000000000000' \
                           '00000000000000000000000000000000' \
                           '00000000000000000000000000000000' \
                           '00000000000000000000000000000000' \
                           '00000000000000000000000000110000' \
                           '10000010010000001010100011001010' \
                           '11100110111010010000000000000000' \
                           '00000000000000000000000001100000' \
                           '00000100100000010101000110010101' \
                           '11001101110100100000000000000001' \
                           '00000000000000000000000011000000' \
                           '00001001000000101010001100101010' \
                           '10011011101001000000000001100011' \
                           '00000100100000010101000000010101' \
                           '11011111110101110100011001010101' \
                           '00110111010010000000000000000111' \
                           '00000000000000000000001100000000' \
                           '00100100000010101000110010101000' \
                           '01101110100100000000000111101110' \
                           '00010110100001000001000111000001' \
                           '10110010100011110001100111110110' \
                           '11010000101000111111001010100011' \
                           '01010110011101100000110000000010' \
                           '10010000001010100011001100100000' \
                           '10101000010001010100000111101101' \
                           '01101101010110000100011100000011' \
                           '11001010001111000110010011011010' \
                           '01100110100001010100011000100111' \
                           '00110111010010000011000110000111' \
                           '01010010101011011000110011010110' \
                           '11011110010010000001111011100001' \
                           '01101000010000010001110000010001' \
                           '00101000111100011001111110101011' \
                           '00000011001111011000100100010111' \
                           '11111100110001001100000110100110' \
                           '00010000101001100111010111011101' \
                           '10100001000110010101101011001001' \
                           '11011101110000010001100111100111' \
                           '01100001101110100100110110100110' \
                           '01101000010101000110010111110110' \
                           '00101110100100110100011011110111' \
                           '11010010101101011000101100101010' \
                           '11010011110010011110001000011010' \
                           '00010100001110111111001110110110' \
                           '00110101010110011111110100001011' \
                           '01101001110010001101011001110100' \
                           '00000110011100000111111010110101' \
                           '01101100111000100001101111110110' \
                           '00100110110111011001110100011101' \
                           '10001110101111000001001010101011' \
                           '11000101111011001100010100000111' \
                           '11111111000000100000010100100011' \
                           '11110110100011011111000110011110' \
                           '00110011011000101101111011000100' \
                           '01101100101101101110000110001111' \
                           '01000001000111000000100101101000' \
                           '11010001110010111100111001101001' \
                           '01001001000010010001011101110000' \
                           '11000100110000011010011011111100' \
                           '10100110011101011101110100010000' \
                           '00011001010110101100101010100001' \
                           '11100101000100110110101101110101' \
                           '11010100110111011011111001101111' \
                           '01110100001100011001010100101001' \
                           '10101111110100111111101000001101' \
                           '11011000110101010111110100101111' \
                           '00000111001000100000111010011001' \
                           '10001011100011011111100111110101' \
                           '10110111011010010100111100111110')

    local result=($(sha1::binary::mapping::to_rotated_blocks ${input_block}))

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi

    return 0
}

function test::sha1::binary::mapping::to_sha1_hex()
{
    local input_block='01000001001000000101010001100101011100110111010010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000'

    local expected_result=('8F0C0855' \
                           '915633E4' \
                           'A7DE1946' \
                           '8B3874C8' \
                           '901DF043')

    local result=($(sha1::binary::mapping::to_sha1_hex ${input_block}))

    if [[ "${result}" != "${expected_result}" ]]; then
        return 1
    fi

    return 0
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
