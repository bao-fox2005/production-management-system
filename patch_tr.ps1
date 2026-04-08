$content = Get-Content 'web\listRoutingStep.jsp' -Raw
$old = 'class="border-b border-slate-50 dark:border-slate-800 last:border-0 hover:bg-slate-50 dark:hover:bg-slate-800/60 transition-colors">'
$new = 'class="border-b border-slate-50 dark:border-slate-800 last:border-0 hover:bg-slate-50 dark:hover:bg-slate-800/60 transition-colors"' + "`r`n" + '                                         data-estimated-time="<%= s.getEstimatedTime() %>"' + "`r`n" + '                                         data-is-inspected="<%= s.isIsInspected() %>">'
$content = $content -replace [regex]::Escape($old), $new
Set-Content 'web\listRoutingStep.jsp' -Value $content -NoNewline -Encoding UTF8
Write-Host "Done"
