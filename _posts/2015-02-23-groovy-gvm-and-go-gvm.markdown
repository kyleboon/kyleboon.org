---
layout: post
title: Using Groovy's GVM and Go's GVM together
date: 2015-02-23 13:33
comments: true
categories: programming bash 
---

This may or may not have been yak shaving, but I wanted to find out [what the weather was like](https://github.com/jfrazelle/weather) and I ended up getting groovy's GVM and go's GVM tools to work together. 

Both GVMs default to being installed at ```~/.gvm``` and define a bash function named ```gvm```. There is an [issue on github](https://github.com/moovweb/gvm/issues/103) that recomends modifying the source of Go's GVM but I wanted to be able to keep up to date with both tools without much (any) work.

Here's how to do it:

* I'm assuming you already have Groovy's GVM installed locally already. 
* Download the [installation script](https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer) for Go locally. You'll want to edit it to change the installation directory:

```bash
BRANCH=${1:-master}
GVM_DEST=${2:-$HOME}
GVM_NAME="govm"
SRC_REPO=${SRC_REPO:-https://github.com/moovweb/gvm.git}

[ "$GVM_DEST" = "$HOME" ] && GVM_NAME=".govm"
```

* Run the installation script that you've saved locally.
* Modify your ```~/.bashrc``` to rename the gvm() function created by Go's GVM before the gvm function is recreated by Groovy's GVM.

```bash
copy_function() {
    declare -F $1 > /dev/null || return 1
    eval "$(echo "${2}()"; declare -f ${1} | tail -n +2)"
}

#THIS MUST BE AT THE END OF THE FILE FOR GVM TO WORK!!!
[[ -s "/home/vagrant/.govm/scripts/gvm" ]] && source "/home/vagrant/.govm/scripts/gvm"

copy_function gvm govm

[[ -s "/home/vagrant/.gvm/bin/gvm-init.sh" ]] && source "/home/vagrant/.gvm/bin/gvm-init.sh"
```

The ```copy_function()``` function came from [stack overflow.](https://stackoverflow.com/questions/1203583/how-do-i-rename-a-bash-function)

That's it. Now you have ```gvm``` from groovy and ```govm``` for go.

## Groovy

```bash
vagrant@vagrant-ubuntu-trusty-64:~$ gvm

Usage: gvm <command> <candidate> [version]
       gvm offline <enable|disable>

   commands:
       install   or i    <candidate> [version]
       uninstall or rm   <candidate> <version>
       list      or ls   <candidate>
       use       or u    <candidate> [version]
       default   or d    <candidate> [version]
       current   or c    [candidate]
       version   or v
       broadcast or b
       help      or h
       offline           <enable|disable>
       selfupdate        [force]
       flush             <candidates|broadcast|archives|temp>

   candidate  :  asciidoctorj, crash, gaiden, glide, gradle, grails, griffon, groovy, groovyserv, jbake, lazybones, springboot, vertx
   version    :  where optional, defaults to latest stable if not provided

eg: gvm install groovy
```
## go

```bash
vagrant@vagrant-ubuntu-trusty-64:~$ govm
Usage: gvm [command]

Description:
  GVM is the Go Version Manager

Commands:
  version    - print the gvm version number
  get        - gets the latest code (for debugging)
  use        - select a go version to use
  diff       - view changes to Go root
  implode    - completely remove gvm
  install    - install go versions
  uninstall  - uninstall go versions
  cross      - install go cross compilers
  linkthis   - link this directory into GOPATH
  list       - list installed go versions
  listall    - list available versions
  alias      - manage go version aliases
  pkgset     - manage go packages sets
  pkgenv     - edit the environment for a package set
```
