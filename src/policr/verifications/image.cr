module Policr
  class ImageVerification < Verification
    make do
      temp_images = Cache.get_images.clone
      true_image_index = Random.rand(0...temp_images.size)
      true_image = temp_images.delete_at true_image_index

      e1_img = temp_images.delete_at Random.rand(0...temp_images.size)
      e2_img = temp_images.delete_at Random.rand(0...temp_images.size)

      {
        3,
        "上图中的内容",
        [
          e1_img.name,
          e2_img.name,
          true_image.name,
          true_image.random_file,
        ],
      }
    end

    def true_index
      3
    end
  end
end
