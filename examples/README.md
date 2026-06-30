# Examples

Example use cases for running this fork of Win11Debloat as part of a Windows
image-build pipeline. Every example follows the same workflow this fork is
built for: run the script once, from the built-in Administrator account in
Audit Mode, before `sysprep /generalize /oobe` seals the image, so every
user account created after that applies the tweaks automatically (they're
baked into `C:\Users\Default\NTUSER.DAT`, not the Administrator's own
profile).

- [`config-samples/`](./config-samples) — Sample `-Config` JSON files
  (`minimal-debloat.json`, `full-debloat.json`) covering a light privacy-only
  pass and a fuller app-removal + tweaks pass. Use these as a starting point
  for your own config, or pass one directly with `-Config`.
- [`unattend/`](./unattend) — An `autounattend.xml` snippet showing how to
  enter Audit Mode and run Win11Debloat automatically via answer-file
  `RunSynchronousCommand` entries, with notes on staging the script/config
  onto the image via `$OEM$`.
- [`ansible/`](./ansible) — An Ansible playbook that copies the repo to a
  target VM over WinRM, runs Win11Debloat with a chosen config, and triggers
  sysprep, for pipelines that orchestrate image builds with Ansible (e.g.
  alongside Packer).

See the main [README](../README.md#usage) for the full list of command-line
parameters and the `-Config` file format.
