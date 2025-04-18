module QrCodeHelper
  def qr_code_as_svg(text, options = {})
    # Automatically determine size based on text length
    # For longer text, we need a larger size
    text_length = text.to_s.length

    # Dynamic size calculation
    size = if text_length > 500
      12
    elsif text_length > 300
      10
    elsif text_length > 100
      8
    else
      6
    end

    # Override with options if provided
    size = options[:size] if options[:size]
    level = options[:level] || :q

    # Create QR code with appropriate size
    begin
      qrcode = RQRCode::QRCode.new(text, size: size, level: level)
    rescue RQRCode::QRCodeRunTimeError => e
      # If we get an error, try with a larger size
      if size < 40 # Maximum QR code size is 40
        size += 2
        retry
      else
        # If we've reached the maximum size, simplify the data
        simplified_text = text.to_s.truncate(100) # Truncate to a reasonable length
        qrcode = RQRCode::QRCode.new(simplified_text, size: 10, level: level)
      end
    end

    # Generate SVG with proper styling for both light and dark modes
    qrcode.as_svg(
      offset: 0,
      color: options[:color] || "000",
      shape_rendering: "crispEdges",
      module_size: options[:module_size] || 6,
      standalone: true,
      use_path: true
    ).html_safe
  end

  def payment_link_for_user(user)
    # Generate a payment link for the user
    # This would typically include the user's wallet ID or other identifier
    wallet = user.wallet

    # Base URL for the payment
    base_url = Rails.application.routes.url_helpers.root_url

    # Remove trailing slash if present
    base_url = base_url.chomp("/")

    # Create the payment link
    "#{base_url}/pay/#{wallet.wallet_id}"
  end
end
