#!/usr/bin/env bash

git config --global user.name "Łukasz Czajka"
git config --global user.email "lukaszcz@mimuw.edu.pl"
git config --global pull.rebase true
git config --global init.defaultBranch main
git config --global core.pager delta

git config --global alias.st "status -sb"
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.wt worktree
git config --global alias.lg "log --oneline -10"
git config --global alias.lgs "log --oneline"
git config --global alias.dt '!git -c diff.external=difft diff'
git config --global alias.difft '!git -c diff.external=difft diff'
git config --global alias.diffnav '!f() { git diff "$@" | diffnav -u; }; f'
git config --global alias.dn '!git diff "$@" | diffnav -u'
