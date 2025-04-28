// file_upload_controller.js
  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    static targets = [
      "dropZone", "input", "placeholder", "preview", "fileName", "fileSize", 
      "progress", "progressBar", "progressText", "errorText", "multipleFilesContainer",
      "currentAttachment", "removeCheckbox"
    ]
    
    static values = {
      maxSize: Number
    }
    
    connect() {
      this.maxSizeBytes = this.maxSizeValue * 1024 * 1024 // Convert MB to bytes
    }
    
    triggerFileInput(event) {
      event.preventDefault()
      this.inputTarget.click()
    }
    
    onDragOver(event) {
      event.preventDefault()
      this.dropZoneTarget.classList.add('border-primary-500', 'bg-primary-50', 'dark:bg-primary-900/20')
    }
    
    onDragLeave(event) {
      event.preventDefault()
      this.dropZoneTarget.classList.remove('border-primary-500', 'bg-primary-50', 'dark:bg-primary-900/20')
    }
    
    onDrop(event) {
      event.preventDefault()
      this.dropZoneTarget.classList.remove('border-primary-500', 'bg-primary-50', 'dark:bg-primary-900/20')
      
      const files = event.dataTransfer.files
      if (files.length > 0) {
        this.inputTarget.files = files
        this.onFileSelected()
      }
    }
    
    onFileSelected() {
      const files = this.inputTarget.files
      
      if (files.length === 0) {
        this.resetFileInput()
        return
      }
      
      // Check file size
      let isValid = true
      for (let i = 0; i < files.length; i++) {
        if (files[i].size > this.maxSizeBytes) {
          isValid = false
          if (this.hasErrorTextTarget) {
            this.errorTextTarget.textContent = `File is too large. Maximum size is ${this.maxSizeValue} MB.`
            this.errorTextTarget.classList.remove('hidden')
          }
          break
        }
      }
      
      if (!isValid) {
        this.resetFileInput()
        return
      }
      
      // Hide current attachment if present
      if (this.hasCurrentAttachmentTarget) {
        this.currentAttachmentTarget.classList.add('hidden')
      }
      
      // Show file preview
      this.placeholderTarget.classList.add('hidden')
      this.previewTarget.classList.remove('hidden')
      
      if (this.inputTarget.multiple) {
        // Multiple files
        this.renderMultipleFilesPreview(files)
      } else {
        // Single file
        const file = files[0]
        this.fileNameTarget.textContent = file.name
        this.fileSizeTarget.textContent = this.formatFileSize(file.size)
      }
      
      // Simulate upload progress for demo purposes
      this.simulateUploadProgress()
    }
    
    renderMultipleFilesPreview(files) {
      if (!this.hasMultipleFilesContainerTarget) return
      
      this.multipleFilesContainerTarget.innerHTML = ''
      
      for (let i = 0; i < files.length; i++) {
        const file = files[i]
        const fileItem = document.createElement('div')
        fileItem.className = 'flex items-center justify-between p-2 bg-white dark:bg-gray-800 rounded-lg shadow-sm'
        fileItem.innerHTML = `
          <div class="flex items-center">
            <div class="flex-shrink-0 w-10 h-10 flex items-center justify-center bg-primary-100 dark:bg-primary-900/30 rounded-lg">
              <svg class="w-5 h-5 text-primary-600 dark:text-primary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
              </svg>
            </div>
            <div class="ml-3 truncate">
              <p class="text-sm font-medium text-gray-900 dark:text-white truncate">${file.name}</p>
              <p class="text-xs text-gray-500 dark:text-gray-400">${this.formatFileSize(file.size)}</p>
            </div>
          </div>
          <button 
            type="button" 
            class="ml-2 flex-shrink-0 text-gray-400 dark:text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
            data-action="click->file-upload#removeFileAt"
            data-index="${i}">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
          </button>
        `
        this.multipleFilesContainerTarget.appendChild(fileItem)
      }
    }
    
    removeFile(event) {
      event.preventDefault()
      this.resetFileInput()
    }
    
    removeFileAt(event) {
      event.preventDefault()
      const index = parseInt(event.currentTarget.dataset.index)
      
      // Convert FileList to Array
      const files = Array.from(this.inputTarget.files)
      files.splice(index, 1)
      
      // Create a new FileList-like object
      const dataTransfer = new DataTransfer()
      files.forEach(file => dataTransfer.items.add(file))
      
      this.inputTarget.files = dataTransfer.files
      this.onFileSelected()
    }
    
    removeCurrentFile(event) {
      event.preventDefault()
      if (this.hasRemoveCheckboxTarget) {
        this.removeCheckboxTarget.checked = true
      }
      if (this.hasCurrentAttachmentTarget) {
        this.currentAttachmentTarget.classList.add('hidden')
      }
    }
    
    resetFileInput() {
      this.inputTarget.value = ''
      this.placeholderTarget.classList.remove('hidden')
      this.previewTarget.classList.add('hidden')
      this.progressTarget.classList.add('hidden')
      
      if (this.hasErrorTextTarget) {
        this.errorTextTarget.classList.add('hidden')
      }
      
      if (this.hasCurrentAttachmentTarget) {
        this.currentAttachmentTarget.classList.remove('hidden')
      }
      if (this.hasRemoveCheckboxTarget) {
        this.removeCheckboxTarget.checked = false
      }
    }
    
    simulateUploadProgress() {
      // Simulate upload progress for demo purposes
      this.progressTarget.classList.remove('hidden')
      this.progressBarTarget.style.width = '0%'
      this.progressTextTarget.textContent = '0%'
      
      let progress = 0
      const interval = setInterval(() => {
        progress += 5
        this.progressBarTarget.style.width = `${progress}%`
        this.progressTextTarget.textContent = `${progress}%`
        
        if (progress >= 100) {
          clearInterval(interval)
          setTimeout(() => {
            this.progressTarget.classList.add('hidden')
          }, 500)
        }
      }, 100)
    }
    
    formatFileSize(bytes) {
      if (bytes === 0) return '0 Bytes'
      
      const k = 1024
      const sizes = ['Bytes', 'KB', 'MB', 'GB']
      const i = Math.floor(Math.log(bytes) / Math.log(k))
      
      return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
    }
  }