require 'test_helper'

module ActiveStorageOverTime
  class AttachmentTest < ActiveSupport::TestCase

    include Rails.application.routes.url_helpers

    test "valid" do
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
    end

    test "Rails 5.x compatibility" do
      # Rails 5.x keys the blob_id in the URL
      signature = "eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBCZz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--9112b21ceae0bf2e165f26f05d070864569f7b18"
      # assert_equal(1, ActiveStorage.verifier.verify(signature, purpose: "blob_id"))

      assert_equal(
        1,
        ActiveStorage::Attachment.where(blob: ActiveStorage::Blob.find_signed(signature)).take.record_id
      )
    end

  end
end
