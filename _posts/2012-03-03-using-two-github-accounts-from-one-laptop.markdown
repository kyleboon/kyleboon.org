---
layout: post
comments: true
title: "Using two github accounts from one laptop"
categories: github shell
---
I have two github accounts (one for work and one personal) and I want to be able to access repositories from either account from my laptop without switching users locally.  I have separate rsa public keys for each account but needed an easy way to force git to know which one to use. Here's what I am doing:
<pre><code>~/.ssh/config
#Default GitHub user (work)
 Host github.com  
 HostName github.com  
 User git  
 IdentityFile /Users/USERNAME/.ssh/id_rsa 

# Personal user 
 Host github-personal  
 HostName github.com  
 User git  
 IdentityFile /Users/USERNAME/.ssh/id_rsa_personal </code></pre>
Then when I create a new github repository for personal use:
<pre>`git remote add origin git@github-personal:username/project.git`</pre>
or for work
<pre>`git remote add origin git@github.com:username/project.git`</pre>
If am cloning an existing repository it works the same way:
<pre>`git clone git@github.com:username/project.git `
`git clone git@github-personal:username/project.git `</pre>
