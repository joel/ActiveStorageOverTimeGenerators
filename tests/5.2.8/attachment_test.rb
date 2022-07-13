require 'test_helper'

module ActiveStorageOverTime
  class AttachmentTest < ActiveSupport::TestCase

    include Rails.application.routes.url_helpers

    test "valid" do
      attachment = Attachment.new

      assert_changes -> { Dir[Rails.root.join("tmp/storage/**/*")].count(&File.method(:file?)) }, +1 do
        attachment.asset = Rack::Test::UploadedFile.new(
          Rails.root.join("../../test/fixtures/blue.png")
        )
      end

      assert Attachment.new.valid?

      assert_nothing_raised { attachment.save! }

      regex = %r{/rails/active_storage/blobs/(?<signature>\w+--\w+)/(\w+)\.(\w+)\Z}
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
    end
  end
end
