#!/usr/bin/env bash

function isLoaded() {
  local agent="$1"
  # Blame will return an error status if the service is not loaded
  [[ $(launchctl blame  $session/$agent) ]] &> /dev/null
}

function isDisabled() {
  local agent="$1"
  local f
  for f in "${disabledAgents[@]}" ; do
    [[ "$f" == "$agent" ]] && return 0
  done
  return 1
}

function launchdReload() {
  local workDir
  workDir="$(mktemp -d)"

  if [[ -v oldGenPath ]] ; then
    local oldUserAgentPath="$oldGenPath/home-files/Library/LaunchAgents"
  fi

  local newUserAgentPath="$newGenPath/home-files/Library/LaunchAgents"
  local oldAgentFiles="$workDir/old-files"
  local newAgentFiles="$workDir/new-files"
  local agentsRemovedFile="$workDir/removed"
  local agentsAddedFile="$workDir/added"
  local agentsUnchangedFile="$workDir/unchanged"

  if [[ ! (-v oldUserAgentPath && -d "$oldUserAgentPath") \
      && ! -d "$newUserAgentPath" ]]; then
    return
  fi

  if [[ ! (-v oldUserAgentPath && -d "$oldUserAgentPath") ]]; then
    touch "$oldAgentFiles"
  else
    find "$oldUserAgentPath" \
      -maxdepth 1 -name '*.plist' -exec shasum '-a' '256' '{}' ';' \
      | awk '{cmd=sprintf("basename %s",$2);cmd | getline out; print $1,substr(out,0,length(out)-6);}' \
      | sort \
      > "$oldAgentFiles"
  fi

  if [[ ! -d "$newUserAgentPath" ]]; then
    touch "$newAgentFiles"
  else
    find "$newUserAgentPath" \
      -maxdepth 1 -name '*.plist' -exec shasum '-a' '256' '{}' ';' \
      | awk '{cmd=sprintf("basename %s",$2);cmd | getline out; print $1,substr(out,0,length(out)-6);}' \
      | sort \
      > "$newAgentFiles"
  fi

  echo "OLD FILES:"
  cat $oldAgentFiles
  echo ""
  echo "NEW FILES:"
  cat $newAgentFiles
  echo ""

  comm -23 $newAgentFiles $oldAgentFiles > $agentsAddedFile
  comm -13 $newAgentFiles $oldAgentFiles > $agentsRemovedFile
  comm -12 $newAgentFiles $oldAgentFiles > $agentsUnchangedFile

  local -a agentsAdded=( $(cat $agentsAddedFile | cut -c2- | cut -d ' ' -f2) )
  local -a agentsRemoved=( $(cat $agentsRemovedFile | cut -c2- | cut -d ' ' -f2) )
  local -a agentsUnchanged=( $(cat $agentsUnchangedFile | cut -c2- | cut -d ' ' -f2 ) )

  local -a maybeLoad=( )
  local -a toLoad=( )
  local -a toUnload=( )
  local -a warnDisabled=( )

  rm -r "$workDir"

  for f in "${agentsAdded[@]}" ; do
    maybeLoad+=("$f")
    if isLoaded $f; then
      toUnload+=("$f")
    fi
  done

  for f in "${agentsRemoved[@]}" ; do
    if isLoaded $f; then
      toUnload+=("$f")
    fi
  done

  for f in "${agentsUnchanged[@]}" ; do
    if ! isLoaded $f; then
      maybeLoad+=("$f")
    fi
  done

  for f in "${maybeLoad[@]}" ; do
    if ! isDisabled $f; then
      toLoad+=("$f")
    else
      warnDisabled+=("$f")
    fi
  done

  toUnload=($(printf "%s\n" "${toUnload[@]}" | sort -u))
  toLoad=($(printf "%s\n" "${toLoad[@]}" | sort -u))
  warnDisabled=($(printf "%s\n" "${warnDisabled[@]}" | sort -u))

  local sugg=""

  for f in "${toUnload[@]}" ; do
    sugg="${sugg}launchctl bootout $session/$f\n"
  done

  for f in "${toLoad[@]}" ; do
    sugg="${sugg}launchctl bootstrap $session ~/Library/LaunchAgents/$f.plist\n"
  done

  if [[ -n "$sugg" ]] ; then
    echo "Suggested commands:"
    echo -n -e "$sugg"
  fi

  for f in "${warnDisabled[@]}" ; do
    echo "Warning: $f disabled"
  done
}

oldGenPath="$1"
newGenPath="$2"
session="gui/$(id -u)"
disabledAgents=( $(launchctl print-disabled $session \
                  | awk '/disabled services = {/,/}/' \
                  | sed -n "s/^.*\"\(.*\)\" => true/\1/p") )

launchdReload
