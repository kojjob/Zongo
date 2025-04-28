import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "provider",
    "phoneNumber",
    "amount",
    "quickAmount",
    "submitButton",
    "loadingIndicator",
    "errorMessage",
    "successMessage",
    "displayAmount",
    "feeAmount",
    "totalAmount",
    "selectedProvider",
    "selectedPhone",
    "recentContacts",
    "contactsList",
    "saveContact",
    "savedContactsContainer",
    "purchaseType",
    "airtimeSection",
    "dataSection",
    "dataPackage",
    "dataProvider",
    "dataAmount",
    "giftCheckbox",
    "recipientSection",
    "scheduleCheckbox",
    "scheduleSection",
    "scheduleFrequency",
    "scheduleDate",
    "promoCode",
    "promoApplyButton",
    "promoStatus",
    "discountAmount",
    "providerLogo"
  ]

  static values = {
    purchaseType: String,
    isGift: Boolean,
    isScheduled: Boolean,
    hasPromo: Boolean,
    discount: Number
  }

  connect() {
    console.log("Airtime controller connected")
    this.purchaseTypeValue = this.purchaseTypeValue || 'airtime'
    this.isGiftValue = false
    this.isScheduledValue = false
    this.hasPromoValue = false
    this.discountValue = 0

    this.initializeForm()
    this.loadSavedContacts()
    this.validateForm()
    this.initializePurchaseType()
    this.loadProviderLogos()
  }

  // Initialize the form with default values and event listeners
  initializeForm() {
    // Set up amount input listener
    if (this.hasAmountTarget) {
      this.amountTarget.addEventListener('input', this.updateAmounts.bind(this))
      this.amountTarget.addEventListener('change', this.validateForm.bind(this))
    }

    // Format phone number as user types
    if (this.hasPhoneNumberTarget) {
      this.phoneNumberTarget.addEventListener('input', this.formatPhoneNumber.bind(this))
      this.phoneNumberTarget.addEventListener('change', this.validateForm.bind(this))
    }

    // Initialize provider selection
    if (this.hasProviderTarget) {
      this.providerTargets.forEach(provider => {
        provider.addEventListener('change', this.handleProviderSelection.bind(this))
      })
    }

    // Initialize data provider selection
    if (this.hasDataProviderTarget) {
      this.dataProviderTargets.forEach(provider => {
        provider.addEventListener('change', this.handleProviderSelection.bind(this))
      })
    }

    // Initialize quick amount buttons
    if (this.hasQuickAmountTarget) {
      this.quickAmountTargets.forEach(button => {
        button.addEventListener('click', this.setQuickAmount.bind(this))
      })
    }

    // Initialize purchase type radio buttons
    if (this.hasPurchaseTypeTarget) {
      this.purchaseTypeTargets.forEach(radio => {
        radio.addEventListener('change', this.togglePurchaseType.bind(this))
      })
    }

    // Initialize gift checkbox
    if (this.hasGiftCheckboxTarget) {
      this.giftCheckboxTarget.addEventListener('change', this.toggleGiftOption.bind(this))
    }

    // Initialize schedule checkbox
    if (this.hasScheduleCheckboxTarget) {
      this.scheduleCheckboxTarget.addEventListener('change', this.toggleScheduleOption.bind(this))
    }

    // Add transition classes to collapsible sections
    if (this.hasRecipientSectionTarget) {
      this.recipientSectionTarget.classList.add('transition-all', 'duration-300', 'transform', 'scale-95', 'opacity-0')
    }

    if (this.hasScheduleSectionTarget) {
      this.scheduleSectionTarget.classList.add('transition-all', 'duration-300', 'transform', 'scale-95', 'opacity-0')
    }

    // Update amounts display
    this.updateAmounts()

    // Update selected provider and phone in summary
    this.updateSelectedProvider()
    this.updateSelectedPhone()
  }

  // Handle provider selection
  handleProviderSelection(event) {
    // Remove active class from all provider cards
    const providerCards = document.querySelectorAll('.provider-option .border-2')
    providerCards.forEach(card => {
      card.classList.remove('border-indigo-500', 'dark:border-indigo-400', 'shadow-md')

      // Reset all provider cards to default state
      const hoverBorderClass = card.closest('.provider-option').querySelector('input').dataset.hoverBorder || 'hover:border-indigo-300'
      card.className = card.className.replace(/hover:border-[a-z]+-\d+/g, hoverBorderClass)
    })

    // Add active class to selected provider card
    const selectedCard = event.target.closest('.provider-option').querySelector('.border-2')
    if (selectedCard) {
      // Add active class with indigo border regardless of provider color
      selectedCard.classList.add('border-indigo-500', 'dark:border-indigo-400', 'shadow-md')

      // Focus on phone number field after selecting provider
      if (this.hasPhoneNumberTarget) {
        setTimeout(() => {
          this.phoneNumberTarget.focus()
        }, 300)
      }
    }

    this.validateForm()
    this.updateSelectedProvider()
  }

  // Format phone number as user types (XXX XXX XXXX)
  formatPhoneNumber(event) {
    const input = event.target
    let value = input.value.replace(/\D/g, '')

    if (value.length > 0) {
      // Format as XXX XXX XXXX
      if (value.length <= 10) {
        const matches = value.match(/(\d{1,3})(\d{0,3})(\d{0,4})/)
        if (matches) {
          let formatted = matches[1]
          if (matches[2]) formatted += ' ' + matches[2]
          if (matches[3]) formatted += ' ' + matches[3]
          input.value = formatted
        }
      }
    }

    this.validateForm()
    this.updateSelectedPhone()
  }

  // Set amount from quick amount buttons
  setQuickAmount(event) {
    const amount = event.currentTarget.dataset.amount
    if (amount && this.hasAmountTarget) {
      this.amountTarget.value = amount

      // Add visual feedback to the clicked button
      this.quickAmountTargets.forEach(btn => {
        btn.classList.remove('bg-indigo-100', 'dark:bg-indigo-900/30', 'text-indigo-700', 'dark:text-indigo-300', 'border-indigo-300', 'shadow')
        btn.classList.add('bg-white', 'dark:bg-gray-800', 'text-indigo-700', 'dark:text-indigo-300', 'border-indigo-100', 'dark:border-indigo-800')
      })

      event.currentTarget.classList.remove('bg-white', 'dark:bg-gray-800', 'border-indigo-100', 'dark:border-indigo-800')
      event.currentTarget.classList.add('bg-indigo-100', 'dark:bg-indigo-900/30', 'text-indigo-700', 'dark:text-indigo-300', 'border-indigo-300', 'shadow')

      this.updateAmounts()
      this.validateForm()
    }
  }

  // Update amount displays
  updateAmounts() {
    // Get the amount based on purchase type
    let amount = 0
    if (this.purchaseTypeValue === 'airtime') {
      amount = parseFloat(this.amountTarget.value) || 0
    } else if (this.purchaseTypeValue === 'data' && this.hasDataAmountTarget) {
      amount = parseFloat(this.dataAmountTarget.value) || 0
    }

    // Calculate fee (1% fee with minimum of 0.5 GHS)
    const fee = Math.max(0.5, amount * 0.01)

    // Apply discount if promo code is valid
    let discount = 0
    if (this.hasPromoValue && this.discountValue > 0) {
      discount = amount * this.discountValue
    }

    // Calculate total
    const total = amount + fee - discount

    // Update display elements
    if (this.hasDisplayAmountTarget) {
      this.displayAmountTarget.textContent = `₵${amount.toFixed(2)}`
    }

    if (this.hasFeeAmountTarget) {
      this.feeAmountTarget.textContent = `₵${fee.toFixed(2)}`
    }

    if (this.hasDiscountAmountTarget && discount > 0) {
      this.discountAmountTarget.textContent = `-₵${discount.toFixed(2)}`
      this.discountAmountTarget.parentElement.classList.remove('hidden')
    } else if (this.hasDiscountAmountTarget) {
      this.discountAmountTarget.parentElement.classList.add('hidden')
    }

    if (this.hasTotalAmountTarget) {
      this.totalAmountTarget.textContent = `₵${total.toFixed(2)}`
    }
  }

  // Validate the form
  validateForm() {
    let isValid = false

    if (this.purchaseTypeValue === 'airtime') {
      // Validate airtime purchase
      const provider = document.querySelector('input[name="provider"]:checked')
      const phoneNumber = this.hasPhoneNumberTarget ? this.phoneNumberTarget.value.replace(/\s/g, '') : ''
      const amount = this.hasAmountTarget ? (parseFloat(this.amountTarget.value) || 0) : 0

      // Check if all required fields are filled for airtime
      isValid = provider && phoneNumber.length >= 10 && amount > 0

      // Additional validation for gift option
      if (this.isGiftValue && this.hasRecipientSectionTarget) {
        const recipientName = document.querySelector('input[name="recipient_name"]')?.value
        const recipientPhone = document.querySelector('input[name="recipient_phone"]')?.value?.replace(/\s/g, '')

        isValid = isValid && recipientName && recipientPhone && recipientPhone.length >= 10
      }
    } else if (this.purchaseTypeValue === 'data') {
      // Validate data purchase
      const dataProvider = document.querySelector('input[name="data_provider"]:checked')
      const phoneNumber = this.hasPhoneNumberTarget ? this.phoneNumberTarget.value.replace(/\s/g, '') : ''
      const dataPackage = document.querySelector('.data-package.border-purple-400')
      const dataAmount = this.hasDataAmountTarget ? (parseFloat(this.dataAmountTarget.value) || 0) : 0

      // Check if all required fields are filled for data
      isValid = dataProvider && phoneNumber.length >= 10 && dataPackage && dataAmount > 0

      // Additional validation for gift option
      if (this.isGiftValue && this.hasRecipientSectionTarget) {
        const recipientName = document.querySelector('input[name="recipient_name"]')?.value
        const recipientPhone = document.querySelector('input[name="recipient_phone"]')?.value?.replace(/\s/g, '')

        isValid = isValid && recipientName && recipientPhone && recipientPhone.length >= 10
      }
    }

    // Additional validation for scheduled option
    if (this.isScheduledValue && this.hasScheduleSectionTarget) {
      const scheduleFrequency = this.hasScheduleFrequencyTarget ? this.scheduleFrequencyTarget.value : ''
      const scheduleDate = this.hasScheduleDateTarget ? this.scheduleDateTarget.value : ''

      isValid = isValid && scheduleFrequency && scheduleDate
    }

    // Update submit button state
    if (this.hasSubmitButtonTarget) {
      if (isValid) {
        this.submitButtonTarget.removeAttribute('disabled')
        this.submitButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
        this.submitButtonTarget.classList.add('hover:shadow-2xl', 'transform', 'hover:-translate-y-1')
      } else {
        this.submitButtonTarget.setAttribute('disabled', 'disabled')
        this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
        this.submitButtonTarget.classList.remove('hover:shadow-2xl', 'transform', 'hover:-translate-y-1')
      }
    }

    // Update payment details in summary
    this.updateSelectedProvider()
    this.updateSelectedPhone()

    return isValid
  }

  // Update selected provider in summary
  updateSelectedProvider() {
    if (this.hasSelectedProviderTarget) {
      let provider

      if (this.purchaseTypeValue === 'airtime') {
        provider = document.querySelector('input[name="provider"]:checked')
      } else {
        provider = document.querySelector('input[name="data_provider"]:checked')
      }

      if (provider) {
        const providerLabel = document.querySelector(`label.provider-option input[value="${provider.value}"]`)
          .closest('.provider-option')
          .querySelector('span.font-bold')
          .textContent

        this.selectedProviderTarget.innerHTML = `
          <div class="w-5 h-5 rounded-full bg-indigo-100 dark:bg-indigo-900/30 flex items-center justify-center text-indigo-500 mr-2">
            <%= icon("globe", class: "w-3 h-3") %>
          </div>
          ${providerLabel}
        `
      } else {
        this.selectedProviderTarget.innerHTML = `
          <div class="w-5 h-5 rounded-full bg-indigo-100 dark:bg-indigo-900/30 flex items-center justify-center text-indigo-500 mr-2">
            <%= icon("globe", class: "w-3 h-3") %>
          </div>
          Not selected
        `
      }
    }
  }

  // Update selected phone in summary
  updateSelectedPhone() {
    if (this.hasSelectedPhoneTarget && this.hasPhoneNumberTarget) {
      const phoneNumber = this.phoneNumberTarget.value.trim()
      if (phoneNumber) {
        this.selectedPhoneTarget.innerHTML = `
          <div class="w-5 h-5 rounded-full bg-indigo-100 dark:bg-indigo-900/30 flex items-center justify-center text-indigo-500 mr-2">
            <%= icon("phone", class: "w-3 h-3") %>
          </div>
          ${phoneNumber}
        `
      } else {
        this.selectedPhoneTarget.innerHTML = `
          <div class="w-5 h-5 rounded-full bg-indigo-100 dark:bg-indigo-900/30 flex items-center justify-center text-indigo-500 mr-2">
            <%= icon("phone", class: "w-3 h-3") %>
          </div>
          Not entered
        `
      }
    }
  }

  // Submit the form
  submitForm(event) {
    if (!this.validateForm()) {
      event.preventDefault()

      // Show error message
      if (this.hasErrorMessageTarget) {
        this.errorMessageTarget.classList.remove('hidden')

        // Scroll to error message
        this.errorMessageTarget.scrollIntoView({ behavior: 'smooth', block: 'center' })

        // Hide error message after 5 seconds
        setTimeout(() => {
          this.errorMessageTarget.classList.add('hidden')
        }, 5000)
      }
    } else {
      // Add purchase type to form data
      const form = event.target.closest('form')

      // Add hidden field for purchase type if it doesn't exist
      if (!form.querySelector('input[name="purchase_type"]')) {
        const purchaseTypeInput = document.createElement('input')
        purchaseTypeInput.type = 'hidden'
        purchaseTypeInput.name = 'purchase_type'
        purchaseTypeInput.value = this.purchaseTypeValue
        form.appendChild(purchaseTypeInput)
      }

      // Add hidden field for gift option if it doesn't exist
      if (!form.querySelector('input[name="is_gift"]')) {
        const isGiftInput = document.createElement('input')
        isGiftInput.type = 'hidden'
        isGiftInput.name = 'is_gift'
        isGiftInput.value = this.isGiftValue
        form.appendChild(isGiftInput)
      }

      // Add hidden field for scheduled option if it doesn't exist
      if (!form.querySelector('input[name="is_scheduled"]')) {
        const isScheduledInput = document.createElement('input')
        isScheduledInput.type = 'hidden'
        isScheduledInput.name = 'is_scheduled'
        isScheduledInput.value = this.isScheduledValue
        form.appendChild(isScheduledInput)
      }

      // Add hidden field for promo code if it doesn't exist
      if (this.hasPromoValue && !form.querySelector('input[name="promo_code"]')) {
        const promoCodeInput = document.createElement('input')
        promoCodeInput.type = 'hidden'
        promoCodeInput.name = 'promo_code'
        promoCodeInput.value = this.hasPromoCodeTarget ? this.promoCodeTarget.value : ''
        form.appendChild(promoCodeInput)
      }

      // Add hidden field for discount if it doesn't exist
      if (this.hasPromoValue && !form.querySelector('input[name="discount"]')) {
        const discountInput = document.createElement('input')
        discountInput.type = 'hidden'
        discountInput.name = 'discount'
        discountInput.value = this.discountValue
        form.appendChild(discountInput)
      }

      // Show loading state
      if (this.hasSubmitButtonTarget && this.hasLoadingIndicatorTarget) {
        this.submitButtonTarget.classList.add('hidden')
        this.loadingIndicatorTarget.classList.remove('hidden')
      }
    }
  }

  // Save contact for future use
  saveContact(event) {
    if (this.hasPhoneNumberTarget) {
      const phoneNumber = this.phoneNumberTarget.value.trim()
      const provider = document.querySelector('input[name="provider"]:checked')?.value

      if (phoneNumber && provider) {
        // Get saved contacts from localStorage
        const savedContacts = JSON.parse(localStorage.getItem('savedAirtimeContacts') || '[]')

        // Check if contact already exists
        const existingContactIndex = savedContacts.findIndex(contact =>
          contact.phoneNumber === phoneNumber && contact.provider === provider
        )

        if (existingContactIndex === -1) {
          // Add new contact
          savedContacts.push({
            phoneNumber,
            provider,
            timestamp: new Date().toISOString()
          })

          // Save to localStorage
          localStorage.setItem('savedAirtimeContacts', JSON.stringify(savedContacts))

          // Show success message
          if (this.hasSuccessMessageTarget) {
            this.successMessageTarget.textContent = 'Contact saved successfully!'
            this.successMessageTarget.classList.remove('hidden')

            // Hide success message after 3 seconds
            setTimeout(() => {
              this.successMessageTarget.classList.add('hidden')
            }, 3000)
          }

          // Reload saved contacts
          this.loadSavedContacts()
        } else {
          // Show already exists message
          if (this.hasSuccessMessageTarget) {
            this.successMessageTarget.textContent = 'Contact already saved!'
            this.successMessageTarget.classList.remove('hidden')

            // Hide success message after 3 seconds
            setTimeout(() => {
              this.successMessageTarget.classList.add('hidden')
            }, 3000)
          }
        }
      }
    }
  }

  // Load saved contacts from localStorage
  loadSavedContacts() {
    if (this.hasContactsListTarget && this.hasSavedContactsContainerTarget) {
      const savedContacts = JSON.parse(localStorage.getItem('savedAirtimeContacts') || '[]')

      if (savedContacts.length > 0) {
        // Show saved contacts container
        this.savedContactsContainerTarget.classList.remove('hidden')

        // Clear existing contacts
        this.contactsListTarget.innerHTML = ''

        // Add contacts to the list (most recent first)
        savedContacts
          .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
          .slice(0, 5) // Show only the 5 most recent contacts
          .forEach(contact => {
            const contactElement = document.createElement('div')
            contactElement.className = 'flex items-center justify-between p-3 hover:bg-gray-50 dark:hover:bg-gray-750 rounded-lg cursor-pointer transition-colors'
            contactElement.dataset.phoneNumber = contact.phoneNumber
            contactElement.dataset.provider = contact.provider

            // Get provider name and icon
            let providerName = 'Unknown'
            let providerIcon = 'phone'

            switch (contact.provider) {
              case 'MTN':
                providerName = 'MTN'
                providerIcon = 'phone'
                break
              case 'VODAFONE':
                providerName = 'Vodafone'
                providerIcon = 'phone'
                break
              case 'AIRTELTIGO':
                providerName = 'AirtelTigo'
                providerIcon = 'phone'
                break
            }

            contactElement.innerHTML = `
              <div class="flex items-center">
                <div class="w-8 h-8 rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center text-green-600 dark:text-green-400 mr-3">
                  <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path>
                  </svg>
                </div>
                <div>
                  <p class="font-medium text-gray-900 dark:text-white">${contact.phoneNumber}</p>
                  <p class="text-xs text-gray-500 dark:text-gray-400">${providerName}</p>
                </div>
              </div>
              <button type="button" class="text-green-600 dark:text-green-400 hover:text-green-800 dark:hover:text-green-300" data-action="airtime#useContact">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <polyline points="9 11 12 14 22 4"></polyline>
                  <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path>
                </svg>
              </button>
            `

            this.contactsListTarget.appendChild(contactElement)
          })
      } else {
        // Hide saved contacts container if no contacts
        this.savedContactsContainerTarget.classList.add('hidden')
      }
    }
  }

  // Use a saved contact
  useContact(event) {
    const contactElement = event.currentTarget.closest('[data-phone-number]')
    if (contactElement) {
      const phoneNumber = contactElement.dataset.phoneNumber
      const provider = contactElement.dataset.provider

      // Set phone number
      if (this.hasPhoneNumberTarget) {
        // Format the phone number
        const formattedNumber = phoneNumber.replace(/(\d{3})(\d{3})(\d{4})/, '$1 $2 $3')
        this.phoneNumberTarget.value = formattedNumber
      }

      // Select provider
      const providerRadio = document.querySelector(`input[name="provider"][value="${provider}"]`)
      if (providerRadio) {
        providerRadio.checked = true

        // Trigger provider selection event
        const event = new Event('change')
        providerRadio.dispatchEvent(event)
      }

      // Focus on amount field
      if (this.hasAmountTarget) {
        setTimeout(() => {
          this.amountTarget.focus()
        }, 300)
      }

      // Validate form
      this.validateForm()
      this.updateSelectedPhone()
    }
  }

  // Show recent contacts dropdown
  showRecentContacts() {
    if (this.hasRecentContactsTarget) {
      this.recentContactsTarget.classList.toggle('hidden')
    }
  }

  // Initialize purchase type (airtime or data)
  initializePurchaseType() {
    if (this.hasPurchaseTypeTarget) {
      this.purchaseTypeTargets.forEach(radio => {
        radio.addEventListener('change', this.togglePurchaseType.bind(this))
      })
    }

    // Initialize with airtime selected by default
    this.togglePurchaseType({ target: { value: this.purchaseTypeValue } })
  }

  // Toggle between airtime and data purchase types
  togglePurchaseType(event) {
    const purchaseType = event.target.value || 'airtime'
    this.purchaseTypeValue = purchaseType

    // Update the UI based on purchase type
    if (this.hasAirtimeSectionTarget && this.hasDataSectionTarget) {
      if (purchaseType === 'airtime') {
        // Show airtime section with animation
        this.airtimeSectionTarget.classList.remove('hidden')
        this.dataSectionTarget.classList.add('hidden')

        // Update the active state of the purchase type cards
        const airtimeCard = document.querySelector('input[name="purchase_type"][value="airtime"]').closest('.group').querySelector('div')
        const dataCard = document.querySelector('input[name="purchase_type"][value="data"]').closest('.group').querySelector('div')

        airtimeCard.classList.add('border-indigo-500', 'dark:border-indigo-400', 'bg-indigo-50', 'dark:bg-indigo-900/10', 'shadow-md')
        dataCard.classList.remove('border-indigo-500', 'dark:border-indigo-400', 'bg-indigo-50', 'dark:bg-indigo-900/10', 'shadow-md')
      } else {
        // Show data section with animation
        this.airtimeSectionTarget.classList.add('hidden')
        this.dataSectionTarget.classList.remove('hidden')

        // Update the active state of the purchase type cards
        const airtimeCard = document.querySelector('input[name="purchase_type"][value="airtime"]').closest('.group').querySelector('div')
        const dataCard = document.querySelector('input[name="purchase_type"][value="data"]').closest('.group').querySelector('div')

        airtimeCard.classList.remove('border-indigo-500', 'dark:border-indigo-400', 'bg-indigo-50', 'dark:bg-indigo-900/10', 'shadow-md')
        dataCard.classList.add('border-indigo-500', 'dark:border-indigo-400', 'bg-indigo-50', 'dark:bg-indigo-900/10', 'shadow-md')
      }
    }

    this.validateForm()
  }

  // Load provider logos
  loadProviderLogos() {
    if (this.hasProviderLogoTarget) {
      // Map of provider values to their logo URLs
      const logoMap = {
        'MTN': '/assets/providers/mtn-logo.png',
        'VODAFONE': '/assets/providers/vodafone-logo.png',
        'AIRTELTIGO': '/assets/providers/airteltigo-logo.png'
      }

      // Set default logos
      this.providerLogoTargets.forEach(logo => {
        const provider = logo.dataset.provider
        if (provider && logoMap[provider]) {
          logo.src = logoMap[provider]
        }
      })
    }
  }

  // Toggle gift option
  toggleGiftOption() {
    if (this.hasGiftCheckboxTarget && this.hasRecipientSectionTarget) {
      this.isGiftValue = this.giftCheckboxTarget.checked

      if (this.isGiftValue) {
        // Show recipient section with animation
        this.recipientSectionTarget.classList.remove('hidden')
        setTimeout(() => {
          this.recipientSectionTarget.classList.add('transform', 'scale-100', 'opacity-100')
          this.recipientSectionTarget.classList.remove('scale-95', 'opacity-0')
        }, 10)
      } else {
        // Hide recipient section with animation
        this.recipientSectionTarget.classList.add('transform', 'scale-95', 'opacity-0')
        this.recipientSectionTarget.classList.remove('scale-100', 'opacity-100')
        setTimeout(() => {
          this.recipientSectionTarget.classList.add('hidden')
        }, 300)
      }

      this.validateForm()
    }
  }

  // Toggle scheduled recharge option
  toggleScheduleOption() {
    if (this.hasScheduleCheckboxTarget && this.hasScheduleSectionTarget) {
      this.isScheduledValue = this.scheduleCheckboxTarget.checked

      if (this.isScheduledValue) {
        // Show schedule section with animation
        this.scheduleSectionTarget.classList.remove('hidden')
        setTimeout(() => {
          this.scheduleSectionTarget.classList.add('transform', 'scale-100', 'opacity-100')
          this.scheduleSectionTarget.classList.remove('scale-95', 'opacity-0')
        }, 10)
      } else {
        // Hide schedule section with animation
        this.scheduleSectionTarget.classList.add('transform', 'scale-95', 'opacity-0')
        this.scheduleSectionTarget.classList.remove('scale-100', 'opacity-100')
        setTimeout(() => {
          this.scheduleSectionTarget.classList.add('hidden')
        }, 300)
      }

      this.validateForm()
    }
  }

  // Handle data package selection
  selectDataPackage(event) {
    if (this.hasDataPackageTarget && this.hasDataAmountTarget) {
      // Remove active class from all package cards
      this.dataPackageTargets.forEach(pkg => {
        pkg.classList.remove('border-purple-400', 'dark:border-purple-600', 'shadow-md', 'bg-purple-50', 'dark:bg-purple-900/10')
      })

      // Add active class to selected package
      const selectedPackage = event.currentTarget
      selectedPackage.classList.add('border-purple-400', 'dark:border-purple-600', 'shadow-md', 'bg-purple-50', 'dark:bg-purple-900/10')

      // Set the amount based on the selected package
      const amount = selectedPackage.dataset.amount
      if (amount && this.hasDataAmountTarget) {
        this.dataAmountTarget.value = amount
        this.updateAmounts()
      }

      this.validateForm()
    }
  }

  // Apply promo code
  applyPromoCode() {
    if (this.hasPromoCodeTarget && this.hasPromoStatusTarget && this.hasDiscountAmountTarget) {
      const promoCode = this.promoCodeTarget.value.trim().toUpperCase()

      if (!promoCode) {
        this.promoStatusTarget.textContent = 'Please enter a promo code'
        this.promoStatusTarget.classList.remove('text-green-600', 'dark:text-green-400')
        this.promoStatusTarget.classList.add('text-red-600', 'dark:text-red-400')
        this.hasPromoValue = false
        this.discountValue = 0
        this.updateAmounts()
        return
      }

      // Simulate promo code validation (in a real app, this would be an API call)
      const validPromoCodes = {
        'WELCOME10': { discount: 0.1, message: '10% discount applied!' },
        'BONUS20': { discount: 0.2, message: '20% discount applied!' },
        'FREEBIES': { discount: 0.05, message: '5% discount applied!' }
      }

      if (validPromoCodes[promoCode]) {
        // Valid promo code
        this.hasPromoValue = true
        this.discountValue = validPromoCodes[promoCode].discount
        this.promoStatusTarget.textContent = validPromoCodes[promoCode].message
        this.promoStatusTarget.classList.remove('text-red-600', 'dark:text-red-400')
        this.promoStatusTarget.classList.add('text-green-600', 'dark:text-green-400')

        // Add visual feedback
        this.promoCodeTarget.classList.add('ring-2', 'ring-green-500', 'border-green-300')

        // Show the discount row
        if (this.hasDiscountAmountTarget) {
          this.discountAmountTarget.parentElement.classList.remove('hidden')
        }

        setTimeout(() => {
          this.promoCodeTarget.classList.remove('ring-2', 'ring-green-500', 'border-green-300')
        }, 2000)
      } else {
        // Invalid promo code
        this.hasPromoValue = false
        this.discountValue = 0
        this.promoStatusTarget.textContent = 'Invalid promo code'
        this.promoStatusTarget.classList.remove('text-green-600', 'dark:text-green-400')
        this.promoStatusTarget.classList.add('text-red-600', 'dark:text-red-400')

        // Add visual feedback
        this.promoCodeTarget.classList.add('ring-2', 'ring-red-500', 'border-red-300')

        // Hide the discount row
        if (this.hasDiscountAmountTarget) {
          this.discountAmountTarget.parentElement.classList.add('hidden')
        }

        setTimeout(() => {
          this.promoCodeTarget.classList.remove('ring-2', 'ring-red-500', 'border-red-300')
        }, 2000)
      }

      this.updateAmounts()
    }
  }
}
