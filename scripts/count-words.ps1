#!/usr/bin/env pwsh
# Counts words in the thesis chapter PROSE only.
#
# Excluded: figures/images and their captions, image-source credits, glossary
# imports, comments, labels (<...>), citations and cross-references (@...),
# and Typst markup. A #gls("x") / #glspl("x") call counts as the single
# abbreviation it renders in the text. Heading titles are counted as text.
#
# Scope: the numbered chapter files in chapters/ only (demo/ and frontmatter/
# are subfolders and are not touched).
#
# Usage:  pwsh scripts/count-words.ps1

param(
    [string]$ChaptersDir = (Join-Path $PSScriptRoot '..' 'chapters')
)

$ErrorActionPreference = 'Stop'

function Get-ProseWordCount {
    param([string[]]$Lines)

    $kept = New-Object System.Collections.Generic.List[string]
    $figDepth = 0

    foreach ($line in $Lines) {
        # inside a multi-line #figure(...) block: skip until parens balance
        if ($figDepth -gt 0) {
            $figDepth += ([regex]::Matches($line, '\(').Count - [regex]::Matches($line, '\)').Count)
            continue
        }

        # drop import lines and image-source credit lines outright
        if ($line -match '^\s*#import') { continue }

        $l = $line -replace '//.*$', ''            # strip line comments
        if ($l -match 'Image sources?:') { continue }

        # enter a figure block, keeping any prose before it on the same line
        $idx = $l.IndexOf('#figure(')
        if ($idx -ge 0) {
            $rest = $l.Substring($idx)
            $figDepth = ([regex]::Matches($rest, '\(').Count - [regex]::Matches($rest, '\)').Count)
            if ($figDepth -lt 0) { $figDepth = 0 }
            $l = $l.Substring(0, $idx)
        }

        $kept.Add($l)
    }

    $text = ($kept -join " `n ")

    # glossary term -> the single word it renders as
    $text = [regex]::Replace($text, '#gls(pl)?\("([^"]*)"\)', ' $2 ')
    # any remaining inline markup call name
    $text = [regex]::Replace($text, '#[A-Za-z][A-Za-z0-9_-]*', ' ')
    # labels and citations / cross-references
    $text = [regex]::Replace($text, '<[^>]+>', ' ')
    $text = [regex]::Replace($text, '@[A-Za-z0-9_:.\-]+', ' ')
    # heading markers, inline-code backticks, emphasis, brackets
    $text = [regex]::Replace($text, '(?m)^\s*=+\s*', ' ')
    $text = $text -replace '[`*_\[\]{}|]', ' '

    # word tokens: letters/digits with internal - / . '
    return [regex]::Matches($text, "[A-Za-z0-9](?:[A-Za-z0-9'./-]*[A-Za-z0-9])?").Count
}

$files = Get-ChildItem -Path $ChaptersDir -Filter '*.typ' -File | Sort-Object Name
$total = 0
foreach ($f in $files) {
    $n = Get-ProseWordCount -Lines (Get-Content -LiteralPath $f.FullName)
    $total += $n
    '{0,-38} {1,7}' -f $f.Name, $n
}
'{0,-38} {1,7}' -f ('-' * 5), ('-' * 7)
'{0,-38} {1,7}' -f 'TOTAL', $total
