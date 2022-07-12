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

      regex = %r{/rails/active_storage/blobs/(?<message>\w+--\w+)/(\w+)\.(\w+)\Z}
      path_for_attachment = polymorphic_path(attachment.asset, only_path: true)

      assert_match(
        regex,
        path_for_attachment,
        "Active Storage URL not recognized"
      )

      message = path_for_attachment.match(regex)[:message]

      assert_equal(attachment.asset.id, ActiveStorage.verifier.verify(message, purpose: "blob_id"))

      assert_equal(
        "eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBCZz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--2f5c0f536abc3a6edbfb947904955b8ee2bda7b6",
        message
      )
    end
  end
end
