#
# Converters to decimal
#

# Char -> Decimal
function converter::decimal::from_char()
{
    # This function converts input ascii char into integer value
    # TODO: Find Char -> ASCII convert method without printf.
    printf "%d" \'${1}
}

# Binary string -> Decimal
function converter::decimal::from_binary()
{
    local input_value="0b${1}"

    echo $((${input_value}))
}

#
# Converters to hex
#

# Binary string -> Hex
function converter::hex::from_binary()
{
    local input_value="0b${1}"
    local results=(${(s:#:)$(([#16] ${input_value}))})

    echo ${results[2]}
}

#
# Converters to binary
#

# Hex -> Binary string
function converter::binary::from_hex()
{
    local input_value="0x${1}"
    local results=(${(s:#:)$(([#2] ${input_value}))})

    echo ${results[2]}
}

# Decimal -> Binary string
function converter::binary::from_decimal()
{
    local input_value=${1}
    local results=(${(s:#:)$(([#2] ${input_value}))})

    echo ${results[2]}
}

# Char -> Binary string
function converter::binary::from_char()
{
    # This function converts input ascii char into 8-bits binary form
    local input_char=${1}
    local ascii_value=$(converter::decimal::from_char ${input_char})
    local binary_string=$(converter::binary::from_decimal ${ascii_value})

    [[ ${#binary_string} < 8 ]] && {
        local padding_length=$((8 - ${#binary_string}))
        local padding_string=${(l.${padding_length}..0.)}

        binary_string="${padding_string}${binary_string}"
    }

    echo -n ${binary_string}
}

# String ([Char]) -> Binary string
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

# Binary string, Decimal, Char -> [Binary string (block_length-bits)]
function converter::binary::split()
{
    local input_binary_string=${1}
    local block_length=${2}
    local delimiter=${3}

    local result_string=''

    while [[ $((${#input_binary_string} - ${block_length})) > 0 ]]; do
        result_string="${result_string}${delimiter}${input_binary_string[1, ${block_length}]}"
        input_binary_string="${input_binary_string[$((${block_length} + 1)), -1]}"
    ; done

    [[ ${#input_binary_string} != 0 ]] && result_string="${result_string}${delimiter}${input_binary_string}"

    echo -n ${result_string[2, -1]}
}

#
# Constants store
#

# -> [Binary string (32-bits)]
function sha1::constant::initial_internal_states()
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

# Decimal (0 - 79) -> Binary string (32-bits)
function sha1::constant::step_coef()
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

# Decimal (0 - 79), Binary string (32-bits), Binary string (32-bits), Binary string (32-bits) -> Binary string (32-bits)
function sha1::mapping::step_mapping()
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
    result=$(converter::binary::from_decimal ${result})

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

# Binary string -> [Binary string (512-bits)]
function sha1::mapping::to_blocks()
{
    # Zero-padding & Append footer
    local base_length=512
    local data_length_info_length=64
    local input_binary_string=${1}

    # Compute input binary length in binary notation and padding to 64-bits
    local input_binary_length_info=$(converter::binary::from_decimal ${#input_binary_string})
    input_binary_length_info="${(l.$((${data_length_info_length} - ${#input_binary_length_info}))..0.)}${input_binary_length_info}"

    # Append 1 to input binary string
    input_binary_string="${input_binary_string}1"

    # Split input binary string into 512-bits blocks
    local blocks=($(converter::binary::split "${input_binary_string}" ${base_length} ' '))
    local last_element=${blocks[-1]}
    local end_length=$(((${base_length} - ${data_length_info_length}) - ${#last_element}))

    if [[ ${end_length} == 0 ]]; then
        # Nothing to do

    elif [[ ${end_length} > 0 ]]; then
        blocks[-1]="${last_element}${(l.${end_length}..0.)}"

    else
        blocks[-1]="${last_element}${(l.$((${base_length} - ${#last_element}))..0.)}"
        blocks=(${blocks} ${(l.$((${base_length} - ${data_length_info_length}))..0.)})
    fi

    blocks[-1]="${blocks[-1]}${input_binary_length_info}"

    echo -n ${blocks}
}

#
# SHA-1 specific computations
#

# Binary string (512-bits) -> [Binary string (32-bits)]
function sha1::mapping::to_rotated_blocks()
{
    # This method computes W16 to W80
    local input_block=${1}

    # Split input binary string into 32-bits blocks
    local blocks=($(converter::binary::split ${input_block} 32 ' '))

    # Compute W16 to W80
    for idx ({16..79}); do
        local base_values=(
            $(converter::decimal::from_binary ${blocks[$((${idx} - 16 + 1))]})
            $(converter::decimal::from_binary ${blocks[$((${idx} - 14 + 1))]})
            $(converter::decimal::from_binary ${blocks[$((${idx} - 8 + 1))]})
            $(converter::decimal::from_binary ${blocks[$((${idx} - 3 + 1))]})
        )

        # Compute rotation
        local xor_value=$(converter::binary::from_decimal $((${base_values[1]} ^ ${base_values[2]} ^ ${base_values[3]} ^ ${base_values[4]})))

        # Padding value with 0 to 32 bits
        local padding_length=$((32 - ${#xor_value}))
        xor_value="${(l.${padding_length}..0.)}${xor_value}"
        xor_value="${xor_value[2, -1]}${xor_value[1]}"

        # Append to block
        blocks=(${blocks} ${xor_value})
    ; done

    echo ${blocks}
}

# Binary string (512-bits), [Binary string (32-bits)] -> [Binary string (32-bits)]
function sha1::mapping::to_sha1_binary()
{
    # Obtain initial internal states and initialize
    local input_block=${1}
    local base_internal_states=($(echo ${2}))
    local current_internal_states=${base_internal_states}

    # Convert (and split) input 512-bits binary string into 80 of 32-bits blocks for each step
    local splitted_blocks=($(sha1::mapping::to_rotated_blocks ${input_block}))

    # Process each steps (80 steps in total)
    for idx ({1..80}); do
        # Obtain partial converted block
        local splitted_block=${splitted_blocks[${idx}]}

        # Prepare current step ID (step ID is 0-origin)
        local step_id=$((${idx} - 1))

        # Update internal states
        current_internal_states=($(sha1::mapping::update_internal_states \
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

        local result="${(l.32..0.)}$(converter::binary::from_decimal $((${lhs} + ${rhs})))"

        # Shrink the number of bits in the result into 32-bits
        current_internal_states[${i}]="${result[-32, -1]}"
    ; done

    echo ${current_internal_states}
}

# Decimal (0 - 79), [Binary string (32-bits)], Binary string (32-bits) -> [Binary string (32-bits)]
function sha1::mapping::update_internal_states()
{
    local step_id=${1}
    local current_internal_states=($(echo ${2}))
    local input_block=${3}

    # Initialize next internal states array
    local new_internal_states=(${current_internal_states})

    local lhs=0
    local rhs=0

    # --- Computation related to F value

    # Compute F value for step value and internal states
    local F=$(sha1::mapping::step_mapping \
              ${step_id} \
              ${current_internal_states[2]} \
              ${current_internal_states[3]} \
              ${current_internal_states[4]})

    lhs="0b${new_internal_states[5]}"
    rhs="0b${F}"

    new_internal_states[5]=$(converter::binary::from_decimal $((${lhs} + ${rhs})))

    # --- Computation related to 5-bits rotated A value

    # Compute 5-bit left rotation
    local rot_A=${current_internal_states[1]}
    rot_A="${rot_A[6, -1]}${rot_A[1, 5]}"

    lhs="0b${new_internal_states[5]}"
    rhs="0b${rot_A}"

    new_internal_states[5]=$(converter::binary::from_decimal $((${lhs} + ${rhs})))

    # --- Computation related to input block W value

    lhs="0b${new_internal_states[5]}"
    rhs="0b${input_block}"

    new_internal_states[5]=$(converter::binary::from_decimal $((${lhs} + ${rhs})))

    # --- Computation related to K value

    # Obtain step constant (K value) for current step ID
    local K=$(sha1::constant::step_coef ${step_id})

    lhs="0b${new_internal_states[5]}"
    rhs="0b${K}"

    new_internal_states[5]=$(converter::binary::from_decimal $((${lhs} + ${rhs})))

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

# String -> Hex
function sha1::main()
{
    local input_string=${1}
    local binary_input_string=$(converter::binary::from_string "${input_string}")
    local splitted_blocks=($(sha1::mapping::to_blocks ${binary_input_string}))

    local result=($(sha1::constant::initial_internal_states))
    foreach block (${splitted_blocks}); do
        result=($(sha1::mapping::to_sha1_binary ${block} "${result}"))
    ; done

    # Convert to hex
    local hex_result=''
    for i ({1..5}); do
        local block=${result[${i}]}

        # Store to results array in hex notation
        hex_result="${hex_result}$(converter::hex::from_binary ${block})"
    ; done

    echo ${hex_result}
}
