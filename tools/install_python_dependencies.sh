#!/usr/bin/env bash
set -e

# Increase the pip timeout to handle TimeoutError
export PIP_DEFAULT_TIMEOUT=200

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
ROOT=$DIR/../
cd $ROOT

# updating uv on macOS results in 403 sometimes
function update_uv() {
  for i in $(seq 1 5);
  do
    if uv self update; then
      return 0
    else
      sleep 2
    fi
  done
  echo "Failed to update uv 5 times!"
}

if ! command -v "uv" > /dev/null 2>&1; then
  echo "installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  UV_BIN='$HOME/.cargo/env'
  ADD_PATH_CMD=". \"$UV_BIN\""
  eval $ADD_PATH_CMD
fi

echo "updating uv..."
update_uv

# TODO: remove --no-cache once this is fixed: https://github.com/astral-sh/uv/issues/4378
echo "installing python packages..."
uv --no-cache sync --frozen --all-extras
source .venv/bin/activate

echo "PYTHONPATH=${PWD}" > $ROOT/.env
if [[ "$(uname)" == 'Darwin' ]]; then
  echo "# msgq doesn't work on mac" >> $ROOT/.env
  echo "export ZMQ=1" >> $ROOT/.env
  echo "export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES" >> $ROOT/.env
fi

if [ "$(uname)" != "Darwin" ] && [ -e "$ROOT/.git" ]; then
  echo "pre-commit hooks install..."
  pre-commit install
  git submodule foreach pre-commit install
fi
