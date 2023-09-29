# frozen_string_literal: true

# Due to breaking changes in Rails 7, ActiveStorage attachments paths generated in earlier Rails versions no longer work.
# This initializer is a fallback to support ActiveStorage attachments paths generated before Rails 7.
#
# See https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#key-generator-digest-class-changing-to-use-sha256

if Rails::VERSION::MAJOR > 6
  Rails.application.config.after_initialize do |app|
    verifier = "ActiveStorage"

    sha1_key_generator = ActiveSupport::KeyGenerator.new(
      app.secret_key_base, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1
    )

    app.message_verifier(verifier).rotate(sha1_key_generator.generate_key(verifier))
  end
end
