module Storage
  class Bucket
    def initialize(bucket_name)
      Aws.config.update({
                            region: 'eu-west-1',
                            credentials: Aws::Credentials.new(ENV['ENTOURAGE_AWS_ACCESS_KEY_ID'], ENV['ENTOURAGE_AWS_SECRET_ACCESS_KEY']),
                        })
      @bucket = Aws::S3::Bucket.new(bucket_name)
    end

    def url_for(key:, extra: {})
      expire = extra[:expire] || 3600
      bucket.object(key_with_folder(key)).presigned_url(:get, expires_in: expire)
    end

    def upload(file:, key:, extra: {})
      bucket.object(key_with_folder(key)).upload_file(file, content_type: extra[:content_type])
    end

    def destroy(key:)
      bucket.object(key_with_folder(key)).delete
    end

    private
    attr_reader :bucket

    def key_with_folder(key)
      ENV["ENTOURAGE_AVATARS_FOLDER"] ? "#{ENV["ENTOURAGE_AVATARS_FOLDER"]}/#{key}" : key
    end
  end
end