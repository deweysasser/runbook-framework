# Runbook-framework

"Any sufficiently detailed documentation is executable"
-- me

## What is it?

A shell (bash) framework to implement run books scripts that help move from fully manual to fully
automated processes.

## Background

I love automation, but often getting something "automated" is a long process, and you actually need
to get something done now and don't have the time to fully automate it.

A few years ago I read
a [blog post](https://blog.danslimmon.com/2019/07/15/do-nothing-scripting-the-key-to-gradual-automation/)
presenting a clever way to move from unautomated to automated processes.

The clever key:  start with a script that does nothing other than tell you what to do. A checklist.
Then, as time evolves, you can automate one little piece. Since the script is walking you through a
checklist, this becomes one step that's done for you instead of you having to do it. This is one of
those simple and amazingly insightful ways of getting things done.

This repository implements a small library of BASH functions to support runbooks in a consistent and
useful way.

## Quickstart

Be sure to read the ["important details"](#important-details) section.


### Writing the script
Create a script that looks like this:

```shell
#!/bin/bash

. runbook-framework.sh

parameters="foo bar"
foo="some default value"

runbook() {
  step "This is a manual step and you'll get a prompt"
  step "This is an automated step" some-command
}
```

Of course, the steps should be doing whatever it is you need.  `some-command` can be a function you
define (I suggest later in the file, so the file starts with your runbook).

If you leave out the command, you've just made a prompt. If you include the command, it will be
executed. The status of all commands will be printed as they are executed.

### Running the script

The framework provides some overall features, including

* -help -- show how to run this runbook, including the parameters
* -show -- show the checklist *without* executing it

### What happened to the output?

The output of each step is stored away and shown only on error or on request.

### Important Details

The script sets up bash to be pretty paranoid, specifically:

```shell
set -ueo pipefail
```

The short form is:  unexpanded variables will be an error, any error (that's not in a conditional)
will stop the script, and it counts errors in the middle of a pipeline, not just the result of the
last command in the pipeline.


## Passing Parameters

You can set the `parameters` variable to a list of parameters you want to use in your script. They
will be set as (global) environment variables, exactly as you type them. All names that begin with
an underscore ('_') are reserved.

When you call the script, you may pass these variables on the command line as command line options.
If any of them are unset, the script will stop. So, if you want a default value, make sure you set
it.

## The Future

* it would be really nifty to support a `-document` argument that prints documentation about the
  runbook.