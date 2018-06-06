class PostReplacement < ApplicationRecord
  DELETION_GRACE_PERIOD = 30.days

  belongs_to :post
  belongs_to :creator, class_name: "User"
  before_validation :initialize_fields, on: :create
  attr_accessor :replacement_file, :final_source, :tags

  def initialize_fields
    self.creator = CurrentUser.user
    self.original_url = post.source
    self.tags = post.tag_string + " " + self.tags.to_s

    self.file_ext_was =  post.file_ext
    self.file_size_was = post.file_size
    self.image_width_was = post.image_width
    self.image_height_was = post.image_height
    self.md5_was = post.md5
  end

  def undo!
    undo_replacement = post.replacements.create(replacement_url: original_url)
    undo_replacement.process!
  end

  def update_ugoira_frame_data(upload)
    post.pixiv_ugoira_frame_data.destroy if post.pixiv_ugoira_frame_data.present?
    upload.ugoira_service.save_frame_data(post) if post.is_ugoira?
  end

  module SearchMethods
    def post_tags_match(query)
      PostQueryBuilder.new(query).build(self.joins(:post))
    end

    def search(params = {})
      q = super

      if params[:creator_id].present?
        q = q.where(creator_id: params[:creator_id].split(",").map(&:to_i))
      end

      if params[:creator_name].present?
        q = q.where(creator_id: User.name_to_id(params[:creator_name]))
      end

      if params[:post_id].present?
        q = q.where(post_id: params[:post_id].split(",").map(&:to_i))
      end

      if params[:post_tags_match].present?
        q = q.post_tags_match(params[:post_tags_match])
      end

      q.apply_default_order(params)
    end
  end

  extend SearchMethods
end
