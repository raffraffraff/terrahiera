#!/bin/bash

# Purpose: Generate a Terraform wrapper module for an upstream module
# Usage: ./generate_wrapper.sh <name> <url>

TMPDIR=$(mktemp -d)
DRY_RUN=false

usage() {
cat <<EOF
Usage: $0 <options>

This script creates a module directory and generates main.tf, outputs.tf and variables.tf files.

$0 prompts for a wrapper name and remote URL if none are provided.

Options:
  --help    show this message
  --dry-run just print the output to the screen
  --name    set the wrapper module name
  --single  module does not use for_each to deploy many resources
  --notypes do not add type comment to variables
  --url     set the remote module url

Examples:
  $0 --name sqs --url https://github.com/terraform-aws-modules/terraform-aws-sqs
  $0 --name eks --single --url https://github.com/terraform-aws-modules/terraform-aws-eks
  $0 --name vpc --single --notypes --url https://github.com/terraform-aws-modules/terraform-aws-vpc
EOF
exit 
}

# Argparsing
until [ -z "$1" ]; do
  case $1 in
    --url)     shift; URL="$1"; shift;;
    --name)    shift; NAME="$1"; shift;;
    --single)  SINGLE=true; shift;;
    --notypes) NOTYPES=true; shift;;
    --dry-run) DRY_RUN=true; shift;;
    *)         usage;; 
  esac
done

# Defaults
SINGLE=${SINGLE:-false}
NOTYPES=${NOTYPES:-false}

# Prompt if no name/url were given
until [ -n "${NAME}" ]; do
 read -p "Wrapper name: " NAME
done
until [ -n "${URL}" ]; do
 read -p "Remote module URL: " URL
done

# Get githubusercontent 'raw' URL
for BRANCH in main master; do 
  RAW_URL=$(curl -s -L -o /dev/null -w '%{url_effective}' "${URL}/blob/${BRANCH}/README.md?raw=true" | sed -n '/raw.githubusercontent/ s_/README.md__p')
done
if [ -z "$RAW_URL" ]; then
  echo "Could not find raw.githubusercontent.com URL for this git project"
  exit 1
fi

# Generating locals.tf
cat <<EOF > ${TMPDIR}/locals.tf
locals {
  config = jsondecode(var.config)
}
EOF

# Generating main.tf
echo "module \"${NAME}\" {" > ${TMPDIR}/main.tf
echo >> ${TMPDIR}/main.tf

## Grab the module source and version
curl -s "${RAW_URL}/README.md" | grep -m1 -A5 -E ' *module "' | grep -E '(source|version) *=' \
  >> ${TMPDIR}/main.tf
if [ $? -eq 0 ]; then
  echo "# TODO: Grab the module source and version from ${URL}" >> ${TMPDIR}/main.tf
fi

if [ "$SINGLE" != "true" ]; then
  echo "  for_each = try(local.config,{}) " >> ${TMPDIR}/main.tf
  echo >> ${TMPDIR}/main.tf
fi

# Download variables.tf, parse and convert to wrapper

curl -s ${RAW_URL}/variables.tf | hcl2json \
| jq -r --arg SINGLE "${SINGLE}" --arg NOTYPES "${NOTYPES}" '
.variable
| keys[] as $k
| if ($SINGLE=="true") then
    if ($NOTYPES=="true") then
      if (.[$k] | .[].type) == "${string}" and (.[$k] | .[].default) != null then
        "\($k)@@@=@@@try(local.config.\($k),\"\(.[$k] | .[].default)\")"
      else 
        "\($k)@@@=@@@try(local.config.\($k),\(.[$k] | .[].default))"
      end
    else
      if (.[$k] | .[].type) == "${string}" and (.[$k] | .[].default) != null then
        "\($k)@@@=@@@try(local.config.\($k),\"\(.[$k] | .[].default)\")@@@# type: \(.[$k] | .[].type)"
      else 
        "\($k)@@@=@@@try(local.config.\($k),\(.[$k] | .[].default))@@@# type: \(.[$k] | .[].type)"
      end
    end
  else
    if ($NOTYPES=="true") then
      if (.[$k] | .[].type) == "${string}" and (.[$k] | .[].default) != null then
        "\($k)@@@=@@@try(each.value.\($k),\"\(.[$k] | .[].default)\")"
      else 
        "\($k)@@@=@@@try(each.value.\($k),\(.[$k] | .[].default))"
      end
    else
      if (.[$k] | .[].type) == "${string}" and (.[$k] | .[].default) != null then
        "\($k)@@@=@@@try(each.value.\($k),\"\(.[$k] | .[].default)\")@@@# type: \(.[$k] | .[].type)"
      else 
        "\($k)@@@=@@@try(each.value.\($k),\(.[$k] | .[].default))@@@# type: \(.[$k] | .[].type)"
      end
    end
  end
' \
| column -t -s '@@@' \
| sed 's/^/  /g' \
>> ${TMPDIR}/main.tf

echo >> ${TMPDIR}/main.tf
echo "}" >> ${TMPDIR}/main.tf
echo >> ${TMPDIR}/main.tf

# Generate variables.tf
cat <<EOF >> ${TMPDIR}/variables.tf
variable "config" {
  type        = any
  description = "A JSON encoded object that contains the full ${NAME} config"
  default     = "{}"
}
EOF

# Generate outputs.tf
curl -s ${RAW_URL}/outputs.tf \
| hcl2json \
| jq -r --arg NAME "${NAME}" --arg SINGLE "${SINGLE}" '
.output
| keys[] as $k
| if ($SINGLE!="true") then
"output \"\($k)\" {\n  value = { for k, v in module.\($NAME) : k => v.\($k) }\n}\n"
else
"output \"\($k)\" {\n  value = module.\($NAME).\($k)\n}\n"
end
' >> ${TMPDIR}/outputs.tf

# Dry run just spits out generated files and their path
if [ "$DRY_RUN" == "true" ]; then
  echo "DRY RUN: We will just output the module files"
  echo
  echo "[locals.tf]"
  cat ${TMPDIR}/locals.tf
  echo
  echo "[main.tf]"
  cat ${TMPDIR}/main.tf
  echo
  echo "[variables.tf]"
  cat ${TMPDIR}/variables.tf
  echo
  echo "[outputs.tf]"
  cat ${TMPDIR}/outputs.tf
  echo
  echo "Files are stored in ${TMPDIR}"
else
  mkdir -p ${NAME}
  cp ${TMPDIR}/* ${NAME}/
fi
