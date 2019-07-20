module Policr::Model
  class Language < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      code: Int32,
      auto: Int32,
      created_at: Time?,
      updated_at: Time?
    )

    def self.add(chat_id, code : LanguageCode, auto : EnableStatus)
      create({
        chat_id: chat_id.to_i64,
        code:    code.value,
        auto:    auto.value,
      })
    end

    def self.find(chat_id)
      where { (_chat_id == chat_id) }.first
    end

    def self.find_or_create(chat_id, data : NamedTuple? = nil)
      lang = find(chat_id)
      lang ||= create!(data)

      lang
    end
  end
end
