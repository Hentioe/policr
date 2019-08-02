module Policr
  class TemplateCommander < Commander
    match :template

    def handle(msg)
      reply_menu do
        reply({
          text:         paste_text,
          reply_markup: paste_markup,
        })
      end
    end

    def_text do
      t "template.desc"
    end
  end
end
