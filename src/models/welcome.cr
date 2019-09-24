module Policr::Model
  class Welcome < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      content: String,
      enabled: Bool,
      link_preview_enabled: Bool,
      is_sticker_mode: Bool,
      sticker_file_id: String?,
      created_at: Time?,
      updated_at: Time?
    )

    def self.raise_uncreated_content!
      raise Exception.new "Uncreated content"
    end

    def self.raise_missing_field!(field_name)
      raise Exception.new "Missing #{field_name}"
    end

    macro def_toggle(name, column, deps = [] of Symbol)
      def self.enable_{{name.id}}!(chat_id : Int64)
        if w = find_by_chat_id chat_id
          {% for col in deps %}
            raise_missing_field!({{col.id.stringify}}) if w.{{col.id}} == nil
          {% end %}
          w.update_column {{column}}, true
        else
          raise_uncreated_content!
        end
      end

      def self.disable_{{name.id}}(chat_id : Int64)
        if w = find_by_chat_id chat_id
          w.update_column {{column}}, false
        end
      end

      def self.{{name.id}}_enabled?(chat_id : Int64) : Bool
        if w = find_by_chat_id chat_id
          w.{{column.id}}
        else
          false
        end
      end

      def self.{{name.id}}_disabled?(chat_id : Int64) : Bool
        if w = find_by_chat_id chat_id
          !w.{{column.id}}
        else
          true
        end
      end
    end

    def_toggle "sticker_mode", :is_sticker_mode, deps: [:sticker_file_id]
    def_toggle "link_preview", :link_preview_enabled

    def self.set_content!(chat_id : Int64, content : String)
      if w = find_by_chat_id chat_id
        w.update_column :content, content
        w
      else
        create!({
          chat_id:              chat_id,
          content:              content,
          enabled:              false,
          link_preview_enabled: true,
          is_sticker_mode:      false,
        })
      end
    end

    def self.set_sticker!(chat_id : Int64, file_id : String)
      if w = find_by_chat_id chat_id
        w.update_column :sticker_file_id, file_id
        w
      else
        raise_uncreated_content!
      end
    end

    def self.find_by_chat_id(chat_id : Int64)
      where { _chat_id == chat_id }.first
    end

    def self.enabled?(chat_id : Int64)
      if (w = find_by_chat_id chat_id) && w.enabled
        w
      end
    end

    def self.enable!(chat_id : Int64)
      if w = find_by_chat_id chat_id
        w.update_column :enabled, true
      else
        raise_uncreated_content!
      end
    end

    def self.disable(chat_id : Int64)
      if w = find_by_chat_id chat_id
        w.update_column :enabled, false
      end
    end
  end
end
