BuildKit
========

A simple build system for organizing your source tree into multiple modules.


Quick Start
-----------

For each module, create following files:

 * .module.build
     An optional executable script that handles the actual build jobs
     of the module.
 * .module.install
     A table that specifies how files of a module should be installed.
     First column is the relative path to the file in the module, and
     second column is the destination path, where it should be
     installed under the STAGEDIR.  You can use environment variables
     with sh-style syntax on the second column, e.g.

       myscript.sh     $BINDIR/myscript
       mydata.txt      $DATADIR/

 * .module.depends
     A list of names of other modules that this module depends on.
     They will be built before this module is built.

Next, from your Makefile, define the environment variables you want to use in
.module.install files first:

    export BINDIR := bin
    export DATADIR := share/myprogram

Then, you need to include this file from your root Makefile:

    include buildkit/modules.mk

And that's it!

You can now use following Make targets to build, stage and install all modules
under your source tree, without messing with any Makefiles:

 * `make build`
 * `make stage`
 * `make clean`
 * `make package`
 * `make install`


Enjoy,

~Jaeho



A Little More Detail on Using BuildKit
--------------------------------------

### BuildKit for Codes with Git

If you are using Git for your project, you can link BuildKit as a submodule to
yours by running the following command:

    git submodule add https://github.com/netj/buildkit.git


### BuildKit without Git

If you can't use Git at all for your development, just download BuildKit and
include it into your source tree, and freely distribute it as long as you
promise to share your improvements with us.  Although you will find GPL from
the COPYING file, since BuildKit will never link with your code, you don't have
to worry about tying yours to GPL.

If you can but don't use Git for managing revisions to your code but still want
to have the latest version of BuildKit automatically, add following lines to
your Makefile:

    buildkit/modules.mk:
    	git clone https://github.com/netj/buildkit.git

This will let Make retrieve BuildKit for you as it discovers the include lines.
You'll probably need to add `buildkit` to the excluded files list of your
version control system.


Configuration
-------------

You may set STAGEDIR and BUILDDIR variables before including modules.mk
if you want to use a different location other than the default `.stage` and
`.build` respectively.  STAGEDIR is the path where everything will be staged
during `make stage`, and BUILDDIR is the place where all intermediate files,
such as timestamps will be placed.

PACKAGENAME and PACKAGEVERSION are the two variables that will determine the
name of the file created by `make package`.  They default to the name of the
root directory, and the current date respectively.


Executable Package
------------------

A special packaging option is available if you want to distribute your product
as a single executable file.  Define a variable named PACKAGEEXECUTES to the
relative path under STAGEDIR, which will be called when the packaged file is
executed after being first extracted to a temporary location.  This is useful
when you want to make your product handy by making it a single file, but still
want to keep independent source codes and data in separate files.

