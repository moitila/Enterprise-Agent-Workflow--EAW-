#!/usr/bin/env bash
# tests/invariants.sh — Structural invariants for the EAW repository.
# No EAW_WORKDIR, no repos.conf, no runtime dependencies.
# Executable from any directory.
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

errors=0

fail() {
    local inv="$1"
    local msg="$2"
    printf "FAIL: %s: %s\n" "$inv" "$msg"
    errors=$(( errors + 1 ))
}

summary() {
    printf "Invariants: errors=%d\n" "$errors"
    exit $(( errors > 0 ? 1 : 0 ))
}

# INV-06: Every track.yaml declares a phases: section (indented under track:)
for track_yaml in tracks/*/track.yaml; do
    [[ -f "$track_yaml" ]] || continue
    if ! awk '/^track:/{in_t=1} in_t && /^[[:space:]]+phases:/{found=1; exit} END{exit !found}' "$track_yaml" 2>/dev/null; then
        fail "INV-06" "missing 'phases:' in ${track_yaml}"
    fi
done

# INV-01: Every ACTIVE in templates/prompts/ points to an existing prompt_vN.md
while IFS= read -r -d '' active_file; do
    phase_dir="$(dirname "$active_file")"
    raw="$(tr -d '[:space:]' < "$active_file")"
    if [[ "$raw" =~ ^v[0-9]+$ ]]; then
        version="$raw"
    elif [[ "$raw" =~ ^[0-9]+$ ]]; then
        version="v${raw}"
    else
        fail "INV-01" "ACTIVE with unrecognized format '${raw}' in ${active_file}"
        continue
    fi
    expected="${phase_dir}/prompt_${version}.md"
    if [[ ! -f "$expected" ]]; then
        fail "INV-01" "ACTIVE points to missing file: ${expected}"
    fi
done < <(find templates/prompts -name 'ACTIVE' -print0)

# INV-02: phase.yaml with onboarding_template must point to existing context dir
# INV-04: phase.yaml with dynamic_context_template must NOT have {{CONTEXT_BLOCK}} in active prompt
while IFS= read -r -d '' phase_yaml; do
    # INV-02
    val02="$(awk '/^[[:space:]]+onboarding_template:/{sub(/^[[:space:]]+onboarding_template:[[:space:]]*/,""); print; exit}' "$phase_yaml")"
    if [[ -n "$val02" ]]; then
        expected_dir="templates/context/onboarding/${val02}"
        if [[ ! -d "$expected_dir" ]]; then
            fail "INV-02" "onboarding_template '${val02}' in ${phase_yaml} has no dir: ${expected_dir}"
        fi
    fi
    # INV-04
    val04="$(awk '/^[[:space:]]+dynamic_context_template:/{sub(/^[[:space:]]+dynamic_context_template:[[:space:]]*/,""); print; exit}' "$phase_yaml")"
    if [[ -n "$val04" ]]; then
        rel="${phase_yaml#tracks/}"
        track_name="${rel%%/*}"
        phase_name="$(basename "$phase_yaml" .yaml)"
        active_file="templates/prompts/${track_name}/${phase_name}/ACTIVE"
        if [[ ! -f "$active_file" ]]; then
            fail "INV-04" "phase '${phase_name}' in '${track_name}' has dynamic_context_template but no ACTIVE"
            continue
        fi
        raw="$(tr -d '[:space:]' < "$active_file")"
        if [[ "$raw" =~ ^v[0-9]+$ ]]; then
            version="$raw"
        elif [[ "$raw" =~ ^[0-9]+$ ]]; then
            version="v${raw}"
        else
            fail "INV-04" "ACTIVE '${active_file}' has unrecognized format '${raw}'"
            continue
        fi
        prompt_file="templates/prompts/${track_name}/${phase_name}/prompt_${version}.md"
        if [[ ! -f "$prompt_file" ]]; then
            fail "INV-04" "ACTIVE points to missing file: ${prompt_file}"
            continue
        fi
        if grep -qF '{{CONTEXT_BLOCK}}' "$prompt_file"; then
            fail "INV-04" "phase '${phase_name}' in '${track_name}': prompt '${prompt_file}' still uses {{CONTEXT_BLOCK}}; migrate to path-reference"
        fi
    fi
done < <(find tracks -name '*.yaml' -path '*/phases/*' -print0)

# INV-03: Tracks WITHOUT dynamic_context must NOT have {{CONTEXT_BLOCK}} in active prompts
for track_dir in tracks/*/; do
    [[ -d "$track_dir" ]] || continue
    track_name="${track_dir%/}"
    track_name="${track_name##*/}"
    # Skip tracks that have dynamic_context phase
    [[ -f "${track_dir}phases/dynamic_context.yaml" ]] && continue
    # Check each phase
    for phase_yaml in "${track_dir}phases/"*.yaml; do
        [[ -f "$phase_yaml" ]] || continue
        phase_name="$(basename "$phase_yaml" .yaml)"
        active_file="templates/prompts/${track_name}/${phase_name}/ACTIVE"
        [[ -f "$active_file" ]] || continue
        raw="$(tr -d '[:space:]' < "$active_file")"
        if [[ "$raw" =~ ^v[0-9]+$ ]]; then
            version="$raw"
        elif [[ "$raw" =~ ^[0-9]+$ ]]; then
            version="v${raw}"
        else
            continue
        fi
        prompt_file="templates/prompts/${track_name}/${phase_name}/prompt_${version}.md"
        [[ -f "$prompt_file" ]] || continue
        if grep -qF '{{CONTEXT_BLOCK}}' "$prompt_file"; then
            fail "INV-03" "track '${track_name}': '${prompt_file}' contains {{CONTEXT_BLOCK}} but track has no dynamic_context phase"
        fi
    done
done

# INV-05: Context templates must have ACTIVE + template_vN.md + template_vN.meta
for tmpl_dir in templates/context/onboarding/*/; do
    [[ -d "$tmpl_dir" ]] || continue
    active_file="${tmpl_dir}ACTIVE"
    if [[ ! -f "$active_file" ]]; then
        fail "INV-05" "missing ACTIVE in ${tmpl_dir}"
        continue
    fi
    active_val="$(tr -d '[:space:]' < "$active_file")"
    if [[ ! "$active_val" =~ ^template_v[0-9]+\.md$ ]]; then
        fail "INV-05" "ACTIVE in ${tmpl_dir} has unexpected format '${active_val}'"
        continue
    fi
    if [[ ! -f "${tmpl_dir}${active_val}" ]]; then
        fail "INV-05" "ACTIVE in ${tmpl_dir} points to missing file: ${active_val}"
    fi
    meta_val="${active_val%.md}.meta"
    if [[ ! -f "${tmpl_dir}${meta_val}" ]]; then
        fail "INV-05" "missing meta file: ${tmpl_dir}${meta_val}"
    fi
done

# INV-08: Every skill entry in skills/registry.yaml has its file: path present on disk
while IFS=' ' read -r skill_name skill_file; do
    if [[ ! -f "$skill_file" ]]; then
        fail "INV-08" "registry skill '${skill_name}': file not found: ${skill_file}"
    fi
done < <(awk '
    /^skills:/{in_s=1; next}
    in_s && /^  [a-z_]+:/{name=substr($0,3); sub(/:$/,"",name); file=""}
    in_s && /^    file:/{file=$2}
    in_s && file!=""{print name, file; file=""}
' skills/registry.yaml)

# INV-07: Every skill declared in phase.skills exists in skills/registry.yaml
# INV-09: eaw_reviewer or eaw_delivery in phase.skills emits WARN (not FAIL)
registry_skills=""
while IFS=' ' read -r sname _sfile; do
    registry_skills="${registry_skills} ${sname} "
done < <(awk '
    /^skills:/{in_s=1; next}
    in_s && /^  [a-z_]+:/{name=substr($0,3); sub(/:$/,"",name); file=""}
    in_s && /^    file:/{file=$2}
    in_s && file!=""{print name, file; file=""}
' skills/registry.yaml)

while IFS= read -r -d '' phase_yaml; do
    track_name="$(dirname "$(dirname "$phase_yaml")")"
    track_name="${track_name##*/}"
    phase_name="$(basename "$phase_yaml" .yaml)"

    while IFS= read -r skill; do
        case "$registry_skills" in
            *" ${skill} "*)
                ;;
            *)
                fail "INV-07" "phase '${phase_name}' in track '${track_name}': skill '${skill}' not found in registry"
                ;;
        esac
        case "$skill" in
            eaw_reviewer|eaw_delivery)
                printf "WARN: INV-09: phase '%s' in '%s': skill '%s' is a delivery/review skill\n" \
                    "$phase_name" "$track_name" "$skill"
                ;;
        esac
    done < <(awk '
        /^phase:/{in_p=1; next}
        in_p && /^[^[:space:]]/{in_p=0; in_sk=0}
        in_p && /^[[:space:]]+skills:[[:space:]]*$/{in_sk=1; next}
        in_p && in_sk && /^[[:space:]]+-[[:space:]]/{
            v=$0; sub(/^[[:space:]]+-[[:space:]]*/,"",v); gsub(/[[:space:]]+$/,"",v); print v
        }
        in_p && in_sk && /^[[:space:]]+[a-z_]+:[[:space:]]*[^-]/{in_sk=0}
    ' "$phase_yaml")
done < <(find tracks -name '*.yaml' -path '*/phases/*' -print0)

summary
