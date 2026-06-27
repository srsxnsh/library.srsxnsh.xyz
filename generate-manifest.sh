#!/usr/bin/env bash
# generate-manifest.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VIEW_DIR="${SCRIPT_DIR}/view"
OUTPUT="${SCRIPT_DIR}/manifest.json"

if [[ ! -d "$VIEW_DIR" ]]; then
  echo "Error: '$VIEW_DIR' does not exist." >&2
  exit 1
fi

echo "Scanning $VIEW_DIR …"
#make a json like son chill i suppoose
printf '{\n' > "$OUTPUT"

first_cat=1
while IFS= read -r -d '' cat_path; do
  cat_name="$(basename "$cat_path")"
  [[ "$first_cat" -eq 0 ]] && printf ',\n' >> "$OUTPUT"
  first_cat=0

  printf '  %s: {\n' "$(json_str "$cat_name")" >> "$OUTPUT"

  first_sub=1
  while IFS= read -r -d '' sub_path; do
    sub_name="$(basename "$sub_path")"
    [[ "$first_sub" -eq 0 ]] && printf ',\n' >> "$OUTPUT"
    first_sub=0

    printf '    %s: [\n' "$(json_str "$sub_name")" >> "$OUTPUT"

    first_file=1
    while IFS= read -r -d '' file_path; do
      file_name="$(basename "$file_path")"
      # she u on my r till i l all over the site:wq
      rel_path="view/${cat_name}/${sub_name}/${file_name}"
      [[ "$first_file" -eq 0 ]] && printf ',\n' >> "$OUTPUT"
      first_file=0
      printf '      {"name": %s, "path": %s}' \
        "$(json_str "$file_name")" \
        "$(json_str "$rel_path")" >> "$OUTPUT"
    done < <(find "$sub_path" -maxdepth 1 -type f ! -name '.*' -print0 | sort -z)

    printf '\n    ]' >> "$OUTPUT"
  done < <(find "$cat_path" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

  printf '\n  }' >> "$OUTPUT"
done < <(find "$VIEW_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

printf '\n}\n' >> "$OUTPUT"

echo "Written to $OUTPUT"

# ── helper ──────────────────────────────────────────────────────────────────
json_str() {
 
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '"%s"' "$s"
}
