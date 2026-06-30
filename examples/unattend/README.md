# Unattended Sysprep / Audit Mode example

[`autounattend.xml`](./autounattend.xml) shows how to wire Win11Debloat into a
Windows answer file so it runs automatically during image preparation,
**before** `sysprep /generalize /oobe` seals the image. This is the intended
way to run this fork: once, against the Default user profile hive, from the
built-in Administrator account, so every user account created after the
sealed image is deployed inherits the applied tweaks.

## How it works

1. The `oobeSystem` pass sets `<Reseal><Mode>Audit</Mode></Reseal>`, which
   tells Windows Setup to boot into **Audit Mode** (signed in as the
   built-in Administrator) instead of showing the normal OOBE screens once
   the initial install finishes.
2. The `auditUser` pass runs three `RunSynchronousCommand` entries, in
   order, on that audit-mode desktop:
   1. Relaxes the PowerShell execution policy for that one process.
   2. Downloads (or runs a pre-staged copy of) Win11Debloat with `-Silent`
      and `-Config` pointing at a JSON config file (see
      [`examples/config-samples`](../config-samples)).
   3. Runs `sysprep /generalize /oobe /shutdown` to seal the image and shut
      the VM/machine down, ready to be captured.

Win11Debloat mounts `C:\Users\Default\NTUSER.DAT` for the duration of the
run and applies every tweak there, then unmounts it before the script
exits. The built-in Administrator's own profile is never touched, it's only
the execution context.

## Staging the script and config file

The sample command in `autounattend.xml` downloads Win11Debloat from GitHub
at audit-mode runtime, which requires the machine to have internet access at
that point. It also assumes a config file already exists on disk at
`C:\Win11Debloat\examples\config-samples\full-debloat.json`, since
`-Config` needs a local file, the downloaded copy is extracted to a temp
folder and cleaned up after the run.

To get a config file (or even the whole repo, for fully offline operation)
onto the image before audit mode runs, add it to your installation media
under the `$OEM$` folder structure, for example:

```
sources\$OEM$\$1\Win11Debloat\...
```

Everything under `$OEM$\$1\` is copied to the root of the system drive
(`C:\`) by Windows Setup during the `specialize` pass, before `auditSystem`/
`auditUser` commands run. Rebuild your installation ISO with this structure
included (e.g. via `oscdimg`, an MDT/WDS share, or your imaging tool of
choice) and the staged files will be available at `C:\Win11Debloat\...` by
the time the commands in this answer file execute.

For a fully offline run, replace the `irm`-based command in
`autounattend.xml` with a direct call to the staged script instead:

```cmd
cmd /c powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Win11Debloat\Win11Debloat.ps1" -Silent -Config "C:\Win11Debloat\examples\config-samples\full-debloat.json"
```

## Merging into a real answer file

This file only contains the audit-mode automation relevant to
Win11Debloat. A complete autounattend.xml for an unattended install also
needs `windowsPE`/`specialize` settings for things like disk partitioning,
product key, locale and the local administrator password — merge the
`oobeSystem` and `auditUser` settings above into your existing answer file
rather than using this one standalone.

## Other ways to enter Audit Mode

If you don't control the answer file (e.g. you're prepping a reference VM
by hand), you can skip the `Reseal`/`oobeSystem` setting above and instead
press **Ctrl+Shift+F3** on the very first OOBE screen after installation —
this drops the machine into the exact same Audit Mode/built-in
Administrator session. From there you can run Win11Debloat manually exactly
as you would via the commands in `auditUser` above, then run
`sysprep /generalize /oobe /shutdown` yourself when finished.
