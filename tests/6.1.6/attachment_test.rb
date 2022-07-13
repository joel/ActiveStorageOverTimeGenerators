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

      attachment.asset = Rack::Test::UploadedFile.new(
        Rails.root.join("../../test/fixtures/blue.png")
      )

      assert Attachment.new.valid?

      assert_changes -> { Dir[Rails.root.join("tmp/storage/**/*")].count(&File.method(:file?)) }, +1 do
        assert_nothing_raised { attachment.save! }
      end

      regex = %r{/rails/active_storage/blobs/redirect/(?<signature>.+--\w+)/(\w+)\.(\w+)\Z}
      path_for_attachment = polymorphic_path(attachment.asset, only_path: true)

      assert_match(
        regex,
        path_for_attachment,
        "Active Storage URL not recognized"
      )

      signature = path_for_attachment.match(regex)[:signature]

      assert_equal(attachment.asset.id, ActiveStorage.verifier.verify(signature, purpose: "blob_id"))

      assert_equal(
        attachment.id,
        ActiveStorage::Attachment.where(blob: ActiveStorage::Blob.find_signed(signature)).take.record_id
      )

      ref_signature = "eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBCZz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--5a1ccbebccd2e79b89c8d7dbbfd17ee1f23d209c"

      assert_equal(signature.split("--")[0], ref_signature.split("--")[0])

      # generated_key = "\xEF*\xA7O'\xB7\u0011\u0014h\x82\x89\xE1\xB1Ģ\xEDt\xF24\x90P\\\b\xE8P=a\a\xFAB\xFCnb漿\u0001\xE5\xD2\xF2DMo\x85\x90C|G\u00140\xBDƾ\xAC\n2P\x9F\u0005\f\xD79\xC8\xE1"
      generated_key = "\xF8bssAA?\xCCc\xB4\xD5$&>\x91;\xB1^\xBB'uH\u0011 \xED\x8Fi\xF7\xEB\xF2²\xA0\x94\xD9\xE7\xCD-\xBE\xDDcq,\x8C\xFC\x89\xDDS\x9C\xDFH\n\x8C\u0003\x98{\xE4#\u001AR\xA0\xF1\xA4s"

      assert_equal(
        Dummy::Application.key_generator.generate_key("ActiveStorage").force_encoding('UTF-8'),
        generated_key.force_encoding('UTF-8')
      )
    end

    test "Rails 5.x compatibility" do
      # Rails 5.x keys the blob_id in the URL
      signature = "eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBCZz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--5a1ccbebccd2e79b89c8d7dbbfd17ee1f23d209c"
      # assert_equal(1, ActiveStorage.verifier.verify(signature, purpose: "blob_id"))

      # assert_equal(1, ActiveStorage.verifier.verify(signature, purpose: "blob_id"))

      # assert_equal(
      #   1,
      #   ActiveStorage::Attachment.where(blob: ActiveStorage::Blob.find_signed(signature)).take.record_id
      # )
    end

    test "compatibility" do
      verifier = ActiveSupport::MessageVerifier.new('foo')

      token = "BAhJIgxmb28gYmFyBjoGRVQ=--c96da3d84a4293a81f3a30c71afe1492ec82e9d6"

      assert_equal("foo bar", verifier.verify(token))
    end

  end
end
