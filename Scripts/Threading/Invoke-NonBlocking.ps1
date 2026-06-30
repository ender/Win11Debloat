# Runs a scriptblock in a background PowerShell runspace, optionally with a timeout.
function Invoke-NonBlocking {
    param(
        [scriptblock]$ScriptBlock,
        [object[]]$ArgumentList = @(),
        [int]$TimeoutSeconds = 0
    )

    # No timeout: run directly in-process
    if ($TimeoutSeconds -eq 0) {
        return (& $ScriptBlock @ArgumentList)
    }

    $ps = [powershell]::Create()
    try {
        $null = $ps.AddScript($ScriptBlock.ToString())
        foreach ($arg in $ArgumentList) {
            $null = $ps.AddArgument($arg)
        }

        $handle = $ps.BeginInvoke()

        if (-not $handle.AsyncWaitHandle.WaitOne($TimeoutSeconds * 1000)) {
            $ps.Stop()
            throw "Operation timed out after $TimeoutSeconds seconds"
        }

        $result = $ps.EndInvoke($handle)

        # Surface non-terminating errors raised inside the runspace so failures
        # (e.g. failed app removals) don't fail silently - the runspace keeps its own error
        # stream that is otherwise discarded on Dispose.
        if ($ps.HadErrors) {
            foreach ($runspaceError in $ps.Streams.Error) {
                Write-Error -ErrorRecord $runspaceError
            }
        }

        if ($result.Count -eq 0) { return $null }
        if ($result.Count -eq 1) { return $result[0] }
        return @($result)
    }
    finally {
        $ps.Dispose()
    }
}
