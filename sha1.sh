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

#
# Converters to hex
#

# Decimal -> hex
function converter::hex::from_decimal()
{
    local input_value=${1}
    local results=(${(s:#:)$(([#16] ${input_value}))})

    echo ${results[2]}
}

#
# Converters to binary
#

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
        result_string="${result_string}${delimiter}${input_binary_string[1,${block_length}]}"
        input_binary_string="${input_binary_string[$((${block_length} + 1)), -1]}"
    ; done

    [[ ${#input_binary_string} != 0 ]] && result_string="${result_string}${delimiter}${input_binary_string}"

    echo -n ${result_string[2, -1]}
}

#
# Constants store
#

# -> [Binary string (32-bits)]
function sha1::binary::constant::initial_internal_states()
{
    local base_length=32
    local states=(
        '0x67452301'
        '0xEFCDAB89'
        '0x98BADCFE'
        '0x10325476'
        '0xC3D2E1F0'
    )

    # Map states into decimal
    for idx ({1..${#states}}); do
        states[${idx}]=$((${states[${idx}]}))
    ; done

    echo -n ${states}
}

# Decimal (0 - 79) -> Binary string (32-bits)
function sha1::binary::constant::step_coef()
{
    local step_id=${1}

    local base_length=32
    local states=(
        '0x5A827999'
        '0x6ED9EBA1'
        '0x8F1BBCDC'
        '0xCA62C1D6'
    )

    local state=${states[$(((${step_id} / 20) + 1))]}

    echo -n $((${state}))
}

#
# Mapping function
#

# Decimal (0 - 79), Binary string (32-bits), Binary string (32-bits), Binary string (32-bits) -> Binary string (32-bits)
function sha1::binary::mapping::step_mapping()
{
    local step_id=${1}
    local base_length=32

    # Pick up buffers
    local B=${2}
    local C=${3}
    local D=${4}

    # Compute state from step ID
    local state=$(((${step_id} / 20) + 1))

    # This will be used for computation of inverse of bits
    local unsigned_inv_mask=$((0xffffffff))

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

    echo -n ${result}
}

#
# Binary split functions
#

# Binary string -> [Binary string (512-bits)]
function sha1::binary::mapping::to_blocks()
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
function sha1::binary::mapping::to_rotated_blocks()
{
    # This method computes W16 to W80
    local input_block=${1}

    # Split input binary string into 32-bits blocks
    local blocks=($(converter::binary::split ${input_block} 32 ' '))

    # Convert binary notation to decimal notation
    for idx ({1..${#blocks}}); do
        local block="0b${blocks[${idx}]}"
        blocks[${idx}]=$((${block}))
    ; done

    # Compute W16 to W80
    for idx ({16..79}); do
        local base_values=(
            ${blocks[$((${idx} - 16 + 1))]}
            ${blocks[$((${idx} - 14 + 1))]}
            ${blocks[$((${idx} - 8 + 1))]}
            ${blocks[$((${idx} - 3 + 1))]}
        )

        # Compute rotation
        local xor_value=$((${base_values[1]} ^ ${base_values[2]} ^ ${base_values[3]} ^ ${base_values[4]}))

        # 1-bit rotate
        xor_value=$((((${xor_value} << 1) & 0xfffffffe) | ((${xor_value} >> 31) & 0x01)))

        # Append to block
        blocks=(${blocks} ${xor_value})
    ; done

    echo ${blocks}
}

# Binary string (512-bits), [Binary string (32-bits)] -> [Binary string (32-bits)]
function sha1::binary::mapping::to_sha1_binary()
{
    # Obtain initial internal states and initialize
    local input_block=${1}
    local base_internal_states=($(echo ${2}))
    local current_internal_states=${base_internal_states}

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
        local lhs=${base_internal_states[${i}]}
        local rhs=${current_internal_states[${i}]}

        local result=$((${lhs} + ${rhs}))

        # Shrink the number of bits in the result into 32-bits
        current_internal_states[${i}]=$((${result} & 0xffffffff))
    ; done

    echo ${current_internal_states}
}

# Decimal (0 - 79), [Binary string (32-bits)], Binary string (32-bits) -> [Binary string (32-bits)]
function sha1::binary::mapping::update_internal_states()
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
    local F=$(sha1::binary::mapping::step_mapping \
              ${step_id} \
              ${current_internal_states[2]} \
              ${current_internal_states[3]} \
              ${current_internal_states[4]})

    lhs=${new_internal_states[5]}
    rhs=${F}

    new_internal_states[5]=$((${lhs} + ${rhs}))

    # --- Computation related to 5-bits rotated A value

    # Compute 5-bit left rotation
    local rot_A=${current_internal_states[1]}
    rot_A=$((((${rot_A} << 5) & 0xffffffe0) | ((${rot_A} >> 27) & 0x1f)))

    lhs=${new_internal_states[5]}
    rhs=${rot_A}

    new_internal_states[5]=$((${lhs} + ${rhs}))

    # --- Computation related to input block W value

    lhs=${new_internal_states[5]}
    rhs=${input_block}

    new_internal_states[5]=$((${lhs} + ${rhs}))

    # --- Computation related to K value

    # Obtain step constant (K value) for current step ID
    local K=$(($(sha1::binary::constant::step_coef ${step_id})))

    lhs=${new_internal_states[5]}
    rhs=${K}

    new_internal_states[5]=$((${lhs} + ${rhs}))

    # --- Shrink computed value to 32-bits
    new_internal_states[5]=$((${new_internal_states[5]} & 0xffffffff))

    # --- Computation related to 30-bits rotated B value
    local rot_B=${current_internal_states[2]}
    rot_B=$((((${rot_B} << 30) & 0xc0000000) | ((${rot_B} >> 2) & 0x3fffffff)))

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
    local splitted_blocks=($(sha1::binary::mapping::to_blocks ${binary_input_string}))

    local result=($(sha1::binary::constant::initial_internal_states))
    foreach block (${splitted_blocks}); do
        result=($(sha1::binary::mapping::to_sha1_binary ${block} "${result}"))
    ; done

    # Convert to hex
    local hex_result=''
    for i ({1..5}); do
        local block=${result[${i}]}

        # Store to results array in hex notation
        hex_result="${hex_result}$(converter::hex::from_decimal ${block})"
    ; done

    echo ${hex_result}
}
