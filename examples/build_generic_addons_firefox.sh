#!/bin/bash
source /etc/profile

travis_start() {
  TRAVIS_STAGE=$1
  echo "[travis:$1:start]" 
}

travis_finish() {
  echo "[travis:$1:finish:result=$2]" 
  sleep 1
}

travis_assert() {
  local result=$?
  if [ $result -ne 0 ]; then
    echo -e "\nThe command \"$TRAVIS_CMD\" failed and exited with $result during $TRAVIS_STAGE.\n\nYour build has been stopped." 
    travis_terminate 2
  fi
}

travis_result() {
  local result=$1
  export TRAVIS_TEST_RESULT=$(( ${TRAVIS_TEST_RESULT:-0} | $(($result != 0)) ))
  echo -e "\nThe command \"$TRAVIS_CMD\" exited with $result."
}

travis_terminate() {
  travis_finish build $1
  pkill -9 -P $$ > /dev/null 2>&1
  exit $1
}

decrypt() {
  echo $1 | base64 -d | openssl rsautl -decrypt -inkey ~/.ssh/id_rsa.repo
}

mkdir -p $HOME/build
cd       $HOME/build

trap 'travis_finish build 1' TERM
trap 'TRAVIS_CMD=$TRAVIS_NEXT_CMD; TRAVIS_NEXT_CMD=$BASH_COMMAND' DEBUG

travis_start build
travis_start export
export TRAVIS_PULL_REQUEST=false
export TRAVIS_SECURE_ENV_VARS=true
export TRAVIS_BUILD_ID=1
export TRAVIS_BUILD_NUMBER=1
export TRAVIS_BUILD_DIR="$HOME/build/travis-ci/travis-ci"
export TRAVIS_JOB_ID=1
export TRAVIS_JOB_NUMBER=1.1
export TRAVIS_BRANCH=master
export TRAVIS_COMMIT=313f61b
export TRAVIS_COMMIT_RANGE=313f61b..313f61a
export TRAVIS_REPO_SLUG=travis-ci/travis-ci
echo \$\ export\ FOO\=foo
export FOO=foo
echo \$\ export\ BAR\=\[secure\]
export BAR=bar
travis_finish export $?

travis_start checkout
export GIT_ASKPASS=echo
echo -en 'travis_fold:start:git.1\r'
echo \$\ git\ clone\ --depth\=50\ --branch\=master\ git://github.com/travis-ci/travis-ci.git\ travis-ci/travis-ci
git clone --depth=50 --branch=master git://github.com/travis-ci/travis-ci.git travis-ci/travis-ci
travis_assert
echo -en 'travis_fold:end:git.1\r'
echo \$\ cd\ travis-ci/travis-ci
cd travis-ci/travis-ci
echo -en 'travis_fold:start:git.2\r'
echo \$\ git\ checkout\ -qf\ 313f61b
git checkout -qf 313f61b
travis_assert
echo -en 'travis_fold:end:git.2\r'
if [[ -f .gitmodules ]]; then
  echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
  echo -en 'travis_fold:start:git.3\r'
  echo \$\ git\ submodule\ init
  git submodule init
  echo -en 'travis_fold:end:git.3\r'
  echo -en 'travis_fold:start:git.4\r'
  echo \$\ git\ submodule\ update
  git submodule update
  travis_assert
  echo -en 'travis_fold:end:git.4\r'
fi
rm -f ~/.ssh/source_rsa
travis_finish checkout $?

travis_start setup
travis_finish setup $?

travis_start announce
travis_finish announce $?

travis_start before_install
echo -en 'travis_fold:start:install_firefox\r'
echo -e "[33;1mInstalling Firefox v20.0[0m"; 
echo \$\ sudo\ mkdir\ -p\ /usr/local/firefox/20.0
sudo mkdir -p /usr/local/firefox/20.0
echo \$\ sudo\ chown\ -R\ travis\ /usr/local/firefox
sudo chown -R travis /usr/local/firefox
echo \$\ wget\ -O\ /tmp/firefox.tar.bz2\ ftp://ftp.mozilla.org/pub/firefox/releases/20.0/linux-x86_64/en-US/firefox-20.0.tar.bz2
wget -O /tmp/firefox.tar.bz2 ftp://ftp.mozilla.org/pub/firefox/releases/20.0/linux-x86_64/en-US/firefox-20.0.tar.bz2
echo \$\ pushd\ /usr/local/firefox/20.0
pushd /usr/local/firefox/20.0
echo \$\ tar\ xf\ /tmp/firefox.tar.bz2
tar xf /tmp/firefox.tar.bz2
echo \$\ sudo\ ln\ -s\ /usr/local/firefox/20.0/firefox/firefox\ /usr/local/bin/firefox
sudo ln -s /usr/local/firefox/20.0/firefox/firefox /usr/local/bin/firefox
echo \$\ popd
popd
echo -en 'travis_fold:end:install_firefox\r'
echo -en 'travis_fold:start:before_install.1\r'
echo \$\ ./before_install_1.sh
./before_install_1.sh
travis_assert
echo -en 'travis_fold:end:before_install.1\r'
echo -en 'travis_fold:start:before_install.2\r'
echo \$\ ./before_install_2.sh
./before_install_2.sh
travis_assert
echo -en 'travis_fold:end:before_install.2\r'
travis_finish before_install $?

travis_start install
travis_finish install $?

travis_start before_script
echo -en 'travis_fold:start:before_script.1\r'
echo \$\ ./before_script_1.sh
./before_script_1.sh
travis_assert
echo -en 'travis_fold:end:before_script.1\r'
echo -en 'travis_fold:start:before_script.2\r'
echo \$\ ./before_script_2.sh
./before_script_2.sh
travis_assert
echo -en 'travis_fold:end:before_script.2\r'
travis_finish before_script $?

travis_start script


travis_result $?
travis_finish script $TRAVIS_TEST_RESULT

if [[ $TRAVIS_TEST_RESULT = 0 ]]; then
  travis_start after_success
  echo -en 'travis_fold:start:after_success.1\r'
  echo \$\ ./after_success_1.sh
  ./after_success_1.sh
  echo -en 'travis_fold:end:after_success.1\r'
  echo -en 'travis_fold:start:after_success.2\r'
  echo \$\ ./after_success_2.sh
  ./after_success_2.sh
  echo -en 'travis_fold:end:after_success.2\r'
  travis_finish after_success $?
fi
if [[ $TRAVIS_TEST_RESULT != 0 ]]; then
  travis_start after_failure
  echo -en 'travis_fold:start:after_failure.1\r'
  echo \$\ ./after_failure_1.sh
  ./after_failure_1.sh
  echo -en 'travis_fold:end:after_failure.1\r'
  echo -en 'travis_fold:start:after_failure.2\r'
  echo \$\ ./after_failure_2.sh
  ./after_failure_2.sh
  echo -en 'travis_fold:end:after_failure.2\r'
  travis_finish after_failure $?
fi

travis_start after_script
echo -en 'travis_fold:start:after_script.1\r'
echo \$\ ./after_script_1.sh
./after_script_1.sh
echo -en 'travis_fold:end:after_script.1\r'
echo -en 'travis_fold:start:after_script.2\r'
echo \$\ ./after_script_2.sh
./after_script_2.sh
echo -en 'travis_fold:end:after_script.2\r'
travis_finish after_script $?

echo -e "\nDone. Your build exited with $TRAVIS_TEST_RESULT."

travis_terminate $TRAVIS_TEST_RESULT
