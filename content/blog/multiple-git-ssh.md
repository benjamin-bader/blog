+++
date = "2020-03-01T19:08:00-08:00"
draft = false
title = "SSH Setup for Multiple Github Accounts"
tags = [ "git", "github", "ssh", "catalina", "tips" ]
slug = "ssh-with-multiple-github-accounts"
+++

Scenario:
You're starting at a new company, and they use GitHub for source control.  This is nice, because you know GitHub.  This is _not_ nice, on the other hand, because you already use it for personal projects.  Bad things can happen when you mix the personal and the professional, and you'd like to avoid even the appearance of impropriety.  Time for a second GitHub account!

This is great, _until_ you want to keep working on your personal things at the same time.  How on Earth can we make SSH behave properly?

*TL;DR*: Use this SSH configuration (usually in `~/.ssh/config`):

```
# Assuming that you have the following SSH keys:
# 1. ~/.ssh/work_id_rsa
# 2. ~/.ssh/personal_id_rsa

Host personal.github.com
  HostName github.com
  IdentityFile ~/.ssh/personal_id_rsa

Host github.com
  HostName github.com
  IdentityFile ~/.ssh/work_id_rsa

Host *
  IgnoreUnknown UseKeychain,AddKeysToAgent
  UseKeychain yes
  AddKeysToAgent
```

When you want to clone personal things, do it like so:
```
git clone git@personal.github.com:username/repo
```

When you want to clone work things, do it the usual way:
```
git clone git@github.com:username/repo
```

The way this works is that git, when cloning this way, uses `ssh` and gives it the URL to resolve.  `ssh` checks the config, and sees if it has any special configuration for the URL.  In this case, if it sees `personal.github.com`, it will know to use the hostname `github.com`, _with your personal SSH key_.

Conversely, if you just use `git@github.com:...`, ssh will know to use your work key instead.

The final config entry, `Host *`, is global configuration that configures SSH to use a so-called agent.  In a nutshell, it means you won't have to enter your keys' passphrases over and over again. The "UseKeychain" config is mac-specific, so it's important to `IgnoreUnknown` it if you want to use this on a non-mac system.

Make sure you `ssh add -K path/to/key` your keys, and run `ssh add -A`.

Hope this helps!