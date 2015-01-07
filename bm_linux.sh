#!/bin/bash

#######################################
# This script merges and compiles 
# markdown documents to HTML, PDF (and ePub TBC)
# Dependencies are:
# * MultiMarkdown
# * Zenity (for interaction)
# * Pandoc
# * Wkhtmltopdf
#######################################


DIR=`dirname "$1"`

cd "$DIR"

#Check if files have been passed
#Required for command line usages
if [ "$#" -ne 0  ]; then

#check if our build dir is present
#make if not
if [ ! -d "build" ]; then

mkdir build

fi

#######################################
# META DATA Settings
#######################################

if [ -a "000_metadata.md" ]; then

#grab metadata from metadata file
title=`/usr/local/bin/multimarkdown 000_metadata.md --extract="Title"`
short_title=`/usr/local/bin/multimarkdown 000_metadata.md --extract="ShortTitle"`
author=`/usr/local/bin/multimarkdown 000_metadata.md --extract="Author"`

else

#check if the first file contains the metadata we need
short_title=`/usr/local/bin/multimarkdown "$1" --extract="ShortTitle"`

#if it doesn't we ask prompt the user
if [ -z "$short_title" ]; then
#create a short title from user input
# IMPORTANT this requires Zenity to be installed!
short_title=$( zenity --entry \
	 --title="Enter filename" \
	 --text="Enter a slug:" \
	 --entry-text "new_title")

#get author from whoami
#replace with a user input form
author=`whoami`

else
#extract metadata from first file
title=`/usr/local/bin/multimarkdown "$1" --extract="Title"`
short_title=`/usr/local/bin/multimarkdown "$1" --extract="ShortTitle"`
author=`/usr/local/bin/multimarkdown "$1" --extract="Author"`


fi


#add a style sheet chooser but check first for it's existance in metadata
#zenity --file-selection --title="Select a CSS file"


fi

#### END METADATA SETTINGS############

#######################################
# PDF Options
#######################################
#select page size
# IMPORTANT this requires Zenity to be installed!
#pdf_page_size=$( zenity --entry \
#	 --title="Enter PDF page size" \
#	 --text="Enter page size:" \
#	 --entry-text "a4")

# Zenity form for PDF options
OUTPUT=$(zenity --forms \
	--title="PDF options" \
	--separator=","\
	--text="Enter PDF Options:" \
	--add-entry "Page size"  \
	--add-entry "Header Centre" \
	--add-entry "Header Left" \
	--add-entry "Header Right" \
	--add-entry "Footer Centre" \
	--add-entry "Footer Left" \
	--add-entry "Footer Right" \
)

pdf_page_size=$(awk -F, '{print $1}' <<<$OUTPUT)

## catch empty pdf_page_size
if [ -z "$pdf_page_size" ]; then
	#Default page style is A4
	#change to letter if you are a Yank
	pdf_page_size="a4"
fi


pdf_header_center=$(awk -F, '{print $2}' <<<$OUTPUT)
pdf_header_left=$(awk -F, '{print $3}' <<<$OUTPUT)
pdf_header_right=$(awk -F, '{print $4}' <<<$OUTPUT)
pdf_footer_center=$(awk -F, '{print $5}' <<<$OUTPUT)
pdf_footer_left=$(awk -F, '{print $6}' <<<$OUTPUT)
pdf_footer_right=$(awk -F, '{print $7}' <<<$OUTPUT)




######################################
#### BUILD
######################################

#build markdown
cat "$@" > "build/$short_title.md"

#build html with critic markup
/usr/local/bin/multimarkdown -a -r "build/$short_title.md" > "build/$short_title.html"

#build pdf with wkhtmltopdf with following options 
#See http://wkhtmltopdf.org/usage/wkhtmltopdf.txt for more information
/usr/local/bin/wkhtmltopdf \
	--print-media-type \
	-s $pdf_page_size \
	--header-center "$pdf_header_center" \
	--header-left "$pdf_header_left" \
	--header-right "$pdf_header_right" \
	--footer-center "$pdf_footer_center" \
	--footer-left "$pdf_footer_left" \
	--footer-right "$pdf_footer_right" \
	\ toc 
	"build/$short_title.html" "build/$short_title.pdf"

#build ePub 
#TBC
#

## Notify user
## Requires Zenity
printf "The following files were succefully built in $DIR/build/:\n $short_title.md \n $short_title.html \n $short_title.pdf" | zenity --title="Docs built!" --text-info


##### END BUILD #####################

#####################################
# Handle no args on command line
#####################################
else
	echo "Usage: `basename $0` <source md>"
fi
