#!/bin/sh

# ---------------------------------------------------------------
# Copyright 2009-2017 Viktor Szakats (vsz.me/hb)
# See LICENSE.txt for licensing terms.
# ---------------------------------------------------------------

# TODO: remove mingwarm, OS/2, MS-DOS references

cd "$(dirname "$0")" || exit

# - Requires MSYS2 or 'Git for Windows' to run on Windows
# - Requires '7z' in PATH
# - Adjust target dir, MinGW dirs, set HB_DIR_MINGW_32, HB_DIR_MINGW_64
#   create packages to be included beforehand.
# - Run this from unmodified official source tree only.

# https://en.wikipedia.org/wiki/Uname#Examples
# https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD
case "$(uname)" in
  *_NT*)   readonly os='win';;
  Linux*)  readonly os='linux';;
  Darwin*) readonly os='mac';;
  *BSD)    readonly os='bsd';;
esac

. ./mpkg_ver.sh
hb_vershrt=$(hb_get_ver_majorminor)
hb_verfull=$(hb_get_ver)

readonly HB_VS_DEF="$(echo "${hb_vershrt}" | sed 's|\.||g')"  # xy
readonly HB_VL_DEF="$(echo "${hb_verfull}" | sed 's|\.||g')"  # xyz
readonly HB_VM_DEF="${hb_vershrt}"                            # x.y
readonly HB_VF_DEF="${hb_verfull}$(hb_get_ver_status)"        # x.y.zrel
readonly HB_RT_DEF=C:/hb

[ -z "${HB_VS}" ] && HB_VS="${HB_VS_DEF}"
[ -z "${HB_VL}" ] && HB_VL="${HB_VL_DEF}"
[ -z "${HB_VM}" ] && HB_VM="${HB_VM_DEF}"
[ -z "${HB_VF}" ] && HB_VF="${HB_VF_DEF}"
[ -z "${HB_RT}" ] && HB_RT="${HB_RT_DEF}"

HB_RT="$(echo "${HB_RT}" | sed 's|\\|/|g')"
HB_DIR_MINGW_32="$(echo "${HB_DIR_MINGW_32}" | sed 's|\\|/|g')"
HB_DIR_MINGW_64="$(echo "${HB_DIR_MINGW_64}" | sed 's|\\|/|g')"

HB_DR="hb${HB_VS}/"
HB_ABSROOT="${HB_RT}/${HB_DR}"

_BRANCH="${APPVEYOR_REPO_BRANCH}${TRAVIS_BRANCH}${CI_BUILD_REF_NAME}${GIT_BRANCH}"
[ -n "${_BRANCH}" ] || _BRANCH="$(git symbolic-ref --short --quiet HEAD)"
[ -n "${_BRANCH}" ] || _BRANCH='master'
[ -n "${CC}" ] || CC="${_BRANCH}"
[ -n "${HB_CC_TO_RELEASE}" ] || HB_CC_TO_RELEASE="${CC}"

_SCRIPT="$(realpath 'mpkg.hb')"
_ROOT="$(realpath '..')"

echo "! Self: $0  Host OS: '${os}'  Branch: '${_BRANCH}'  Config: '${CC}'"

case "${os}" in
  win)
    # Hack for 'Git for Windows'. Windows system paths may override
    # standard tools.
    alias find=/usr/bin/find
    ;;
  mac)
    alias cp=gcp
    ;;
esac

[ "${os}" = 'win' ] || win='wine'

if [ -z "${HB_BASE}" ]; then
  # Auto-detect the base bitness, by default it will be 32-bit, and 64-bit
  # if it's the only one available.
  if   [ -d "../pkg/win/mingw/harbour-${HB_VF}-win-mingw" ]; then
    _lib_target='32'  # MinGW 32-bit base system
  elif [ -d "../pkg/win/clang/harbour-${HB_VF}-win-clang" ]; then
    _lib_target='32'  # LLVM/Clang 32-bit base system
  elif [ -d "../pkg/win/mingw64/harbour-${HB_VF}-win-mingw64" ]; then
    _lib_target='64'  # MinGW 64-bit base system
  elif [ -d "../pkg/win/clang64/harbour-${HB_VF}-win-clang64" ]; then
    _lib_target='64'  # LLVM/Clang 64-bit base system
  fi
else
  _lib_target="${HB_BASE}"
fi

echo "! Creating ${_lib_target}-bit hosted package"

# Assemble package from per-target builds

[ ! -d "${HB_ABSROOT}" ] || rm -f -r "${HB_ABSROOT}"
mkdir -p "${HB_ABSROOT}"

(
  cd .. || exit
  # shellcheck disable=SC2046
  cp -f -p --parents $(find 'addons' -type f -name '*') "${HB_ABSROOT}"
  # shellcheck disable=SC2046
  cp -f -p --parents $(find 'extras' -type f -name '*') "${HB_ABSROOT}"
  # shellcheck disable=SC2046
  cp -f -p --parents $(find 'tests'  -type f -name '*') "${HB_ABSROOT}"
)

mkdir -p "${HB_ABSROOT}bin/"

# Copy these first to let 3rd party .dlls with overlapping names be
# overwritten by selected native target's binaries.
if ls      "../pkg/wce/mingwarm/harbour-${HB_VF}-wce-mingwarm/bin/"*.dll > /dev/null 2>&1; then
  cp -f -p "../pkg/wce/mingwarm/harbour-${HB_VF}-wce-mingwarm/bin/"*.dll "${HB_ABSROOT}bin/"
fi

if [ "${_lib_target}" = '32' ]; then
  if ls      "../pkg/win/mingw64/harbour-${HB_VF}-win-mingw64/bin/"*.dll > /dev/null 2>&1; then
    cp -f -p "../pkg/win/mingw64/harbour-${HB_VF}-win-mingw64/bin/"*.dll "${HB_ABSROOT}bin/"
  elif ls    "../pkg/win/clang64/harbour-${HB_VF}-win-clang64/bin/"*.dll > /dev/null 2>&1; then
    cp -f -p "../pkg/win/clang64/harbour-${HB_VF}-win-clang64/bin/"*.dll "${HB_ABSROOT}bin/"
  fi
  if [ -d    "../pkg/win/mingw/harbour-${HB_VF}-win-mingw" ]; then
    ( cd     "../pkg/win/mingw/harbour-${HB_VF}-win-mingw" && cp -f -p -R ./* "${HB_ABSROOT}" )
  elif [ -d  "../pkg/win/clang/harbour-${HB_VF}-win-clang" ]; then
    ( cd     "../pkg/win/clang/harbour-${HB_VF}-win-clang" && cp -f -p -R ./* "${HB_ABSROOT}" )
  fi
elif [ "${_lib_target}" = '64' ]; then
  if ls      "../pkg/win/mingw/harbour-${HB_VF}-win-mingw/bin/"*.dll > /dev/null 2>&1; then
    cp -f -p "../pkg/win/mingw/harbour-${HB_VF}-win-mingw/bin/"*.dll "${HB_ABSROOT}bin/"
  elif ls    "../pkg/win/clang/harbour-${HB_VF}-win-clang/bin/"*.dll > /dev/null 2>&1; then
    cp -f -p "../pkg/win/clang/harbour-${HB_VF}-win-clang/bin/"*.dll "${HB_ABSROOT}bin/"
  fi
  if [ -d    "../pkg/win/mingw64/harbour-${HB_VF}-win-mingw64" ]; then
    ( cd     "../pkg/win/mingw64/harbour-${HB_VF}-win-mingw64" && cp -f -p -R ./* "${HB_ABSROOT}" )
  elif [ -d  "../pkg/win/clang64/harbour-${HB_VF}-win-clang64" ]; then
    ( cd     "../pkg/win/clang64/harbour-${HB_VF}-win-clang64" && cp -f -p -R ./* "${HB_ABSROOT}" )
  fi
fi

for dir in \
  "../pkg/win/mingw/harbour-${HB_VF}-win-mingw" \
  "../pkg/win/mingw64/harbour-${HB_VF}-win-mingw64" \
  "../pkg/wce/mingwarm/harbour-${HB_VF}-wce-mingwarm" \
  "../pkg/win/clang/harbour-${HB_VF}-win-clang" \
  "../pkg/win/clang64/harbour-${HB_VF}-win-clang64" \
  "../pkg/win/msvc/harbour-${HB_VF}-win-msvc" \
  "../pkg/win/msvc64/harbour-${HB_VF}-win-msvc64" \
  "../pkg/os2/watcom/harbour-${HB_VF}-os2-watcom" \
  "../pkg/dos/watcom/hb${HB_VL}wa"; do
  if [ -d "${dir}" ]; then
  (
    cd "${dir}" || exit
    # shellcheck disable=SC2046
    cp -f -p --parents $(find 'lib' -type f -name '*') "${HB_ABSROOT}"
  )
  fi
done

# Workaround for ld --no-insert-timestamp bug that exist as of binutils 2.25,
# when the PE build timestamp field is often filled with random bytes instead
# of zeroes. -s option is not fixing this, 'strip' randomly fails either, so
# we're patching manually.

if [ "${os}" = 'win' ]; then
  _bin_hbmk2="$(find ../bin -type f -name 'hbmk2.exe' | head -n 1)"
else
  _bin_hbmk2="$(find ../bin -type f -name 'hbmk2' | head -n 1)"
fi

# NOTE: Do not forget to update the list of binary names created
#       by the GNU Make process, in case it changes.
for name in \
  'harbour*.dll' \
  'harbour.exe' \
  'hbi18n.exe' \
  'hbmk2.exe' \
  'hbpp.exe' \
  'hbspeed.exe' \
  'hbtest.exe'; do
  for file in ${HB_ABSROOT}bin/${name}; do

    # Remove code signature first
    if [ -f "${HB_CODESIGN_KEY}" ]; then
      # 'strip' would also work, but this is cleaner
      osslsigncode remove-signature -in "${file}" -out "${file}-unsigned"
      mv -f "${file}-unsigned" "${file}"
    fi

    # Remove embedded timestamps
    "${_bin_hbmk2}" "${_SCRIPT}" pe "${_ROOT}" "${file}"

    # Re-add code signature
    if [ -f "${HB_CODESIGN_KEY}" ]; then
      (
        set +x
        osslsigncode sign -h sha256 -in "${file}" -out "${file}-signed" \
          -pkcs12 "${HB_CODESIGN_KEY}" -pass "${HB_CODESIGN_KEY_PASS}" \
          -ts 'http://timestamp.digicert.com'
        mv -f "${file}-signed" "${file}"
      )
    fi

    # Set timestamp
    touch -c -r "${HB_ABSROOT}README.md" "${file}"
  done
done

# Workaround for ld --no-insert-timestamp issue in that it won't remove
# internal timestamps from generated implibs.
# Slow. Requires binutils 2.23 (maybe 2.24/2.25).
# Short synonym '-D' is not recognized as of binutils 2.25.
for _cpu in '' '64'; do
  [ "${_cpu}" != '64' ] && _mingw_dir="${HB_DIR_MINGW_32}"
  [ "${_cpu}"  = '64' ] && _mingw_dir="${HB_DIR_MINGW_64}"
  [ "${_cpu}" != '64' ] && _mingw_pfx="${HB_PFX_MINGW_32}"
  [ "${_cpu}"  = '64' ] && _mingw_pfx="${HB_PFX_MINGW_64}"
  for files in \
    "${HB_ABSROOT}lib/win/mingw${_cpu}/*-*.*" \
    "${HB_ABSROOT}lib/win/mingw${_cpu}/*.dll.*" \
    "${HB_ABSROOT}lib/win/clang${_cpu}/*-*.*" \
    "${HB_ABSROOT}lib/win/clang${_cpu}/*.dll.*"; do
    # shellcheck disable=SC2086
    if ls ${files} > /dev/null 2>&1; then
      "${_mingw_dir}${_mingw_pfx}strip" -p --enable-deterministic-archives -g ${files}
    fi
  done
done

# Copy 3rd party static libraries

if [ "${_HB_BUNDLE_3RDLIB}" = 'yes' ]; then
  for name in \
      'openssl' \
      'libssh2' \
      'nghttp2' \
      'brotli' \
      'curl' \
  ; do
    eval dir_32="\$$(echo "HB_DIR_${name}_32" | tr '[:lower:]' '[:upper:]' 2> /dev/null)"
    dir_32=$(echo "${dir_32}" | sed 's|\\|/|g')
    eval dir_64="\$$(echo "HB_DIR_${name}_64" | tr '[:lower:]' '[:upper:]' 2> /dev/null)"
    dir_64=$(echo "${dir_64}" | sed 's|\\|/|g')
    for file in ${dir_32}lib/*.a; do
      [ -d "${HB_ABSROOT}lib/win/mingw/" ] && cp -f -p "${file}" "${HB_ABSROOT}lib/win/mingw/"
      [ -d "${HB_ABSROOT}lib/win/clang/" ] && cp -f -p "${file}" "${HB_ABSROOT}lib/win/clang/"
    done
    for file in ${dir_64}lib/*.a; do
      [ -d "${HB_ABSROOT}lib/win/mingw64/" ] && cp -f -p "${file}" "${HB_ABSROOT}lib/win/mingw64/"
      [ -d "${HB_ABSROOT}lib/win/clang64/" ] && cp -f -p "${file}" "${HB_ABSROOT}lib/win/clang64/"
    done
    [ -f "${dir_64}COPYING.txt" ] && cp -f -p "${dir_64}COPYING.txt" "${HB_ABSROOT}LICENSE_${name}.txt"
    [ -f "${dir_64}LICENSE.txt" ] && cp -f -p "${dir_64}LICENSE.txt" "${HB_ABSROOT}LICENSE_${name}.txt"
    [ "${name}" = 'curl' ] && cp -f -p "${dir_64}bin/curl-ca-bundle.crt" "${HB_ABSROOT}bin/cacert.pem"
  done
fi

# Copy core 3rd party headers

(
  cd .. || exit
  # shellcheck disable=SC2046
  cp -f -p --parents $(find 'src/3rd' -name '*.h') "${HB_ABSROOT}"
)

# Burn build information into RELNOTES.md

_hb_ver="${HB_VF}"
if [ "${HB_VF}" != "${HB_VF_DEF}" ]; then
  _hb_ver="${HB_VF_DEF} ${_hb_ver}"
fi

GITHUB_SLUG="$(git config remote.origin.url | sed -e 's/.git$//' | grep -o -E '[^/]+/[^/]+$')"
_vcs_id="$(git rev-parse --verify HEAD)"
_vcs_id_short="$(git rev-parse --verify --short HEAD)"
_vcs_url="$(git ls-remote --get-url | sed 's|.git$||')/"

sed -e "s|@HB_VER_COMMIT_ID_SHORT@|${_vcs_id_short}|g" \
    -e "s|@HB_VER_ORIGIN_URL@|${_vcs_url}|g" \
    -e "s|@HB_VERSION@|${_hb_ver}|g" \
    'RELNOTES.md' | unix2dos > "${HB_ABSROOT}RELNOTES.md"
touch -c -r "${HB_ABSROOT}README.md" "${HB_ABSROOT}RELNOTES.md"

sed "s|@HB_URL_SRC@|${_vcs_url}archive/${_vcs_id}.tar.gz|g" \
    'getsrc.sh' > "${HB_ABSROOT}getsrc.sh"
chmod +x "${HB_ABSROOT}getsrc.sh"
touch -c -r "${HB_ABSROOT}README.md" "${HB_ABSROOT}getsrc.sh"

cp -f -p ../include/_repover.txt "${HB_ABSROOT}include/"
touch -c -r "${HB_ABSROOT}README.md" "${HB_ABSROOT}include/_repover.txt"

# Register build information

(
  ${win} "${HB_ABSROOT}bin/harbour" -build 2> /dev/null \
  | dos2unix | grep -Ev '^(Version:|Platform:|Extra )'
  echo "Source archive URL: ${_vcs_url}archive/${_vcs_id}.zip"
  echo ---------------------------
  printenv | grep '_VER=' | grep -v '^_' | sort
  echo ---------------------------
  printenv \
  | grep -E  '^(HB_USER_|HB_BUILD_|HB_WITH_|HBMK_WITH_|HB_STATIC_)' \
  | grep -Ev '^(HB_BUILD_POSTRUN_HOST=|HB_BUILD_POSTRUN=|HB_BUILD_PKG=)' \
  | sed "s|${HOME}|~|g" | sort
  echo ---------------------------
  cd "${HB_ABSROOT}lib" || exit
  find . -type d | grep -Eo '\./[a-z]+?/[a-z0-9]+?$' | cut -c 3-
) | tee -a "${HB_ABSROOT}BUILD.txt"

unix2dos -k "${HB_ABSROOT}BUILD.txt"

# Set timestamps

touch -c -r "${HB_ABSROOT}README.md" "${HB_ABSROOT}BUILD.txt"
touch -c -r "${HB_ABSROOT}README.md" ../BUILD*.txt

# Copy optional text files containing compiler details

if ls      ../BUILD*.txt > /dev/null 2>&1; then
  cp -f -p ../BUILD*.txt "${HB_ABSROOT}"
fi

# Set file attributes

chmod +x \
  "${HB_ABSROOT}"bin/*.hb
# shellcheck disable=SC2046
chmod -x \
  "${HB_ABSROOT}"bin/*.dll \
  "${HB_ABSROOT}"bin/*.exe \
  $(find "${HB_ABSROOT}"lib/win -name '*.a') \
  $(find "${HB_ABSROOT}"lib/win -name '*.lib')

if [ "${os}" = 'win' ]; then
  find "${HB_ABSROOT%/}" -exec attrib +A -R {} \;
fi

# Create installer/archive

cd "${HB_RT}" || exit

(
  echo '*.sh'
  echo '*.md'
  echo '*.txt'
  echo 'bin/*.dll'
  echo 'bin/*.exe'
  echo 'bin/*.hb'
  echo 'bin/*.pem'
  echo 'include/*'
  echo 'lib/*'
  echo 'src/*'
  echo 'addons/*'
  echo 'contrib/*'
  echo 'doc/*'
  echo 'extras/*'
  echo 'tests/*'
) >> "${_ROOT}/_hbfiles"

_pkgprefix=
_pkgsuffix=
if [ "${_BRANCH#*prod*}" != "${_BRANCH}" ]; then
  case "${os}" in
    bsd|mac) _pkgsuffix="$(TZ=UTC stat -f '-%Sm' -t '%Y%m%d-%H%M' "${HB_ABSROOT}README.md")";;
    *)       _pkgsuffix="$(       stat -c '%Y' "${HB_ABSROOT}README.md" | TZ=UTC awk '{print "-" strftime("%Y%m%d-%H%M", $1)}')";;
  esac
elif [ "${CC}" != "${HB_CC_TO_RELEASE}" ]; then
  _pkgprefix="_"  # to avoid getting deployed
  _pkgsuffix="-${CC#*mingw-*}"
elif [ "${os}" != 'win' ]; then
  _pkgsuffix="-built-on-${os}"
fi

_pkgname="${_ROOT}/${_pkgprefix}harbour-${HB_VF}-win${_pkgsuffix}.7z"

echo "! Package: '$(basename "${_pkgname}")'"

rm -f "${_pkgname}"
(
  cd "${HB_DR}" || exit
  "${_bin_hbmk2}" "${_SCRIPT}" ts "${_ROOT}"
  # NOTE: add -stl option after updating to 15.12 or upper
  7z a -bd -r -mx "${_pkgname}" "@${_ROOT}/_hbfiles" > /dev/null
)

rm "${_ROOT}/_hbfiles"

touch -c -r "${HB_ABSROOT}README.md" "${_pkgname}"

# <filename>: <size> bytes <YYYY-MM-DD> <HH:MM>
case "${os}" in
  bsd|mac) TZ=UTC stat -f '%N: %z bytes %Sm' -t '%Y-%m-%d %H:%M' "${_pkgname}";;
  *)       TZ=UTC stat -c '%n: %s bytes %y' "${_pkgname}";;
esac
openssl dgst -sha256 "${_pkgname}"

cd - || exit

(
  set +x
  if [ "${_BRANCH#*prod*}" != "${_BRANCH}" ] && \
     [ "${CC}" = "${HB_CC_TO_RELEASE}" ] && \
     [ -n "${PUSHOVER_USER}" ] && \
     [ -n "${PUSHOVER_TOKEN}" ]; then
    # https://pushover.net/api
    curl -sS \
      --form-string "user=${PUSHOVER_USER}" \
      --form-string "token=${PUSHOVER_TOKEN}" \
      --form-string "title=${GITHUB_SLUG}" \
      --form-string "message=Build ready: ${_BRANCH} / ${CC} / ${os}" \
      --form-string 'html=1' \
      --form-string 'priority=1' \
      https://api.pushover.net/1/messages.json
    echo
    echo "! Push notification: Build ready."
  fi

  if [ "${CC}" = "${HB_CC_TO_RELEASE}" ]; then
    if [ -n "${GITHUB_TOKEN}" ]; then
      # Create tag update JSON request
      # https://developer.github.com/v3/git/refs/#update-a-reference
      jq -nc ".sha = \"${_vcs_id}\" | .force = true" \
      | curl -sS \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -d @- \
        -X PATCH "https://api.github.com/repos/${GITHUB_SLUG}/git/refs/tags/v${HB_VF_DEF}"
    else
      echo '! Warning: GITHUB_TOKEN is empty. GitHub tag update skipped.'
    fi
  fi

  if [ -n "${VIRUSTOTAL_APIKEY}" ]; then
    # https://www.virustotal.com/documentation/public-api/#scanning-files
    if [ "$(wc -c < "${_pkgname}")" -lt 32000000 ]; then
      out="$(curl -sS \
        --form-string "apikey=${VIRUSTOTAL_APIKEY}" \
        --form "file=@${_pkgname}" \
        -X POST https://www.virustotal.com/vtapi/v2/file/scan)"
      echo "${out}"
      echo "VirusTotal URL for '${_pkgname}':"
      echo "${out}" | jq '.permalink'
    else
      echo "! File too large for VirusTotal Public API. Upload skipped."
    fi
  fi
)
