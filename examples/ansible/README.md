# Ansible example

[`playbook.yml`](./playbook.yml) shows how to drive Win11Debloat from Ansible
as one step of a golden-image build pipeline, rather than running it by hand.
This fits the common "VM template + Packer/Ansible" pattern: bring up a VM,
install Windows, boot it into Audit Mode (signed in as the built-in
Administrator), then have Ansible copy in and run Win11Debloat before
sysprep seals the image for capture.

This is **not** meant to be run against a fleet of live/production machines.
Win11Debloat only ever touches the Default user profile hive, and is
designed to run exactly once per image, before that image is generalized.

## Requirements

- The `ansible.windows` collection on the control node: `ansible-galaxy collection install ansible.windows`
- A target host already reachable over WinRM, signed in to (or otherwise
  able to run commands as) the built-in Administrator account in Audit
  Mode. Most pipelines enable WinRM via a `specialize`-pass command in
  their answer file (see [`../unattend`](../unattend)) or via the imaging
  tool itself (e.g. Packer's `winrm` communicator).

## Usage

1. Copy `inventory.ini` and fill in your target host's address and
   credentials (ideally via `ansible-vault` rather than plain text, see the
   comment in the file).
2. Adjust `win11debloat_config` in `playbook.yml` if you want to use a
   different config file from [`../config-samples`](../config-samples), or
   point it at your own.
3. Run:

   ```sh
   ansible-playbook -i inventory.ini playbook.yml
   ```

## What the playbook does

1. Copies this repository to `C:\Win11Debloat` on the target.
2. Relaxes the PowerShell execution policy for the run.
3. Runs `Win11Debloat.ps1 -Silent -Config <path>`, which mounts
   `C:\Users\Default\NTUSER.DAT`, applies every tweak/app-removal in the
   config file to that hive, and unmounts it again.
4. Runs `sysprep /generalize /oobe /shutdown` to seal the image and power
   the machine off.

The WinRM connection drops as soon as the machine shuts down in the last
step, so that task is fired without Ansible waiting on its result. Whatever
orchestrates this playbook (Packer, a hypervisor API call, a CI pipeline) is
responsible for detecting the power-off and capturing the resulting disk
image.
