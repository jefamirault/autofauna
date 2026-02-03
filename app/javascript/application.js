// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

function renderGoogleButton() {
  const gSignInEl = document.querySelector(".g_id_signin");
  const gIdOnload = document.querySelector("#g_id_onload");

  if (gSignInEl && gIdOnload && window.google?.accounts?.id) {
    // Initialize with config from the data attributes (required for Turbo navigation)
    google.accounts.id.initialize({
      client_id: gIdOnload.dataset.client_id,
      login_uri: gIdOnload.dataset.login_uri,
      ux_mode: "redirect",
      auto_select: gIdOnload.dataset.auto_prompt !== "false"
    });

    google.accounts.id.renderButton(gSignInEl, {
      type: "standard", size: "large", theme: "outline",
      text: "sign_in_with", shape: "rectangular", width: 400
    });
  }
}

// Render on Turbo navigation (library already loaded)
document.addEventListener("turbo:load", renderGoogleButton);

// Render when Google library finishes loading
window.addEventListener("google-loaded", renderGoogleButton);

// Handle case where Google loaded before this script
if (window.googleLoaded) {
  renderGoogleButton();
}
