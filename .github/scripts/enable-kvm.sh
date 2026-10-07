#!/usr/bin/env bash
set -euo pipefail

mkdir -p reports
exec > >(tee reports/kvm-setup.log) 2>&1

echo "Runner image: ${ImageOS:-unknown}"
echo "Image version: ${ImageVersion:-unknown}"
uname -a
id
ls -l /dev/kvm || true

# Keep permissions when udev processes another event for the device.
echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"' \
  | sudo tee /etc/udev/rules.d/99-kvm4all.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --name-match=kvm
sudo udevadm settle --timeout=5 || echo '::warning::udev did not settle within 5 seconds; checking KVM directly'

for attempt in {1..10}; do
  if [[ -c /dev/kvm ]]; then
    if sudo chmod 666 /dev/kvm && [[ -r /dev/kvm && -w /dev/kvm ]]; then
      echo 'KVM is available, readable and writable'
      ls -l /dev/kvm
      exit 0
    fi
  fi
  echo "Waiting for KVM device and permissions ($attempt/10)"
  if [[ "$attempt" -lt 10 ]]; then sleep 1; fi
done

if [[ ! -c /dev/kvm ]]; then
  echo '::error::KVM character device /dev/kvm is unavailable on this runner'
else
  echo '::error::/dev/kvm exists but is not readable/writable'
fi
ls -l /dev/kvm || true
stat /dev/kvm || true
if command -v getfacl >/dev/null 2>&1; then getfacl /dev/kvm || true; fi
exit 1
