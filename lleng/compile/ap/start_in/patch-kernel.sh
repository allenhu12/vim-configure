#! /bin/sh
# A little script I whipped up to make it easy to
# patch source trees and have sane error handling
# -Erik
#
# (c) 2002 Erik Andersen <andersen@codepoet.org>

# Set directories from arguments, or use defaults.
targetdir=${1-.}
patchdir=${2-../kernel-patches}
shift 2
echo "parameter: ${@}"
patchpattern=${@-*}
echo "targetdir: ${targetdir}"
echo "patchdir: ${patchdir}"
echo "patchpattern: ${patchpattern}"
if [ ! -d "${targetdir}" ] ; then
    echo "Aborting.  '${targetdir}' is not a directory."
    exit 1
fi
if [ ! -d "${patchdir}" ] ; then
    echo "Aborting.  '${patchdir}' is not a directory."
    exit 1
fi
    
for i in `cd ${patchdir} >/dev/null ; ls -d ${patchpattern} 2> /dev/null` ; do 
    case "$i" in
	*.gz)
	type="gzip"; uncomp="gunzip -dc"; ;; 
	*.bz)
	type="bzip"; uncomp="bunzip -dc"; ;; 
	*.bz2)
	type="bzip2"; uncomp="bunzip2 -dc"; ;; 
	*.zip)
	type="zip"; uncomp="unzip -d"; ;; 
	*.Z)
	type="compress"; uncomp="uncompress -c"; ;; 
	*)
	type="plaintext"; uncomp="cat"; ;; 
    esac
    echo ""
    echo "Applying ${i} using ${type}: " 
    echo " ${uncomp} ${patchdir}/${i} | patch -g0 -p1 -E -d ${targetdir} "
    ${uncomp} ${patchdir}/${i} | patch -g0 -p1 -E -d ${targetdir} 
    if [ $? != 0 ] ; then
        echo "Patch failed!  Please fix $i!"
	exit 1
    fi
done

# Check for rejects...
if [ "`find $targetdir/ '(' -name '*.rej' -o -name '.*.rej' ')' -print`" ] ; then
    echo "Aborting.  Reject files found."
    exit 1
fi

# Remove backup files
find $targetdir/ '(' -name '*.orig' -o -name '.*.orig' ')' -exec rm -f {} \;
