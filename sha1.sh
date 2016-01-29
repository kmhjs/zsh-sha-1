function sha1::integer::fromChar()
{
    # This function converts input ascii char into integer value
    printf "%d" \'${1}
}

function sha1::binary::fromChar()
{
    # This function converts input ascii char into 8-bits binary form
    local input_char=${1}
    local ascii_value=$(sha1::integer::fromChar ${input_char})
    local binary_string=$(echo "ibase=10;obase=2;${ascii_value}" | bc)

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
