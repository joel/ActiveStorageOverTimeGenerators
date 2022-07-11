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

      regex = %r{/rails/active_storage/blobs/redirect/(?<message>.+--\w+)/(\w+)\.(\w+)\Z}
      path_for_attachment = polymorphic_path(attachment.asset, only_path: true)

      assert_match(
        regex,
        path_for_attachment,
        "Active Storage URL not recognized"
      )

      message = path_for_attachment.match(regex)[:message]

      assert_equal(attachment.asset.id, ActiveStorage.verifier.verify(message, purpose: "blob_id"))
    end

    test "Rails 5.x compatibility" do
      # Rails 5.x keys the blob_id in the URL
      message = "eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBCZz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--6c13b469ea9800834de3cef4976b4ef57c9d7211"
      assert_equal(attachment.asset.id, ActiveStorage.verifier.verify(message, purpose: "blob_id"))
    end

  end
end
