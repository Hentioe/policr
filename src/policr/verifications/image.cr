module Policr
  class ImageVerification < Verification
    @true_index = 3

    make do
      temp_images = Cache.get_images.clone
      true_image_index = Random.rand(0...temp_images.size)
      true_image = temp_images.delete_at true_image_index

      e1_img = temp_images.delete_at Random.rand(0...temp_images.size)
      e2_img = temp_images.delete_at Random.rand(0...temp_images.size)

      title = "上图中的内容"
      answers = [
        [e1_img.name],
        [e2_img.name],
        [true_image.name],
      ]
      file_path = true_image.random_file
      Question.image_build(@true_index, title, answers, file_path).discord
    end

    def true_index
      @true_index
    end
  end
end
