  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    static targets = [
      "phoneInput", "countryButton", "countryDropdown", "countryFlag", 
      "countryCode", "countryCodeInput", "countrySearch", "countriesList"
    ]
    
    static values = {
      defaultCountry: String
    }
    
    connect() {
      this.loadCountries()
      
      // Close dropdown when clicking outside
      document.addEventListener('click', this.handleOutsideClick.bind(this))
    }
    
    disconnect() {
      document.removeEventListener('click', this.handleOutsideClick.bind(this))
    }
    
    handleOutsideClick(event) {
      if (this.hasCountryDropdownTarget && 
          !this.element.contains(event.target) &&
          this.countryDropdownTarget.classList.contains('block')) {
        this.hideCountryDropdown()
      }
    }
    
    toggleCountrySelect(event) {
      event.preventDefault()
      event.stopPropagation()
      
      if (this.countryDropdownTarget.classList.contains('hidden')) {
        this.showCountryDropdown()
      } else {
        this.hideCountryDropdown()
      }
    }
    
    showCountryDropdown() {
      this.countryDropdownTarget.classList.remove('hidden', 'opacity-0', 'scale-95')
      this.countryDropdownTarget.classList.add('block', 'opacity-100', 'scale-100')
      
      if (this.hasCountrySearchTarget) {
        this.countrySearchTarget.focus()
      }
    }
    
    hideCountryDropdown() {
      this.countryDropdownTarget.classList.remove('block', 'opacity-100', 'scale-100')
      this.countryDropdownTarget.classList.add('hidden', 'opacity-0', 'scale-95')
      
      if (this.hasCountrySearchTarget) {
        this.countrySearchTarget.value = ''
        this.filterCountries()
      }
    }
    
    selectCountry(event) {
      const countryCode = event.currentTarget.dataset.code
      const countryDialCode = event.currentTarget.dataset.dialCode
      const countryFlag = event.currentTarget.dataset.flag
      
      this.countryFlagTarget.textContent = countryFlag
      this.countryCodeTarget.textContent = countryDialCode
      if (this.hasCountryCodeInputTarget) {
        this.countryCodeInputTarget.value = countryCode
      }
      
      this.hideCountryDropdown()
      this.phoneInputTarget.focus()
    }
    
    filterCountries() {
      if (!this.hasCountrySearchTarget || !this.hasCountriesListTarget) return
      
      const query = this.countrySearchTarget.value.toLowerCase()
      const items = this.countriesListTarget.querySelectorAll('li')
      
      items.forEach(item => {
        const countryName = item.dataset.name.toLowerCase()
        if (countryName.includes(query)) {
          item.classList.remove('hidden')
        } else {
          item.classList.add('hidden')
        }
      })
    }
    
    formatNumber() {
      // Implement phone number formatting based on selected country
      // This is a placeholder - consider using a library like libphonenumber-js for production
    }
    
    loadCountries() {
      // Define a list of common countries (for brevity)
      // In production, you might fetch this from an API or use a more complete list
      const countries = [
        { code: 'GH', name: 'Ghana', dialCode: '+233', flag: '🇬🇭' },
        { code: 'NG', name: 'Nigeria', dialCode: '+234', flag: '🇳🇬' },
        { code: 'KE', name: 'Kenya', dialCode: '+254', flag: '🇰🇪' },
        { code: 'ZA', name: 'South Africa', dialCode: '+27', flag: '🇿🇦' },
        { code: 'US', name: 'United States', dialCode: '+1', flag: '🇺🇸' },
        { code: 'GB', name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧' },
        { code: 'CA', name: 'Canada', dialCode: '+1', flag: '🇨🇦' },
        { code: 'IN', name: 'India', dialCode: '+91', flag: '🇮🇳' },
        { code: 'DE', name: 'Germany', dialCode: '+49', flag: '🇩🇪' },
        { code: 'FR', name: 'France', dialCode: '+33', flag: '🇫🇷' }
      ]
      
      // Set default country
      const defaultCountry = countries.find(c => c.code === this.defaultCountryValue) || countries[0]
      this.countryFlagTarget.textContent = defaultCountry.flag
      this.countryCodeTarget.textContent = defaultCountry.dialCode
      if (this.hasCountryCodeInputTarget) {
        this.countryCodeInputTarget.value = defaultCountry.code
      }
      
      // Populate countries list
      this.countriesListTarget.innerHTML = ''
      countries.forEach(country => {
        const item = document.createElement('li')
        item.className = 'cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700 px-3 py-2'
        item.dataset.code = country.code
        item.dataset.dialCode = country.dialCode
        item.dataset.flag = country.flag
        item.dataset.name = country.name
        item.dataset.action = 'click->phone-input#selectCountry'
        item.innerHTML = `
          <div class="flex items-center">
            <span class="mr-2 text-lg">${country.flag}</span>
            <span class="text-gray-900 dark:text-white font-medium">${country.name}</span>
            <span class="ml-auto text-gray-500 dark:text-gray-400">${country.dialCode}</span>
          </div>
        `
        this.countriesListTarget.appendChild(item)
      })
    }
  }