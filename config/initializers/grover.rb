Grover.configure do |config|
  config.options = {
    format: 'A4', # Page size
    margin: {
      top: '1cm',
      bottom: '1cm',
      left: '1cm',
      right: '1cm'
    },
    prefer_css_page_size: true,
    emulate_media: 'screen',
    print_background: true,
    extra_http_headers: { 'Accept-Language': 'pt-BR' },
    timezone: 'America/Sao_Paulo',
    formats: :html, encoding: 'utf8',
    display_url: 'http://localhost:3000', # Required for relative URLs
    fonts: ['Arial', 'Helvetica', 'sans-serif'], # Use default system fonts
  }

end
