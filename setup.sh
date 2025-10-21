#!/usr/bin/env bash
# Setup the product for usage
#
# Copyright 2025 Buo-ren Lin <buo.ren.lin@gmail.com>
# SPDX-License-Identifier: CC-BY-SA-4.0+
CODIMD_DOMAIN="${CODIMD_DOMAIN:-""}"
CODIMD_HTTPS_PORT="${CODIMD_HTTPS_PORT:-""}"
CODIMD_GENERATE_SELFSIGNED_CERTIFICATE="${CODIMD_GENERATE_SELFSIGNED_CERTIFICATE:-""}"
CODIMD_POSTGRESQL_PASSWORD="${CODIMD_POSTGRESQL_PASSWORD:-""}"
CODIMD_SESSION_SECRET="${CODIMD_SESSION_SECRET:-""}"

init(){
    local operation_timestamp
    if ! operation_timestamp="$(printf '%(%Y%m%d%H%M%S)T')"; then
        printf \
            'Error: Unable to determine the operation timestamp.\n' \
            1>&2
        exit 1
    fi

    printf \
        'Info: Checking the availability of the Basic English word list...\n'
    if ! test -e "${script_dir}/basic-english-word-list/all.sorted.txt"; then
        printf \
            'Error: The Basic English word list is not available.\n' \
            1>&2
        exit 1
    fi

    printf \
        'Info: Loading the Basic English word list into an array...\n'
    if ! mapfile -t word_list \
        <"${script_dir}/basic-english-word-list/all.sorted.txt"; then
        printf \
            'Error: Unable to load the Basic English word list into an array.\n' \
            1>&2
        exit 1
    fi
    word_count="${#word_list[@]}"
    printf \
        'Info: Loaded %d words into the Basic English word list array.\n' \
        "${word_count}"

    if test -z "${CODIMD_DOMAIN}"; then
        while true; do
            printf \
                'Which domain name/IP address do you want to use for the CodiMD service? (e.g., codimd.example.com): '
            read -r user_input
            if test -z "${user_input}"; then
                printf \
                    'Error: Domain name/IP address cannot be empty, please try again.\n'
                continue
            fi

            if ! is_domain_valid "${user_input}" \
                && ! is_ip_address_valid "${user_input}"; then
                printf \
                    'Error: Invalid domain name format, please try again.\n'
                continue
            else
                CODIMD_DOMAIN="${user_input}"
                break
            fi
        done
    fi

    if test -z "${CODIMD_HTTPS_PORT}"; then
        while true; do
            printf \
                'Which port do you want to use for HTTPS access to the CodiMD service? (default: 443): '
            read -r user_input
            if test -z "${user_input}"; then
                CODIMD_HTTPS_PORT="443"
                break
            fi

            if is_port_valid "${user_input}"; then
                CODIMD_HTTPS_PORT="${user_input}"
                break
            else
                printf \
                    'Error: Invalid port number, please try again.\n' \
                    1>&2
                continue
            fi
        done
    fi

    if test -z "${CODIMD_POSTGRESQL_PASSWORD}"; then
        printf \
            'Which password do you want to use for the PostgreSQL database? (default: randomly generated): '
        read -r user_input
        if test -z "${user_input}"; then
            if ! CODIMD_POSTGRESQL_PASSWORD="$(generate_passphrase 4 "${word_list[@]}")"; then
                printf \
                    'Error: Unable to generate a random passphrase for the PostgreSQL database.\n' \
                    1>&2
                exit 1
            fi
            printf \
                'Info: Generated random PostgreSQL password: %s\n' \
                "${CODIMD_POSTGRESQL_PASSWORD}"
        else
            CODIMD_POSTGRESQL_PASSWORD="${user_input}"
        fi
    fi

    if test -z "${CODIMD_SESSION_SECRET}"; then
        printf \
            'Which password do you want to use for the session secret? (default: randomly generated): '
        read -r user_input
        if test -z "${user_input}"; then
            if ! CODIMD_SESSION_SECRET="$(generate_passphrase 4 "${word_list[@]}")"; then
                printf \
                    'Error: Unable to generate a random passphrase for the session secret.\n' \
                    1>&2
                exit 1
            fi
            printf \
                'Info: Generated random session secret: %s\n' \
                "${CODIMD_SESSION_SECRET}"
        else
            CODIMD_SESSION_SECRET="${user_input}"
        fi
    fi

    local -a sed_opts_common=(
        --regexp-extended
    )

    printf \
        'Info: Generating the environment file from template...\n'
    local real_env_file="${script_dir}/.env"
    local template_env_file="${script_dir}/.env.in"

    local -a sed_opts=(
        "${sed_opts_common[@]}"
        --expression="s@__CODIMD_DOMAIN__@${CODIMD_DOMAIN}@g"
        --expression="s@__CODIMD_POSTGRESQL_PASSWORD__@${CODIMD_POSTGRESQL_PASSWORD}@g"
        --expression="s@__CODIMD_SESSION_SECRET__@${CODIMD_SESSION_SECRET}@g"
    )

    # __CODIMD_HTTPS_PORT_Q__: We don't need the port specification URL component for the default HTTPS port 443
    if test "${CODIMD_HTTPS_PORT}" != 443; then
        sed_opts+=(
            --expression="s@#?CMD_URL_ADDPORT=.*@CMD_URL_ADDPORT=true@g"
            --expression="s@__CODIMD_HTTPS_PORT_Q__@:${CODIMD_HTTPS_PORT}@g"
        )
    else
        sed_opts+=(
            --expression="s@#?CMD_URL_ADDPORT=.*@CMD_URL_ADDPORT=false@g"
            --expression="s@__CODIMD_HTTPS_PORT_Q__@@g"
        )
    fi

    local -a cp_opts_backup=(
        --archive
        --verbose
    )

    if test -e "${real_env_file}"; then
        local backup_env_file="${real_env_file}.bak.${operation_timestamp}"
        printf \
            'Info: Backing up the existing environment file to "%s"...\n' \
            "${backup_env_file}"
        if ! cp "${cp_opts_backup[@]}" \
            "${real_env_file}" \
            "${backup_env_file}"; then
            printf \
                'Error: Unable to back up the existing environment file.\n' \
                1>&2
            exit 1
        fi
    fi

    if ! sed "${sed_opts[@]}" \
        "${template_env_file}" \
        >"${real_env_file}"; then
        printf \
            'Error: Unable to generate the environment file from template.\n' \
            1>&2
        exit 1
    fi

    printf \
        'Info: Generating the Compose configuration file from template...\n'
    local -a sed_opts=(
        "${sed_opts_common[@]}"
        --expression="s@__CODIMD_HTTPS_PORT__@${CODIMD_HTTPS_PORT}@g"
    )
    if test "${CODIMD_HTTPS_PORT}" == 443; then
        sed_opts+=(
            # For redirecting HTTP to HTTPS when using the default HTTPS port
            --expression="s@#- 80:80@- 80:80@g"
        )
    fi
    template_compose_file="${script_dir}/compose.yml.in"
    real_compose_file="${script_dir}/compose.yml"

    if test -e "${real_compose_file}"; then
        local backup_compose_file="${real_compose_file}.bak.${operation_timestamp}"
        printf \
            'Info: Backing up the existing Compose file to "%s"...\n' \
            "${backup_compose_file}"
        if ! cp "${cp_opts_backup[@]}" \
            "${real_compose_file}" \
            "${backup_compose_file}"; then
            printf \
                'Error: Unable to back up the existing Compose file.\n' \
                1>&2
            exit 1
        fi
    fi

    if ! sed "${sed_opts[@]}" \
        "${template_compose_file}" \
        >"${real_compose_file}"; then
        printf \
            'Error: Unable to generate the Compose configuration file from template.\n' \
            1>&2
        exit 1
    fi

    printf \
        'Info: Generating the companion NGINX drop-in configuration file from template...\n'
    local -a sed_opts=(
        "${sed_opts_common[@]}"
        --expression="s@__CODIMD_DOMAIN__@${CODIMD_DOMAIN}@g"
    )
    local template_nginx_dropin_config="${script_dir}/nginx.conf.d/codimd.conf.in"
    local real_nginx_dropin_config="${script_dir}/nginx.conf.d/codimd.conf"

    if test -e "${real_nginx_dropin_config}"; then
        local backup_nginx_dropin_config="${real_nginx_dropin_config}.bak.${operation_timestamp}"
        printf \
            'Info: Backing up the existing NGINX drop-in configuration file to "%s"...\n' \
            "${backup_nginx_dropin_config}"
        if ! cp "${cp_opts_backup[@]}" \
            "${real_nginx_dropin_config}" \
            "${backup_nginx_dropin_config}"; then
            printf \
                'Error: Unable to back up the existing NGINX drop-in configuration file.\n' \
                1>&2
            exit 1
        fi
    fi

    if ! sed "${sed_opts[@]}" \
        "${template_nginx_dropin_config}" \
        >"${real_nginx_dropin_config}"; then
        printf \
            'Error: Unable to generate the NGINX drop-in configuration file from template.\n' \
            1>&2
        exit 1
    fi

    if test -z "${CODIMD_GENERATE_SELFSIGNED_CERTIFICATE}"; then
        while true; do
            printf \
                'Do you want to generate a self-signed SSL certificate? (Y/n): '
            read -r user_input
            case "${user_input}" in
                [nN])
                    CODIMD_GENERATE_SELFSIGNED_CERTIFICATE=false
                    printf \
                        'Warning: You have chosen not to generate a self-signed SSL certificate. Please ensure that you have provided a valid SSL certificate for the domain "%s" before launching the service.\n' \
                        "${CODIMD_DOMAIN}" \
                        1>&2
                    break
                    ;;
                [yY]|'')
                    CODIMD_GENERATE_SELFSIGNED_CERTIFICATE=true
                    break
                    ;;
                *)
                    printf \
                        'Error: Invalid input, please try again.\n' \
                        1>&2
                    ;;
            esac
        done
    fi

    if test "${CODIMD_GENERATE_SELFSIGNED_CERTIFICATE}" == true; then
        printf \
            'Info: Generating self-signed SSL certificate...\n'
        local cert_dir="${script_dir}/ssl"
        if ! mkdir --parents "${cert_dir}"; then
            printf \
                'Error: Unable to create the certificate directory.\n' \
                1>&2
            exit 1
        fi

        local cert="${cert_dir}/${CODIMD_DOMAIN}.crt"
        local key="${cert_dir}/${CODIMD_DOMAIN}.key"
        if ! openssl req \
            -x509 \
            -nodes \
            -days 365 \
            -newkey rsa:2048 \
            -keyout "${key}" \
            -out "${cert}" \
            -subj "/CN=${CODIMD_DOMAIN}"; then
            printf \
                'Error: Unable to generate the self-signed SSL certificate.\n' \
                1>&2
            exit 1
        fi
    fi

    printf \
        'Info: Operation completed without errors.\n'

    local -a secret_vars=(
        CODIMD_POSTGRESQL_PASSWORD
        CODIMD_SESSION_SECRET
    )
    printf \
        'Info: The following secrets are used in this setup:\n\n'
    for var in "${secret_vars[@]}"; do
        printf '* %s=%s\n' "${var}" "${!var}"
    done
    printf '\n'

    printf \
        'Info: Please securely store these secrets for future reference.\n'
}

is_port_valid(){
    local port="$1"; shift

    local regex_natural_number='^[1-9][0-9]*$'
    if ! [[ "${port}" =~ ${regex_natural_number} ]]; then
        return 1
    fi

    if test "${port}" -lt 1 \
        || test "${port}" -gt 65535; then
        return 1
    fi
    return 0
}

is_domain_valid(){
    local domain="$1"; shift
    local ascii_domain

    # Check if domain is empty
    if test -z "${domain}"; then
        return 1
    fi

    # Check for invalid characters or patterns
    if grep -Eq '[[:space:][:cntrl:]]|^\.|\.\.|\.$|^-|-$' <<<"${domain}"; then
        return 1
    fi

    # Check for invalid double hyphens (but allow punycode xn--)
    if grep -Eq '(^|\.)[^x][^n]-{2}|^xn-{3,}|[^n]-{2}' <<<"${domain}"; then
        return 1
    fi

    # Reject IP addresses (basic check)
    if grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' <<<"${domain}"; then
        return 1
    fi

    # Handle IDN domains if idn tool is available
    if command -v idn >/dev/null 2>&1; then
        if ! ascii_domain=$(idn -a "${domain}" 2>/dev/null); then
            return 1
        fi
    elif command -v idn2 >/dev/null 2>&1; then
        if ! ascii_domain=$(idn2 --to-ascii "${domain}" 2>/dev/null); then
            return 1
        fi
    fi

    # Validate ASCII domain format
    # Domain names can contain letters, digits, hyphens, and dots
    # Must not start or end with hyphen, must not have consecutive dots
    if ! grep -Eq \
        '^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$' \
        <<<"${ascii_domain}"; then
        return 1
    fi

    # Check domain length (maximum 253 characters for FQDN)
    if test "${#ascii_domain}" -gt 253; then
        return 1
    fi

    # Check individual label lengths (maximum 63 characters per label)
    local IFS='.'
    for label in ${ascii_domain}; do
        if test "${#label}" -gt 63; then
            return 1
        fi
    done

    return 0
}

# FIXME: Support IPv6
is_ip_address_valid(){
    local ip="${1}"; shift

    # Check if IP address is empty
    if test -z "${ip}"; then
        return 1
    fi

    # Validate IP address format (basic check)
    if ! grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' <<<"${ip}"; then
        return 1
    fi

    # Check individual octet values
    local IFS='.'
    for octet in ${ip}; do
        if test "${octet}" -lt 0 || test "${octet}" -gt 255; then
            return 1
        fi
    done

    return 0
}

# Generate a random alphanumeric passphrase
generate_passphrase(){
    local length="${1}"; shift
    local -a word_list=("${@}")

    local regex_natural_number='^[1-9][0-9]*$'
    if ! [[ "${length}" =~ ${regex_natural_number} ]]; then
        printf \
            '%s: Error: The passphrase length must be a positive integer.\n' \
            "${FUNCNAME[0]}" \
            1>&2
        return 1
    fi

    if test "${#word_list[@]}" -eq 0; then
        printf \
            '%s: Error: The word list cannot be empty.\n' \
            "${FUNCNAME[0]}" \
            1>&2
        return 1
    fi
    local word_count="${#word_list[@]}"

    local -a passphrase_words=()
    local -i index=0
    for (( i = 0; i < length; i++ )); do
        index=$((RANDOM % word_count))
        passphrase_words+=("${word_list[index]}")
    done

    echo "${passphrase_words[@]}"
}

printf \
    'Info: Configuring the defensive interpreter behaviors...\n'
set_opts=(
    # Terminate script execution when an unhandled error occurs
    -o errexit
    -o errtrace

    # Terminate script execution when an unset parameter variable is
    # referenced
    -o nounset
)
if ! set "${set_opts[@]}"; then
    printf \
        'Error: Unable to configure the defensive interpreter behaviors.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Checking the existence of the required commands...\n'
required_commands=(
    cp
    date
    grep
    openssl
    realpath
    sed
)
flag_required_command_check_failed=false
for command in "${required_commands[@]}"; do
    if ! command -v "${command}" >/dev/null; then
        flag_required_command_check_failed=true
        printf \
            'Error: This program requires the "%s" command to be available in your command search PATHs.\n' \
            "${command}" \
            1>&2
    fi
done
if test "${flag_required_command_check_failed}" == true; then
    printf \
        'Error: Required command check failed, please check your installation.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Checking the availability of idn utilities...\n'
if ! command -v idn >/dev/null \
    && ! command -v idn2 >/dev/null; then
    printf \
        'Error: Neither "idn" nor "idn2" command is available.  This is required for handling International Domain Name (IDN) domain names.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Configuring the convenience variables...\n'
if test -v BASH_SOURCE; then
    # Convenience variables may not need to be referenced
    # shellcheck disable=SC2034
    {
        printf \
            'Info: Determining the absolute path of the program...\n'
        if ! script="$(
            realpath \
                --strip \
                "${BASH_SOURCE[0]}"
            )"; then
            printf \
                'Error: Unable to determine the absolute path of the program.\n' \
                1>&2
            exit 1
        fi
        script_dir="${script%/*}"
        script_filename="${script##*/}"
        script_name="${script_filename%%.*}"
    }
fi
# Convenience variables may not need to be referenced
# shellcheck disable=SC2034
{
    script_basecommand="${0}"
    script_args=("${@}")
}

printf \
    'Info: Setting the ERR trap...\n'
trap_err(){
    printf \
        'Error: The program has encountered an unhandled error and is prematurely aborted.\n' \
        1>&2
}
if ! trap trap_err ERR; then
    printf \
        'Error: Unable to set the ERR trap.\n' \
        1>&2
    exit 1
fi

init
