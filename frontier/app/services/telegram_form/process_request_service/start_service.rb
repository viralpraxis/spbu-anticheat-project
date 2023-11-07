# frozen_string_literal: true

class TelegramForm::ProcessRequestService::StartService < TelegramForm::ProcessRequestService::ApplicationService
  def call
    telegram_chat.telegram_forms.incompleted.take&.destroy!

    options = {}
    event, telegram_form_stage = if telegram_chat.completed? && (course = telegram_chat.latest_submitted_course)
      options = { course: }
      %i[updated_to_course_provided_stage course_provided]
    elsif telegram_chat.completed?
      %i[telegram_chat_group_provided telegram_chat_populated]
    else
      %i[updated_to_created_stage created]
    end

    telegram_form = telegram_chat.telegram_forms.create!(telegram_chat:, stage: telegram_form_stage, **options)

    success! event:, context: { telegram_form: }
  end
end
