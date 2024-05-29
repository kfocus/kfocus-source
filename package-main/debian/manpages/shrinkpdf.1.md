% SHRINKPDF(1) shrinkpdf 24.04
% Copyright (c) 2014, Alfred Klomp
% Revised March 2021, May 2024

# NAME
shrinkpdf - Reduces PDF filesize by lossy recompressing with Ghostscript.

# SYNOPSIS
**shrinkpdf**

# DESCRIPTION
Reduce a PDF file size through lossy recompressing with Ghostscript.
If the file size is not reduced, then a straight copy is done if both
inputs are files. Default DPI is 72.

# USAGE
kfocus-shrinkpdf [-d DPI] INFILE [OUTFILE]

