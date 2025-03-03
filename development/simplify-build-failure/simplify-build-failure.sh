#!/bin/bash
#
#  Copyright (C) 2020 The Android Open Source Project
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

set -e

function usage() {
  echo 'NAME'
  echo '  simplify-build-failure.sh'
  echo
  echo 'SYNOPSIS'
  echo "  $0 (--task <gradle task> <other gradle arguments> <error message> [--clean] | --command <shell command> ) [--continue] [--limit-to-path <file path>] [--check-lines-in <subfile path>] [--num-jobs <count>]"
  echo
  echo DESCRIPTION
  echo '  Searches for a minimal set of files and/or lines required to reproduce a given build failure'
  echo
  echo OPTIONS
  echo
  echo '  --task <gradle task> <other gradle arguments> <error message>`'
  echo '    Specifies that `./gradlew <gradle task>` must fail with error message <error message>'
  echo
  echo '  --command <shell command>'
  echo '    Specifies that <shell command> must succeed.'
  echo
  echo '  --continue'
  echo '    Attempts to pick up from a previous invocation of simplify-build-failure.sh'
  echo
  echo '  --limit-to-path <limitPath>'
  echo '    Will check only <limitPath> (plus subdirectories, if present) for possible simplications. This can make the simplification process faster if there are paths that you know are'
  echo '    uninteresting to you'
  echo
  echo '  --check-lines-in <subfile path>'
  echo '    Specifies that individual lines in files in <subfile path> will be considered for removal, too'
  echo
  echo '  --num-jobs <count>'
  echo '    Specifies the number of jobs to run at once'
  echo
  echo '  --clean'
  echo '    Specifies that each build should start from a consistent state'
  exit 1
}

function notify() {
  echo simplify-build-failure.sh $1
  notify-send simplify-build-failure.sh $1
}

function failed() {
  notify failed
  exit 1
}

gradleTasks=""
gradleExtraArguments=""
errorMessage=""
gradleCommand=""
grepCommand=""
testCommand=""
resume=false
subfilePath=""
limitToPath=""
numJobs="auto"
clean="false"

export ALLOW_MISSING_PROJECTS=true # so that if we delete entire projects then the AndroidX build doesn't think we made a spelling mistake

workingDir="$(pwd)"
cd "$(dirname $0)"
scriptPath="$(pwd)"
cd ../..
supportRoot="$(pwd)"
checkoutRoot="$(cd $supportRoot/../.. && pwd)"
tempDir="$checkoutRoot/simplify-tmp"

pathsToNotShrink="gradlew"

if [ ! -e "$workingDir/gradlew" ]; then
  echo "Error; ./gradlew does not exist. Must cd to a dir containing a ./gradlew first"
  # so that this script knows which gradlew to use (in frameworks/support or frameworks/support/ui)
  exit 1
fi

while [ "$1" != "" ]; do
  arg="$1"
  shift
  if [ "$arg" == "--continue" ]; then
    resume=true
    continue
  fi
  if [ "$arg" == "--task" ]; then
    gradleTasks="$1"
    if [ "$gradleTasks" == "" ]; then
      usage
    fi
    shift
    gradleExtraArguments="$1"
    shift
    errorMessage="$1"
    if [ "$errorMessage" == "" ]; then
      usage
    fi
    shift

    gradleCommand="OUT_DIR=out ./gradlew $gradleExtraArguments >log 2>&1"
    grepCommand="$scriptPath/impl/grepOrTail.sh \"$errorMessage\" log"
    continue
  fi
  if [ "$arg" == "--command" ]; then
    if [ "$1" == "" ]; then
      usage
    fi
    testCommand="$1"
    shift
    gradleCommand=""
    grepCommand=""
    if echo "$testCommand" | grep -v OUT_DIR 2>/dev/null; then
      testCommand="export OUT_DIR=out; $testCommand"
    else
      echo "Sorry, customizing OUT_DIR is not supported at the moment because we want impl/join.sh to be able to detect it and skip deleting it"
      exit 1
    fi
    continue
  fi
  if [ "$arg" == "--check-lines-in" ]; then
    subfilePath="$1"
    # normalize path
    subfilePath="$(realpath $subfilePath --relative-to=.)"
    shift
    continue
  fi
  if [ "$arg" == "--limit-to-path" ]; then
    limitToPath="$1"
    shift
    continue
  fi
  if [ "$arg" == "--num-jobs" ]; then
    numJobs="$1"
    shift
    continue
  fi
  if [ "$arg" == "--clean" ]; then
    clean=true
    continue
  fi
  echo "Unrecognized argument '$arg'"
  usage
done

if [ "$gradleCommand" == "" ]; then
  if [ "$clean" == "true" ]; then
    echo "Option --clean requires option --task"
    usage
  fi
  if [ "$testCommand" == "" ]; then
    usage
  fi
fi

# delete temp dir if not resuming
if [ "$resume" == "true" ]; then
  if [ -d "$tempDir" ]; then
    echo "Not deleting temp dir $tempDir"
  fi
else
  echo "Removing temp dir $tempDir"
  rm "$tempDir" -rf
fi

referencePassingDir="$tempDir/base"
referenceFailingDir="$tempDir/failing"
# backup code so user can keep editing
if [ ! -e "$referenceFailingDir" ]; then
  echo backing up frameworks/support into "$referenceFailingDir" in case you want to continue to make modifications or run other builds
  rm "$referenceFailingDir" -rf
  mkdir -p "$tempDir"
  cp -rT . "$referenceFailingDir"
  # remove some unhelpful settings
  sed -i 's/.*Werror.*//' "$referenceFailingDir/buildSrc/shared.gradle"
  sed -i 's/.*Exception.*cannot include.*//' "$referenceFailingDir/settings.gradle"
  # remove some generated files that we don't want diff-filterer.py to track
  rm -rf "$referenceFailingDir/.gradle" "$referenceFailingDir/buildSrc/.gradle" "$referenceFailingDir/out"
  rm -rf "$referenceFailingDir/tasks" # generated by simplify-build-failure and could be inadvertently copied into source by the user
fi

# compute destination state, which is usually almost empty
rm "$referencePassingDir" -rf
if [ "$limitToPath" != "" ]; then
  mkdir -p "$(dirname $referencePassingDir)"
  cp -r "$supportRoot" "$referencePassingDir"
  rm "$referencePassingDir/$limitToPath" -rf
else
  mkdir -p "$referencePassingDir"
  # restore any special files that we don't want to shrink
  for path in $pathsToNotShrink; do
    cp "$supportRoot/$path" "$referencePassingDir"
  done
fi

if [ "$subfilePath" != "" ]; then
  if [ ! -e "$subfilePath" ]; then
    echo "$subfilePath" does not exist
    exit 1
  fi
fi

# if Gradle tasks are specified, then determine the appropriate shell command
if [ "$gradleCommand" != "" ]; then
  gradleCommand="$(echo "$gradleCommand" | sed 's/gradlew/gradlew --no-daemon/')"
  # determine whether we can reduce the list of tasks we'll be running
  # prepare directory
  allTasksWork="$tempDir/allTasksWork"
  allTasks="$tempDir/tasks"
  if [ -e "$allTasks" ]; then
    echo Skipping recalculating list of all relevant tasks, "$allTasks" already exists
  else
    echo Calculating list of tasks to run
    rm -rf "$allTasksWork"
    cp -r "$referenceFailingDir" "$allTasksWork"
    # list tasks required for running this
    if bash -c "cd $allTasksWork && OUT_DIR=out ./gradlew --no-daemon --dry-run $gradleTasks >log 2>&1"; then
      echo "Expanded full list of tasks to run"
    else
      echo "Failed to expand full list of tasks to run; using given list of taks"
    fi
    # process output and split into files
    mkdir -p "$allTasks"
    taskListFile="$allTasksWork/tasklist"
    # A task line will start with one or more project names separated by ":", then have a task name, and lastly either end of line or " " followed by a status (like UP-TO-DATE)
    # We want the task path so we search for task lines and remove any trailing status
    cat "$allTasksWork/log" | grep '^\(:[a-zA-Z0-9\-]\+\)\+\( \|$\)' | sed 's/ .*//' > "$taskListFile"
    bash -c "cd $allTasks && split -l 1 '$taskListFile'"
    # also include the original tasks in case either we failed to compute the list of tasks (due to the build failing during project configuration) or there are too many tasks to fit in one command line invocation
    bash -c "cd $allTasks && echo '$gradleTasks' > givenTasks"
  fi

  # build command for passing to diff-filterer
  # set OUT_DIR
  testCommand="export OUT_DIR=out"
  # delete log
  testCommand="$testCommand && rm -f log"
  # make sure at least one task exists
  testCommand="$testCommand && ls tasks/* >/dev/null"
  # build a shell script for running each task listed in the tasks/ dir
  # We call xargs because the full set of tasks might be too long for the shell, and xargs will
  # split into multiple gradlew invocations if needed
  # Also, once we reproduce the error, we stop running more Gradle commands
  testCommand="$testCommand && echo > run.sh && cat tasks/* | xargs echo '$grepCommand && exit 0; $gradleCommand' >> run.sh"

  # run Gradle
  testCommand="$testCommand && chmod u+x run.sh && ./run.sh >log 2>&1"
  if [ "$clean" != "true" ]; then
    # If the daemon is enabled, then sleep for a little bit in case Gradle fails very quickly
    # If we run too many builds in a row with Gradle daemons enabled then the daemons might get confused
    testCommand="$testCommand; sleep 2"
  fi
  # check for the error message that we want
  testCommand="$testCommand; $grepCommand"

  # identify a minimal set of tasks to reproduce the problem
  minTasksFailing="$tempDir/minTasksFailing"
  minTasksGoal="$referenceFailingDir"
  minTasksOutput="$tempDir/minTasks_output"
  if [ -e "$minTasksOutput" ]; then
    echo already computed the minimum set of required tasks, can be seen in $minTasksGoal
  else
    rm -rf "$minTasksFailing"
    cp -r "$minTasksGoal" "$minTasksFailing"
    cp -r "$allTasks" "$minTasksFailing/"
    echo Asking diff-filterer for a minimal set of tasks to reproduce this problem
    if ./development/file-utils/diff-filterer.py --work-path "$tempDir" --num-jobs "$numJobs" "$minTasksFailing" "$minTasksGoal" "$testCommand"; then
      echo diff-filterer successfully identifed a minimal set of required tasks
      cp -r "$tempDir/bestResults" "$minTasksOutput"
    else
      failed
    fi
  fi
  referenceFailingDir="$minTasksOutput"
  echo Will use goal directory of "$referenceFailingDir"
fi

filtererStep1Work="$tempDir"
filtererStep1Output="$filtererStep1Work/bestResults"
fewestFilesOutputPath="$tempDir/fewestFiles"
if echo "$resume" | grep "true" >/dev/null && stat "$fewestFilesOutputPath" >/dev/null 2>/dev/null; then
  echo "Skipping asking diff-filterer for a minimal set of files, $fewestFilesOutputPath already exists"
else
  if [ "$resume" == "true" ]; then
    if stat "$filtererStep1Output" >/dev/null 2>/dev/null; then
      echo "Reusing $filtererStep1Output to resume asking diff-filterer for a minimal set of files"
      # Copy the previous results to resume from
      rm "$referenceFailingDir" -rf
      cp -rT "$filtererStep1Output" "$referenceFailingDir"
    else
      echo "Cannot resume previous execution; neither $fewestFilesOutputPath nor $filtererStep1Output exists"
      exit 1
    fi
  fi
  echo Running diff-filterer.py once to identify the minimal set of files needed to reproduce the error
  if ./development/file-utils/diff-filterer.py --work-path $filtererStep1Work --num-jobs "$numJobs" "$referenceFailingDir" "$referencePassingDir" "$testCommand"; then
    echo diff-filterer completed successfully
  else
    failed
  fi
  echo Copying minimal set of files into $fewestFilesOutputPath
  rm -rf "$fewestFilesOutputPath"
  cp -rT "$filtererStep1Output" "$fewestFilesOutputPath"
fi

if [ "$subfilePath" == "" ]; then
  echo Splitting files into individual lines was not enabled. Done. See results at $filtererStep1Work/bestResults
else
  if [ "$subfilePath" == "." ]; then
    subfilePath=""
  fi
  if echo "$resume" | grep true >/dev/null && stat $fewestFilesOutputPath >/dev/null 2>/dev/null; then
    echo "Skipping recopying $filtererStep1Output to $fewestFilesOutputPath"
  else
    echo Copying minimal set of files into $fewestFilesOutputPath
    rm -rf "$fewestFilesOutputPath"
    cp -rT "$filtererStep1Output" "$fewestFilesOutputPath"
  fi

  echo Creating working directory for identifying individually smallest files
  noFunctionBodies_Passing="$tempDir/noFunctionBodies_Passing"
  noFunctionBodies_goal="$tempDir/noFunctionBodies_goal"
  noFunctionBodies_work="work"
  noFunctionBodies_sandbox="$noFunctionBodies_work/$subfilePath"
  noFunctionBodies_output="$tempDir/noFunctionBodies_output"

  # set up command for running diff-filterer against diffs within files
  filtererOptions="--num-jobs $numJobs"

  if echo "$resume" | grep true >/dev/null && stat "$noFunctionBodies_output" >/dev/null 2>/dev/null; then
    echo "Skipping asking diff-filterer to remove function bodies because $noFunctionBodies_output already exists"
  else
    echo Splitting files into smaller pieces
    rm -rf "$noFunctionBodies_Passing" "$noFunctionBodies_goal"
    mkdir -p "$noFunctionBodies_Passing" "$noFunctionBodies_goal"
    cd "$noFunctionBodies_Passing"
    cp -rT "$fewestFilesOutputPath" "$noFunctionBodies_work"
    cp -rT "$noFunctionBodies_Passing" "$noFunctionBodies_goal"

    splitsPath="${subfilePath}.split"
    "${scriptPath}/impl/split.sh" --consolidate-leaves "$noFunctionBodies_sandbox" "$splitsPath"
    rm "$noFunctionBodies_sandbox" -rf

    echo Removing deepest lines
    cd "$noFunctionBodies_goal"
    "${scriptPath}/impl/split.sh" --remove-leaves "$noFunctionBodies_sandbox" "$splitsPath"
    rm "$noFunctionBodies_sandbox" -rf

    # restore any special files that we don't want to shrink
    for path in $pathsToNotShrink; do
      relativePathFromSubfilePath="$(realpath --relative-to="./$subfilePath" "$path")"
      if ! echo "$relativePathFromSubfilePath" | grep "^\.\." >/dev/null 2>/dev/null; then
        # This file is contained in $subfilePath so we were going to try to shrink it if it weren't exempt
        echo Exempting "$path" from shrinking
        # Copy the exploded version of the file that doesn't have any missing pieces
        rm -rf "$splitsPath/$relativePathFromSubfilePath"
        cp -rT "$noFunctionBodies_Passing/$splitsPath/$relativePathFromSubfilePath" "$noFunctionBodies_goal/$splitsPath/$relativePathFromSubfilePath"
      fi
    done

    # TODO: maybe we should make diff-filterer.py directly support checking individual line differences within files rather than first running split.sh and asking diff-filterer.py to run join.sh
    # It would be harder to implement in diff-filterer.py though because diff-filterer.py would also need to support comparing against nonempty files too
    echo Running diff-filterer.py again to identify which function bodies can be removed
    if "$supportRoot/development/file-utils/diff-filterer.py" $filtererOptions --allow-goal-passing --work-path "$(cd $supportRoot/../.. && pwd)" "$noFunctionBodies_Passing" "$noFunctionBodies_goal" "${scriptPath}/impl/join.sh ${splitsPath} ${noFunctionBodies_sandbox} && cd ${noFunctionBodies_work} && $testCommand"; then
      echo diff-filterer completed successfully
    else
      failed
    fi

    echo Re-joining the files
    rm -rf "${noFunctionBodies_output}"
    cp -rT "$(cd $supportRoot/../../bestResults && pwd)" "${noFunctionBodies_output}"
    cd "${noFunctionBodies_output}"
    "${scriptPath}/impl/join.sh" "${splitsPath}" "${noFunctionBodies_sandbox}"
  fi

  # prepare for another invocation of diff-filterer, to remove other code that is now unused
  smallestFilesInput="$tempDir/smallestFilesInput"
  smallestFilesGoal="$tempDir/smallestFilesGoal"
  smallestFilesWork="work"
  smallestFilesSandbox="$smallestFilesWork/$subfilePath"

  rm -rf "$smallestFilesInput" "$smallestFilesGoal"
  mkdir -p "$smallestFilesInput"
  cp -rT "${noFunctionBodies_output}" "$smallestFilesInput"

  echo Splitting files into individual lines
  cd "$smallestFilesInput"
  splitsPath="${subfilePath}.split"
  "${scriptPath}/impl/split.sh" "$smallestFilesSandbox" "$splitsPath"
  rm "$smallestFilesSandbox" -rf

  # Make a dir holding the destination file state
  if [ "$limitToPath" != "" ]; then
    # The user said they were only interested in trying to delete files under a certain path
    # So, our target state is the original state minus that path (and its descendants)
    mkdir -p "$smallestFilesGoal"
    cp -rT "$smallestFilesInput/$smallestFilesWork" "$smallestFilesGoal/$smallestFilesWork"
    cd "$smallestFilesGoal/$smallestFilesWork"
    rm "$limitToPath" -rf
    cd -
  else
    # The user didn't request to limit the search to a specific path, so we mostly try to delete as many
    # files as possible
    mkdir -p "$smallestFilesGoal"
  fi
  echo now check $smallestFilesGoal
  # Restore any special exempt files
  cd "$smallestFilesGoal"
  for path in $pathsToNotShrink; do
    relativePathFromSubfilePath="$(realpath --relative-to="./$subfilePath" "$path")"
    if ! echo "$relativePathFromSubfilePath" | grep "^\.\." >/dev/null 2>/dev/null; then
      # This file is contained in $subfilePath so we were going to try to shrink it if it weren't exempt
      # Copy the exploded version of the file that doesn't have any missing pieces
      echo Exempting "$path" from shrinking
      destPath="$smallestFilesGoal/$splitsPath/$relativePathFromSubfilePath"
      rm -rf "$destPath"
      mkdir -p "$(dirname "$destPath")"
      echo cp -rT "$noFunctionBodies_Passing/$splitsPath/$relativePathFromSubfilePath" "$destPath"
      cp -rT "$noFunctionBodies_Passing/$splitsPath/$relativePathFromSubfilePath" "$smallestFilesGoal/$splitsPath/$relativePathFromSubfilePath"
    fi
  done

  echo Running diff-filterer.py again to identify the minimal set of lines needed to reproduce the error
  if "$supportRoot/development/file-utils/diff-filterer.py" $filtererOptions --work-path "$(cd $supportRoot/../.. && pwd)" "$smallestFilesInput" "$smallestFilesGoal" "${scriptPath}/impl/join.sh ${splitsPath} ${smallestFilesSandbox} && cd ${smallestFilesWork} && $testCommand"; then
    echo diff-filterer completed successfully
  else
    failed
  fi

  echo Re-joining the files
  smallestFilesOutput="$tempDir/smallestFilesOutput"
  rm -rf "$smallestFilesOutput"
  cp -rT "$(cd $supportRoot/../../bestResults && pwd)" "${smallestFilesOutput}"
  cd "${smallestFilesOutput}"
  "${scriptPath}/impl/join.sh" "${splitsPath}" "${smallestFilesSandbox}"

  echo "Done. See simplest discovered reproduction test case at ${smallestFilesOutput}/${smallestFilesWork}"
fi
notify succeeded
