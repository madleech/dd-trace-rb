# typed: ignore

if %w[1 true].include?((ENV['DD_APPSEC_ENABLED'] || '').downcase)
  begin
    require 'datadog/security'
  rescue StandardError => e
    puts "AppSec failed to load. No security check will be performed. error: #{e.message}"
  end

  begin
    require 'datadog/security/contrib/auto_instrument'
    Datadog::AppSec::Contrib::AutoInstrument.patch_all
  rescue StandardError => e
    puts "AppSec failed to instrument. No security check will be performed. error: #{e.message}"
  end
end
