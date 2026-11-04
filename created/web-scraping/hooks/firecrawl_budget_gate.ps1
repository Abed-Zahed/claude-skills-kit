# firecrawl_budget_gate.ps1
# PreToolUse gate for mcp__firecrawl__* and the capped mcp__gemini__* research tools.
# Denies PDF and document URLs (billed per page), enforces an adaptive per-session
# and per-day Firecrawl credit budget, and enforces Gemini per-tool daily caps.
# Fails OPEN on any internal error (research must not brick) but logs the error.
#
# State and log live under the user profile, never inside a project folder.
# Test overrides: RESEARCH_STATE_PATH, RESEARCH_LOG_PATH.
# Budget identity: RESEARCH_BUDGET_KEY (set by a dispatcher so retries and verifier
# passes share a parent's budget), else session_id.
# RESEARCH_BASE overrides the base allowance (default 60 interactive, 25 scoped).

$ErrorActionPreference = 'Stop'
$ClaudeDir = Join-Path $env:USERPROFILE '.claude'
$StatePath = if ($env:RESEARCH_STATE_PATH) { $env:RESEARCH_STATE_PATH } else { Join-Path $ClaudeDir 'research_budget_state.json' }
$LogPath   = if ($env:RESEARCH_LOG_PATH)   { $env:RESEARCH_LOG_PATH }   else { Join-Path $ClaudeDir 'research_tool_log.jsonl' }
$CacheDir  = Join-Path $ClaudeDir 'research_cache'
$DayCeiling = 400
$SessionCeiling = 150
$GrantSize = 25
# Policy charges (not measured prices): tools whose Firecrawl pricing is dynamic or
# unverified are charged a fixed amount so they still consume budget. Reconcile
# periodically against the Firecrawl dashboard and adjust this table.
$PolicyCharge = @{ extract = 25; agent = 25; parse = 10 }
$NoCharge = @('agent_status','check_crawl_status','interact_stop','feedback','search_feedback',
              'monitor_list','monitor_get','monitor_checks','monitor_check','monitor_delete')
$GeminiBucket = @{
    'gemini-deep-research' = 'deep-research'; 'gemini-search' = 'search'
    'gemini-analyze-url' = 'url'; 'gemini-extract-from-url' = 'url'
    'gemini-summarize-pdf' = 'pdf'; 'gemini-analyze-document' = 'pdf'
    'gemini-youtube' = 'youtube'; 'gemini-youtube-summary' = 'youtube'
}
$FreeRoute = "Free route: WebSearch to find, WebFetch to read, Exa (web_search_exa / web_fetch_exa) for semantic search or a page fetch, and curl plus pypdf into $CacheDir for any PDF. See the web-scraping skill README."

try {
    foreach ($p in @($StatePath, $LogPath)) {
        $d = Split-Path -Parent $p
        if ($d -and -not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }
} catch { }

function Emit-Deny([string]$Reason) {
    $o = @{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'deny'; permissionDecisionReason = $Reason } }
    Write-Output ($o | ConvertTo-Json -Depth 5 -Compress)
}

function Write-Log($Entry) {
    try {
        if ((Test-Path $LogPath) -and ((Get-Item $LogPath).Length -gt 2MB)) {
            # Single-file rotation; upgrade to dated retention if the log matters more.
            Move-Item -Path $LogPath -Destination "$LogPath.old" -Force
        }
        # .NET calls, not -Encoding UTF8: Windows PowerShell 5.1 would write a BOM.
        [System.IO.File]::AppendAllText($LogPath, (($Entry | ConvertTo-Json -Compress) + "`n"), (New-Object System.Text.UTF8Encoding($false)))
    } catch { }
}

$mutex = $null; $held = $false
try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }
    $j = $raw | ConvertFrom-Json
    $toolName = [string]$j.tool_name
    $ti = $j.tool_input
    $isFc = $toolName -like 'mcp__firecrawl__*'
    $isGem = $toolName -like 'mcp__gemini__*'
    if (-not ($isFc -or $isGem)) { exit 0 }

    $key = if ($env:RESEARCH_BUDGET_KEY) { $env:RESEARCH_BUDGET_KEY } elseif ($j.session_id) { [string]$j.session_id } else { 'unknown' }
    # A scoped worker with no explicit base gets the cheap tier (25); interactive sessions get 60.
    $base = if ($env:RESEARCH_BUDGET_KEY) { 25 } else { 60 }
    if ($env:RESEARCH_BASE -match '^\d+$') { $base = [int]$env:RESEARCH_BASE }

    $urls = @()
    if ($ti) {
        if ($ti.url) { $urls += [string]$ti.url }
        if ($ti.urls) { $urls += @($ti.urls | ForEach-Object { [string]$_ }) }
    }
    $url = if ($urls.Count -gt 0) { $urls[0] } else { $null }

    $fcName = $toolName -replace '^mcp__firecrawl__firecrawl_', ''
    # 0. Pure-input denies, evaluated before any state or lock so they hold even if the mutex stalls.
    if ($isFc -and $ti -and ($ti.pdfOptions -or ($ti.parsers -and (@($ti.parsers) -contains 'pdf')))) {
        Write-Log @{ ts = (Get-Date).ToUniversalTime().ToString('o'); key = $key; tool = $toolName; url = $url; est = 0; decision = 'deny-pdf-options' }
        Emit-Deny "pdfOptions or a pdf parser signals a PDF scrape, which bills per PDF page and cannot be sized before the call. $FreeRoute"
        exit 0
    }
    if ($isFc -and $fcName -eq 'crawl' -and -not ($ti -and $ti.limit)) {
        Write-Log @{ ts = (Get-Date).ToUniversalTime().ToString('o'); key = $key; tool = $toolName; url = $url; est = 0; decision = 'deny-crawl-nolimit' }
        Emit-Deny 'firecrawl_crawl without an explicit limit is refused (it bills 1 credit per page crawled). Pass a small limit, or use map to list URLs (1 credit) and scrape only the ones you need.'
        exit 0
    }
    # 1. Document URLs are never paid-scraped, in ANY position of a url list. No state needed.
    #    Known hole: extensionless endpoints that serve a PDF cannot be seen before the call.
    if ($isFc) {
        foreach ($u in $urls) {
            if ($u -match '\.(pdf|ps|djvu|docx?|pptx?|epub)(\?|#|$)') {
                Write-Log @{ ts = (Get-Date).ToUniversalTime().ToString('o'); key = $key; tool = $toolName; url = $u; est = 0; decision = 'deny-document-url' }
                Emit-Deny "PDF or document URL ($u). Firecrawl bills per page, and a PDF is billed per PDF page. $FreeRoute The free path gives equivalent text for most documents."
                exit 0
            }
        }
    }

    Add-Type -AssemblyName System.Web.Extensions
    $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $ser.MaxJsonLength = 67108864

    $mutex = New-Object System.Threading.Mutex($false, 'Global\ResearchBudgetGate')
    try { $held = $mutex.WaitOne(3000) } catch [System.Threading.AbandonedMutexException] { $held = $true }
    if (-not $held) {
        # Never do an unlocked read-modify-write on the shared state file: lost updates
        # and tmp collisions would hide overspend. Fail open, loudly in the log.
        Write-Log @{ ts = (Get-Date).ToUniversalTime().ToString('o'); key = $key; tool = $toolName; url = $url; decision = 'fail-open'; error = 'mutex-timeout' }
        exit 0
    }

    $today = (Get-Date).ToString('yyyy-MM-dd')
    if (Test-Path $StatePath) { $state = $ser.DeserializeObject((Get-Content -Path $StatePath -Raw)) } else { $state = @{} }
    if (-not $state.ContainsKey('sessions')) { $state['sessions'] = @{} }
    if (-not $state.ContainsKey('gemini_caps')) { $state['gemini_caps'] = @{ 'deep-research' = 2; 'search' = 6; 'url' = 6; 'pdf' = 4; 'youtube' = 2 } }
    if (-not $state.ContainsKey('gemini_used')) { $state['gemini_used'] = @{} }
    if (-not $state.ContainsKey('day_credits')) { $state['day_credits'] = 0 }
    # A human may LOWER a ceiling by editing the file; a value above the built-in constant is ignored.
    $dayCeil = $DayCeiling; $sessCeil = $SessionCeiling
    if ($state.ContainsKey('day_ceiling') -and ([int]$state['day_ceiling'] -gt 0)) { $dayCeil = [Math]::Min($DayCeiling, [int]$state['day_ceiling']) }
    if ($state.ContainsKey('session_ceiling') -and ([int]$state['session_ceiling'] -gt 0)) { $sessCeil = [Math]::Min($SessionCeiling, [int]$state['session_ceiling']) }
    $state['day_ceiling'] = $dayCeil; $state['session_ceiling'] = $sessCeil
    if ($state['day'] -ne $today) { $state['day'] = $today; $state['day_credits'] = 0; $state['gemini_used'] = @{} }
    # prune sessions older than 14 days
    $cut = (Get-Date).ToUniversalTime().AddDays(-14)
    foreach ($k in @($state['sessions'].Keys)) {
        $st = $state['sessions'][$k]['started']
        if ($st -and ([datetime]::Parse($st).ToUniversalTime() -lt $cut)) { $state['sessions'].Remove($k) }
    }
    if (-not $state['sessions'].ContainsKey($key)) {
        $tier = if ($env:RESEARCH_BUDGET_KEY) { 'scoped' } else { 'default' }
        $state['sessions'][$key] = @{ tier = $tier; base = $base; grants = 0; spent = 0; calls = 0; started = (Get-Date).ToUniversalTime().ToString('o') }
    }
    $s = $state['sessions'][$key]

    $decision = 'allow'; $reason = $null; $est = 0

    if ($isGem) {
        $name = $toolName -replace '^mcp__gemini__', ''
        if ($GeminiBucket.ContainsKey($name)) {
            $b = $GeminiBucket[$name]
            $used = if ($state['gemini_used'].ContainsKey($b)) { [int]$state['gemini_used'][$b] } else { 0 }
            $cap = [int]$state['gemini_caps'][$b]
            if ($used -ge $cap) {
                $decision = 'deny-gemini-cap'
                $reason = "Gemini daily cap for '$b' reached ($used of $cap today). The caps are a configurable guess and a human can raise them. $FreeRoute"
            } else {
                $state['gemini_used'][$b] = $used + 1
            }
        }
    } else {
        $name = $toolName -replace '^mcp__firecrawl__firecrawl_', ''
        if ($NoCharge -contains $name) { $est = 0 }
        elseif ($name -eq 'crawl') {
            if ($ti -and $ti.limit) { $est = [int]$ti.limit } else { $decision = 'deny-crawl-nolimit'; $reason = 'firecrawl_crawl without an explicit limit is refused (it bills 1 credit per page crawled). Pass a small limit, or use map to list URLs (1 credit) and scrape only the ones you need.' }
        }
        elseif ($name -eq 'search') { $est = if ($ti -and $ti.limit) { [int]$ti.limit } else { 5 } }
        elseif ($name -eq 'scrape') {
            $est = 1
            $flat = if ($ti) { ($ti | ConvertTo-Json -Depth 6 -Compress) } else { '' }
            if ($flat -match '"json"|jsonOptions|"schema"') { $est += 4 }
        }
        elseif ($name -eq 'map') { $est = 1 }
        elseif ($name -eq 'interact') {
            # Schema: timeout is in seconds (max 300). Rates: 2 credits per session-minute
            # code only, 7 once a prompt is used. Default 2 minutes when no timeout is given.
            $mins = 2
            if ($ti -and $ti.timeout -and ([double]$ti.timeout -gt 0)) { $mins = [Math]::Ceiling([double]$ti.timeout / 60) }
            $rate = if ($ti -and $ti.prompt) { 7 } else { 2 }
            $est = [Math]::Max(4, [int]($mins * $rate))
        }
        elseif ($PolicyCharge.ContainsKey($name)) { $est = $PolicyCharge[$name] }
        else { $est = 25 }   # policy charge: a tool not in the budget table is treated as expensive

        if ($decision -eq 'allow' -and $est -gt 0) {
            $grants = [Math]::Min([int]$s['grants'], 3)
            $cap = [Math]::Min([int]$s['base'] + $GrantSize * $grants, $sessCeil)
            $left = $cap - [int]$s['spent']
            $dayLeft = $dayCeil - [int]$state['day_credits']
            if ($est -gt $left) {
                $decision = 'deny-session-budget'
                $reason = "Session Firecrawl budget: $($s['spent']) of $cap credits used, this call estimates $est. $FreeRoute A human must approve any top-up. Do not edit the budget state file."
            } elseif ($est -gt $dayLeft) {
                $decision = 'deny-day-ceiling'
                $reason = "Daily Firecrawl ceiling of $dayCeil credits reached ($($state['day_credits']) used today, this call estimates $est). $FreeRoute"
            } else {
                $s['spent'] = [int]$s['spent'] + $est
                $s['calls'] = [int]$s['calls'] + 1
                $state['day_credits'] = [int]$state['day_credits'] + $est
            }
        }
    }

    $tmp = "$StatePath.$PID.tmp"
    [System.IO.File]::WriteAllText($tmp, $ser.Serialize($state), (New-Object System.Text.UTF8Encoding($false)))
    Move-Item -Path $tmp -Destination $StatePath -Force

    Write-Log @{ ts = (Get-Date).ToUniversalTime().ToString('o'); key = $key; tool = $toolName; url = $url; est = $est; decision = $decision; spent = [int]$s['spent'] }
    if ($decision -ne 'allow') { Emit-Deny $reason }
    exit 0
} catch {
    Write-Log @{ ts = (Get-Date).ToUniversalTime().ToString('o'); tool = 'gate-error'; decision = 'fail-open'; error = "$_" }
    exit 0
} finally {
    if ($mutex -and $held) { try { $mutex.ReleaseMutex() } catch { } }
}
