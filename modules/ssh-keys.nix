{
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIKIABDEIeccdbZwTgxhkVUIyZa8fx9uyiE0I2S9t4x1 cab404@meow2"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGIMIOqtigXoU2PzXjSgcyJt+dbQfaKvmno0Ex9+F3lR keimoger@nixos"
    # CI deploys, private half is the SSH_PRIVKEY_INFRA secret.
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOpwpXOXWbuSiH42mSxjwaHmGbrI2qcXYXSbu//buJmL Gelioinfra"
  ];
}
