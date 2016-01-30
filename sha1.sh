#
# Converters to integer
#

function converter::integer::from_char()
{
    # This function converts input ascii char into integer value
    printf "%d" \'${1}
}

function converter::integer::from_binary()
{
    local input_value="0b${1}"

    echo $((${input_value}))
}

#
# Converters to binary
#

function converter::binary::from_hex()
{
    local input_value="0x${1}"

    echo $(([#2]${input_value})) | cut -d '#' -f 2
}

function converter::binary::from_integer()
{
    local input_value=${1}

    echo $(([#2]${input_value})) | cut -d '#' -f 2
}

function converter::binary::from_char()
{
    # This function converts input ascii char into 8-bits binary form
    local input_char=${1}
    local ascii_value=$(converter::integer::from_char ${input_char})
    local binary_string=$(converter::binary::from_integer ${ascii_value})

    [[ ${#binary_string} < 8 ]] && {
        local padding_length=$((8 - ${#binary_string}))
        local padding_string=${(l.${padding_length}..0.)}

        binary_string="${padding_string}${binary_string}"
    }

    echo -n ${binary_string}
}

function converter::binary::from_string()
{
    # This function converts input string into binary form
    local input_string=${1}
    local binary_string=''

    for idx ({1..${#input_string}}); do
        binary_string="${binary_string}$(converter::binary::from_char ${input_string[${idx}]})"
    ; done

    echo -n ${binary_string}
}

function converter::binary::split()
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

#
# Constants store
#

function sha1::binary::constant::initial_internal_states()
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
        local binary=$(converter::binary::from_hex ${s})
        local padding_length=$((${base_length} - ${#binary}))
        binary="${(l.${padding_length}..0.)}${binary}"
        binary_states=(${binary_states} ${binary})
    ; done

    echo -n ${binary_states}
}

function sha1::binary::constant::step_coef()
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

    local binary=$(converter::binary::from_hex ${state})
    local padding_length=$((${base_length} - ${#binary}))
    binary="${(l.${padding_length}..0.)}${binary}"

    echo -n ${binary}
}

#
# Mapping function
#

function sha1::binary::mapping::step_mapping()
{
    local step_id=${1}
    local base_length=32

    # Pick up buffers
    local B="0b${2}"
    local C="0b${3}"
    local D="0b${4}"

    # Compute state from step ID
    local state=$(((${step_id} / 20) + 1))

    # This will be used for computation of inverse of bits
    local unsigned_inv_mask="0b${(l.${base_length}..1.)}"

    # Apply mapping function
    local result=""
    case ${state} in
        1)
            result=$(((${B} & ${C}) | ((${unsigned_inv_mask} - ${B}) & ${D})))
            ;;
        2)
            result=$((${B} ^ ${C} ^ ${D}))
            ;;
        3)
            result=$(((${B} & ${C}) | (${C} & ${D}) | (${D} & ${B})))
            ;;
        *)
            result=$((${B} ^ ${C} ^ ${D}))
            ;;
    esac

    # Convert into binary notation
    result=$(converter::binary::from_integer ${result})

    # If padding is required, padding. Otherwise, trim.
    if [[ ${#result} -lt ${base_length} ]]; then
        local padding_length=$((${base_length} - ${#result}))
        result="${(l.${padding_length}..0.)}${result}"

    elif [[ ${#result} -gt ${base_length} ]]; then
        result=${result[-${base_length}, -1]}
    fi

    echo -n ${result}
}

#
# Binary split functions
#

function sha1::binary::mapping::to_blocks()
{
    # Zero-padding & Append footer
    local base_length=512
    local reserved_length=64
    local input_binary_string=${1}
    local data_length=$((${base_length} - ${reserved_length}))

    # Split input binary string into (512 - 64)-bits blocks
    local blocks=($(converter::binary::split ${input_binary_string} ${data_length} ' '))

    local result_blocks=''
    local delimiter=' '

    # Complete to create 512-bits blocks
    for idx ({1..${#blocks}}); do
        # Compute original message length (number of bits), and append 64-bits padded binary data with 0
        local block=${blocks[${idx}]}
        local block_length_binary=$(converter::binary::from_integer ${#block})
        block_length_binary="${(l.$((${reserved_length} - ${#block_length_binary}))..0.)}${block_length_binary}"

        # If reached to the end of message
        [[ ${idx} == ${#blocks} ]] && {
            local padding_length=$((${data_length} - ${#block}))

            # When padding is required, append padding information '10000000', and padding
            [[ $((${padding_length} - 8)) > 0 ]] && {
                block="${block}10000000"
                padding_length=$((${padding_length} - 8))
            }

            # Complete block
            block="${block}${(l.${padding_length}..0.)}"
        }

        # Append to result blocks
        result_blocks="${result_blocks}${delimiter}${block}${block_length_binary}"
    ; done

    echo -n ${result_blocks[2, -1]}
}

#
# SHA-1 specific computations
#

function sha1::binary::mapping::to_rotated_blocks()
{
    # This method computes W16 to W80
    local input_block=${1}

    # Split input binary string into 32-bits blocks
    local blocks=($(converter::binary::split ${input_block} 32 ' '))

    # Compute W16 to W80
    for idx ({16..79}); do
        local base_values=(
            $(converter::integer::from_binary ${blocks[$((${idx} - 16 + 1))]})
            $(converter::integer::from_binary ${blocks[$((${idx} - 14 + 1))]})
            $(converter::integer::from_binary ${blocks[$((${idx} - 8 + 1))]})
            $(converter::integer::from_binary ${blocks[$((${idx} - 3 + 1))]})
        )

        # Compute rotation
        local xor_value=$(converter::binary::from_integer $((${base_values[1]} ^ ${base_values[2]} ^ ${base_values[3]} ^ ${base_values[4]})))

        # Padding value with 0 to 32 bits
        local padding_length=$((32 - ${#xor_value}))
        xor_value="${(l.${padding_length}..0.)}${xor_value}"
        xor_value="${xor_value[2, -1]}${xor_value[1]}"

        # Append to block
        blocks=(${blocks} ${xor_value})
    ; done

    echo ${blocks}
}

function sha1::binary::mapping::to_sha1_hex()
{
    # - Inputs
    #   - input_block (512 bits message block)

    # Obtain initial internal states and initialize
    local base_internal_states=($(sha1::binary::constant::initial_internal_states))
    local current_internal_states=${base_internal_states}
    local input_block=${1}

    # Convert (and split) input 512-bits binary string into 80 of 32-bits blocks for each step
    local splitted_blocks=($(sha1::binary::mapping::to_rotated_blocks ${input_block}))

    # Process each steps (80 steps in total)
    for idx ({1..80}); do
        # Obtain partial converted block
        local splitted_block=${splitted_blocks[${idx}]}

        # Prepare current step ID (step ID is 0-origin)
        local step_id=$((${idx} - 1))

        # Update internal states
        current_internal_states=($(sha1::binary::mapping::update_internal_states \
                                   ${step_id} \
                                   "${current_internal_states}" \
                                   ${splitted_block}))
    ; done

    local hex_result=()

    # Finish up the SHA-1 value
    for i ({1..5}); do
        # Add initial state value to current state value
        local lhs="0b${base_internal_states[${i}]}"
        local rhs="0b${current_internal_states[${i}]}"

        local result=$(converter::binary::from_integer $((${lhs} + ${rhs})))

        # Shrink the number of bits in the result into 32-bits
        result="0b${result[-32, -1]}"

        # Store to results array in hex notation
        hex_result=(${hex_result} $(echo $(([#16] ${result})) | cut -d '#' -f 2))
    ; done

    echo ${hex_result}
}

function sha1::binary::mapping::update_internal_states()
{
    local step_id=${1}
    local current_internal_states=($(echo ${2} | tr ' ' '\n'))
    local input_block=${3}

    # Initialize next internal states array
    local new_internal_states=(${current_internal_states})

    local lhs=0
    local rhs=0

    # --- Computation related to F value

    # Compute F value for step value and internal states
    local F=$(sha1::binary::mapping::step_mapping \
              ${step_id} \
              ${current_internal_states[2]} \
              ${current_internal_states[3]} \
              ${current_internal_states[4]})

    lhs="0b${new_internal_states[5]}"
    rhs="0b${F}"

    new_internal_states[5]=$(converter::binary::from_integer $((${lhs} + ${rhs})))

    # --- Computation related to 5-bits rotated A value

    # Compute 5-bit left rotation
    local rot_A=${current_internal_states[1]}
    rot_A="${rot_A[6, -1]}${rot_A[1, 5]}"

    lhs="0b${new_internal_states[5]}"
    rhs="0b${rot_A}"

    new_internal_states[5]=$(converter::binary::from_integer $((${lhs} + ${rhs})))

    # --- Computation related to input block W value

    lhs="0b${new_internal_states[5]}"
    rhs="0b${input_block}"

    new_internal_states[5]=$(converter::binary::from_integer $((${lhs} + ${rhs})))

    # --- Computation related to K value

    # Obtain step constant (K value) for current step ID
    local K=$(sha1::binary::constant::step_coef ${step_id})

    lhs="0b${new_internal_states[5]}"
    rhs="0b${K}"

    new_internal_states[5]=$(converter::binary::from_integer $((${lhs} + ${rhs})))

    # --- Shrink computed value to 32-bits
    new_internal_states[5]=${${new_internal_states[5]}[-32,-1]}

    # --- Computation related to 30-bits rotated B value
    local rot_B=${current_internal_states[2]}
    rot_B="${rot_B[31, 32]}${rot_B[1, 30]}"

    # --- Remapping of current states
    new_internal_states[1]=${new_internal_states[5]}
    new_internal_states[2]=${current_internal_states[1]}
    new_internal_states[3]=${rot_B}
    new_internal_states[4]=${current_internal_states[3]}
    new_internal_states[5]=${current_internal_states[4]}

    echo ${new_internal_states}
}

function sha1::main()
{
    local input_string=${1}
    local binary_input_string=$(converter::binary::from_string "${input_string}")
    local splitted_blocks=($(sha1::binary::mapping::to_blocks ${binary_input_string}))

    foreach block (${splitted_blocks}); do
        sha1::binary::mapping::to_sha1_hex ${block}
    ; done
}
