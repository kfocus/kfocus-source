#!/bin/bash
#
# 2024-10-10 This is a logic-check script to ensure that m2g5p1 systems (NOT
#   m2g5p) are checked for having the correct blacklist for the thunderbolt
#   module, which can cause problems. It is an excerpt that has been tested
#   and merged back into package-hw/debian/postinst.
#
_handlerFn () {
  ## Begin Add or remove symlink for m2g5p1 thunderbolt blacklist
  _symlink='/etc/default/grub.d/10_kfocus-tbt.cfg';
  _tgt_file='';
  # Consider only if m2g5p1 system
  if [[ "${_dmiName:-}" =~ ^X370SN.*1$ ]]; then
    # Skip changing this file if it already exists
    if [ -f "${_symlink}" ] || [ -h "${_symlink}" ]; then
      true;
    # Otherwise, set it to blacklist thunderbolt with OFF name
    else
      _target_file='/usr/lib/kfocus/conf/';
      _target_file+='m2g5p1-etc_default_grub.d_10_kfocus-tbt-off.cfg';
      _symlinkTable+=( "${_symlink}|${_target_file}" );
    fi
  # Always remove file for non-m2g5p1 systems
  else
    _symlinkTable+=( "${_symlink}|" );
  fi
  ## . End Add or remove symlink for m2g5p1 thunderbolt blacklist
  echo "_symlinkTable: ${_symlinkTable[*]}";
}

_setupFn () {
  declare _lib_file _config_code _model_code
  # Import common and determine config_code from model matrix
  _lib_file='/usr/lib/kfocus/lib/common.2.source';
  _config_code='';
  _model_code='';
  _dmiName='';

  if [ -r "${_lib_file}" ]; then
    # shellcheck disable=1091,1090 source=/usr/lib/kfocus/lib/common.2.source
    source "${_lib_file}" || true;
    if [ "$(type -t _cm2EchoModelStrFn)" = 'function' ]; then
      _model_code="$(_cm2EchoModelStrFn 'code')";
      _config_code="$(_cm2EchoModelStrFn 'config_code')";
    fi
    if [ -f "${_cm2DmiProductNameFile}" ]; then
      _dmiName="$(_cm2CatStripEchoFn "${_cm2DmiProductNameFile}")";
    fi
  fi
  if [ -z "${_config_code:-}" ]; then _config_code='other'; fi
  if [ -z "${_model_code:-}"  ]; then  _model_code='other'; fi

  echo "_config_code : ${_config_code}";
  echo "_model_code  : ${_model_code}";
  echo "_dmiName     : ${_dmiName}";
}
declare _dmiName _symlinkTable;
_dmiName='';
_symlinkTable=();

_setupFn;
_handlerFn;


