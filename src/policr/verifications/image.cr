module Policr
  class ImageVerification < Verification
    @indeces : Array(Int32) = [Random.rand(1..3)]

    make do
      temp_images = Cache.get_images.clone
      true_image_index = Random.rand(0...temp_images.size)
      true_image = temp_images.delete_at true_image_index

      e1_img = temp_images.delete_at Random.rand(0...temp_images.size)
      e2_img = temp_images.delete_at Random.rand(0...temp_images.size)

      title = "上图中的内容"

      wrong_ans = [e1_img.name, e2_img.name]

      answers = (1..3).map do |i|
        if i == @indeces[0]
          [true_image.name]
        else
          [wrong_ans.delete_at 0]
        end
      end

      file_path = true_image.random_file
      Question.image_build(title, answers, file_path).discord
    end

    def indeces
      @indeces
    end
  end
end
