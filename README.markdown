BuildKit
========

A simple build system for organizing your source tree into multiple modules.


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


Next, you need to include this file from your root Makefile:

    include buildkit/modules.mk
    buildkit/modules.mk:
    	git clone http://github.com/netj/buildkit.git

You may set STAGEDIR and BUILDDIR variables before including modules.mk
if you want to use a different location other than the default `.stage` and
`.build` respectively.


Now, you can use following Make targets to build, stage and install all
modules under your source tree, without messing with any Makefiles:

 * make build
 * make stage
 * make clean
 * make package
 * make install



Enjoy,

~Jaeho
