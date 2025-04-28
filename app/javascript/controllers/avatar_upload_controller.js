import { Controller } from "@hotwired/stimulus"

// Controller for handling avatar uploads with preview and progress indication
export default class extends Controller {
  static targets = ["input", "currentAvatar", "placeholderAvatar", "previewContainer", "preview", "uploadIcon", "loadingIcon", "progressText"]

  connect() {
    console.log("AvatarUploadController connected");
  }

  // Preview the selected image before upload
  previewImage(event) {
    const input = event.target;

    if (input.files && input.files[0]) {
      const file = input.files[0];

      // Check file size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        alert("File size exceeds 5MB. Please choose a smaller image.");
        input.value = "";
        return;
      }

      const reader = new FileReader();

      reader.onload = (e) => {
        // Set the preview image source
        this.previewTarget.src = e.target.result;

        // Show the preview container
        this.previewContainerTarget.classList.remove("hidden");

        // Hide the current avatar or placeholder if they exist
        if (this.hasCurrentAvatarTarget) {
          this.currentAvatarTarget.classList.add("hidden");
        }

        if (this.hasPlaceholderAvatarTarget) {
          this.placeholderAvatarTarget.classList.add("hidden");
        }
      };

      reader.readAsDataURL(file);
    }
  }

  // Called when direct upload is initialized
  beginUpload(event) {
    console.log("Upload started");

    // Show loading state
    this.uploadIconTarget.classList.add("hidden");
    this.loadingIconTarget.classList.remove("hidden");

    // Initialize progress text
    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = "Starting upload...";
      this.progressTextTarget.classList.remove("hidden");
    }
  }

  // Called during direct upload progress
  uploadProgress(event) {
    const { progress } = event.detail;
    const percentage = Math.floor(progress);

    console.log(`Upload progress: ${percentage}%`);

    // Update progress text
    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = `Uploading: ${percentage}%`;
    }
  }

  // Called when direct upload encounters an error
  uploadError(event) {
    const { error } = event.detail;
    console.error("Upload error:", error);

    // Show error state
    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = `Error: ${error}`;
      this.progressTextTarget.classList.add("text-red-600");
      this.progressTextTarget.classList.remove("text-primary-600");
      this.progressTextTarget.classList.remove("hidden");
    }

    // Reset UI
    this.uploadIconTarget.classList.remove("hidden");
    this.loadingIconTarget.classList.add("hidden");

    // Reset the file input
    if (this.hasInputTarget) {
      this.inputTarget.value = "";
    }

    // Hide the preview
    if (this.hasPreviewContainerTarget) {
      this.previewContainerTarget.classList.add("hidden");
    }

    // Show the original avatar or placeholder
    if (this.hasCurrentAvatarTarget) {
      this.currentAvatarTarget.classList.remove("hidden");
    }

    if (this.hasPlaceholderAvatarTarget && !this.hasCurrentAvatarTarget) {
      this.placeholderAvatarTarget.classList.remove("hidden");
    }
  }

  // Called when direct upload ends
  uploadEnd(event) {
    console.log("Upload ended");

    // Update progress text
    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = "Upload complete! Saving changes...";
    }

    // Keep loading state until form submission completes
  }
}
