function sha1::integer::fromChar()
{
    # This function converts input ascii char into integer value
    printf "%d" \'${1}
}

function sha1::integer::fromBinary()
{
    local input_value="0b${1}"

    echo $((${input_value}))
}

function sha1::binary::baseInternalStates()
{
    local base_length=32
    local states=(
        '67452301'
        'EFCDAB89'
        '98BADCFE'
        '10325476'
        'C3D2E1F0'
    )

    local binary_states=()
    foreach s (${states}); do
        local binary=$(sha1::binary::fromHex ${s})
        local padding_length=$((${base_length} - ${#binary}))
        binary="${(l.${padding_length}..0.)}${binary}"
        binary_states=(${binary_states} ${binary})
    ; done

    echo -n ${binary_states}
}

function sha1::binary::constntForStepID()
{
    local step_id=${1}

    local base_length=32
    local states=(
        '5A827999'
        '6ED9EBA1'
        '8F1BBCDC'
        'CA62C1D6'
    )

    local state=${states[$(((${step_id} / 20) + 1))]}

    local binary=$(sha1::binary::fromHex ${state})
    local padding_length=$((${base_length} - ${#binary}))
    binary="${(l.${padding_length}..0.)}${binary}"

    echo -n ${binary}
}

function sha1::binary::transformForStepID()
{
    local step_id=${1}
    local in_b="0b${2}"
    local in_c="0b${3}"
    local in_d="0b${4}"

    local base_length=32
    local state=$(((${step_id} / 20) + 1))

    local unsigned_inv_mask="0b${(l.${base_length}..1.)}"

    local result=""
    case ${state} in
        1)
            result=$(((${in_b} & ${in_c}) | ((${unsigned_inv_mask} - ${in_b}) & ${in_d})))
            ;;
        2)
            result=$((${in_b} ^ ${in_c} ^ ${in_d}))
            ;;
        3)
            result=$(((${in_b} & ${in_c}) | (${in_c} & ${in_d}) | (${in_d} & ${in_b})))
            ;;
        *)
            result=$((${in_b} ^ ${in_c} ^ ${in_d}))
            ;;
    esac

    result=$(echo $(([#2]${result})) | cut -d '#' -f 2)

    if [[ ${#result} -lt ${base_length} ]]; then
        local padding_length=$((${base_length} - ${#result}))
        result="${(l.${padding_length}..0.)}${result}"
    elif [[ ${#result} -gt ${base_length} ]]; then
        result=${result[-${base_length}, -1]}
    fi

    echo -n ${result}
}

function sha1::binary::fromHex()
{
    local input_value="0x${1}"

    echo $(([#2]${input_value})) | cut -d '#' -f 2
}

function sha1::binary::fromInteger()
{
    local input_value=${1}

    echo $(([#2]${input_value})) | cut -d '#' -f 2
}

function sha1::binary::fromChar()
{
    # This function converts input ascii char into 8-bits binary form
    local input_char=${1}
    local ascii_value=$(sha1::integer::fromChar ${input_char})
    local binary_string=$(sha1::binary::fromInteger ${ascii_value})

    [[ ${#binary_string} < 8 ]] && {
        local padding_length=$((8 - ${#binary_string}))
        local padding_string=${(l.${padding_length}..0.)}

        binary_string="${padding_string}${binary_string}"
    }

    echo -n ${binary_string}
}

function sha1::binary::fromString()
{
    # This function converts input string into binary form
    local input_string=${1}
    local binary_string=''

    for idx ({1..${#input_string}}); do
        binary_string="${binary_string}$(sha1::binary::fromChar ${input_string[${idx}]})"
    ; done

    echo -n ${binary_string}
}

function sha1::binary::appendOne()
{
    # This function appends 1 in the tail of input
    local binary_string=${1}

    echo -n "${binary_string}1"
}

function sha1::binary::splitIntoBitBlocks()
{
    local input_binary_string=${1}
    local block_length=${2}
    local delimiter=${3}

    local result_string=''

    while [[ $((${#input_binary_string} - ${block_length})) > 0 ]]; do
        result_string="${result_string}${delimiter}${input_binary_string[1,${block_length}]}"
        input_binary_string="${input_binary_string[$((${block_length} + 1)), -1]}"
    ; done

    [[ ${#input_binary_string} != 0 ]] && result_string="${result_string}${delimiter}${input_binary_string}"

    echo -n ${result_string[2, -1]}
}

function sha1::binary::createBlocks()
{
    # Zero-padding & Append footer
    local base_length=512
    local reserved_length=64
    local input_binary_string=${1}
    local data_length=$((${base_length} - ${reserved_length}))
    local blocks=($(sha1::binary::splitIntoBitBlocks ${input_binary_string} ${data_length} ' '))

    local result_blocks=''
    local delimiter=' '

    for idx ({1..${#blocks}}); do
        local block=${blocks[${idx}]}
        local block_length_binary=$(sha1::binary::fromInteger ${#block})
        block_length_binary="${(l.$((${reserved_length} - ${#block_length_binary}))..0.)}${block_length_binary}"

        [[ ${idx} == ${#blocks} ]] && {
            local padding_length=$((${data_length} - ${#block}))
            [[ $((${padding_length} - 8)) > 0 ]] && {
                block="${block}10000000"
                padding_length=$((${padding_length} - 8))
            }
            block="${block}${(l.${padding_length}..0.)}"
        }

        result_blocks="${result_blocks}${delimiter}${block}${block_length_binary}"
    ; done

    echo -n ${result_blocks[2, -1]}
}

function sha1::binary::block::computeRotatedBlocks()
{
    # This method computes W16 to W80
    local input_block=${1}
    local blocks=($(sha1::binary::splitIntoBitBlocks ${input_block} 32 ' '))

    for idx ({16..79}); do
        local base_values=(
            $(sha1::integer::fromBinary ${blocks[$((${idx} - 16 + 1))]})
            $(sha1::integer::fromBinary ${blocks[$((${idx} - 14 + 1))]})
            $(sha1::integer::fromBinary ${blocks[$((${idx} - 8 + 1))]})
            $(sha1::integer::fromBinary ${blocks[$((${idx} - 3 + 1))]})
        )

        local xor_value=${base_values[1]}
        for i ({2..4}); do
            xor_value=$((${xor_value} ^ ${base_values[${i}]}))
        ; done

        local xor_binary_value=$(sha1::binary::fromInteger ${xor_value})
        local padding_length=$((32 - ${#xor_binary_value}))
        xor_binary_value="${(l.${padding_length}..0.)}${xor_binary_value}"
        xor_binary_value="${xor_binary_value[2, -1]}${xor_binary_value[1]}"

        blocks=(${blocks} ${xor_binary_value})
    ; done

    echo ${blocks}
}

function sha1::main()
{
    local input_string=${1}
    local binary_input_string=$(sha1::binary::fromString "${input_string}")
    local splitted_blocks=($(sha1::binary::createBlocks ${binary_input_string}))

    foreach block (${splitted_blocks}); do
        sha1::binary::block::combineAll ${block}
    ; done
}

# TODO: Change the function name
function sha1::binary::block::combineAll()
{
    # - Inputs
    #   - input_block (512 bits message block)
    local base_internal_state=($(sha1::binary::baseInternalStates))
    local current_internal_state=${base_internal_state}
    local input_block=${1}

    local splitted_blocks=($(sha1::binary::block::computeRotatedBlocks ${input_block}))

    for idx ({1..${#splitted_blocks}}); do
        local splitted_block=${splitted_blocks[${idx}]}
        current_internal_state=($(sha1::binary::block::updateInternalState $((${idx} - 1)) "${current_internal_state}" ${splitted_block}))
    ; done

    local hex_result=()

    for i ({1..5}); do
        local lhs="0b${base_internal_state[${i}]}"
        local rhs="0b${current_internal_state[${i}]}"

        local result=$(echo $(([#2] ${lhs} + ${rhs})) | cut -d '#' -f 2)

        result="0b${result[-32, -1]}"

        hex_result=(${hex_result} $(echo $(([#16] ${result})) | cut -d '#' -f 2))
    ; done

    echo ${hex_result}
}

function sha1::binary::block::updateInternalState()
{
    local step_id=${1}
    local current_internal_states=($(echo ${2} | tr ' ' '\n'))
    local input_block=${3}

    local new_internal_states=(${current_internal_states})
    local step_constant=$(sha1::binary::constntForStepID ${step_id})

    local result=$(sha1::binary::transformForStepID \
                  ${step_id} \
                  ${current_internal_states[2]} \
                  ${current_internal_states[3]} \
                  ${current_internal_states[4]})

    local lhs=0
    local rhs=0

    # ---

    lhs="0b${new_internal_states[5]}"
    rhs="0b${result}"

    result=$(echo $(([#2] ${lhs} + ${rhs})) | cut -d '#' -f 2)
    new_internal_states[5]=${result}

    # ---

    result=${current_internal_states[1]}
    result="${result[6, -1]}${result[1, 5]}"

    lhs="0b${new_internal_states[5]}"
    rhs="0b${result}"

    result=$(echo $(([#2] ${lhs} + ${rhs})) | cut -d '#' -f 2)
    new_internal_states[5]=${result}

    # ---

    lhs="0b${new_internal_states[5]}"
    rhs="0b${input_block}"

    result=$(echo $(([#2] ${lhs} + ${rhs})) | cut -d '#' -f 2)
    new_internal_states[5]=${result}

    # ---

    lhs="0b${new_internal_states[5]}"
    rhs="0b${step_constant}"

    result=$(echo $(([#2] ${lhs} + ${rhs})) | cut -d '#' -f 2)

    result="${(l.$((32 - ${#result}))..0.)}${result}"
    new_internal_states[5]=${result[-32,-1]}

    # ---

    result=${current_internal_states[2]}

    new_internal_states[1]=${new_internal_states[5]}
    new_internal_states[2]=${current_internal_states[1]}
    new_internal_states[3]="${result[31, 32]}${result[1, 30]}"
    new_internal_states[4]=${current_internal_states[3]}
    new_internal_states[5]=${current_internal_states[4]}

    echo ${new_internal_states}
}

