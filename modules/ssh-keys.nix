{
  # Extra keys on top of the owner's key from barecore.nix.
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGIMIOqtigXoU2PzXjSgcyJt+dbQfaKvmno0Ex9+F3lR keimoger@nixos"
    # CI deploys, private half is the SSH_PRIVKEY_INFRA secret.
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOpwpXOXWbuSiH42mSxjwaHmGbrI2qcXYXSbu//buJmL Gelioinfra"
  ];
}
