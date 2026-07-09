import { Controller } from "@hotwired/stimulus"

// Generic single-image upload widget: a hidden native file input driven by explicit
// "Choose a photo" / "Take a photo" buttons, client-side preview of the staged file,
// and a hidden remove flag so an existing upload can be cleared on save.
// (plant_graphic_controller has its own copy of this flow, coupled to the graphics library.)
export default class extends Controller {
  static targets = ["fileInput", "preview", "currentImage", "removeFlag", "removeButton", "cameraButton"]

  connect() {
    // "Take a photo" only makes sense on devices with a camera (touch/mobile);
    // on desktop the capture attribute is ignored, so hide the redundant button.
    if (this.hasCameraButtonTarget && !window.matchMedia("(pointer: coarse)").matches) {
      this.cameraButtonTarget.style.display = "none"
    }
  }

  // Open the regular file picker (gallery / file browser).
  chooseFile() {
    this.fileInputTarget.removeAttribute("capture")
    this.fileInputTarget.click()
  }

  // Open the device camera directly to take a new photo.
  takePhoto() {
    this.fileInputTarget.setAttribute("capture", "environment")
    this.fileInputTarget.click()
  }

  // Show a client-side preview of the chosen file before upload.
  filePreview() {
    const file = this.fileInputTarget.files && this.fileInputTarget.files[0]
    if (!file) {
      this.previewTarget.style.display = "none"
      return
    }

    // A newly staged file supersedes any pending removal of the old one.
    if (this.hasRemoveFlagTarget) this.removeFlagTarget.value = "0"
    if (this.hasCurrentImageTarget) this.currentImageTarget.style.display = "none"

    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewTarget.src = e.target.result
      this.previewTarget.style.display = "block"
    }
    reader.readAsDataURL(file)
  }

  // Mark the stored image for removal on save and clear any staged file.
  remove() {
    if (this.hasRemoveFlagTarget) this.removeFlagTarget.value = "1"
    if (this.hasCurrentImageTarget) this.currentImageTarget.style.display = "none"
    if (this.hasRemoveButtonTarget) this.removeButtonTarget.style.display = "none"
    this.fileInputTarget.value = ""
    this.previewTarget.style.display = "none"
    this.previewTarget.removeAttribute("src")
  }
}
