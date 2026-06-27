#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VIEW_DIR="${SCRIPT_DIR}/view"
OUTPUT="${SCRIPT_DIR}/manifest.json"

if [[ ! -d "$VIEW_DIR" ]]; then
  echo "Error: '$VIEW_DIR' does not exist." >&2
  exit 1
fi

j() { python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$1"; }

echo "Scanning $VIEW_DIR ..."

out='{'
first_cat=1
for cat_path in "$VIEW_DIR"/*/; do
  [[ -d "$cat_path" ]] || continue
  cat_name="$(basename "$cat_path")"
  [[ "$first_cat" -eq 0 ]] && out+=','
  first_cat=0
  out+="$(j "$cat_name"): {"
  first_sub=1
  for sub_path in "$cat_path"*/; do
    [[ -d "$sub_path" ]] || continue
    sub_name="$(basename "$sub_path")"
    [[ "$first_sub" -eq 0 ]] && out+=','
    first_sub=0
    out+="$(j "$sub_name"): ["
    first_file=1
    for file_path in "$sub_path"*; do
      [[ -f "$file_path" ]] || continue
      file_name="$(basename "$file_path")"
      rel_path="view/${cat_name}/${sub_name}/${file_name}"
      [[ "$first_file" -eq 0 ]] && out+=','
      first_file=0
      out+="{\"name\": $(j "$file_name"), \"path\": $(j "$rel_path")}"
    done
    out+=']'
  done
  out+='}'
done
out+='}'

echo "$out" | python3 -m json.tool > "$OUTPUT"
echo "Written to $OUTPUT"
