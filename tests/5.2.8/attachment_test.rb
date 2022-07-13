require 'test_helper'

module ActiveStorageOverTime
  class AttachmentTest < ActiveSupport::TestCase

    include Rails.application.routes.url_helpers

    test "that secret_key_base is correctly set" do
      # That is essential to ensure that the key is correctly generated
      assert_equal(
        Dummy::Application.secret_key_base,
        "your-secret"
      )
    end

    test "the consistency of the behavior" do
      attachment = Attachment.new

      # In Rails 5.x the asset is create when the file is assigned, that change behavior change in Rails 6.x
      assert_changes -> { Dir[Rails.root.join("tmp/storage/**/*")].count(&File.method(:file?)) }, +1 do
        attachment.asset = Rack::Test::UploadedFile.new(
          Rails.root.join("../../test/fixtures/blue.png")
        )
      end

      assert Attachment.new.valid?

      assert_nothing_raised { attachment.save! }

      # That route changes in Rails 6.x
      # get "/rails/active_storage/blobs/:signed_id/*filename" => "active_storage/blobs#show", as: :rails_service_blob
      regex = %r{/rails/active_storage/blobs/(?<signature>\w+--\w+)/(\w+)\.(\w+)\Z}
      path_for_attachment = polymorphic_path(attachment.asset, only_path: true)

      assert_match(
        regex,
        path_for_attachment,
        "Active Storage URL not recognized"
      )

      signature = path_for_attachment.match(regex)[:signature]

      assert ActiveStorage.verifier.valid_message?(signature)

      # We can find the asset in the storage
      assert_equal(attachment.asset.id, ActiveStorage.verifier.verify(signature, purpose: "blob_id"))

      # From the asset we can find the parent record
      assert_equal(
        attachment.id,
        ActiveStorage::Attachment.where(blob: ActiveStorage::Blob.find_signed(signature)).take.record_id
      )

      # Public URL from the service
      assert_nothing_raised do
        ActiveStorage::Current.set(host: "https://www.example.com") { attachment.asset.service_url(expires_in: nil) }
      end

      # That signature was generated with the correct secret key in Rails 5.x
      ref_signature = "eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBCZz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--9112b21ceae0bf2e165f26f05d070864569f7b18"

      # We check the data get encoded the same way over and over again
      # data--digest
      assert_equal(signature, ref_signature)
    end

    test "that the same message verifier always can decode the token" do
      verifier = ActiveSupport::MessageVerifier.new('foo')

      token = verifier.generate("foo bar")

      assert_equal("foo bar", verifier.verify(token))
    end

    test "the generate_key stay constant" do
      generated_key = "\xF8bssAA?\xCCc\xB4\xD5$&>\x91;\xB1^\xBB'uH\x11 \xED\x8Fi\xF7\xEB\xF2\xC2\xB2\xA0\x94\xD9\xE7\xCD-\xBE\xDDcq,\x8C\xFC\x89\xDDS\x9C\xDFH\n\x8C\x03\x98{\xE4#\x1AR\xA0\xF1\xA4s"

      assert_equal(
        Dummy::Application.key_generator.generate_key("ActiveStorage").force_encoding('UTF-8'),
        generated_key.force_encoding('UTF-8')
      )
    end
  end
end
