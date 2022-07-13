require 'test_helper'

module ActiveStorageOverTime
  class AttachmentTest < ActiveSupport::TestCase

    include Rails.application.routes.url_helpers

    test "valid" do

      assert_equal(
        Dummy::Application.secret_key_base,
        "your-secret"
      )

      attachment = Attachment.new

      assert_changes -> { Dir[Rails.root.join("tmp/storage/**/*")].count(&File.method(:file?)) }, +1 do
        attachment.asset = Rack::Test::UploadedFile.new(
          Rails.root.join("../../test/fixtures/blue.png")
        )
      end

      assert Attachment.new.valid?

      assert_nothing_raised { attachment.save! }

      regex = %r{/rails/active_storage/blobs/(?<signature>\w+--\w+)/(\w+)\.(\w+)\Z}
      path_for_attachment = polymorphic_path(attachment.asset, only_path: true) # attachment.asset.service_url (need the host set!)

      assert_match(
        regex,
        path_for_attachment,
        "Active Storage URL not recognized"
      )

      signature = path_for_attachment.match(regex)[:signature]

      assert ActiveStorage.verifier.valid_message?(signature)

      assert_equal(attachment.asset.id, ActiveStorage.verifier.verify(signature, purpose: "blob_id"))

      assert_equal(
        attachment.id,
        ActiveStorage::Attachment.where(blob: ActiveStorage::Blob.find_signed(signature)).take.record_id
      )

      ref_signature = "eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBCZz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--5a1ccbebccd2e79b89c8d7dbbfd17ee1f23d209c"

      assert_equal(signature.split("--")[0], ref_signature.split("--")[0])
      # assert_equal(signature, ref_signature)

      verifier = ActiveSupport::MessageVerifier.new('foo')

      token = verifier.generate("foo bar")

      assert_equal("foo bar", verifier.verify(token))

      generated_key = "\xF8bssAA?\xCCc\xB4\xD5$&>\x91;\xB1^\xBB'uH\x11 \xED\x8Fi\xF7\xEB\xF2\xC2\xB2\xA0\x94\xD9\xE7\xCD-\xBE\xDDcq,\x8C\xFC\x89\xDDS\x9C\xDFH\n\x8C\x03\x98{\xE4#\x1AR\xA0\xF1\xA4s"

      assert_equal(
        Dummy::Application.key_generator.generate_key("ActiveStorage").force_encoding('UTF-8'),
        generated_key.force_encoding('UTF-8')
      )
    end
  end
end
