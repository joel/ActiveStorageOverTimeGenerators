require 'test_helper'

module ActiveStorageOverTime
  class AttachmentTest < ActiveSupport::TestCase

    include Rails.application.routes.url_helpers

    test "use SHA256 instead of SHA1" do
      assert_equal(
        OpenSSL::Digest::SHA256,
        ActiveSupport::KeyGenerator.hash_digest_class
      )
    end

    test "that secret_key_base is correctly set" do
      # That is essential to ensure that the key is correctly generated
      assert_equal(
        Dummy::Application.secret_key_base,
        "your-secret"
      )
    end

    test "the consistency of the behavior" do
      attachment = Attachment.new

      # Test if the old, Rails 5.x, behavior is gone
      assert_no_difference -> { Dir[Rails.root.join("tmp/storage/**/*")].count(&File.method(:file?)) } do
        attachment.asset = Rack::Test::UploadedFile.new(
          Rails.root.join("../../test/fixtures/blue.png")
        )
      end

      assert Attachment.new.valid?

      # In Rails 6.x the asset is create when the record is saved
      assert_changes -> { Dir[Rails.root.join("tmp/storage/**/*")].count(&File.method(:file?)) }, +1 do
        assert_nothing_raised { attachment.save! }
      end

      regex = %r{/rails/active_storage/blobs(/redirect)?/(?<signature>.+--\w+)/(\w+)\.(\w+)\Z}
      path_for_attachment = polymorphic_path(attachment.asset, only_path: true)

      assert_match(
        regex,
        path_for_attachment,
        "Active Storage URL not recognized"
      )

      signature = path_for_attachment.match(regex)[:signature]

      # We can find the asset in the storage
      assert_equal(attachment.asset.id, ActiveStorage.verifier.verify(signature, purpose: "blob_id"))

      # From the asset we can find the parent record
      assert_equal(
        attachment.id,
        ActiveStorage::Attachment.where(blob: ActiveStorage::Blob.find_signed(signature)).take.record_id
      )

      # Public URL from the service
      assert_nothing_raised do
        ActiveStorage::Current.set(host: "https://www.example.com") { attachment.asset.url(expires_in: nil) }
      end

      # That signature was generated with the correct secret key in Rails 5.x
      ref_signature = "eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBCZz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--9112b21ceae0bf2e165f26f05d070864569f7b18"

      # This signature has now changed due to the use of SHA256
      assert_not_equal(signature, ref_signature)
    end

    test "the generated SHA1 key changed due to the use of SHA256" do
      generated_key = "\xF8bssAA?\xCCc\xB4\xD5$&>\x91;\xB1^\xBB'uH\u0011 \xED\x8Fi\xF7\xEB\xF2²\xA0\x94\xD9\xE7\xCD-\xBE\xDDcq,\x8C\xFC\x89\xDDS\x9C\xDFH\n\x8C\u0003\x98{\xE4#\u001AR\xA0\xF1\xA4s"

      assert_not_equal(
        Dummy::Application.key_generator.generate_key("ActiveStorage").force_encoding("ASCII-8BIT"),
        generated_key.force_encoding("ASCII-8BIT")
      )
    end

    test "that the same message verifier always can decode the token" do
      verifier = ActiveSupport::MessageVerifier.new('foo')

      assert_equal(
        verifier.generate("foo bar"),
        "BAhJIgxmb28gYmFyBjoGRVQ=--c96da3d84a4293a81f3a30c71afe1492ec82e9d6"
      )

      # Token generated with Rails 5.x
      token = "BAhJIgxmb28gYmFyBjoGRVQ=--c96da3d84a4293a81f3a30c71afe1492ec82e9d6"

      assert_equal("foo bar", verifier.verify(token))
    end

    test "Rails 5.x compatibility" do
      # Signatue from a Rails 5.x app
      signature = "eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBCZz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--9112b21ceae0bf2e165f26f05d070864569f7b18"

      assert_equal(1, ActiveStorage.verifier.verify(signature, purpose: "blob_id"))
    end

  end
end
