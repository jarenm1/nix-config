{ ... }:
{
  services.gnome.gnome-keyring.enable = true;

  # Unlock the login keyring for both normal TTY and greetd logins.
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
}
