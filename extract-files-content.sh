#!/bin/bash

# Cross-platform `realpath` compatibility
if ! command -v realpath &> /dev/null; then
  realpath() { [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"; }
fi

# Set the root directory
script_path="$(realpath "$0")"
project_root="$(dirname "$script_path")"

# Prompt user
echo "Where to save the output?"
echo "Y = current folder"
echo "N = parent folder"
echo "C = custom path"
read -rp "[Y/N/C]: " choice

case "${choice^^}" in
  Y) save_base="$project_root" ;;
  N) save_base="$(dirname "$project_root")" ;;
  C)
    read -rp "Enter full path: " custom_path
    save_base="$custom_path"
    ;;
  *)
    echo "Invalid input. Defaulting to current folder."
    save_base="$project_root"
    ;;
esac

# Output folder
root_folder_name="$(basename "$project_root")"
output_dir="$save_base/extraction_$root_folder_name"
mkdir -p "$output_dir"
output_file="$output_dir/extractedContent.md"

# Extensions map
declare -A language_map=(
  [php]=php [js]=javascript [ts]=typescript [jsx]=jsx [tsx]=tsx
  [html]=html [css]=css [json]=json [xml]=xml [md]=markdown [py]=python
  [sh]=bash [c]=c [cpp]=cpp [cs]=csharp [java]=java [lua]=lua [rb]=ruby
  [go]=go [rs]=rust [swift]=swift [kt]=kotlin [scala]=scala [yml]=yaml
  [yaml]=yaml [ini]=ini [bat]=batch [toml]=toml
)

always_allow=(
  Dockerfile Makefile .gitignore .prettierrc .editorconfig
  .gitattributes .eslintrc .babelrc
)

# Clean old output
[ -f "$output_file" ] && rm -f "$output_file"

# File search and extraction
find "$project_root" -type f | while read -r file; do
  filename="$(basename "$file")"
  ext="${filename##*.}"
  ext_lower="${ext,,}"

  include=false
  [[ -n "${language_map[$ext_lower]}" ]] && include=true
  [[ " ${always_allow[*]} " == *" $filename "* ]] && include=true

  if [ "$include" = true ]; then
    echo "### $filename" >> "$output_file"
    echo '```' >> "$output_file"
    cat "$file" 2>/dev/null >> "$output_file" || echo "[ERROR READING FILE]" >> "$output_file"
    echo -e '\n```' >> "$output_file"
    echo >> "$output_file"
  fi
done

echo ""
echo "✅ Markdown file generated at:"
echo "$output_file"
