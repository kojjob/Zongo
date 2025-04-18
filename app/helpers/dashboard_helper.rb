module DashboardHelper
  # Custom icon helper that renders SVG icons inline
  # This allows for better styling and accessibility
  def icon(name, options = {})
    options[:class] ||= "w-5 h-5"
    options[:stroke] ||= "currentColor"
    options[:fill] ||= "none"
    options[:stroke_width] ||= 2
    options[:aria_hidden] = true unless options.key?(:aria_hidden)

    # Define icons with their paths
    icons = {
      "wallet" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M19 18V6a2 2 0 00-2-2H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2zM16 12h2"/></svg>),

      "money-in" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><circle cx="12" cy="12" r="10"/><polyline points="12 16 12 8"/><polyline points="8 12 12 8 16 12"/></svg>),

      "money-out" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><circle cx="12" cy="12" r="10"/><polyline points="12 8 12 16"/><polyline points="8 12 12 16 16 12"/></svg>),

      "transfer" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><line x1="10" y1="13" x2="21" y2="13"></line><line x1="3" y1="7" x2="14" y2="7"></line><polyline points="17 10 21 13 17 16"></polyline><polyline points="7 4 3 7 7 10"></polyline></svg>),

      "user" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>),

      "calendar" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>),

      "chart-bar" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><rect x="3" y="12" width="6" height="8" rx="1"></rect><rect x="9" y="8" width="6" height="12" rx="1"></rect><rect x="15" y="4" width="6" height="16" rx="1"></rect></svg>),

      "shield" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>),

      "shield-check" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path><path d="M9 12l2 2 4-4"></path></svg>),

      "refresh" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M23 4v6h-6"></path><path d="M1 20v-6h6"></path><path d="M3.51 9a9 9 0 0114.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0020.49 15"></path></svg>),

      "plus-circle" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="16"></line><line x1="8" y1="12" x2="16" y2="12"></line></svg>),

      "credit-card" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"></rect><line x1="1" y1="10" x2="23" y2="10"></line></svg>),

      "history" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>),

      "mobile-screen" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><rect x="5" y="2" width="14" height="20" rx="2" ry="2"></rect><line x1="12" y1="18" x2="12.01" y2="18"></line></svg>),

      "file-invoice" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>),

      "qrcode" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect><rect x="14" y="14" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect></svg>),

      "school" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M22 10v6M2 10l10-5 10 5-10 5z"></path><path d="M6 12v5c0 2 2 3 6 3s6-1 6-3v-5"></path></svg>),

      "location-point" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path><circle cx="12" cy="10" r="3"></circle></svg>),

      "question-circle" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><circle cx="12" cy="12" r="10"></circle><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>),

      "dots-horizontal" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><circle cx="12" cy="12" r="1"></circle><circle cx="19" cy="12" r="1"></circle><circle cx="5" cy="12" r="1"></circle></svg>),

      "chevron-right" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><polyline points="9 18 15 12 9 6"></polyline></svg>),

      "arrow-right" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>),

      "piggy-bank" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M19 5c-1.5 0-2.8.8-3.5 2M6.5 20H3v-3.5c0-.82.34-1.6.93-2.17"></path><path d="M3.1 14.43c.3-3.93 3.31-7.43 6.9-7.43 3.93 0 7 3.58 7 8s-3.07 8-7 8c-1.5 0-2.85-.58-4.08-1.5"></path><path d="M14 11h.01"></path></svg>),

      "eye" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>),

      "eye-off" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line></svg>),

      "check-circle" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>),

      "x-circle" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>),

      "alert-triangle" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>),

      "phone" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path></svg>),

      "message-circle" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path></svg>),

      "help-circle" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><circle cx="12" cy="12" r="10"></circle><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>),

      "book-open" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"></path><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"></path></svg>),

      "map-pin" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path><circle cx="12" cy="10" r="3"></circle></svg>),

      "settings" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path></svg>),

      "plus" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>),

      "lightning" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"></path></svg>),

      "empty-wallet" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M19 18V6a2 2 0 00-2-2H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2zM16 12h2"></path><path d="M4 9h2m10-5H8"></path></svg>),

      "light-bulb" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M9 18h6"></path><path d="M10 22h4"></path><path d="M12 2v4"></path><path d="M12 6C8.69 6 6 8.69 6 12c0 2.22 1.5 4.36 4 5.24V18h4v-0.76c2.5-0.88 4-3.02 4-5.24 0-3.31-2.69-6-6-6z"></path></svg>),

      "check" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><polyline points="20 6 9 17 4 12"></polyline></svg>),

      "bell" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path><path d="M13.73 21a2 2 0 0 1-3.46 0"></path></svg>),

      "server" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect><rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect><line x1="6" y1="6" x2="6.01" y2="6"></line><line x1="6" y1="18" x2="6.01" y2="18"></line></svg>),

      "home" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg>),

      "logout" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>),

      "menu" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>),

      "users" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>),

      "chart-bar" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path></svg>),

      "currency-dollar" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="6" x2="12" y2="18"></line><path d="M8 12h8"></path><path d="M10 9c0 0 1.5-1 2-1c1.5 0 2 1 2 2s-1 2-2 2c-1 0-2 1-2 2s.5 2 2 2c.5 0 2-1 2-1"></path></svg>),

      "mail" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path><polyline points="22,6 12,13 2,6"></polyline></svg>),

      "history" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>),

      "refresh" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M23 4v6h-6"></path><path d="M1 20v-6h6"></path><path d="M3.51 9a9 9 0 0114.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0020.49 15"></path></svg>),

      "money-in" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><line x1="12" y1="5" x2="12" y2="19"></line><polyline points="19 12 12 19 5 12"></polyline></svg>),

      "money-out" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><line x1="12" y1="19" x2="12" y2="5"></line><polyline points="5 12 12 5 19 12"></polyline></svg>),

      "mobile-screen" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><rect x="5" y="2" width="14" height="20" rx="2" ry="2"></rect><line x1="12" y1="18" x2="12.01" y2="18"></line></svg>),

      "file-invoice" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>),

      "wallet" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M19 5H5a2 2 0 00-2 2v10a2 2 0 002 2h14a2 2 0 002-2V7a2 2 0 00-2-2z"></path><path d="M21 12h-4a2 2 0 010-4h4"></path></svg>),

      "shield-check" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path><polyline points="9 12 11 14 15 10"></polyline></svg>),

      "eye-off" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line></svg>),

      "eye" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>),

      "plus-circle" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="16"></line><line x1="8" y1="12" x2="16" y2="12"></line></svg>),

      "calendar" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>),

      "qrcode" => %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect><rect x="14" y="14" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect></svg>)
    }

    # Return the SVG for the requested icon or a fallback
    icons[name.to_s] || %Q(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#{options[:fill]}" stroke="#{options[:stroke]}" stroke-width="#{options[:stroke_width]}" stroke-linecap="round" stroke-linejoin="round" class="#{options[:class]}" aria-hidden="#{options[:aria_hidden]}"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>)
  end

  # Format currency amount for better readability
  # This is especially helpful for less literate users
  def format_amount(amount, currency = "₵")
    # Handle nil or zero amount
    return "#{currency} 0" if amount.nil? || amount.zero?

    # Convert to absolute value for formatting
    abs_amount = amount.abs

    # Format with thousand separators
    formatted = number_with_delimiter(abs_amount)

    # Add positive/negative sign
    prefix = amount.negative? ? "-" : "+"
    prefix = "" if amount.negative? == false && !options[:always_show_sign]

    "#{prefix}#{currency} #{formatted}"
  end

  # Create a color class based on transaction amount
  # Green for positive, red for negative
  def amount_color_class(amount)
    if amount.nil? || amount.zero?
      "text-gray-600 dark:text-gray-400"
    elsif amount.positive?
      "text-green-600 dark:text-green-400"
    else
      "text-red-600 dark:text-red-400"
    end
  end

  # Calculate the percentage of a progress bar
  def calculate_percentage(current, target)
    return 0 if target.nil? || target.zero?
    percentage = ((current.to_f / target.to_f) * 100).round
    [ percentage, 100 ].min # Ensure percentage doesn't exceed 100%
  end

  # Generate random bright colors for visual elements
  # This helps create visually distinct elements that are easier to recognize
  def random_color
    colors = [
      "bg-primary-500", "bg-secondary-500", "bg-accent-500",
      "bg-green-500", "bg-blue-500", "bg-purple-500",
      "bg-red-500", "bg-yellow-500", "bg-indigo-500",
      "bg-pink-500", "bg-teal-500"
    ]
    colors.sample
  end

  # Format date in a more friendly way
  # "Today", "Yesterday", or formatted date
  def friendly_date(date)
    return "N/A" unless date

    today = Date.today

    if date.to_date == today
      "Today"
    elsif date.to_date == today - 1.day
      "Yesterday"
    elsif date.to_date > today - 7.days
      date.strftime("%A") # Day name
    else
      date.strftime("%d %b %Y") # Formatted date
    end
  end

  # Format time in 12-hour format with AM/PM
  def friendly_time(time)
    return "N/A" unless time
    time.strftime("%I:%M %p") # 12-hour clock with AM/PM
  end

  # Simplify transaction descriptions
  # Makes descriptions more accessible for less literate users
  def simplified_transaction_type(type)
    case type.to_s.downcase
    when "deposit"
      "Money In"
    when "withdrawal"
      "Money Out"
    when "transfer"
      "Transfer"
    when "payment"
      "Payment"
    else
      type.to_s.titleize
    end
  end

  # Generate transaction icon based on type
  def transaction_icon_class(type, is_incoming = false)
    base_class = "w-10 h-10 rounded-full flex items-center justify-center mr-3"

    case type.to_s.downcase
    when "deposit", "money_in"
      "#{base_class} bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400"
    when "withdrawal", "money_out"
      "#{base_class} bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400"
    when "transfer"
      if is_incoming
        "#{base_class} bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400"
      else
        "#{base_class} bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400"
      end
    when "payment"
      "#{base_class} bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400"
    when "airtime"
      "#{base_class} bg-yellow-100 dark:bg-yellow-900/30 text-yellow-600 dark:text-yellow-400"
    else
      "#{base_class} bg-gray-100 dark:bg-gray-900/30 text-gray-600 dark:text-gray-400"
    end
  end

  # Helper to display security level based on user settings
  def security_level(user)
    # Count security measures that are enabled
    measures = []

    # Check for PIN
    measures << "pin" if user.respond_to?(:pin_digest) && user.pin_digest.present?

    # Check for 2FA
    measures << "2fa" if user.respond_to?(:two_factor_enabled) && user.two_factor_enabled

    # Check for biometrics
    measures << "biometrics" if user.respond_to?(:biometrics_enabled) && user.biometrics_enabled

    # Return security level based on number of measures
    case measures.size
    when 0
      { level: "Low", color: "text-red-600 dark:text-red-400", icon: "alert-triangle", message: "Your account is not secure" }
    when 1
      { level: "Basic", color: "text-yellow-600 dark:text-yellow-400", icon: "shield", message: "Basic protection enabled" }
    when 2
      { level: "Good", color: "text-green-600 dark:text-green-400", icon: "shield-check", message: "Good protection level" }
    else
      { level: "Strong", color: "text-blue-600 dark:text-blue-400", icon: "shield-check", message: "Maximum security enabled" }
    end
  end

  # Generate a simple gradient background style
  # Used for visual cards and elements
  def gradient_background(color1, color2)
    "background: linear-gradient(to right, #{color1}, #{color2});"
  end

  # Create visually distinctive patterns for backgrounds
  # These patterns help create recognizable visual elements that
  # are easier to identify for less literate users
  def background_pattern(type = "dots")
    case type
    when "dots"
      "bg-pattern-dots bg-gray-200 dark:bg-gray-800"
    when "lines"
      "bg-[linear-gradient(90deg,rgba(0,0,0,0)_0%,rgba(0,0,0,0)_50%,rgba(0,0,0,0.05)_50%,rgba(0,0,0,0.05)_100%)] bg-[length:8px_8px]"
    when "grid"
      "bg-[linear-gradient(0deg,rgba(0,0,0,0.05)_1px,transparent_1px),linear-gradient(90deg,rgba(0,0,0,0.05)_1px,transparent_1px)] bg-[size:20px_20px]"
    else
      ""
    end
  end

  # Create an animated loading indicator
  def loading_indicator(options = {})
    options[:size] ||= "w-6 h-6"
    options[:color] ||= "text-primary-600 dark:text-primary-400"

    content_tag :div, class: "flex justify-center items-center" do
      content_tag :div, nil, class: "#{options[:size]} border-2 border-t-transparent border-solid rounded-full animate-spin #{options[:color]}"
    end
  end

  # Show a badge with color based on status
  def status_badge(status, text = nil)
    text ||= status.to_s.titleize

    case status.to_s.downcase
    when "completed", "success", "active"
      badge_class = "bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300"
      icon_name = "check-circle"
    when "pending", "processing"
      badge_class = "bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-300"
      icon_name = "clock"
    when "failed", "error", "cancelled"
      badge_class = "bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-300"
      icon_name = "x-circle"
    when "warning", "overdue"
      badge_class = "bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-300"
      icon_name = "alert-triangle"
    else
      badge_class = "bg-gray-100 dark:bg-gray-900/30 text-gray-800 dark:text-gray-300"
      icon_name = "info"
    end

    content_tag :span, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{badge_class}" do
      concat icon(icon_name, class: "w-3.5 h-3.5 mr-1")
      concat text
    end
  end
end
