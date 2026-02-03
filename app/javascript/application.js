// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("turbo:load", () => {
  const gSignInEl = document.querySelector(".g_id_signin");
  if (gSignInEl && window.google?.accounts?.id) {
    google.accounts.id.renderButton(gSignInEl, {
      type: "standard", size: "large", theme: "outline",
      text: "sign_in_with", shape: "rectangular", width: 400
    });
  }
});
