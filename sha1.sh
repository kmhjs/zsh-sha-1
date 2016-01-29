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
