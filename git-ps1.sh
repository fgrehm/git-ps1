#!/bin/bash
#
# git-ps1 - git-augmented PS1
#
# See README for configuration options.
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
# #

GIT=`which git`

BRANCH=$($GIT symbolic-ref HEAD 2>/dev/null \
    || $GIT rev-parse HEAD 2>/dev/null | cut -c1-10 \
)

# if no branch or hash was returned, then we're not in a repository
if [ -z "$BRANCH" ]; then
    exit
fi

# creates a color from the given color code
mkcolor()
{
    echo "\[\033[00;$1m\]"
}

BRANCH=${BRANCH#refs/heads/}
GIT_STATUS=$( $GIT status 2>/dev/null )

# colors can be overridden via the GITPS1_COLOR_* environment variables
COLOR_DEFAULT=$( mkcolor ${GITPS1_COLOR_DEFAULT:-33} )
COLOR_FASTFWD=$( mkcolor ${GITPS1_COLOR_FASTFWD:-31} )
COLOR_STAGED=$( mkcolor ${GITPS1_COLOR_STAGED:-32} )
COLOR_UNTRACKED=$( mkcolor ${GITPS1_COLOR_UNTRACKED:-31} )
COLOR_UNSTAGED=$( mkcolor ${GITPS1_COLOR_UNSTAGED:-33} )
COLOR_AHEAD=$( mkcolor ${GITPS1_COLOR_AHEAD:-33} )

# indicators may be overridden via the GITPS1_IND_* environment vars; set to
# '0' to disable
IND_STAGED=${GITPS1_IND_STAGED:-*}
IND_UNSTAGED=${GITPS1_IND_UNSTAGED:-*}
IND_UNTRACKED=${GITPS1_IND_UNTRACKED:-*}
IND_AHEAD=${GITPS1_IND_AHEAD:-@}
IND_AHEAD_COUNT=${GITPS1_IND_AHEAD_COUNT:-@}

STATUS=''
COLOR=$COLOR_DEFAULT
NO_COLOR=$( mkcolor 0 )

# uncommited files
if [ "$IND_UNSTAGED" != '0' ]; then
    $GIT diff --no-ext-diff --quiet --exit-code || \
        STATUS="${STATUS}${COLOR_UNSTAGED}${IND_UNSTAGED}"
fi

# not on branch/behind origin
if [ "$( echo $GIT_STATUS | grep 'Not currently on\|is behind' )" ]; then
    COLOR=$COLOR_FASTFWD
fi

# staged
if [  "$IND_STAGED" != '0' ]; then
    if [ "$( echo $GIT_STATUS | grep 'to be committed' )" ]; then
        STATUS="${STATUS}${COLOR_STAGED}${IND_STAGED}"
    fi
fi

# untracked
if [ "$IND_UNTRACKED" != '0' ]; then
    if [ -n "$( $GIT ls-files --others --exclude-standard )" ]; then
        STATUS="${STATUS}${COLOR_UNTRACKED}${IND_UNTRACKED}"
    fi
fi

# ahead of tracking
if [ "$IND_AHEAD" != '0' ]; then
    if [ "$( echo $GIT_STATUS | grep 'is ahead' )" ]; then
        STATUS="${STATUS}${COLOR_AHEAD}${IND_AHEAD}"

        # append count?
        if [ "$IND_AHEAD_COUNT" != '0' ]; then
            AHEAD_COUNT=$( echo $GIT_STATUS \
                | grep -o 'by [0-9]\+ commits\?' \
                | cut -d' ' -f2 \
            )
            STATUS="${STATUS}${AHEAD_COUNT}"
        fi
    fi
fi

# Since last commit based on https://gist.github.com/926846

function format_unit {
  local UNIT=$1
  case "$UNIT" in
      seconds) UNIT="s" ;;
      minutes) UNIT="m" ;;
      hours) UNIT="h" ;;
      days) UNIT="d" ;;
      weeks) UNIT="w" ;;
      months) UNIT="mo" ;;
      years) UNIT="yr" ;;
      *);;
  esac
  echo ${UNIT}
}

SINCE_LAST_COMMIT=$($GIT log --pretty=format:'%ar' -1)
SINCE_LAST_COMMIT=(${SINCE_LAST_COMMIT// / })

VALUE=${SINCE_LAST_COMMIT[0]}

UNIT=$(format_unit ${SINCE_LAST_COMMIT[1]/,/})

# for old projects, git reports years and months
if [ ${SINCE_LAST_COMMIT[2]} != "ago" ]; then
  EXTRA_VALUE=${SINCE_LAST_COMMIT[2]}
  EXTRA_UNIT=$(format_unit ${SINCE_LAST_COMMIT[3]/,/})
fi

DELTA_COLOR=''
if [ "$UNIT" == "s" ] || [ "$UNIT" == "m" ]; then
  DELTA_COLOR=$( mkcolor 32 )
elif [ "$UNIT" == "h" ]; then
  DELTA_COLOR=$( mkcolor 33 )
else
  DELTA_COLOR=$( mkcolor 31 )
fi

DELTA="${VALUE}${UNIT}${EXTRA_VALUE}${EXTRA_UNIT}"
DELTA="${NO_COLOR} ∆ ${DELTA_COLOR}${DELTA}${NO_COLOR}"

# output the status string
echo "$COLOR[${BRANCH}${STATUS}${COLOR}${DELTA}${COLOR}]$NO_COLOR "
