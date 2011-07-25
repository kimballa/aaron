#!/usr/bin/env python
#
# Usage:
# rebase-patchset.py branchlist.txt dest-branch [start-branch]
#
# Let's say you have a linear stack of branches like this:
# (time extending 'up')
#
#  topicB
#    |
#  topicA
#    |
#  master
#
# When master changes, you then have:
#
#  topicB
#    |
#  topicA   master
#    |      /
#  (old master)
#
# And you need to rebase topicA onto master, then topicB onto topicA.
#
#
# This script will rebase a set of branches for you, in the correct order.
# You need to create a branchlist.txt file containing branch names,
# one per line, that form a linear chain. The newest branch goes last.
# e.g., in the above example, this file may look like:
#
#    topicA
#    topicB
#
# Then when master moves forward, you run:
# $ rebase-patchset.py branchlist.txt master
#
# If you had a longer chain (topicA, topicB, .... topicF)
# and you only wanted to rebase part of it (e.g., starting with branch
# 'topicD', including refs as far back as 'startref', rebased onto topicC):
#
# $ rebase-patchset.py branchlist.txt topicC topicD startref
#
# This form of the command will start with topicD and continue through topicF.
#


import os
import sys

def read_branch_list(branch_list_file):
  """ Read the list of branches out of the branchlist file """
  h = open(branch_list_file)
  branches = []
  try:
    while True:
      line = h.readline()
      if not line:
        break;
      line = line.strip()
      if line.startswith("#") or len(line) == 0:
        continue
      branches.append(line)
  finally:
    h.close()

  return branches


def run(cmd):
  """ Run a command, throw an exception if it fails.
      Print results to stdout/stderr.
  """
  print "Executing: " + cmd
  ret = os.system(cmd)
  if ret != 0:
    print "Command did not exit successfully: " + str(ret)
    raise Exception("Error running subcommand.") 

def run_for_value(cmd):
  """ Run a command, capture stdout and return as a string.
  """
  print "Executing: " + cmd
  lines = []
  h = os.popen(cmd, "r")
  while True:
    line = h.readline();
    if line == '':
      break
    line = line.rstrip()
    lines.append(line)
  ret = h.close()
  if ret > 0:
    print "WARNING: Error return code: " + str(ret)
  return "\n".join(lines)


def rebase_all(dest_branch, branch_list, start_ref):
  for branch in branch_list:
    print "Rebasing branch: " + branch
    run("git checkout " + branch)
    lastrev = run_for_value("git rev-parse HEAD")
    if start_ref:
      run("git rebase --onto " + dest_branch + " " + start_ref + " " + branch)
    else:
      run("git rebase " + dest_branch)
    dest_branch = branch
    start_ref = lastrev

def print_usage():
  print """
Usage: rebase-patchset.py branchlist.txt dest-branch [start-branch [parent-ref]]
   branchlist.txt    A file containing a list of branches to rebase.
   dest-branch       The destination where the listed branches should rebase to
   start-branch      A branch in branchlist.txt identifying the start of a
                     subsequence of branches to rebase.
   parent-ref        The ref describing the first commit that is not 'part of'
                     start-branch.
"""

def main():
  if sys.argv[1] == "-h" or sys.argv[1] == "--help":
    print_usage()
    return 0

  branch_list_file = sys.argv[1]
  dest_branch = sys.argv[2]
  if len(sys.argv) > 3:
    start_branch = sys.argv[3]
  else:
    start_branch = None

  if len(sys.argv) > 4:
    start_ref = sys.argv[4]
  else:
    start_ref = None

  all_branches = read_branch_list(branch_list_file)
  if start_branch:
    start_offset = all_branches.index(start_branch)
    if start_offset >= 0:
      all_branches = all_branches[start_offset:]
    else:
      print "No such branch in branchlist: " + start_branch
      return 1

  rebase_all(dest_branch, all_branches, start_ref)
  

if __name__ == "__main__":
  sys.exit(main())

